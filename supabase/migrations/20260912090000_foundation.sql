-- =============================================================================
-- ClickGas - Phase 0 foundation (run once, after 20260911180000_slots_avatars.sql)
--
--   1. private schema + is_staff() helper
--   2. money stored in fils: numeric(12,3) JOD
--   3. service fees per delivered order (customer 0.100 + distributor 0.050)
--      and the distributor ledger (what each distributor owes the platform)
--   4. order state machine: allowed status changes live in one table and are
--      enforced by a trigger on every update
--   5. phone login checks the password in the database and allows 5 failed
--      attempts per phone per 15 minutes (replaces email_for_phone)
--   6. diagnostics uploads, scheduled job runs, feature flags
--   7. descriptions (comment on) for the dashboard and generated docs
--
-- Documentation: docs/business-rules.md, docs/errors.md, docs/data-model.md
-- =============================================================================

-- ---------------------------------------------------------------- 1. basics
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create extension if not exists pgcrypto with schema extensions;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and is_active
  );
$$;
comment on function public.is_staff() is
  'True when the caller is an active admin (staff). Used by RLS policies.';

-- ---------------------------------------------------------------- 2. money in fils
-- 1 JOD = 1000 fils, so every amount keeps 3 decimals.
alter table public.services alter column price type numeric(12, 3);
alter table public.app_config alter column delivery_fee type numeric(12, 3);
alter table public.orders
  alter column unit_price type numeric(12, 3),
  alter column delivery_fee type numeric(12, 3),
  alter column total_price type numeric(12, 3);
alter table public.order_releases alter column total_price type numeric(12, 3);

-- ---------------------------------------------------------------- 3. fees
create table public.fee_settings (
  id bigint generated always as identity primary key,
  customer_fee numeric(12, 3) not null check (customer_fee >= 0),
  driver_fee numeric(12, 3) not null check (driver_fee >= 0),
  effective_from timestamptz not null default now(),
  note text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);
comment on table public.fee_settings is
  'Platform service fee per delivered order, with the date it takes effect. The latest row with effective_from <= now() applies.';
comment on column public.fee_settings.customer_fee is 'Added to the customer total (JOD).';
comment on column public.fee_settings.driver_fee is 'Charged to the distributor on delivery (JOD).';

insert into public.fee_settings (customer_fee, driver_fee, note)
values (0.100, 0.050, 'Launch fee: 15 piasters per delivered order (customer 10, distributor 5)');

alter table public.fee_settings enable row level security;
create policy "fees are public" on public.fee_settings
  for select to anon, authenticated using (true);
revoke insert, update, delete on public.fee_settings from anon, authenticated;

create view public.current_fees with (security_invoker = true) as
  select customer_fee, driver_fee, effective_from
    from public.fee_settings
   where effective_from <= now()
   order by effective_from desc, id desc
   limit 1;
comment on view public.current_fees is 'The fee pair in force right now.';
grant select on public.current_fees to anon, authenticated;

alter table public.orders
  add column service_fee numeric(12, 3) not null default 0,
  add column driver_fee numeric(12, 3) not null default 0;
comment on column public.orders.service_fee is 'Customer service fee copied from current_fees when the order was placed.';
comment on column public.orders.driver_fee is 'Distributor fee copied from current_fees when the order was placed.';
comment on column public.orders.total_price is 'What the customer pays: unit_price * quantity + delivery_fee + service_fee.';

-- Prices, fees and status are always decided by the server, never the client.
create or replace function public.prepare_new_order()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  s public.services;
  v_delivery numeric(12, 3);
  v_customer_fee numeric(12, 3);
  v_driver_fee numeric(12, 3);
begin
  select * into s from public.services where id = new.service_id and is_active;
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
  if new.city_id is null then
    select city_id into new.city_id from public.profiles where id = new.customer_id;
  end if;
  return new;
end $$;

-- Ledger: positive amounts are owed by the distributor to the platform,
-- negative amounts are payments received from the distributor.
create type public.ledger_kind as enum ('order_fee', 'payment', 'adjustment');

create table public.driver_ledger (
  id bigint generated always as identity primary key,
  driver_id uuid not null references public.drivers (id) on delete cascade,
  order_id uuid references public.orders (id) on delete set null,
  kind public.ledger_kind not null,
  amount numeric(12, 3) not null,
  note text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);
