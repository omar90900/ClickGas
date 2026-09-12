-- =============================================================================
-- ClickGas - coverage and demo readiness
-- (run once, after 20260912200000_revenue_and_charges.sql)
--
-- Some distributors in an area use the app and others don't, so coverage is
-- uneven. This file:
--   1. widens the search for a waiting order: offered within driver_radius_km,
--      growing by radius_step_km every radius_step_minutes up to max_radius_km
--      (2 -> 4 -> 6 km). The dispatch radius goes back to 2 km.
--   2. expires orders nobody accepted within order_expiry_minutes (20), every
--      minute (pg_cron job "clickgas-expire-orders", logged in job_runs).
--   3. lets the customer app check coverage before ordering, records where
--      customers found no distributor (coverage_gaps), and adds
--      admin_coverage() for the dashboard.
--   4. marks demo data (profiles.is_demo, orders.is_demo), adds a per-staff
--      "hide demo data" switch used by the dashboard functions, and
--      service-role-only demo_seed_order / demo_reset_data for tools/demo.
--
-- Documentation: docs/decisions/0012-coverage-expiry-and-demo-data.md,
-- docs/runbooks/demo.md
-- =============================================================================

-- ---------------------------------------------------------------- 1. wider search
alter table public.app_config
  add column radius_step_km numeric(5, 2) not null default 2 check (radius_step_km >= 0),
  add column radius_step_minutes smallint not null default 5 check (radius_step_minutes between 1 and 60),
  add column max_radius_km numeric(5, 2) not null default 6 check (max_radius_km > 0),
  add column order_expiry_minutes smallint not null default 20 check (order_expiry_minutes between 5 and 240);
comment on column public.app_config.radius_step_km is 'A waiting order is offered this much further every radius_step_minutes.';
comment on column public.app_config.radius_step_minutes is 'Minutes between search widenings.';
comment on column public.app_config.max_radius_km is 'The search never goes beyond this distance.';
comment on column public.app_config.order_expiry_minutes is 'Pending orders older than this are expired by expire_stale_orders().';

update public.app_config set driver_radius_km = 2 where id;

create or replace function public.order_radius_km(p_created_at timestamptz)
returns numeric language sql stable security definer set search_path = '' as $$
  select greatest(c.driver_radius_km,
                  least(c.max_radius_km,
                        c.driver_radius_km + c.radius_step_km *
                          floor(greatest(extract(epoch from now() - p_created_at), 0) / 60
                                / c.radius_step_minutes)))
    from public.app_config c
   where c.id;
$$;
comment on function public.order_radius_km(timestamptz) is
  'How far a pending order placed at p_created_at is offered right now (km): the dispatch radius, widened step by step up to max_radius_km.';

