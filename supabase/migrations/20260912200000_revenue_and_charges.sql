-- =============================================================================
-- ClickGas - fees are platform revenue; charges replace the distributor ledger
-- (run once, after 20260912150000_admin_core.sql)
--
-- ClickGas is a service platform: agencies and their distributors own the
-- cylinders; the platform earns only the service fee on each delivered order.
--
--   1. Delivery no longer books a debt for the distributor. The fees stay on
--      the order (service_fee, driver_fee) and are reported as revenue.
--   2. Removed: driver_ledger, driver_balance, record_driver_payment,
--      admin_adjust_balance, admin_balances.
--   3. driver_charges: fines or fees for particular items that staff raise
--      against a distributor, each with a title and an explanation the
--      distributor sees. open -> paid | waived.
--   4. admin_finance(from, to): revenue, per agency and distributor, charges.
--   5. Dashboard functions updated (overview, distributor list, order detail).
--
-- Documentation: docs/decisions/0011-revenue-and-charges.md, docs/api.md#staff
-- =============================================================================

-- ---------------------------------------------------------------- 1. delivery
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
    raise exception 'INVALID_TRANSITION' using detail = format('complete_order order=%s', p_order_id);
  end if;
  update public.drivers
     set cylinders_on_board = greatest(cylinders_on_board - o.quantity, 0)
   where id = auth.uid();
  return o;
end $$;
comment on function public.complete_order(uuid) is
  'Distributor marks an order delivered and lowers stock. The order keeps its fees (platform revenue). Error: INVALID_TRANSITION.';

-- ---------------------------------------------------------------- 2. remove the ledger
drop function if exists public.admin_balances();
drop function if exists public.admin_adjust_balance(uuid, numeric, text);
drop function if exists public.record_driver_payment(uuid, numeric, text);
drop function if exists public.driver_balance();
drop table if exists public.driver_ledger;
drop type if exists public.ledger_kind;

-- ---------------------------------------------------------------- 3. charges
create type public.charge_kind as enum ('fine', 'item_fee', 'other');
create type public.charge_status as enum ('open', 'paid', 'waived');

create table public.driver_charges (
  id bigint generated always as identity primary key,
  driver_id uuid not null references public.drivers (id) on delete cascade,
  order_id uuid references public.orders (id) on delete set null,
  kind public.charge_kind not null,
  title text not null check (char_length(title) between 2 and 80),
  note text not null check (char_length(note) between 3 and 500),
  amount numeric(12, 3) not null check (amount > 0 and amount <= 10000),
  status public.charge_status not null default 'open',
  created_by uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  settled_at timestamptz,
  settled_by uuid references public.profiles (id) on delete set null,
  settle_note text check (char_length(settle_note) <= 300)
);
comment on table public.driver_charges is
  'Fines or fees for particular items raised by staff against a distributor, with an explanation shown to them. Not the per-order service fee.';
comment on column public.driver_charges.note is 'Explanation the distributor sees in their app.';
comment on column public.driver_charges.order_id is 'Optional: the order the charge is about.';
create index driver_charges_driver_idx on public.driver_charges (driver_id, created_at desc);
create index driver_charges_open_idx on public.driver_charges (status) where status = 'open';

alter table public.driver_charges enable row level security;
create policy "driver and staff read charges" on public.driver_charges
  for select to authenticated using (driver_id = auth.uid() or (select public.is_staff()));
revoke insert, update, delete on public.driver_charges from anon, authenticated;

create or replace function public.admin_create_charge(
  p_driver_id uuid,
  p_kind public.charge_kind,
  p_title text,
  p_amount numeric,
  p_note text default null,
  p_order_id uuid default null
) returns public.driver_charges language plpgsql security definer set search_path = '' as $$
declare
  c public.driver_charges;
  v_note text;
  v_number bigint;
begin
  perform private.require_staff(array['operations'::public.staff_role]);
  v_note := private.require_reason(p_note);
  if char_length(trim(coalesce(p_title, ''))) < 2 then
    raise exception 'INVALID_SETTING' using detail = 'title needs 2 characters or more';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 10000 then
    raise exception 'INVALID_AMOUNT' using detail = format('amount=%s', p_amount);
  end if;
  if not exists (select 1 from public.drivers where id = p_driver_id) then
    raise exception 'NOT_FOUND' using detail = format('driver %s', p_driver_id);
  end if;
  if p_order_id is not null then
    select order_number into v_number from public.orders
     where id = p_order_id and driver_id = p_driver_id;
    if not found then
      raise exception 'INVALID_TARGET' using detail = 'the order is not assigned to this distributor';
    end if;
  end if;
  insert into public.driver_charges (driver_id, order_id, kind, title, note, amount)
  values (p_driver_id, p_order_id, p_kind, left(trim(p_title), 80), left(v_note, 500), round(p_amount, 3))
  returning * into c;
  perform private.audit('charge.create', 'driver', p_driver_id::text, v_note,
    jsonb_build_object('charge_id', c.id, 'kind', c.kind, 'title', c.title,
                       'amount', c.amount, 'order_number', v_number));
  return c;