comment on table public.driver_ledger is
  'What each distributor owes the platform. order_fee rows (+) are booked on delivery; payment rows (-) are recorded by staff.';
create unique index driver_ledger_one_fee_per_order on public.driver_ledger (order_id)
  where kind = 'order_fee';
create index driver_ledger_driver_idx on public.driver_ledger (driver_id, created_at desc);

alter table public.driver_ledger enable row level security;
create policy "driver reads own ledger" on public.driver_ledger
  for select to authenticated using (driver_id = auth.uid() or public.is_staff());
revoke insert, update, delete on public.driver_ledger from anon, authenticated;

create or replace function public.driver_balance()
returns numeric language sql stable security definer set search_path = '' as $$
  select coalesce(sum(amount), 0)::numeric(12, 3)
    from public.driver_ledger where driver_id = auth.uid();
$$;
comment on function public.driver_balance() is
  'Amount the calling distributor currently owes the platform (JOD).';

create or replace function public.record_driver_payment(
  p_driver_id uuid, p_amount numeric, p_note text default null
) returns public.driver_ledger language plpgsql security definer set search_path = '' as $$
declare
  row_out public.driver_ledger;
begin
  if not public.is_staff() then
    raise exception 'PERMISSION_DENIED' using detail = 'staff only';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'INVALID_AMOUNT' using detail = format('amount=%s', p_amount);
  end if;
  insert into public.driver_ledger (driver_id, kind, amount, note)
  values (p_driver_id, 'payment', -round(p_amount, 3), left(p_note, 200))
  returning * into row_out;
  return row_out;
end $$;
comment on function public.record_driver_payment(uuid, numeric, text) is
  'Staff records cash or transfer received from a distributor (stored as a negative ledger row).';

-- Delivery now also books the fees in the ledger.
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
  if o.service_fee + o.driver_fee > 0 then
    insert into public.driver_ledger (driver_id, order_id, kind, amount, note)
    values (auth.uid(), o.id, 'order_fee', o.service_fee + o.driver_fee,
            format('Order %s: customer fee %s + distributor fee %s',
                   o.order_number, o.service_fee, o.driver_fee))
    on conflict do nothing;
  end if;
  return o;
end $$;

-- ---------------------------------------------------------------- 4. state machine
alter type public.order_status add value if not exists 'expired';

create table public.order_transitions (
  from_status text not null,
  to_status text not null,
  actor text not null check (actor in ('customer', 'driver', 'admin', 'system')),
  via text not null,
  primary key (from_status, to_status, actor)
);
comment on table public.order_transitions is
  'Every allowed order status change and who may make it. Enforced by check_order_transition(); anything not listed is rejected with INVALID_TRANSITION.';

insert into public.order_transitions (from_status, to_status, actor, via) values
  ('pending',    'accepted',   'driver',   'accept_order'),
  ('pending',    'cancelled',  'customer', 'cancel_order'),
  ('pending',    'cancelled',  'admin',    'admin action'),
  ('pending',    'cancelled',  'system',   'maintenance'),
  ('pending',    'expired',    'system',   'expiry job'),
  ('accepted',   'on_the_way', 'driver',   'start_delivery'),
  ('accepted',   'pending',    'driver',   'release_order'),
  ('on_the_way', 'pending',    'driver',   'release_order'),
  ('accepted',   'delivered',  'driver',   'complete_order'),
  ('on_the_way', 'delivered',  'driver',   'complete_order'),
  ('accepted',   'cancelled',  'admin',    'admin action'),
  ('on_the_way', 'cancelled',  'admin',    'admin action'),
  ('accepted',   'cancelled',  'system',   'maintenance'),
  ('on_the_way', 'cancelled',  'system',   'maintenance');

alter table public.order_transitions enable row level security;
create policy "transitions are readable" on public.order_transitions
  for select to authenticated using (true);
revoke insert, update, delete on public.order_transitions from anon, authenticated;