drop function if exists public.nearby_orders(double precision, double precision);
create function public.nearby_orders(p_lat double precision, p_lng double precision)
returns table (
  id uuid, order_number bigint, customer_name text, customer_avatar text,
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
    select o.id, o.order_number, p.full_name, p.avatar_url, o.service_name_ar,
           o.service_name_en, o.quantity, o.total_price, o.payment_method,
           o.delivery_lat, o.delivery_lng, o.delivery_address, o.notes,
           o.created_at, x.dist
      from public.orders o
      join public.profiles p on p.id = o.customer_id
      cross join lateral (
        select public.distance_m(p_lat, p_lng, o.delivery_lat, o.delivery_lng) as dist
      ) x
     where o.status = 'pending'
       and x.dist <= public.order_radius_km(o.created_at) * 1000
     order by x.dist
     limit 50;
end $$;
comment on function public.nearby_orders(double precision, double precision) is
  'Pending orders within their current search radius (order_radius_km) of the given point, nearest first. Error: NOT_A_VERIFIED_DRIVER.';
revoke execute on function public.nearby_orders(double precision, double precision) from public, anon;
grant execute on function public.nearby_orders(double precision, double precision) to authenticated;

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
       > public.order_radius_km(o.created_at) * 1000 * 1.25 then
    raise exception 'ORDER_TOO_FAR'
      using detail = format('order %s is offered within %s km', o.order_number, public.order_radius_km(o.created_at));
  end if;

  update public.orders
     set status = 'accepted', driver_id = auth.uid(), accepted_at = now()
   where id = o.id
  returning * into o;
  return o;
end $$;
comment on function public.accept_order(uuid) is
  'Distributor accepts a pending order (within 1.25 x its current search radius). Errors: NOT_A_VERIFIED_DRIVER, DRIVER_OFFLINE, MAX_ACTIVE_ORDERS, ORDER_NOT_AVAILABLE, NOT_ENOUGH_CYLINDERS, ORDER_TOO_FAR.';

-- ---------------------------------------------------------------- 2. expiry
create or replace function public.expire_stale_orders()
returns integer language plpgsql security definer set search_path = '' as $$
declare
  v_run bigint;
  v_numbers bigint[];
begin
  insert into public.job_runs (job) values ('expire_orders') returning id into v_run;
  with expired as (
    update public.orders o
       set status = 'expired'
     where o.status = 'pending'
       and o.created_at < now() - make_interval(
             mins => (select c.order_expiry_minutes from public.app_config c where c.id))
    returning o.order_number
  )
  select coalesce(array_agg(order_number), '{}') into v_numbers from expired;
  update public.job_runs
     set finished_at = now(), ok = true,
         detail = jsonb_build_object('expired', cardinality(v_numbers), 'orders', to_jsonb(v_numbers))
   where id = v_run;
  -- Keep the log small: successful runs for 2 days, failures for 30.
  delete from public.job_runs
   where job = 'expire_orders'
     and ((ok and started_at < now() - interval '2 days') or started_at < now() - interval '30 days');
  return cardinality(v_numbers);
exception when others then
  insert into public.job_runs (job, finished_at, ok, detail)
  values ('expire_orders', now(), false, jsonb_build_object('error', sqlerrm));
  return 0;
end $$;
comment on function public.expire_stale_orders() is
  'Scheduled every minute: pending orders older than order_expiry_minutes become expired (as the system). Logs each run in job_runs.';

do $$
begin
  create extension if not exists pg_cron;
  perform cron.schedule('clickgas-expire-orders', '* * * * *', 'select public.expire_stale_orders()');
exception when others then
  raise notice 'pg_cron not available (%) - schedule public.expire_stale_orders() manually', sqlerrm;
end $$;

-- ---------------------------------------------------------------- 3. coverage
create table public.coverage_gaps (
  id bigint generated always as identity primary key,
  customer_id uuid references public.profiles (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  city_id smallint references public.cities (id),
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);
comment on table public.coverage_gaps is
  'A customer checked a location and no distributor was online within max_radius_km (at most one row per customer per 10 minutes). Feeds the unserved-demand map.';
create index coverage_gaps_created_idx on public.coverage_gaps (created_at desc);
alter table public.coverage_gaps enable row level security;
create policy "staff read coverage gaps" on public.coverage_gaps
  for select to authenticated using ((select public.is_staff()));
revoke insert, update, delete on public.coverage_gaps from anon, authenticated;

-- ---------------------------------------------------------------- 4. demo data
alter table public.profiles add column is_demo boolean not null default false;
alter table public.orders add column is_demo boolean not null default false;
alter table public.staff_members add column hide_demo boolean not null default false;
comment on column public.profiles.is_demo is 'Created by tools/demo; removed by the demo reset.';
comment on column public.orders.is_demo is 'Placed by a demo customer (copied from the profile when the order is created).';
comment on column public.staff_members.hide_demo is 'This staff member''s dashboard hides demo data.';

create or replace function private.hide_demo()
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((select s.hide_demo from public.staff_members s where s.user_id = auth.uid()), false);
$$;

-- True when a row should be shown to the calling staff member.
create or replace function private.visible(p_is_demo boolean)
returns boolean language sql stable set search_path = '' as $$
  select not coalesce(p_is_demo, false) or not private.hide_demo();
$$;

-- Seed mode: only demo_seed_order() turns it on, for its own transaction.
-- Clients can't set custom settings through the API.
create or replace function private.seeding()
returns boolean language sql stable set search_path = '' as $$
  select coalesce(current_setting('clickgas.seed', true), '') = 'on';
$$;

create or replace function public.prepare_new_order()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  s public.services;
  v_seed boolean := private.seeding();
  v_delivery numeric(12, 3);
  v_customer_fee numeric(12, 3);
  v_driver_fee numeric(12, 3);
begin
  select * into s from public.services where id = new.service_id and (is_active or v_seed);
  if not found then
    raise exception 'SERVICE_UNAVAILABLE' using detail = format('service_id=%s', new.service_id);
  end if;
  select delivery_fee into v_delivery from public.app_config where id;
  select customer_fee, driver_fee into v_customer_fee, v_driver_fee from public.current_fees;
  v_delivery := coalesce(v_delivery, 0);
  v_customer_fee := coalesce(v_customer_fee, 0);
  v_driver_fee := coalesce(v_driver_fee, 0);

  new.service_code := s.code;
  new.service_name_ar := s.name_ar;
  new.service_name_en := s.name_en;
  new.unit_price := s.price;
  new.delivery_fee := v_delivery;
  new.service_fee := v_customer_fee;
  new.driver_fee := v_driver_fee;
  new.total_price := s.price * new.quantity + v_delivery + v_customer_fee;
  new.is_demo := coalesce((select p.is_demo from public.profiles p where p.id = new.customer_id), false);
  if new.city_id is null then
    select city_id into new.city_id from public.profiles where id = new.customer_id;
  end if;

  if v_seed then
    -- tools/demo writes history: keep the given status, distributor and times.
    new.created_at := coalesce(new.created_at, now());
    new.updated_at := coalesce(new.updated_at, new.created_at);
    return new;
  end if;

  new.status := 'pending';
  new.driver_id := null;
  new.rating := null;
  new.rating_comment := null;
  new.cancel_reason := null;
  new.customer_confirmed_at := null;
  new.created_at := now();
  new.updated_at := now();
  new.accepted_at := null;
  new.on_the_way_at := null;
  new.delivered_at := null;
  new.cancelled_at := null;
  return new;
end $$;

create or replace function public.log_order_event()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if private.seeding() then
    return new; -- demo_seed_order writes its own backdated events
  end if;
  if tg_op = 'INSERT' or new.status is distinct from old.status then
    insert into public.order_events (order_id, status, actor_id)
    values (new.id, new.status, auth.uid());
  end if;
  return new;
end $$;

-- Customer: is anyone serving this spot right now? Records a gap if not.
create or replace function public.coverage_check(p_lat double precision, p_lng double precision)
returns jsonb language plpgsql volatile security definer set search_path = '' as $$
declare
  cfg public.app_config;
  v_uid uuid := auth.uid();
  v_nearby int;
  v_nearest double precision;
begin
  if v_uid is null then
    raise exception 'PERMISSION_DENIED' using detail = 'sign in first';
  end if;
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'INVALID_SETTING' using detail = 'coordinates out of range';
  end if;
  select * into cfg from public.app_config where id;
  select count(*) filter (where x.dist <= cfg.max_radius_km * 1000), min(x.dist)
    into v_nearby, v_nearest
    from public.drivers d
    cross join lateral (select public.distance_m(p_lat, p_lng, d.lat, d.lng) as dist) x
   where d.is_online and d.status = 'approved' and d.lat is not null and d.lng is not null
     and d.location_updated_at > now() - interval '10 minutes';
  if v_nearby = 0 and not exists (
       select 1 from public.coverage_gaps g
        where g.customer_id = v_uid and g.created_at > now() - interval '10 minutes') then
    insert into public.coverage_gaps (customer_id, lat, lng, city_id, is_demo)
    select v_uid, p_lat, p_lng, p.city_id, p.is_demo from public.profiles p where p.id = v_uid;
  end if;
  return jsonb_build_object(
    'nearby', v_nearby,
    'nearest_km', round((v_nearest / 1000)::numeric, 1),
    'radius_km', cfg.driver_radius_km,
    'max_radius_km', cfg.max_radius_km,
    'expiry_minutes', cfg.order_expiry_minutes);
end $$;
comment on function public.coverage_check(double precision, double precision) is
  'Customer: online distributors within max_radius_km of a point and the nearest distance. Records a coverage gap when there are none. Errors: PERMISSION_DENIED, INVALID_SETTING.';

create or replace function public.demo_seed_order(p jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
  v_status public.order_status := coalesce(p ->> 'status', 'delivered')::public.order_status;
  v_created timestamptz := coalesce((p ->> 'created_at')::timestamptz, now());
  v_accepted timestamptz := (p ->> 'accepted_at')::timestamptz;
  v_delivered timestamptz := (p ->> 'delivered_at')::timestamptz;
  v_cancelled timestamptz := (p ->> 'cancelled_at')::timestamptz;
  v_expired timestamptz;
  v_driver uuid := (p ->> 'driver_id')::uuid;
begin
  if not exists (select 1 from public.profiles
                  where id = (p ->> 'customer_id')::uuid and is_demo) then
    raise exception 'INVALID_TARGET' using detail = 'demo orders need a demo customer';
  end if;
  if v_status = 'expired' then
    v_expired := v_created + interval '20 minutes';
  end if;
  perform set_config('clickgas.seed', 'on', true);
  insert into public.orders
    (customer_id, driver_id, service_id, quantity, payment_method, status,
     delivery_lat, delivery_lng, delivery_address, city_id, rating, rating_comment,
     cancel_reason, created_at, updated_at, accepted_at, on_the_way_at, delivered_at,
     cancelled_at, customer_confirmed_at)
  values
    ((p ->> 'customer_id')::uuid, v_driver, coalesce((p ->> 'service_id')::smallint, 1),
     coalesce((p ->> 'quantity')::smallint, 1), 'cash', v_status,
     (p ->> 'lat')::double precision, (p ->> 'lng')::double precision, p ->> 'address',
     nullif(p ->> 'city_id', '')::smallint, (p ->> 'rating')::smallint, p ->> 'rating_comment',
     p ->> 'cancel_reason', v_created,
     coalesce(v_delivered, v_cancelled, v_expired, v_accepted, v_created),
     v_accepted,
     case when v_delivered is not null then v_accepted + interval '3 minutes' end,
     v_delivered, v_cancelled,
     case when v_delivered is not null then v_delivered + interval '10 minutes' end)
  returning * into o;
  insert into public.order_events (order_id, status, actor_id, created_at)
  select o.id, e.status, e.actor, e.at
    from (values
      ('pending'::public.order_status, o.customer_id, v_created),
      ('accepted'::public.order_status, v_driver, v_accepted),
      ('on_the_way'::public.order_status, v_driver, o.on_the_way_at),
      ('delivered'::public.order_status, v_driver, v_delivered),
      ('cancelled'::public.order_status, o.customer_id, v_cancelled),
      ('expired'::public.order_status, null::uuid, v_expired)) as e (status, actor, at)
   where e.at is not null;
  if o.rating is not null and v_driver is not null then
    update public.drivers
       set rating_sum = rating_sum + o.rating, rating_count = rating_count + 1
     where id = v_driver;
  end if;
  perform set_config('clickgas.seed', 'off', true);
  return o.id;
end $$;
comment on function public.demo_seed_order(jsonb) is
  'tools/demo only (service role): writes one past order for a demo customer with its status history. Error: INVALID_TARGET.';

create or replace function public.demo_reset_data()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_actions int;
  v_orders int;
  v_gaps int;
begin
  delete from public.admin_actions a using public.profiles p
   where p.id = a.actor_id and p.is_demo;
  get diagnostics v_actions = row_count;
  delete from public.orders where is_demo;
  get diagnostics v_orders = row_count;
  delete from public.coverage_gaps where is_demo;
  get diagnostics v_gaps = row_count;
  return jsonb_build_object('admin_actions', v_actions, 'orders', v_orders, 'coverage_gaps', v_gaps);
end $$;
comment on function public.demo_reset_data() is
  'tools/demo only (service role): deletes demo orders, gaps and demo staff actions. The script then deletes the demo accounts.';

-- ---------------------------------------------------------------- 5. dashboard
drop function if exists public.admin_whoami();
create function public.admin_whoami()
returns table (user_id uuid, full_name text, email text, role public.staff_role, hide_demo boolean)
language sql stable security definer set search_path = '' as $$
  select p.id, p.full_name, p.email, s.role, s.hide_demo
    from public.staff_members s
    join public.profiles p on p.id = s.user_id
   where s.user_id = auth.uid() and p.role = 'admin' and p.is_active;
$$;
comment on function public.admin_whoami() is
  'The signed-in staff member, role and demo-data preference; no row when the caller is not staff.';

create or replace function public.admin_set_hide_demo(p_hide boolean)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_staff();
  update public.staff_members set hide_demo = coalesce(p_hide, false) where user_id = auth.uid();
  return coalesce(p_hide, false);
end $$;
comment on function public.admin_set_hide_demo(boolean) is
  'The caller''s dashboard shows or hides demo data. Any staff role.';

create or replace function public.admin_overview()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_tz constant text := 'Asia/Amman';
  v_today date := (now() at time zone v_tz)::date;
  v_start timestamptz := (now() at time zone v_tz)::date::timestamp at time zone v_tz;
  v_month timestamptz := date_trunc('month', now() at time zone v_tz) at time zone v_tz;
  v_series jsonb;
  v jsonb;
begin
  perform private.require_staff();

  with o as (
    select * from public.orders where private.visible(is_demo)
  ), days as (
    select g::date as day
      from generate_series((v_today - 13)::timestamp, v_today::timestamp, interval '1 day') as g
  ), placed as (
    select (o.created_at at time zone v_tz)::date as day, count(*) as n
      from o where o.created_at >= v_start - interval '14 days'
     group by 1
  ), done as (
    select (o.delivered_at at time zone v_tz)::date as day, count(*) as n,
           sum(o.service_fee + o.driver_fee) as fees
      from o where o.status = 'delivered' and o.delivered_at >= v_start - interval '14 days'
     group by 1
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'day', days.day,
           'orders', coalesce(placed.n, 0),
           'delivered', coalesce(done.n, 0),
           'fees', coalesce(done.fees, 0)) order by days.day), '[]'::jsonb)
    into v_series
    from days
    left join placed on placed.day = days.day
    left join done on done.day = days.day;

  with o as (
    select * from public.orders where private.visible(is_demo)
  ), d as (
    select dr.* from public.drivers dr join public.profiles p on p.id = dr.id
     where private.visible(p.is_demo)
  )
  select jsonb_build_object(
    'day_start', v_start,
    'orders_today', (select count(*) from o where created_at >= v_start),
    'delivered_today', (select count(*) from o where status = 'delivered' and delivered_at >= v_start),
    'cancelled_today', (select count(*) from o where status = 'cancelled' and cancelled_at >= v_start),
    'expired_today', (select count(*) from o where status = 'expired' and updated_at >= v_start),
    'sales_today', (select coalesce(sum(total_price), 0) from o
                     where status = 'delivered' and delivered_at >= v_start),
    'fees_today', (select coalesce(sum(service_fee + driver_fee), 0) from o
                    where status = 'delivered' and delivered_at >= v_start),
    'fees_month', (select coalesce(sum(service_fee + driver_fee), 0) from o
                    where status = 'delivered' and delivered_at >= v_month),
    'median_accept_seconds', (select percentile_cont(0.5) within group
                                (order by extract(epoch from accepted_at - created_at))
                                from o where accepted_at >= v_start),
    'pending', (select count(*) from o where status = 'pending'),
    'in_progress', (select count(*) from o where status in ('accepted', 'on_the_way')),
    'pending_over_10m', (select count(*) from o
                          where status = 'pending' and created_at < now() - interval '10 minutes'),
    'drivers_online', (select count(*) from d where is_online and status = 'approved'),
    'drivers_approved', (select count(*) from d where status = 'approved'),
    'drivers_awaiting_approval', (select count(*) from d where status = 'pending'),
    'documents_to_review', (select count(*) from public.driver_documents x
                             join d on d.id = x.driver_id where x.status = 'pending'),
    'customers_total', (select count(*) from public.profiles
                         where role = 'customer' and private.visible(is_demo)),
    'customers_new_today', (select count(*) from public.profiles
                             where role = 'customer' and created_at >= v_start and private.visible(is_demo)),
    'charges_open', (select coalesce(sum(c.amount), 0) from public.driver_charges c
                      join d on d.id = c.driver_id where c.status = 'open'),
    'last_14_days', v_series
  ) into v;
  return v;
end $$;

create or replace function public.admin_live_map()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_staff();
  return jsonb_build_object(
    'orders', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'id', o.id, 'order_number', o.order_number, 'status', o.status,
               'quantity', o.quantity, 'total_price', o.total_price,
               'lat', o.delivery_lat, 'lng', o.delivery_lng, 'address', o.delivery_address,
               'created_at', o.created_at, 'accepted_at', o.accepted_at,
               'driver_id', o.driver_id, 'customer_name', p.full_name,
               'service_name_ar', o.service_name_ar, 'service_name_en', o.service_name_en,
               'radius_km', public.order_radius_km(o.created_at), 'is_demo', o.is_demo)
               order by o.created_at), '[]'::jsonb)
        from public.orders o
        join public.profiles p on p.id = o.customer_id
       where o.status in ('pending', 'accepted', 'on_the_way') and private.visible(o.is_demo)),
    'drivers', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'id', d.id, 'full_name', p.full_name, 'phone', p.phone, 'avatar_url', p.avatar_url,
               'lat', d.lat, 'lng', d.lng, 'heading', d.heading, 'is_online', d.is_online,
               'location_updated_at', d.location_updated_at,
               'cylinders_on_board', d.cylinders_on_board, 'vehicle_plate', d.vehicle_plate,
               'is_demo', p.is_demo,
               'open_orders', (select count(*) from public.orders o
                                where o.driver_id = d.id and o.status in ('accepted', 'on_the_way'))
             )), '[]'::jsonb)
        from public.drivers d
        join public.profiles p on p.id = d.id
       where d.lat is not null and d.lng is not null and private.visible(p.is_demo)
         and (d.is_online or exists (select 1 from public.orders o
                                      where o.driver_id = d.id and o.status in ('accepted', 'on_the_way'))))
  );