end $$;
comment on function public.admin_create_charge(uuid, public.charge_kind, text, numeric, text, uuid) is
  'Staff raise a fine or item fee against a distributor with an explanation (optionally for one of their orders). Roles: owner, operations. Errors: PERMISSION_DENIED, REASON_REQUIRED, INVALID_SETTING, INVALID_AMOUNT, NOT_FOUND, INVALID_TARGET.';

create or replace function public.admin_settle_charge(
  p_charge_id bigint, p_status public.charge_status, p_note text default null
) returns public.driver_charges language plpgsql security definer set search_path = '' as $$
declare
  c public.driver_charges;
  v_note text := nullif(trim(p_note), '');
begin
  if p_status = 'paid' then
    perform private.require_staff(array['operations'::public.staff_role]);
  elsif p_status = 'waived' then
    perform private.require_owner();
    v_note := private.require_reason(p_note);
  else
    raise exception 'INVALID_SETTING' using detail = 'status must be paid or waived';
  end if;
  select * into c from public.driver_charges where id = p_charge_id for update;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('charge %s', p_charge_id);
  end if;
  if c.status <> 'open' then
    raise exception 'CHARGE_NOT_OPEN' using detail = format('charge %s is %s', c.id, c.status);
  end if;
  update public.driver_charges
     set status = p_status, settled_at = now(), settled_by = auth.uid(), settle_note = left(v_note, 300)
   where id = p_charge_id
  returning * into c;
  perform private.audit('charge.' || p_status::text, 'driver', c.driver_id::text, v_note,
    jsonb_build_object('charge_id', c.id, 'title', c.title, 'amount', c.amount));
  return c;
end $$;
comment on function public.admin_settle_charge(bigint, public.charge_status, text) is
  'Mark an open charge paid (owner, operations) or waive it (owner, with a reason). Errors: PERMISSION_DENIED, REASON_REQUIRED, INVALID_SETTING, NOT_FOUND, CHARGE_NOT_OPEN.';

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
     order by (c.status = 'open') desc, c.created_at desc
     limit least(greatest(coalesce(p_limit, 100), 1), 500)
    offset greatest(coalesce(p_offset, 0), 0);
end $$;
comment on function public.admin_list_charges(public.charge_status, uuid, integer, integer) is
  'Charges with distributor, agency, order and who raised/settled them; open first. Any staff role.';

-- ---------------------------------------------------------------- 4. finance report
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
  ), days as (
    select g::date as day
      from generate_series((p_from at time zone v_tz)::date::timestamp,
                           ((p_to - interval '1 second') at time zone v_tz)::date::timestamp,
                           interval '1 day') as g
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
                  from public.driver_charges)
  ) into v;
  return v;
end $$;
comment on function public.admin_finance(timestamptz, timestamptz) is
  'Revenue for a period (delivered orders: customer fees, distributor fees, order value), per day (Jordan time), per agency and distributor, plus charges. Any staff role. Error: INVALID_SETTING.';