create or replace function public.check_order_transition()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_actor text;
begin
  if new.status = old.status then
    return new;
  end if;
  v_actor := case
    when v_uid is null then 'system'
    when v_uid = old.customer_id then 'customer'
    when v_uid = coalesce(new.driver_id, old.driver_id) then 'driver'
    when exists (select 1 from public.profiles where id = v_uid and role = 'admin') then 'admin'
    else 'unknown'
  end;
  if not exists (
    select 1 from public.order_transitions t
     where t.from_status = old.status::text
       and t.to_status = new.status::text
       and t.actor = v_actor
  ) then
    raise exception 'INVALID_TRANSITION'
      using detail = format('order %s: %s -> %s by %s', old.order_number, old.status, new.status, v_actor);
  end if;
  return new;
end $$;
comment on function public.check_order_transition() is
  'Trigger: rejects any order status change not listed in order_transitions.';
revoke execute on function public.check_order_transition() from public, anon, authenticated;

create trigger orders_check_transition before update of status on public.orders
  for each row execute function public.check_order_transition();

-- ---------------------------------------------------------------- 5. phone login
create table private.login_attempts (
  phone text not null,
  attempted_at timestamptz not null default now()
);
create index login_attempts_phone_idx on private.login_attempts (phone, attempted_at desc);

-- Returns the account email only when the password is right, so the app can
-- finish the sign-in with Supabase Auth. Wrong password -> null (and the
-- attempt is counted); 5 failures in 15 minutes -> TOO_MANY_ATTEMPTS.
create or replace function public.login_email_for_phone(p_phone text, p_password text)
returns text language plpgsql volatile security definer set search_path = '' as $$
declare
  v_email text;
  v_hash text;
  v_recent int;
begin
  delete from private.login_attempts where attempted_at < now() - interval '1 day';
  select count(*) into v_recent from private.login_attempts
   where phone = p_phone and attempted_at > now() - interval '15 minutes';
  if v_recent >= 5 then
    raise exception 'TOO_MANY_ATTEMPTS' using detail = 'wait 15 minutes';
  end if;
  select u.email, u.encrypted_password into v_email, v_hash
    from public.profiles p
    join auth.users u on u.id = p.id
   where p.phone = p_phone and p.is_active;
  if v_hash is null or extensions.crypt(p_password, v_hash) is distinct from v_hash then
    insert into private.login_attempts (phone) values (p_phone);
    return null;
  end if;
  delete from private.login_attempts where phone = p_phone;
  return v_email;
end $$;
comment on function public.login_email_for_phone(text, text) is
  'Phone + password login step 1: returns the account email if the password matches. Rate limited per phone.';
revoke execute on function public.login_email_for_phone(text, text) from public;
grant execute on function public.login_email_for_phone(text, text) to anon, authenticated;

-- The old lookup revealed the email of any registered phone.
drop function if exists public.email_for_phone(text);

comment on function public.is_phone_registered(text) is
  'Used by sign-up to show "phone already registered". Accepted trade-off, see docs/decisions/0005-phone-login.md.';

-- ---------------------------------------------------------------- 6. operations
create table public.diagnostics (
  id bigint generated always as identity primary key,
  user_id uuid default auth.uid() references auth.users (id) on delete set null,
  app text not null check (app in ('customer', 'distributor', 'admin', 'unknown')),
  app_version text,
  environment text,
  platform text,
  locale text,
  logs jsonb not null default '[]'::jsonb check (pg_column_size(logs) < 262144),
  note text check (char_length(note) <= 500),
  created_at timestamptz not null default now()
);
comment on table public.diagnostics is
  'Logs uploaded from a phone via Settings > Send diagnostics. Readable by staff; see docs/runbooks/diagnostics.md.';
create index diagnostics_user_idx on public.diagnostics (user_id, created_at desc);

alter table public.diagnostics enable row level security;
create policy "users upload own diagnostics" on public.diagnostics
  for insert to authenticated with check (user_id = auth.uid());
create policy "owner and staff read diagnostics" on public.diagnostics
  for select to authenticated using (user_id = auth.uid() or public.is_staff());
revoke update, delete on public.diagnostics from anon, authenticated;

create table public.job_runs (
  id bigint generated always as identity primary key,
  job text not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  ok boolean,
  detail jsonb
);
comment on table public.job_runs is 'One row per scheduled job run (pg_cron), with outcome and details.';
create index job_runs_job_idx on public.job_runs (job, started_at desc);
alter table public.job_runs enable row level security;
create policy "staff read job runs" on public.job_runs
  for select to authenticated using (public.is_staff());