end $$;

drop function if exists public.admin_list_drivers(public.driver_status, text, uuid);
create function public.admin_list_drivers(
  p_status public.driver_status default null,
  p_search text default null,
  p_driver_id uuid default null
) returns table (
  id uuid, full_name text, phone text, email text, avatar_url text, is_active boolean,
  city_id smallint, created_at timestamptz, vehicle_plate text, vehicle_model text,
  agency_name text, status public.driver_status, status_reason text,
  status_changed_at timestamptz, is_online boolean, lat double precision,
  lng double precision, location_updated_at timestamptz, cylinders_on_board smallint,
  rating_avg numeric, rating_count integer, open_orders bigint, delivered_orders bigint,
  open_charges numeric, documents_pending bigint, documents_total bigint, is_demo boolean
) language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
declare
  v_q text := nullif(trim(p_search), '');
begin
  perform private.require_staff();
  return query
    select d.id, p.full_name, p.phone, p.email, p.avatar_url, p.is_active, d.city_id,
           d.created_at, d.vehicle_plate, d.vehicle_model, d.agency_name, d.status,
           d.status_reason, d.status_changed_at, d.is_online, d.lat, d.lng,
           d.location_updated_at, d.cylinders_on_board,
           case when d.rating_count = 0 then 0::numeric
                else round(d.rating_sum::numeric / d.rating_count, 1) end,
           d.rating_count,
           (select count(*) from public.orders o
             where o.driver_id = d.id and o.status in ('accepted', 'on_the_way')),
           (select count(*) from public.orders o
             where o.driver_id = d.id and o.status = 'delivered'),
           (select coalesce(sum(c.amount), 0)::numeric from public.driver_charges c
             where c.driver_id = d.id and c.status = 'open'),
           (select count(*) from public.driver_documents x
             where x.driver_id = d.id and x.status = 'pending'),
           (select count(*) from public.driver_documents x where x.driver_id = d.id),
           p.is_demo
      from public.drivers d
      join public.profiles p on p.id = d.id
     where (p_status is null or d.status = p_status)
       and (p_driver_id is null or d.id = p_driver_id)
       and (p_driver_id is not null or private.visible(p.is_demo))
       and (v_q is null
            or p.full_name ilike '%' || v_q || '%'
            or p.phone like '%' || v_q || '%'
            or d.vehicle_plate ilike '%' || v_q || '%'
            or d.agency_name ilike '%' || v_q || '%')
     order by (d.status = 'pending') desc, d.created_at desc
     limit 500;