-- ---------------------------------------------------------------- 5. dashboard updates
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

  with days as (
    select g::date as day
      from generate_series((v_today - 13)::timestamp, v_today::timestamp, interval '1 day') as g
  ), placed as (
    select (o.created_at at time zone v_tz)::date as day, count(*) as n
      from public.orders o
     where o.created_at >= v_start - interval '14 days'
     group by 1
  ), done as (
    select (o.delivered_at at time zone v_tz)::date as day, count(*) as n,
           sum(o.service_fee + o.driver_fee) as fees
      from public.orders o
     where o.status = 'delivered' and o.delivered_at >= v_start - interval '14 days'
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

  select jsonb_build_object(
    'day_start', v_start,
    'orders_today', (select count(*) from public.orders where created_at >= v_start),
    'delivered_today', (select count(*) from public.orders
                         where status = 'delivered' and delivered_at >= v_start),
    'cancelled_today', (select count(*) from public.orders
                         where status = 'cancelled' and cancelled_at >= v_start),
    'expired_today', (select count(*) from public.orders
                       where status = 'expired' and updated_at >= v_start),
    'sales_today', (select coalesce(sum(total_price), 0) from public.orders
                     where status = 'delivered' and delivered_at >= v_start),
    'fees_today', (select coalesce(sum(service_fee + driver_fee), 0) from public.orders
                    where status = 'delivered' and delivered_at >= v_start),
    'fees_month', (select coalesce(sum(service_fee + driver_fee), 0) from public.orders
                    where status = 'delivered' and delivered_at >= v_month),
    'median_accept_seconds', (select percentile_cont(0.5) within group
                                (order by extract(epoch from accepted_at - created_at))
                                from public.orders where accepted_at >= v_start),
    'pending', (select count(*) from public.orders where status = 'pending'),
    'in_progress', (select count(*) from public.orders where status in ('accepted', 'on_the_way')),
    'pending_over_10m', (select count(*) from public.orders
                          where status = 'pending' and created_at < now() - interval '10 minutes'),
    'drivers_online', (select count(*) from public.drivers where is_online and status = 'approved'),
    'drivers_approved', (select count(*) from public.drivers where status = 'approved'),
    'drivers_awaiting_approval', (select count(*) from public.drivers where status = 'pending'),
    'documents_to_review', (select count(*) from public.driver_documents where status = 'pending'),
    'customers_total', (select count(*) from public.profiles where role = 'customer'),
    'customers_new_today', (select count(*) from public.profiles
                             where role = 'customer' and created_at >= v_start),
    'charges_open', (select coalesce(sum(amount), 0) from public.driver_charges where status = 'open'),
    'last_14_days', v_series
  ) into v;
  return v;
end $$;
comment on function public.admin_overview() is
  'Dashboard numbers for today and this month (Jordan time), open charges, plus a 14-day series. Any staff role.';

-- The balance column becomes open_charges, so the function is recreated.
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
  open_charges numeric, documents_pending bigint, documents_total bigint
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
           (select count(*) from public.driver_documents x where x.driver_id = d.id)
      from public.drivers d
      join public.profiles p on p.id = d.id
     where (p_status is null or d.status = p_status)
       and (p_driver_id is null or d.id = p_driver_id)
       and (v_q is null
            or p.full_name ilike '%' || v_q || '%'
            or p.phone like '%' || v_q || '%'
            or d.vehicle_plate ilike '%' || v_q || '%'
            or d.agency_name ilike '%' || v_q || '%')
     order by (d.status = 'pending') desc, d.created_at desc
     limit 500;
end $$;
comment on function public.admin_list_drivers(public.driver_status, text, uuid) is
  'Distributors with approval state, live state, workload, open charges and document counts (pending first); p_driver_id returns one. Any staff role.';

create or replace function public.admin_order_detail(p_order_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  o public.orders;
begin
  perform private.require_staff();
  select * into o from public.orders where id = p_order_id;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('order %s', p_order_id);
  end if;
  return jsonb_build_object(
    'order', to_jsonb(o),
    'customer', (select jsonb_build_object('id', p.id, 'full_name', p.full_name, 'phone', p.phone,
                          'email', p.email, 'avatar_url', p.avatar_url, 'is_active', p.is_active)
                   from public.profiles p where p.id = o.customer_id),
    'driver', (select jsonb_build_object('id', d.id, 'full_name', p.full_name, 'phone', p.phone,
                        'avatar_url', p.avatar_url, 'vehicle_plate', d.vehicle_plate,
                        'vehicle_model', d.vehicle_model, 'agency_name', d.agency_name,
                        'lat', d.lat, 'lng', d.lng,
                        'location_updated_at', d.location_updated_at, 'is_online', d.is_online)
                 from public.drivers d join public.profiles p on p.id = d.id
                where d.id = o.driver_id),
    'events', (select coalesce(jsonb_agg(jsonb_build_object(
                        'status', e.status, 'at', e.created_at, 'actor_id', e.actor_id,
                        'actor_name', p.full_name, 'actor_role', p.role)
                        order by e.created_at, e.id), '[]'::jsonb)
                 from public.order_events e
                 left join public.profiles p on p.id = e.actor_id
                where e.order_id = o.id),
    'releases', (select coalesce(jsonb_agg(jsonb_build_object(
                          'driver_id', r.driver_id, 'driver_name', p.full_name,
                          'reason', r.reason, 'at', r.created_at)
                          order by r.created_at), '[]'::jsonb)
                   from public.order_releases r
                   left join public.profiles p on p.id = r.driver_id
                  where r.order_id = o.id),
    'charges', (select coalesce(jsonb_agg(to_jsonb(c) order by c.created_at), '[]'::jsonb)
                  from public.driver_charges c where c.order_id = o.id),
    'actions', (select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at), '[]'::jsonb)
                  from public.admin_actions a
                 where a.target_type = 'order' and a.target_id = o.id::text)
  );
end $$;
comment on function public.admin_order_detail(uuid) is
  'Order inspector: the order, customer, distributor, status events with who did them, releases, charges about the order and staff actions. Any staff role. Error: NOT_FOUND.';

-- ---------------------------------------------------------------- privileges
do $$
declare
  fn text;
begin
  foreach fn in array array[
    'public.admin_create_charge(uuid, public.charge_kind, text, numeric, text, uuid)',
    'public.admin_settle_charge(bigint, public.charge_status, text)',
    'public.admin_list_charges(public.charge_status, uuid, integer, integer)',
    'public.admin_finance(timestamptz, timestamptz)',
    'public.admin_list_drivers(public.driver_status, text, uuid)'
  ] loop
    execute format('revoke execute on function %s from public, anon', fn);
    execute format('grant execute on function %s to authenticated', fn);
  end loop;
end $$;
