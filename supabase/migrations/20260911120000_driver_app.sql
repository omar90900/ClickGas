-- =============================================================================
-- ClickGas - driver app support (run once, after 20260911000000_init.sql)
--
--   * Driver sign-up from the driver app (account_type = 'driver'): creates the
--     profile with role 'driver' + an unverified drivers row (vehicle, agency).
--   * Multi-order dispatch: a driver holds up to app_config.max_active_orders
--     orders at once, only within app_config.driver_radius_km, and only if the
--     cylinders on board cover them.
--   * A slot is freed when the customer confirms receipt (or automatically
--     after app_config.confirm_timeout_minutes).
--   * A driver can release (cancel) an accepted order: it goes back to
--     'pending' for other drivers and is logged in order_releases.
-- =============================================================================

-- ---------------------------------------------------------------- columns
alter table public.drivers
  add column agency_name text,
  add column cylinders_on_board smallint not null default 0
    check (cylinders_on_board between 0 and 500);

alter table public.app_config
  add column driver_radius_km numeric(5, 2) not null default 2,
  add column max_active_orders smallint not null default 3,
  add column auto_verify_drivers boolean not null default false,
  add column confirm_timeout_minutes smallint not null default 120;

alter table public.orders
  add column customer_confirmed_at timestamptz;

grant update (cylinders_on_board, agency_name) on public.drivers to authenticated;

-- ---------------------------------------------------------------- releases log
create table public.order_releases (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders (id) on delete cascade,
  driver_id uuid not null references public.drivers (id) on delete cascade,
  order_number bigint not null,
  service_name_ar text not null,
  service_name_en text not null,
  quantity smallint not null,
  total_price numeric(10, 2) not null,
  reason text,
  created_at timestamptz not null default now()
);
create index order_releases_driver_idx on public.order_releases (driver_id, created_at desc);

alter table public.order_releases enable row level security;
create policy "driver reads own releases" on public.order_releases
  for select to authenticated using (driver_id = auth.uid());
revoke insert, update, delete on public.order_releases from anon, authenticated;

-- ---------------------------------------------------------------- sign-up
-- Customer app sends no account_type -> customer. Driver app sends
-- account_type = 'driver' -> driver profile + unverified drivers row.
-- Admin accounts can never be created from the apps.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  is_driver boolean := coalesce(meta ->> 'account_type' = 'driver', false);
  v_city smallint := nullif(meta ->> 'city_id', '')::smallint;
begin
  insert into public.profiles (id, full_name, phone, email, city_id, role)
  values (
    new.id,
    coalesce(meta ->> 'full_name', ''),
    meta ->> 'phone',
    new.email,
    v_city,
    case when is_driver then 'driver'::public.user_role else 'customer'::public.user_role end
  );
  if is_driver then
    insert into public.drivers (id, vehicle_plate, vehicle_model, agency_name, city_id, is_verified)
    values (
      new.id,
      nullif(trim(meta ->> 'vehicle_plate'), ''),
      nullif(trim(meta ->> 'vehicle_type'), ''),
      nullif(trim(meta ->> 'agency_name'), ''),
      v_city,
      coalesce((select auto_verify_drivers from public.app_config where id), false)
    );
  end if;
  return new;
end $$;

-- ---------------------------------------------------------------- helpers
create or replace function public.distance_m(
  lat1 double precision, lng1 double precision,
  lat2 double precision, lng2 double precision
) returns double precision language sql immutable set search_path = '' as $$
  select 2 * 6371000 * asin(sqrt(
    power(sin(radians(lat2 - lat1) / 2), 2) +
    cos(radians(lat1)) * cos(radians(lat2)) * power(sin(radians(lng2 - lng1) / 2), 2)
  ));
$$;

-- Orders currently occupying the driver's slots, and cylinders committed.
create or replace function public.driver_committed_orders(p_driver_id uuid)
returns table (order_count int, cylinders int)
language sql stable security definer set search_path = '' as $$
  select
    count(*)::int,
    coalesce(sum(o.quantity) filter (where o.status in ('accepted', 'on_the_way')), 0)::int
  from public.orders o
  where o.driver_id = p_driver_id
    and (
      o.status in ('accepted', 'on_the_way')
      or (o.status = 'delivered' and o.customer_confirmed_at is null
          and o.delivered_at > now() - make_interval(
            mins => (select c.confirm_timeout_minutes from public.app_config c where c.id)))
    );
$$;

-- ---------------------------------------------------------------- RPC: driver
-- Pending orders within the dispatch radius, nearest first, with the
-- customer's name (profiles are private, so this is the only way to see it).
create or replace function public.nearby_orders(p_lat double precision, p_lng double precision)
returns table (
  id uuid, order_number bigint, customer_name text,
  service_name_ar text, service_name_en text, quantity smallint,
  total_price numeric, payment_method public.payment_method,
  delivery_lat double precision, delivery_lng double precision,
  delivery_address text, notes text, created_at timestamptz, distance_m double precision
) language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
begin
  if not public.is_verified_driver() then
    raise exception 'NOT_A_VERIFIED_DRIVER';
  end if;
  return query
    select o.id, o.order_number, p.full_name, o.service_name_ar, o.service_name_en,
           o.quantity, o.total_price, o.payment_method, o.delivery_lat, o.delivery_lng,
           o.delivery_address, o.notes, o.created_at, x.dist
      from public.orders o
      join public.profiles p on p.id = o.customer_id
      cross join lateral (
        select public.distance_m(p_lat, p_lng, o.delivery_lat, o.delivery_lng) as dist
      ) x
     where o.status = 'pending'
       and x.dist <= (select c.driver_radius_km from public.app_config c where c.id) * 1000
     order by x.dist
     limit 50;