end $$;
comment on function public.admin_list_drivers(public.driver_status, text, uuid) is
  'Distributors with approval state, live state, workload, open charges, document counts and demo flag (pending first); p_driver_id returns one. Any staff role.';

drop function if exists public.admin_list_customers(text, integer, integer);
create function public.admin_list_customers(
  p_search text default null, p_limit integer default 50, p_offset integer default 0
) returns table (
  id uuid, full_name text, phone text, email text, avatar_url text, city_id smallint,
  is_active boolean, created_at timestamptz, orders_total bigint, delivered bigint,
  cancelled bigint, open_orders bigint, last_order_at timestamptz, is_demo boolean,
  total_count bigint
) language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
declare
  v_q text := nullif(trim(p_search), '');
begin
  perform private.require_staff();
  return query
    select p.id, p.full_name, p.phone, p.email, p.avatar_url, p.city_id, p.is_active,
           p.created_at,
           count(o.id),
           count(o.id) filter (where o.status = 'delivered'),
           count(o.id) filter (where o.status = 'cancelled'),
           count(o.id) filter (where o.status in ('pending', 'accepted', 'on_the_way')),
           max(o.created_at),
           p.is_demo,
           count(*) over ()
      from public.profiles p
      left join public.orders o on o.customer_id = p.id
     where p.role = 'customer'
       and private.visible(p.is_demo)
       and (v_q is null
            or p.full_name ilike '%' || v_q || '%'
            or p.phone like '%' || v_q || '%'
            or p.email ilike '%' || v_q || '%')
     group by p.id
     order by p.created_at desc
     limit least(greatest(coalesce(p_limit, 50), 1), 200)
    offset greatest(coalesce(p_offset, 0), 0);