revoke insert, update, delete on public.job_runs from anon, authenticated;

create table public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  description text not null,
  updated_at timestamptz not null default now()
);
comment on table public.feature_flags is 'Turns features on or off without releasing new app builds.';
insert into public.feature_flags (key, enabled, description) values
  ('push_notifications', false, 'Push via FCM when the app is closed (Phase 2).'),
  ('complaints', false, 'Complaints in both apps (Phase 2).'),
  ('driver_score', false, 'Driver score and tiers (Phase 4).'),
  ('electronic_payments', false, 'Card and CliQ payments - postponed after the proof of concept.');
alter table public.feature_flags enable row level security;
create policy "flags are public" on public.feature_flags
  for select to anon, authenticated using (true);
create policy "staff edit flags" on public.feature_flags
  for update to authenticated using (public.is_staff()) with check (public.is_staff());
revoke insert, delete on public.feature_flags from anon, authenticated;

alter table public.app_config
  add column min_customer_version text not null default '1.0.0',
  add column min_distributor_version text not null default '1.0.0';
comment on column public.app_config.min_customer_version is 'Older customer app builds are asked to update.';
comment on column public.app_config.min_distributor_version is 'Older distributor app builds are asked to update.';

-- ---------------------------------------------------------------- 7. descriptions
comment on table public.profiles is 'One row per account (customer, driver or admin), created by the sign-up trigger. Role is never taken from the client.';
comment on table public.drivers is 'Distributor details, verification, live location, stock and rating totals.';
comment on table public.orders is 'Customer orders. Prices and fees are set by prepare_new_order(); status changes only through RPCs, checked against order_transitions.';
comment on table public.order_events is 'Audit trail: one row per order status change, with the actor.';
comment on table public.order_releases is 'Orders a distributor gave back (release_order); shown as cancelled in their sales log.';
comment on table public.services is 'What customers can order and its price (JOD).';
comment on table public.cities is 'Jordanian cities offered at sign-up.';
comment on table public.app_config is 'Single-row settings: delivery fee, dispatch radius, order limits, minimum app versions.';
comment on function public.accept_order(uuid) is 'Distributor accepts a pending order. Errors: NOT_A_VERIFIED_DRIVER, DRIVER_OFFLINE, MAX_ACTIVE_ORDERS, ORDER_NOT_AVAILABLE, NOT_ENOUGH_CYLINDERS, ORDER_TOO_FAR.';
comment on function public.start_delivery(uuid) is 'Distributor marks an accepted order as on the way. Error: INVALID_TRANSITION.';
comment on function public.complete_order(uuid) is 'Distributor marks an order delivered; lowers stock and books fees in driver_ledger. Error: INVALID_TRANSITION.';
comment on function public.release_order(uuid, text) is 'Distributor gives an order back; it returns to pending and is logged in order_releases. Error: INVALID_TRANSITION.';
comment on function public.cancel_order(uuid, text) is 'Customer cancels a pending order. Error: ORDER_NOT_CANCELLABLE.';
comment on function public.confirm_delivery(uuid) is 'Customer confirms receipt of a delivered order. Error: ORDER_NOT_CONFIRMABLE.';
comment on function public.rate_order(uuid, smallint, text) is 'Customer rates a delivered order once. Errors: INVALID_RATING, ORDER_NOT_RATEABLE.';
comment on function public.nearby_orders(double precision, double precision) is 'Pending orders within driver_radius_km of the given point, nearest first. Error: NOT_A_VERIFIED_DRIVER.';
comment on function public.driver_active_orders() is 'The calling distributor''s accepted and on-the-way orders with customer contact.';
comment on function public.get_order_driver(uuid) is 'Distributor card for the calling customer''s order.';

-- ---------------------------------------------------------------- privileges
revoke execute on function public.driver_balance() from public, anon;
revoke execute on function public.record_driver_payment(uuid, numeric, text) from public, anon;
grant execute on function public.driver_balance() to authenticated;
grant execute on function public.record_driver_payment(uuid, numeric, text) to authenticated;