end $$;

-- The driver's accepted / in-progress / awaiting-confirmation orders with
-- the customer's name and phone.
create or replace function public.driver_active_orders()
returns table (
  id uuid, order_number bigint, status public.order_status,
  customer_name text, customer_phone text,
  service_name_ar text, service_name_en text, quantity smallint,
  total_price numeric, payment_method public.payment_method,
  delivery_lat double precision, delivery_lng double precision,
  delivery_address text, notes text, created_at timestamptz,
  accepted_at timestamptz, delivered_at timestamptz, customer_confirmed_at timestamptz
) language sql stable security definer set search_path = '' as $$
  select o.id, o.order_number, o.status, p.full_name, p.phone,
         o.service_name_ar, o.service_name_en, o.quantity, o.total_price,
         o.payment_method, o.delivery_lat, o.delivery_lng, o.delivery_address,
         o.notes, o.created_at, o.accepted_at, o.delivered_at, o.customer_confirmed_at
    from public.orders o
    join public.profiles p on p.id = o.customer_id
   where o.driver_id = auth.uid()
     and (
       o.status in ('accepted', 'on_the_way')
       or (o.status = 'delivered' and o.customer_confirmed_at is null
           and o.delivered_at > now() - make_interval(
             mins => (select c.confirm_timeout_minutes from public.app_config c where c.id)))
     )
   order by o.accepted_at;
$$;

create or replace function public.accept_order(p_order_id uuid)
returns public.orders language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
  d public.drivers;
  cfg public.app_config;
  committed record;
begin
  if not public.is_verified_driver() then
    raise exception 'NOT_A_VERIFIED_DRIVER';
  end if;
  select * into d from public.drivers where id = auth.uid() for update;
  if not d.is_online then
    raise exception 'DRIVER_OFFLINE';
  end if;
  select * into cfg from public.app_config where id;
  select * into committed from public.driver_committed_orders(auth.uid());
  if committed.order_count >= cfg.max_active_orders then
    raise exception 'MAX_ACTIVE_ORDERS';
  end if;

  -- skip locked: if another driver is accepting it right now, it's taken.
  select * into o from public.orders
   where id = p_order_id and status = 'pending'
   for update skip locked;
  if not found then
    raise exception 'ORDER_NOT_AVAILABLE';
  end if;
  if d.cylinders_on_board < committed.cylinders + o.quantity then
    raise exception 'NOT_ENOUGH_CYLINDERS';
  end if;
  if d.lat is not null and d.lng is not null and
     public.distance_m(d.lat, d.lng, o.delivery_lat, o.delivery_lng)
       > cfg.driver_radius_km * 1000 * 1.25 then
    raise exception 'ORDER_TOO_FAR';
  end if;

  update public.orders
     set status = 'accepted', driver_id = auth.uid(), accepted_at = now()
   where id = o.id
  returning * into o;
  return o;
end $$;

create or replace function public.complete_order(p_order_id uuid)
returns public.orders language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
begin
  update public.orders
     set status = 'delivered', delivered_at = now()
   where id = p_order_id and driver_id = auth.uid() and status in ('accepted', 'on_the_way')
  returning * into o;
  if not found then
    raise exception 'INVALID_TRANSITION';
  end if;
  update public.drivers
     set cylinders_on_board = greatest(cylinders_on_board - o.quantity, 0)
   where id = auth.uid();
  return o;
end $$;

create or replace function public.release_order(p_order_id uuid, p_reason text default null)
returns public.orders language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
begin
  select * into o from public.orders
   where id = p_order_id and driver_id = auth.uid() and status in ('accepted', 'on_the_way')
   for update;
  if not found then
    raise exception 'INVALID_TRANSITION';
  end if;
  insert into public.order_releases
    (order_id, driver_id, order_number, service_name_ar, service_name_en, quantity, total_price, reason)
  values
    (o.id, auth.uid(), o.order_number, o.service_name_ar, o.service_name_en, o.quantity, o.total_price, left(p_reason, 200));
  update public.orders
     set status = 'pending', driver_id = null, accepted_at = null, on_the_way_at = null
   where id = o.id
  returning * into o;
  return o;
end $$;

-- ---------------------------------------------------------------- RPC: customer
create or replace function public.confirm_delivery(p_order_id uuid)
returns public.orders language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
begin
  update public.orders
     set customer_confirmed_at = now()
   where id = p_order_id and customer_id = auth.uid()
     and status = 'delivered' and customer_confirmed_at is null
  returning * into o;
  if not found then
    raise exception 'ORDER_NOT_CONFIRMABLE';
  end if;
  return o;
end $$;

-- ---------------------------------------------------------------- privileges
revoke execute on function public.driver_committed_orders(uuid) from public, anon, authenticated;
revoke execute on function public.nearby_orders(double precision, double precision) from public, anon;
revoke execute on function public.driver_active_orders() from public, anon;
revoke execute on function public.release_order(uuid, text) from public, anon;
revoke execute on function public.confirm_delivery(uuid) from public, anon;
grant execute on function public.nearby_orders(double precision, double precision) to authenticated;
grant execute on function public.driver_active_orders() to authenticated;
grant execute on function public.release_order(uuid, text) to authenticated;
grant execute on function public.confirm_delivery(uuid) to authenticated;