end $$;
comment on function public.admin_list_customers(text, integer, integer) is
  'Customers with order counts and demo flag, newest first, searchable, paged (total_count = all matches). Any staff role.';

create or replace function public.admin_search_orders(
  p_search text default null,
  p_statuses text[] default null,
  p_city_id smallint default null,
  p_driver_id uuid default null,
  p_customer_id uuid default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_limit integer default 50,
  p_offset integer default 0
) returns table (
  id uuid, order_number bigint, status public.order_status, created_at timestamptz,
  accepted_at timestamptz, delivered_at timestamptz, cancelled_at timestamptz,
  customer_id uuid, customer_name text, customer_phone text,
  driver_id uuid, driver_name text, driver_phone text, city_id smallint,
  service_name_ar text, service_name_en text, quantity smallint, total_price numeric,
  service_fee numeric, driver_fee numeric, delivery_address text,
  delivery_lat double precision, delivery_lng double precision, cancel_reason text,
  rating smallint, total_count bigint
) language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
declare
  v_q text := nullif(trim(p_search), '');
  v_number bigint := case when v_q ~ '^[0-9]{1,15}$' then v_q::bigint end;
begin
  perform private.require_staff();
  return query
    select o.id, o.order_number, o.status, o.created_at, o.accepted_at, o.delivered_at,
           o.cancelled_at, o.customer_id, c.full_name, c.phone, o.driver_id, dp.full_name,
           dp.phone, o.city_id, o.service_name_ar, o.service_name_en, o.quantity,
           o.total_price, o.service_fee, o.driver_fee, o.delivery_address, o.delivery_lat,
           o.delivery_lng, o.cancel_reason, o.rating,
           count(*) over ()
      from public.orders o
      join public.profiles c on c.id = o.customer_id
      left join public.profiles dp on dp.id = o.driver_id
     where private.visible(o.is_demo)
       and (v_q is null
            or o.order_number = v_number
            or c.phone like '%' || v_q || '%'
            or c.full_name ilike '%' || v_q || '%'
            or dp.phone like '%' || v_q || '%'
            or dp.full_name ilike '%' || v_q || '%')
       and (p_statuses is null or cardinality(p_statuses) = 0 or o.status::text = any (p_statuses))
       and (p_city_id is null or o.city_id = p_city_id)
       and (p_driver_id is null or o.driver_id = p_driver_id)
       and (p_customer_id is null or o.customer_id = p_customer_id)
       and (p_from is null or o.created_at >= p_from)
       and (p_to is null or o.created_at < p_to)
     order by o.created_at desc
     limit least(greatest(coalesce(p_limit, 50), 1), 200)
    offset greatest(coalesce(p_offset, 0), 0);
end $$;

create or replace function public.admin_finance(p_from timestamptz, p_to timestamptz)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_tz constant text := 'Asia/Amman';
  v jsonb;
begin
  perform private.require_staff();
  if p_from is null or p_to is null or p_to <= p_from or p_to - p_from > interval '400 days' then
    raise exception 'INVALID_SETTING' using detail = 'period: from before to, at most 400 days';
  end if;

  with done as (
    select o.driver_id, o.quantity, o.total_price, o.service_fee, o.driver_fee, o.delivered_at,
           d.agency_name
      from public.orders o
      left join public.drivers d on d.id = o.driver_id
     where o.status = 'delivered' and o.delivered_at >= p_from and o.delivered_at < p_to
       and private.visible(o.is_demo)
  ), days as (
    select g::date as day
      from generate_series((p_from at time zone v_tz)::date::timestamp,
                           ((p_to - interval '1 second') at time zone v_tz)::date::timestamp,
                           interval '1 day') as g
  ), ch as (
    select c.* from public.driver_charges c
      join public.profiles p on p.id = c.driver_id
     where private.visible(p.is_demo)
  )
  select jsonb_build_object(
    'from', p_from,
    'to', p_to,
    'totals', (select jsonb_build_object(
                 'delivered_orders', count(*),
                 'cylinders', coalesce(sum(quantity), 0),
                 'order_value', coalesce(sum(total_price), 0),
                 'customer_fees', coalesce(sum(service_fee), 0),
                 'distributor_fees', coalesce(sum(driver_fee), 0),
                 'platform_fees', coalesce(sum(service_fee + driver_fee), 0))
                 from done),
    'by_day', (select coalesce(jsonb_agg(jsonb_build_object(
                        'day', days.day,
                        'delivered', coalesce(x.n, 0),
                        'fees', coalesce(x.fees, 0)) order by days.day), '[]'::jsonb)
                 from days
                 left join (select (delivered_at at time zone v_tz)::date as day, count(*) as n,
                                   sum(service_fee + driver_fee) as fees
                              from done group by 1) x on x.day = days.day),
    'by_agency', (select coalesce(jsonb_agg(a order by a.fees desc), '[]'::jsonb)
                    from (select coalesce(nullif(trim(agency_name), ''), '') as agency,
                                 count(distinct driver_id) as distributors,
                                 count(*) as delivered,
                                 sum(service_fee + driver_fee) as fees
                            from done group by 1) a),
    'by_distributor', (select coalesce(jsonb_agg(b order by b.fees desc), '[]'::jsonb)
                         from (select done.driver_id, p.full_name,
                                      coalesce(done.agency_name, '') as agency,
                                      count(*) as delivered,
                                      sum(done.total_price) as order_value,
                                      sum(done.service_fee + done.driver_fee) as fees
                                 from done
                                 left join public.profiles p on p.id = done.driver_id
                                group by done.driver_id, p.full_name, done.agency_name
                                order by fees desc
                                limit 100) b),
    'charges', (select jsonb_build_object(
                  'open_count', count(*) filter (where status = 'open'),
                  'open_amount', coalesce(sum(amount) filter (where status = 'open'), 0),
                  'raised_amount', coalesce(sum(amount) filter (where created_at >= p_from and created_at < p_to), 0),
                  'paid_amount', coalesce(sum(amount) filter (where status = 'paid' and settled_at >= p_from and settled_at < p_to), 0),
                  'waived_amount', coalesce(sum(amount) filter (where status = 'waived' and settled_at >= p_from and settled_at < p_to), 0))
                  from ch)
  ) into v;
  return v;
end $$;

create or replace function public.admin_list_charges(
  p_status public.charge_status default null,
  p_driver_id uuid default null,
  p_limit integer default 100,
  p_offset integer default 0
) returns table (
  id bigint, driver_id uuid, driver_name text, driver_phone text, agency_name text,
  order_id uuid, order_number bigint, kind public.charge_kind, title text, note text,
  amount numeric, status public.charge_status, created_at timestamptz,
  created_by_name text, settled_at timestamptz, settled_by_name text, settle_note text,
  total_count bigint
) language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
begin
  perform private.require_staff();
  return query
    select c.id, c.driver_id, dp.full_name, dp.phone, d.agency_name, c.order_id, o.order_number,
           c.kind, c.title, c.note, c.amount, c.status, c.created_at, cb.full_name,
           c.settled_at, sb.full_name, c.settle_note, count(*) over ()
      from public.driver_charges c
      join public.drivers d on d.id = c.driver_id
      join public.profiles dp on dp.id = c.driver_id
      left join public.orders o on o.id = c.order_id
      left join public.profiles cb on cb.id = c.created_by
      left join public.profiles sb on sb.id = c.settled_by
     where (p_status is null or c.status = p_status)
       and (p_driver_id is null or c.driver_id = p_driver_id)
       and (p_driver_id is not null or private.visible(dp.is_demo))
     order by (c.status = 'open') desc, c.created_at desc
     limit least(greatest(coalesce(p_limit, 100), 1), 500)
    offset greatest(coalesce(p_offset, 0), 0);
end $$;

create or replace function public.admin_coverage(p_from timestamptz, p_to timestamptz)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v jsonb;
begin
  perform private.require_staff();
  if p_from is null or p_to is null or p_to <= p_from or p_to - p_from > interval '400 days' then
    raise exception 'INVALID_SETTING' using detail = 'period: from before to, at most 400 days';
  end if;
  with o as (
    select * from public.orders
     where created_at >= p_from and created_at < p_to and private.visible(is_demo)
  ), g as (
    select * from public.coverage_gaps
     where created_at >= p_from and created_at < p_to and private.visible(is_demo)
  )
  select jsonb_build_object(
    'totals', (select jsonb_build_object(
                 'placed', count(*),
                 'accepted', count(*) filter (where accepted_at is not null or status = 'delivered'),
                 'delivered', count(*) filter (where status = 'delivered'),
                 'expired', count(*) filter (where status = 'expired'),
                 'cancelled', count(*) filter (where status = 'cancelled'),
                 'median_accept_seconds', percentile_cont(0.5) within group
                     (order by extract(epoch from accepted_at - created_at))
                     filter (where accepted_at is not null))
                 from o),
    'gaps', (select count(*) from g),
    'by_city', (select coalesce(jsonb_agg(c order by c.placed desc), '[]'::jsonb)
                  from (select o.city_id, ci.name_ar, ci.name_en,
                               count(*) as placed,
                               count(*) filter (where o.accepted_at is not null or o.status = 'delivered') as accepted,
                               count(*) filter (where o.status = 'expired') as expired,
                               (select count(*) from g where g.city_id is not distinct from o.city_id) as gaps,
                               percentile_cont(0.5) within group
                                 (order by extract(epoch from o.accepted_at - o.created_at))
                                 filter (where o.accepted_at is not null) as median_accept_seconds
                          from o left join public.cities ci on ci.id = o.city_id
                         group by o.city_id, ci.name_ar, ci.name_en) c),
    'points', (select coalesce(jsonb_agg(pt order by pt.at desc), '[]'::jsonb)
                 from ((select 'expired'::text as kind, o.delivery_lat as lat, o.delivery_lng as lng,
                               o.created_at as at, o.order_number, o.id::text as order_id
                          from o where o.status = 'expired'
                         order by o.created_at desc limit 300)
                       union all
                       (select 'gap'::text, g.lat, g.lng, g.created_at, null::bigint, null::text
                          from g order by g.created_at desc limit 300)) pt),
    'job_runs', (select coalesce(jsonb_agg(j order by j.started_at desc), '[]'::jsonb)
                   from (select job, started_at, finished_at, ok, detail
                           from public.job_runs order by started_at desc limit 10) j)
  ) into v;
  return v;
end $$;
comment on function public.admin_coverage(timestamptz, timestamptz) is
  'Coverage for a period: orders placed / accepted / expired, median time to accept, per city, map points of expired orders and coverage gaps, last job runs. Any staff role. Error: INVALID_SETTING.';

create or replace function public.admin_update_config(p_changes jsonb)
returns public.app_config language plpgsql security definer set search_path = '' as $$
declare
  c public.app_config;
  v_before jsonb;
  v_unknown text;
  v_allowed constant text[] := array[
    'delivery_fee', 'max_quantity', 'search_radius_km', 'support_phone',
    'driver_radius_km', 'max_active_orders', 'auto_verify_drivers',
    'confirm_timeout_minutes', 'min_customer_version', 'min_distributor_version',
    'radius_step_km', 'radius_step_minutes', 'max_radius_km', 'order_expiry_minutes'];
begin
  perform private.require_owner();
  if p_changes is null or jsonb_typeof(p_changes) <> 'object' or p_changes = '{}'::jsonb then
    raise exception 'INVALID_SETTING' using detail = 'expected a JSON object with at least one setting';
  end if;
  select string_agg(k, ', ') into v_unknown
    from jsonb_object_keys(p_changes) as k
   where k <> all (v_allowed);
  if v_unknown is not null then
    raise exception 'INVALID_SETTING' using detail = 'unknown setting: ' || v_unknown;
  end if;

  select * into c from public.app_config where id for update;
  v_before := to_jsonb(c);
  begin
    if p_changes ? 'delivery_fee' then c.delivery_fee := round((p_changes ->> 'delivery_fee')::numeric, 3); end if;
    if p_changes ? 'max_quantity' then c.max_quantity := (p_changes ->> 'max_quantity')::smallint; end if;
    if p_changes ? 'search_radius_km' then c.search_radius_km := (p_changes ->> 'search_radius_km')::numeric; end if;
    if p_changes ? 'support_phone' then c.support_phone := nullif(trim(p_changes ->> 'support_phone'), ''); end if;
    if p_changes ? 'driver_radius_km' then c.driver_radius_km := (p_changes ->> 'driver_radius_km')::numeric; end if;
    if p_changes ? 'max_active_orders' then c.max_active_orders := (p_changes ->> 'max_active_orders')::smallint; end if;
    if p_changes ? 'auto_verify_drivers' then c.auto_verify_drivers := (p_changes ->> 'auto_verify_drivers')::boolean; end if;
    if p_changes ? 'confirm_timeout_minutes' then c.confirm_timeout_minutes := (p_changes ->> 'confirm_timeout_minutes')::smallint; end if;
    if p_changes ? 'min_customer_version' then c.min_customer_version := trim(p_changes ->> 'min_customer_version'); end if;
    if p_changes ? 'min_distributor_version' then c.min_distributor_version := trim(p_changes ->> 'min_distributor_version'); end if;
    if p_changes ? 'radius_step_km' then c.radius_step_km := (p_changes ->> 'radius_step_km')::numeric; end if;
    if p_changes ? 'radius_step_minutes' then c.radius_step_minutes := (p_changes ->> 'radius_step_minutes')::smallint; end if;
    if p_changes ? 'max_radius_km' then c.max_radius_km := (p_changes ->> 'max_radius_km')::numeric; end if;
    if p_changes ? 'order_expiry_minutes' then c.order_expiry_minutes := (p_changes ->> 'order_expiry_minutes')::smallint; end if;
  exception when invalid_text_representation or numeric_value_out_of_range or datatype_mismatch then
    raise exception 'INVALID_SETTING' using detail = 'a value has the wrong type';
  end;

  if c.delivery_fee is null or c.delivery_fee < 0 or c.delivery_fee > 20 then
    raise exception 'INVALID_SETTING' using detail = 'delivery_fee: 0 - 20';
  elsif c.max_quantity is null or c.max_quantity not between 1 and 10 then
    raise exception 'INVALID_SETTING' using detail = 'max_quantity: 1 - 10';
  elsif c.search_radius_km is null or c.search_radius_km not between 0.5 and 100 then
    raise exception 'INVALID_SETTING' using detail = 'search_radius_km: 0.5 - 100';
  elsif c.driver_radius_km is null or c.driver_radius_km not between 0.5 and 50 then
    raise exception 'INVALID_SETTING' using detail = 'driver_radius_km: 0.5 - 50';
  elsif c.max_active_orders is null or c.max_active_orders not between 1 and 10 then
    raise exception 'INVALID_SETTING' using detail = 'max_active_orders: 1 - 10';
  elsif c.confirm_timeout_minutes is null or c.confirm_timeout_minutes not between 5 and 1440 then
    raise exception 'INVALID_SETTING' using detail = 'confirm_timeout_minutes: 5 - 1440';
  elsif c.auto_verify_drivers is null then
    raise exception 'INVALID_SETTING' using detail = 'auto_verify_drivers: true or false';
  elsif c.support_phone is not null and c.support_phone !~ '^\+9627[789][0-9]{7}$' then
    raise exception 'INVALID_SETTING' using detail = 'support_phone: +9627XXXXXXXX';
  elsif c.min_customer_version !~ '^[0-9]+\.[0-9]+\.[0-9]+$'
     or c.min_distributor_version !~ '^[0-9]+\.[0-9]+\.[0-9]+$' then
    raise exception 'INVALID_SETTING' using detail = 'versions look like 1.2.3';
  elsif c.radius_step_km is null or c.radius_step_km not between 0 and 10 then
    raise exception 'INVALID_SETTING' using detail = 'radius_step_km: 0 - 10';
  elsif c.radius_step_minutes is null or c.radius_step_minutes not between 1 and 60 then
    raise exception 'INVALID_SETTING' using detail = 'radius_step_minutes: 1 - 60';
  elsif c.max_radius_km is null or c.max_radius_km < c.driver_radius_km or c.max_radius_km > 50 then
    raise exception 'INVALID_SETTING' using detail = 'max_radius_km: at least driver_radius_km, at most 50';
  elsif c.order_expiry_minutes is null or c.order_expiry_minutes not between 5 and 240 then
    raise exception 'INVALID_SETTING' using detail = 'order_expiry_minutes: 5 - 240';
  end if;

  update public.app_config
     set delivery_fee = c.delivery_fee,
         max_quantity = c.max_quantity,
         search_radius_km = c.search_radius_km,
         support_phone = c.support_phone,
         driver_radius_km = c.driver_radius_km,
         max_active_orders = c.max_active_orders,
         auto_verify_drivers = c.auto_verify_drivers,
         confirm_timeout_minutes = c.confirm_timeout_minutes,
         min_customer_version = c.min_customer_version,
         min_distributor_version = c.min_distributor_version,
         radius_step_km = c.radius_step_km,
         radius_step_minutes = c.radius_step_minutes,
         max_radius_km = c.max_radius_km,
         order_expiry_minutes = c.order_expiry_minutes,
         updated_at = now()
   where id
  returning * into c;
  perform private.audit('config.update', 'config', null, null,
    jsonb_build_object('changes', p_changes, 'before', v_before));
  return c;
end $$;

-- ---------------------------------------------------------------- privileges
do $$
declare
  fn text;
begin
  foreach fn in array array[
    'public.order_radius_km(timestamptz)',
    'public.coverage_check(double precision, double precision)',
    'public.admin_whoami()',
    'public.admin_set_hide_demo(boolean)',
    'public.admin_coverage(timestamptz, timestamptz)',
    'public.admin_list_drivers(public.driver_status, text, uuid)',
    'public.admin_list_customers(text, integer, integer)'
  ] loop
    execute format('revoke execute on function %s from public, anon', fn);
    execute format('grant execute on function %s to authenticated', fn);
  end loop;
  foreach fn in array array[
    'public.expire_stale_orders()',
    'public.demo_seed_order(jsonb)',
    'public.demo_reset_data()'
  ] loop
    execute format('revoke execute on function %s from public, anon, authenticated', fn);
    execute format('grant execute on function %s to service_role', fn);
  end loop;
end $$;
