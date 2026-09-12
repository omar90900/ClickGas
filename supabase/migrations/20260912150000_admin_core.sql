-- =============================================================================
-- ClickGas - Phase 1 admin core (run once, after 20260912090000_foundation.sql)
--
--   1. staff roles: owner (everything), operations (orders, distributors,
--      payments), support (customers, read-only on money)
--   2. admin_actions: audit trail written by every staff function
--   3. staff read access (RLS) to profiles, drivers, orders and their logs
--   4. distributor approval status: pending / approved / rejected / suspended
--   5. distributor documents + private `driver-docs` storage bucket
--   6. staff actions: approve distributors, review documents, block accounts,
--      cancel and reassign orders, record payments, adjust balances
--   7. owner settings: prices (+ price_history), fees, app settings, cities,
--      feature flags, staff accounts
--   8. dashboard reads: overview, live map, lists, order search, inspector
--
-- Every staff write goes through a function here; none are granted directly.
-- Documentation: docs/api.md#staff, docs/business-rules.md#staff,
-- docs/decisions/0010-staff-roles-and-audit.md
-- =============================================================================

-- ---------------------------------------------------------------- 1. staff roles
create type public.staff_role as enum ('owner', 'operations', 'support');

create table public.staff_members (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  role public.staff_role not null,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);
comment on table public.staff_members is
  'Staff accounts and their role. The profile must also have role = admin and be active. Managed with admin_save_staff / admin_remove_staff.';

create or replace function public.my_staff_role()
returns public.staff_role language sql stable security definer set search_path = '' as $$
  select s.role
    from public.staff_members s
    join public.profiles p on p.id = s.user_id
   where s.user_id = auth.uid() and p.role = 'admin' and p.is_active;
$$;
comment on function public.my_staff_role() is
  'The caller''s staff role, or null when the caller is not active staff.';

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = '' as $$
  select public.my_staff_role() is not null;
$$;
comment on function public.is_staff() is
  'True when the caller is active staff (any role). Used by RLS policies.';

-- Raises PERMISSION_DENIED unless the caller is staff with one of p_allowed.
-- The owner always passes; null means any staff role; an empty array means
-- owner only.
create or replace function private.require_staff(p_allowed public.staff_role[] default null)
returns public.staff_role language plpgsql stable security definer set search_path = '' as $$
declare
  v public.staff_role := public.my_staff_role();
begin
  if v is null then
    raise exception 'PERMISSION_DENIED' using detail = 'staff only';
  end if;
  if v <> 'owner' and p_allowed is not null and not (v = any (p_allowed)) then
    raise exception 'PERMISSION_DENIED' using detail = format('role %s cannot do this', v);
  end if;
  return v;
end $$;

create or replace function private.require_owner()
returns void language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_staff(array[]::public.staff_role[]);
end $$;

-- Blocking, rejecting and cancelling always need a reason (3+ characters).
create or replace function private.require_reason(p_reason text)
returns text language plpgsql immutable set search_path = '' as $$
begin
  if coalesce(char_length(trim(p_reason)), 0) < 3 then
    raise exception 'REASON_REQUIRED' using detail = 'give a reason of 3 characters or more';
  end if;
  return left(trim(p_reason), 300);
end $$;

-- ---------------------------------------------------------------- 2. audit trail
create table public.admin_actions (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles (id) on delete set null,
  actor_name text,
  actor_role public.staff_role,
  action text not null,
  target_type text not null,
  target_id text,
  reason text,
  detail jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
comment on table public.admin_actions is
  'Audit trail: one row per staff action (who, what, on which record, why, before/after). Written only by staff functions.';
comment on column public.admin_actions.action is 'Dotted name, e.g. driver.set_status, order.cancel, fees.set.';
comment on column public.admin_actions.target_type is 'driver, user, order, service, fees, config, city, flag, staff, document.';
create index admin_actions_created_idx on public.admin_actions (created_at desc);
create index admin_actions_target_idx on public.admin_actions (target_type, target_id, created_at desc);

create or replace function private.audit(
  p_action text,
  p_target_type text,
  p_target_id text,
  p_reason text default null,
  p_detail jsonb default '{}'::jsonb
) returns void language sql security definer set search_path = '' as $$
  insert into public.admin_actions
    (actor_id, actor_name, actor_role, action, target_type, target_id, reason, detail)
  select auth.uid(), p.full_name, public.my_staff_role(), p_action, p_target_type,
         p_target_id, nullif(trim(p_reason), ''), coalesce(p_detail, '{}'::jsonb)
    from (select 1) as one
    left join public.profiles p on p.id = auth.uid();
$$;

-- ---------------------------------------------------------------- 3. staff read access
alter table public.staff_members enable row level security;
alter table public.admin_actions enable row level security;

create policy "staff read staff" on public.staff_members
  for select to authenticated using ((select public.is_staff()));
revoke insert, update, delete on public.staff_members from anon, authenticated;

create policy "staff read audit" on public.admin_actions
  for select to authenticated using ((select public.is_staff()));
revoke insert, update, delete on public.admin_actions from anon, authenticated;

create policy "staff read profiles" on public.profiles
  for select to authenticated using ((select public.is_staff()));
create policy "staff read drivers" on public.drivers
  for select to authenticated using ((select public.is_staff()));
create policy "staff read orders" on public.orders
  for select to authenticated using ((select public.is_staff()));
create policy "staff read order events" on public.order_events
  for select to authenticated using ((select public.is_staff()));
create policy "staff read releases" on public.order_releases
  for select to authenticated using ((select public.is_staff()));
create policy "staff read all services" on public.services
  for select to authenticated using ((select public.is_staff()));
create policy "staff read all cities" on public.cities
  for select to authenticated using ((select public.is_staff()));

-- ---------------------------------------------------------------- 4. distributor status
create type public.driver_status as enum ('pending', 'approved', 'rejected', 'suspended');

alter table public.drivers
  add column status public.driver_status not null default 'pending',
  add column status_reason text,
  add column status_changed_at timestamptz,
  add column status_changed_by uuid references public.profiles (id) on delete set null;
comment on column public.drivers.status is
  'Approval state. Only approved distributors can go online and take orders; is_verified mirrors status = approved.';
comment on column public.drivers.status_reason is 'Why the distributor was rejected or suspended (shown to them).';

update public.drivers
   set status = case when is_verified then 'approved'::public.driver_status
                     else 'pending'::public.driver_status end;

-- status leads; is_verified follows it (older code and RLS read is_verified).
create or replace function public.sync_driver_status()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    if new.is_verified then
      new.status := 'approved'::public.driver_status;
    end if;
  elsif new.status is distinct from old.status then
    null;
  elsif new.is_verified is distinct from old.is_verified then
    new.status := case when new.is_verified then 'approved'::public.driver_status
                       else 'suspended'::public.driver_status end;
  end if;
  new.is_verified := new.status = 'approved';
  if not new.is_verified then
    new.is_online := false;
  end if;
  return new;
end $$;
comment on function public.sync_driver_status() is
  'Trigger: keeps drivers.is_verified equal to status = approved and takes unapproved distributors offline.';
revoke execute on function public.sync_driver_status() from public, anon, authenticated;

create trigger drivers_sync_status before insert or update on public.drivers
  for each row execute function public.sync_driver_status();

-- ---------------------------------------------------------------- 5. documents
create type public.document_kind as enum
  ('national_id', 'driving_licence', 'vehicle_registration', 'agency_letter');
create type public.document_status as enum ('pending', 'approved', 'rejected');

create table public.driver_documents (
  id bigint generated always as identity primary key,
  driver_id uuid not null references public.drivers (id) on delete cascade,
  kind public.document_kind not null,
  file_path text not null check (char_length(file_path) <= 300),
  status public.document_status not null default 'pending',
  expires_on date,
  review_note text,
  uploaded_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles (id) on delete set null,
  unique (driver_id, kind)
);
comment on table public.driver_documents is
  'One current file per distributor and document kind (a new upload replaces the old one and goes back to pending). Files live in the private driver-docs bucket.';
comment on column public.driver_documents.file_path is 'Path inside the driver-docs bucket: <driver id>/<kind>-<timestamp>.<ext>.';

alter table public.driver_documents enable row level security;
create policy "driver and staff read documents" on public.driver_documents
  for select to authenticated using (driver_id = auth.uid() or (select public.is_staff()));
revoke insert, update, delete on public.driver_documents from anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('driver-docs', 'driver-docs', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

-- Files at driver-docs/<driver id>/...: the distributor uploads and reads
-- their own folder; staff read everything. Nobody overwrites or deletes.
create policy "driver-docs: owner uploads" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'driver-docs' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "driver-docs: owner and staff read" on storage.objects
  for select to authenticated
  using (bucket_id = 'driver-docs'
         and ((storage.foldername(name))[1] = auth.uid()::text or public.is_staff()));

create or replace function public.submit_driver_document(
  p_kind public.document_kind, p_file_path text, p_expires_on date default null
) returns public.driver_documents language plpgsql security definer set search_path = '' as $$
declare
  doc public.driver_documents;
begin
  if not exists (select 1 from public.drivers where id = auth.uid()) then
    raise exception 'PERMISSION_DENIED' using detail = 'distributors only';
  end if;
  if p_file_path is null or split_part(p_file_path, '/', 1) <> auth.uid()::text
     or p_file_path like '%..%' then
    raise exception 'PERMISSION_DENIED' using detail = 'the file must be in your own folder';
  end if;
  if p_expires_on is not null and p_expires_on < current_date then
    raise exception 'DOCUMENT_EXPIRED' using detail = format('%s expired on %s', p_kind, p_expires_on);
  end if;
  insert into public.driver_documents (driver_id, kind, file_path, expires_on)
  values (auth.uid(), p_kind, p_file_path, p_expires_on)
  on conflict (driver_id, kind) do update
    set file_path = excluded.file_path,
        expires_on = excluded.expires_on,
        status = 'pending',
        review_note = null,
        uploaded_at = now(),
        reviewed_at = null,
        reviewed_by = null
  returning * into doc;
  -- A rejected distributor who sends new papers goes back into the queue.
  update public.drivers
     set status = 'pending', status_reason = null, status_changed_at = now()
   where id = auth.uid() and status = 'rejected';
  return doc;
end $$;
comment on function public.submit_driver_document(public.document_kind, text, date) is
  'Distributor registers an uploaded document (replaces the previous one of that kind, back to pending). Errors: PERMISSION_DENIED, DOCUMENT_EXPIRED.';

-- ---------------------------------------------------------------- 6. staff actions
create or replace function public.admin_set_driver_status(
  p_driver_id uuid, p_status public.driver_status, p_reason text default null
) returns public.drivers language plpgsql security definer set search_path = '' as $$
declare
  d public.drivers;
  v_from public.driver_status;
  v_reason text;
begin
  perform private.require_staff(array['operations'::public.staff_role]);
  if p_status in ('rejected', 'suspended') then
    v_reason := private.require_reason(p_reason);
  end if;
  select * into d from public.drivers where id = p_driver_id for update;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('driver %s', p_driver_id);
  end if;
  v_from := d.status;
  update public.drivers
     set status = p_status,
         status_reason = v_reason,
         status_changed_at = now(),
         status_changed_by = auth.uid()
   where id = p_driver_id
  returning * into d;
  perform private.audit('driver.set_status', 'driver', p_driver_id::text, v_reason,
    jsonb_build_object('from', v_from, 'to', p_status));
  return d;
end $$;
comment on function public.admin_set_driver_status(uuid, public.driver_status, text) is
  'Approve, reject, suspend or reopen a distributor. Reason required to reject or suspend. Roles: owner, operations. Errors: PERMISSION_DENIED, REASON_REQUIRED, NOT_FOUND.';

create or replace function public.admin_review_document(
  p_document_id bigint, p_approve boolean, p_note text default null
) returns public.driver_documents language plpgsql security definer set search_path = '' as $$
declare
  doc public.driver_documents;
  v_note text := nullif(trim(p_note), '');
begin
  perform private.require_staff(array['operations'::public.staff_role]);
  if not p_approve then
    v_note := private.require_reason(p_note);
  end if;
  update public.driver_documents
     set status = case when p_approve then 'approved'::public.document_status
                       else 'rejected'::public.document_status end,
         review_note = v_note,
         reviewed_at = now(),
         reviewed_by = auth.uid()
   where id = p_document_id
  returning * into doc;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('document %s', p_document_id);
  end if;
  perform private.audit(case when p_approve then 'document.approve' else 'document.reject' end,
    'driver', doc.driver_id::text, v_note, jsonb_build_object('document_id', doc.id, 'kind', doc.kind));
  return doc;
end $$;
comment on function public.admin_review_document(bigint, boolean, text) is
  'Approve or reject one distributor document (reason required to reject). Roles: owner, operations. Errors: PERMISSION_DENIED, REASON_REQUIRED, NOT_FOUND.';

create or replace function public.admin_set_account_active(
  p_user_id uuid, p_active boolean, p_reason text default null
) returns public.profiles language plpgsql security definer set search_path = '' as $$
declare
  pr public.profiles;
  v_reason text := nullif(trim(p_reason), '');
begin
  perform private.require_staff();
  if not p_active then
    v_reason := private.require_reason(p_reason);
  end if;
  select * into pr from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('user %s', p_user_id);
  end if;
  if pr.role = 'admin' then
    raise exception 'INVALID_TARGET' using detail = 'staff accounts are managed in Staff';
  end if;
  if pr.role = 'driver' then
    perform private.require_staff(array['operations'::public.staff_role]);
  end if;
  update public.profiles set is_active = p_active where id = p_user_id returning * into pr;
  if not p_active then
    update public.drivers set is_online = false where id = p_user_id;
  end if;
  perform private.audit(case when p_active then 'account.unblock' else 'account.block' end,
    'user', p_user_id::text, v_reason, jsonb_build_object('role', pr.role));
  return pr;
end $$;
comment on function public.admin_set_account_active(uuid, boolean, text) is
  'Block or unblock a customer or distributor. Blocked accounts cannot order, take orders or sign in by phone. Roles: any staff for customers, owner/operations for distributors. Errors: PERMISSION_DENIED, REASON_REQUIRED, NOT_FOUND, INVALID_TARGET.';

create or replace function public.admin_cancel_order(p_order_id uuid, p_reason text)
returns public.orders language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
  v_from public.order_status;
  v_reason text;
begin
  perform private.require_staff(array['operations'::public.staff_role]);
  v_reason := private.require_reason(p_reason);
  select * into o from public.orders where id = p_order_id for update;
  if not found or o.status not in ('pending', 'accepted', 'on_the_way') then
    raise exception 'ORDER_NOT_CANCELLABLE'
      using detail = format('order %s is %s', coalesce(o.order_number::text, p_order_id::text), coalesce(o.status::text, 'missing'));
  end if;
  v_from := o.status;
  update public.orders
     set status = 'cancelled', cancelled_at = now(), cancel_reason = v_reason
   where id = p_order_id
  returning * into o;
  perform private.audit('order.cancel', 'order', p_order_id::text, v_reason,
    jsonb_build_object('order_number', o.order_number, 'from', v_from, 'driver_id', o.driver_id));
  return o;
end $$;
comment on function public.admin_cancel_order(uuid, text) is
  'Staff cancels an open order with a reason (the distributor''s slot frees). Roles: owner, operations. Errors: PERMISSION_DENIED, REASON_REQUIRED, ORDER_NOT_CANCELLABLE.';

-- Assign an open order to a distributor, or (p_driver_id null) put it back in
-- the queue for everyone. Same checks as accept_order except online/distance.
create or replace function public.admin_assign_order(
  p_order_id uuid, p_driver_id uuid, p_reason text
) returns public.orders language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
  d public.drivers;
  cfg public.app_config;
  committed record;
  v_from public.order_status;
  v_from_driver uuid;
  v_reason text;
begin
  perform private.require_staff(array['operations'::public.staff_role]);
  v_reason := private.require_reason(p_reason);
  select * into o from public.orders where id = p_order_id for update;
  if not found or o.status not in ('pending', 'accepted', 'on_the_way') then
    raise exception 'INVALID_TRANSITION'
      using detail = format('order %s is not open', coalesce(o.order_number::text, p_order_id::text));
  end if;
  v_from := o.status;
  v_from_driver := o.driver_id;

  if p_driver_id is null then
    if o.status = 'pending' then
      raise exception 'INVALID_TRANSITION'
        using detail = format('order %s is already waiting for a distributor', o.order_number);
    end if;
    update public.orders
       set status = 'pending', driver_id = null, accepted_at = null, on_the_way_at = null
     where id = o.id
    returning * into o;
  else
    if p_driver_id = o.driver_id then
      raise exception 'INVALID_TRANSITION'
        using detail = format('order %s is already with this distributor', o.order_number);
    end if;
    select dr.* into d
      from public.drivers dr join public.profiles p on p.id = dr.id
     where dr.id = p_driver_id and dr.status = 'approved' and p.is_active
       for update of dr;
    if not found then
      raise exception 'NOT_A_VERIFIED_DRIVER' using detail = format('driver %s', p_driver_id);
    end if;
    select * into cfg from public.app_config where id;
    select * into committed from public.driver_committed_orders(p_driver_id);
    if committed.order_count >= cfg.max_active_orders then
      raise exception 'MAX_ACTIVE_ORDERS' using detail = format('driver has %s open orders', committed.order_count);
    end if;
    if d.cylinders_on_board < committed.cylinders + o.quantity then
      raise exception 'NOT_ENOUGH_CYLINDERS'
        using detail = format('on board %s, committed %s, order %s', d.cylinders_on_board, committed.cylinders, o.quantity);
    end if;
    update public.orders
       set status = 'accepted', driver_id = p_driver_id, accepted_at = now(), on_the_way_at = null
     where id = o.id
    returning * into o;
  end if;

  perform private.audit(case when p_driver_id is null then 'order.return_to_queue' else 'order.assign' end,
    'order', o.id::text, v_reason,
    jsonb_build_object('order_number', o.order_number, 'from', v_from,
                       'from_driver', v_from_driver, 'to_driver', p_driver_id));
  return o;
end $$;
comment on function public.admin_assign_order(uuid, uuid, text) is
  'Staff gives an open order to an approved distributor, or back to the queue (driver null). Roles: owner, operations. Errors: PERMISSION_DENIED, REASON_REQUIRED, INVALID_TRANSITION, NOT_A_VERIFIED_DRIVER, MAX_ACTIVE_ORDERS, NOT_ENOUGH_CYLINDERS.';

update public.order_transitions set via = 'admin_cancel_order'
 where actor = 'admin' and to_status = 'cancelled';
insert into public.order_transitions (from_status, to_status, actor, via) values
  ('pending',    'accepted', 'admin', 'admin_assign_order'),
  ('on_the_way', 'accepted', 'admin', 'admin_assign_order'),
  ('accepted',   'pending',  'admin', 'admin_assign_order'),
  ('on_the_way', 'pending',  'admin', 'admin_assign_order');

-- Replaces the Phase 0 version: role check + audit.
create or replace function public.record_driver_payment(
  p_driver_id uuid, p_amount numeric, p_note text default null
) returns public.driver_ledger language plpgsql security definer set search_path = '' as $$
declare
  row_out public.driver_ledger;
begin
  perform private.require_staff(array['operations'::public.staff_role]);
  if p_amount is null or p_amount <= 0 or p_amount > 10000 then
    raise exception 'INVALID_AMOUNT' using detail = format('amount=%s', p_amount);
  end if;
  if not exists (select 1 from public.drivers where id = p_driver_id) then
    raise exception 'NOT_FOUND' using detail = format('driver %s', p_driver_id);
  end if;
  insert into public.driver_ledger (driver_id, kind, amount, note)
  values (p_driver_id, 'payment', -round(p_amount, 3), left(nullif(trim(p_note), ''), 200))
  returning * into row_out;
  perform private.audit('ledger.payment', 'driver', p_driver_id::text, p_note,
    jsonb_build_object('ledger_id', row_out.id, 'amount', round(p_amount, 3)));
  return row_out;
end $$;
comment on function public.record_driver_payment(uuid, numeric, text) is
  'Staff records cash received from a distributor (a negative ledger row). Roles: owner, operations. Errors: PERMISSION_DENIED, INVALID_AMOUNT, NOT_FOUND.';

create or replace function public.admin_adjust_balance(
  p_driver_id uuid, p_amount numeric, p_reason text
) returns public.driver_ledger language plpgsql security definer set search_path = '' as $$
declare
  row_out public.driver_ledger;
  v_reason text;
begin
  perform private.require_owner();
  v_reason := private.require_reason(p_reason);
  if p_amount is null or p_amount = 0 or abs(p_amount) > 1000 then
    raise exception 'INVALID_AMOUNT' using detail = format('amount=%s', p_amount);
  end if;
  if not exists (select 1 from public.drivers where id = p_driver_id) then
    raise exception 'NOT_FOUND' using detail = format('driver %s', p_driver_id);
  end if;
  insert into public.driver_ledger (driver_id, kind, amount, note)
  values (p_driver_id, 'adjustment', round(p_amount, 3), left(v_reason, 200))
  returning * into row_out;
  perform private.audit('ledger.adjust', 'driver', p_driver_id::text, v_reason,
    jsonb_build_object('ledger_id', row_out.id, 'amount', row_out.amount));
  return row_out;
end $$;
comment on function public.admin_adjust_balance(uuid, numeric, text) is
  'Owner corrects a distributor balance: positive adds to what they owe, negative waives. Errors: PERMISSION_DENIED, REASON_REQUIRED, INVALID_AMOUNT, NOT_FOUND.';

-- ---------------------------------------------------------------- 7. owner settings
create table public.price_history (
  id bigint generated always as identity primary key,
  service_id smallint not null references public.services (id) on delete cascade,
  old_price numeric(12, 3),
  new_price numeric(12, 3) not null,
  changed_by uuid default auth.uid() references public.profiles (id) on delete set null,
  changed_at timestamptz not null default now()
);
comment on table public.price_history is 'Every service price, written by a trigger on services (so no path can skip it).';
create index price_history_service_idx on public.price_history (service_id, changed_at desc);
alter table public.price_history enable row level security;
create policy "staff read price history" on public.price_history
  for select to authenticated using ((select public.is_staff()));
revoke insert, update, delete on public.price_history from anon, authenticated;

insert into public.price_history (service_id, old_price, new_price, changed_by, changed_at)
select id, null, price, null, created_at from public.services;

create or replace function public.log_price_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' or new.price is distinct from old.price then
    insert into public.price_history (service_id, old_price, new_price)
    values (new.id, case when tg_op = 'UPDATE' then old.price end, new.price);
  end if;
  return null;
end $$;
revoke execute on function public.log_price_change() from public, anon, authenticated;
create trigger services_price_history after insert or update of price on public.services
  for each row execute function public.log_price_change();

create or replace function public.admin_update_service(
  p_service_id smallint,
  p_price numeric default null,
  p_is_active boolean default null,
  p_name_ar text default null,
  p_name_en text default null,
  p_description_ar text default null,
  p_description_en text default null,
  p_badge text default null,
  p_sort_order smallint default null
) returns public.services language plpgsql security definer set search_path = '' as $$
declare
  s public.services;
  v_before jsonb;
begin
  perform private.require_owner();
  select * into s from public.services where id = p_service_id for update;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('service %s', p_service_id);
  end if;
  if p_price is not null and (p_price <= 0 or p_price > 1000) then
    raise exception 'INVALID_AMOUNT' using detail = format('price=%s', p_price);
  end if;
  if char_length(trim(coalesce(p_name_ar, 'ok'))) < 2 or char_length(trim(coalesce(p_name_en, 'ok'))) < 2 then
    raise exception 'INVALID_SETTING' using detail = 'names need 2 characters or more';
  end if;
  v_before := to_jsonb(s);
  update public.services
     set price = coalesce(round(p_price, 3), price),
         is_active = coalesce(p_is_active, is_active),
         name_ar = coalesce(nullif(trim(p_name_ar), ''), name_ar),
         name_en = coalesce(nullif(trim(p_name_en), ''), name_en),
         description_ar = case when p_description_ar is null then description_ar
                               else nullif(trim(p_description_ar), '') end,
         description_en = case when p_description_en is null then description_en
                               else nullif(trim(p_description_en), '') end,
         badge = case when p_badge is null then badge else nullif(trim(p_badge), '') end,
         sort_order = coalesce(p_sort_order, sort_order)
   where id = p_service_id
  returning * into s;
  perform private.audit('service.update', 'service', p_service_id::text, null,
    jsonb_build_object('before', v_before, 'after', to_jsonb(s)));
  return s;
end $$;
comment on function public.admin_update_service(smallint, numeric, boolean, text, text, text, text, text, smallint) is
  'Owner edits a service; null leaves a field unchanged, empty text clears a description or badge. New orders use the new price; old orders keep theirs. Errors: PERMISSION_DENIED, NOT_FOUND, INVALID_AMOUNT, INVALID_SETTING.';

create or replace function public.admin_create_service(
  p_code text,
  p_name_ar text,
  p_name_en text,
  p_price numeric,
  p_icon text default 'exchange',
  p_description_ar text default null,
  p_description_en text default null
) returns public.services language plpgsql security definer set search_path = '' as $$
declare
  s public.services;
begin
  perform private.require_owner();
  if p_code is null or p_code !~ '^[a-z][a-z0-9_]{1,30}$' then
    raise exception 'INVALID_SETTING' using detail = 'code: lowercase letters, digits and _';
  end if;
  if exists (select 1 from public.services where code = p_code) then
    raise exception 'INVALID_SETTING' using detail = format('code %s already exists', p_code);
  end if;
  if char_length(trim(coalesce(p_name_ar, ''))) < 2 or char_length(trim(coalesce(p_name_en, ''))) < 2 then
    raise exception 'INVALID_SETTING' using detail = 'names need 2 characters or more';
  end if;
  if p_price is null or p_price <= 0 or p_price > 1000 then
    raise exception 'INVALID_AMOUNT' using detail = format('price=%s', p_price);
  end if;
  insert into public.services
    (code, name_ar, name_en, description_ar, description_en, price, icon, sort_order)
  values
    (p_code, trim(p_name_ar), trim(p_name_en), nullif(trim(p_description_ar), ''),
     nullif(trim(p_description_en), ''), round(p_price, 3), coalesce(nullif(p_icon, ''), 'exchange'),
     coalesce((select max(sort_order) from public.services), 0) + 1)
  returning * into s;
  perform private.audit('service.create', 'service', s.id::text, null, jsonb_build_object('after', to_jsonb(s)));
  return s;
end $$;
comment on function public.admin_create_service(text, text, text, numeric, text, text, text) is
  'Owner adds a service (active, last in the list). Errors: PERMISSION_DENIED, INVALID_SETTING, INVALID_AMOUNT.';

create or replace function public.admin_set_fees(
  p_customer_fee numeric,
  p_driver_fee numeric,
  p_effective_from timestamptz default null,
  p_note text default null
) returns public.fee_settings language plpgsql security definer set search_path = '' as $$
declare
  f public.fee_settings;
  v_from timestamptz := coalesce(p_effective_from, now());
begin
  perform private.require_owner();
  if p_customer_fee is null or p_driver_fee is null
     or p_customer_fee < 0 or p_driver_fee < 0 or p_customer_fee > 5 or p_driver_fee > 5 then
    raise exception 'INVALID_AMOUNT'
      using detail = format('customer_fee=%s driver_fee=%s (0 - 5 JOD)', p_customer_fee, p_driver_fee);
  end if;
  if v_from < now() - interval '5 minutes' then
    raise exception 'INVALID_SETTING' using detail = 'the effective date cannot be in the past';
  end if;
  insert into public.fee_settings (customer_fee, driver_fee, effective_from, note)
  values (round(p_customer_fee, 3), round(p_driver_fee, 3), v_from, left(nullif(trim(p_note), ''), 200))
  returning * into f;
  perform private.audit('fees.set', 'fees', f.id::text, p_note,
    jsonb_build_object('customer_fee', f.customer_fee, 'driver_fee', f.driver_fee,
                       'effective_from', f.effective_from));
  return f;
end $$;
comment on function public.admin_set_fees(numeric, numeric, timestamptz, text) is
  'Owner sets the service fee pair from a date (now or later). Orders keep the fees they were placed with. Errors: PERMISSION_DENIED, INVALID_AMOUNT, INVALID_SETTING.';

create or replace function public.admin_update_config(p_changes jsonb)
returns public.app_config language plpgsql security definer set search_path = '' as $$
declare
  c public.app_config;
  v_before jsonb;
  v_unknown text;
  v_allowed constant text[] := array[
    'delivery_fee', 'max_quantity', 'search_radius_km', 'support_phone',
    'driver_radius_km', 'max_active_orders', 'auto_verify_drivers',
    'confirm_timeout_minutes', 'min_customer_version', 'min_distributor_version'];
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
         updated_at = now()
   where id
  returning * into c;
  perform private.audit('config.update', 'config', null, null,
    jsonb_build_object('changes', p_changes, 'before', v_before));
  return c;
end $$;
comment on function public.admin_update_config(jsonb) is
  'Owner changes app settings, e.g. {"driver_radius_km": 3}. Only listed keys, each range-checked. Errors: PERMISSION_DENIED, INVALID_SETTING.';

create or replace function public.admin_set_city_active(p_city_id smallint, p_is_active boolean)
returns public.cities language plpgsql security definer set search_path = '' as $$
declare
  ct public.cities;
begin
  perform private.require_owner();
  update public.cities set is_active = p_is_active where id = p_city_id returning * into ct;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('city %s', p_city_id);
  end if;
  perform private.audit('city.set_active', 'city', p_city_id::text, null,
    jsonb_build_object('is_active', p_is_active));
  return ct;
end $$;
comment on function public.admin_set_city_active(smallint, boolean) is
  'Owner shows or hides a city at sign-up. Errors: PERMISSION_DENIED, NOT_FOUND.';

drop policy if exists "staff edit flags" on public.feature_flags;
revoke update on public.feature_flags from anon, authenticated;

create or replace function public.admin_set_flag(p_key text, p_enabled boolean)
returns public.feature_flags language plpgsql security definer set search_path = '' as $$
declare
  f public.feature_flags;
begin
  perform private.require_owner();
  update public.feature_flags set enabled = p_enabled, updated_at = now()
   where key = p_key
  returning * into f;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('flag %s', p_key);
  end if;
  perform private.audit('flag.set', 'flag', p_key, null, jsonb_build_object('enabled', p_enabled));
  return f;
end $$;
comment on function public.admin_set_flag(text, boolean) is
  'Owner turns a feature flag on or off. Errors: PERMISSION_DENIED, NOT_FOUND.';

-- Staff accounts: an existing customer or staff account (found by email or
-- +962 phone) becomes staff with a role. Distributor accounts cannot.
create or replace function public.admin_save_staff(p_login text, p_role public.staff_role)
returns public.staff_members language plpgsql security definer set search_path = '' as $$
declare
  pr public.profiles;
  sm public.staff_members;
  v_from public.staff_role;
begin
  perform private.require_owner();
  select * into pr from public.profiles
   where lower(email) = lower(trim(p_login)) or phone = trim(p_login)
   limit 1;
  if not found then
    raise exception 'NOT_FOUND' using detail = 'no account with that email or phone';
  end if;
  if pr.role = 'driver' then
    raise exception 'INVALID_TARGET' using detail = 'distributor accounts cannot be staff';
  end if;
  select role into v_from from public.staff_members where user_id = pr.id;
  if v_from = 'owner' and p_role <> 'owner'
     and (select count(*) from public.staff_members where role = 'owner') <= 1 then
    raise exception 'LAST_OWNER' using detail = 'there must always be one owner';
  end if;
  update public.profiles set role = 'admin', is_active = true where id = pr.id;
  insert into public.staff_members (user_id, role) values (pr.id, p_role)
  on conflict (user_id) do update set role = excluded.role
  returning * into sm;
  perform private.audit('staff.save', 'staff', pr.id::text, null,
    jsonb_build_object('from', v_from, 'to', p_role, 'name', pr.full_name));
  return sm;
end $$;
comment on function public.admin_save_staff(text, public.staff_role) is
  'Owner makes an account staff or changes its role. Errors: PERMISSION_DENIED, NOT_FOUND, INVALID_TARGET, LAST_OWNER.';

create or replace function public.admin_remove_staff(p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_from public.staff_role;
begin
  perform private.require_owner();
  select role into v_from from public.staff_members where user_id = p_user_id;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('staff %s', p_user_id);
  end if;
  if v_from = 'owner' and (select count(*) from public.staff_members where role = 'owner') <= 1 then
    raise exception 'LAST_OWNER' using detail = 'there must always be one owner';
  end if;
  delete from public.staff_members where user_id = p_user_id;
  update public.profiles set role = 'customer' where id = p_user_id;
  perform private.audit('staff.remove', 'staff', p_user_id::text, null, jsonb_build_object('from', v_from));
end $$;
comment on function public.admin_remove_staff(uuid) is
  'Owner removes a staff member (the account becomes a customer). Errors: PERMISSION_DENIED, NOT_FOUND, LAST_OWNER.';

-- ---------------------------------------------------------------- 8. dashboard reads
create or replace function public.admin_whoami()
returns table (user_id uuid, full_name text, email text, role public.staff_role)
language sql stable security definer set search_path = '' as $$
  select p.id, p.full_name, p.email, s.role
    from public.staff_members s
    join public.profiles p on p.id = s.user_id
   where s.user_id = auth.uid() and p.role = 'admin' and p.is_active;
$$;
comment on function public.admin_whoami() is
  'The signed-in staff member and role; no row when the caller is not staff.';

-- "Today" is the calendar day in Jordan (Asia/Amman).
create or replace function public.admin_overview()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_tz constant text := 'Asia/Amman';
  v_today date := (now() at time zone v_tz)::date;
  v_start timestamptz := (now() at time zone v_tz)::date::timestamp at time zone v_tz;
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
    'fees_outstanding', (select coalesce(sum(amount), 0) from public.driver_ledger),
    'last_14_days', v_series
  ) into v;
  return v;
end $$;
comment on function public.admin_overview() is
  'Dashboard numbers for today (Jordan time) plus a 14-day series. Any staff role.';

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
               'service_name_ar', o.service_name_ar, 'service_name_en', o.service_name_en)
               order by o.created_at), '[]'::jsonb)
        from public.orders o
        join public.profiles p on p.id = o.customer_id
       where o.status in ('pending', 'accepted', 'on_the_way')),
    'drivers', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'id', d.id, 'full_name', p.full_name, 'phone', p.phone, 'avatar_url', p.avatar_url,
               'lat', d.lat, 'lng', d.lng, 'heading', d.heading, 'is_online', d.is_online,
               'location_updated_at', d.location_updated_at,
               'cylinders_on_board', d.cylinders_on_board, 'vehicle_plate', d.vehicle_plate,
               'open_orders', (select count(*) from public.orders o
                                where o.driver_id = d.id and o.status in ('accepted', 'on_the_way'))
             )), '[]'::jsonb)
        from public.drivers d
        join public.profiles p on p.id = d.id
       where d.lat is not null and d.lng is not null
         and (d.is_online or exists (select 1 from public.orders o
                                      where o.driver_id = d.id and o.status in ('accepted', 'on_the_way'))))
  );
end $$;
comment on function public.admin_live_map() is
  'Open orders and online (or busy) distributors with positions, for the live map. Any staff role.';

create or replace function public.admin_list_drivers(
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
  balance numeric, documents_pending bigint, documents_total bigint
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
           (select coalesce(sum(l.amount), 0)::numeric from public.driver_ledger l
             where l.driver_id = d.id),
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
  'Distributors with approval state, live state, workload, balance owed and document counts (pending first); p_driver_id returns one. Any staff role.';

create or replace function public.admin_list_customers(
  p_search text default null, p_limit integer default 50, p_offset integer default 0
) returns table (
  id uuid, full_name text, phone text, email text, avatar_url text, city_id smallint,
  is_active boolean, created_at timestamptz, orders_total bigint, delivered bigint,
  cancelled bigint, open_orders bigint, last_order_at timestamptz, total_count bigint
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
           count(*) over ()
      from public.profiles p
      left join public.orders o on o.customer_id = p.id
     where p.role = 'customer'
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
  'Customers with order counts, newest first, searchable by name/phone/email, paged (total_count = all matches). Any staff role.';

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
     where (v_q is null
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
comment on function public.admin_search_orders(text, text[], smallint, uuid, uuid, timestamptz, timestamptz, integer, integer) is
  'Order search: text matches order number, customer or distributor name/phone; filters by status, city, distributor, customer, dates; paged, newest first. Any staff role.';

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
                        'vehicle_model', d.vehicle_model, 'lat', d.lat, 'lng', d.lng,
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
    'ledger', (select coalesce(jsonb_agg(to_jsonb(l) order by l.created_at), '[]'::jsonb)
                 from public.driver_ledger l where l.order_id = o.id),
    'actions', (select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at), '[]'::jsonb)
                  from public.admin_actions a
                 where a.target_type = 'order' and a.target_id = o.id::text)
  );
end $$;
comment on function public.admin_order_detail(uuid) is
  'Order inspector: the order, customer, distributor, status events with who did them, releases, fees booked and staff actions. Any staff role. Error: NOT_FOUND.';

create or replace function public.admin_balances()
returns table (
  driver_id uuid, full_name text, phone text, status public.driver_status,
  fees numeric, payments numeric, adjustments numeric, balance numeric,
  deliveries bigint, last_payment_at timestamptz
) language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
begin
  perform private.require_staff();
  return query
    select d.id, p.full_name, p.phone, d.status,
           coalesce(sum(l.amount) filter (where l.kind = 'order_fee'), 0)::numeric,
           coalesce(-sum(l.amount) filter (where l.kind = 'payment'), 0)::numeric,
           coalesce(sum(l.amount) filter (where l.kind = 'adjustment'), 0)::numeric,
           coalesce(sum(l.amount), 0)::numeric,
           count(l.id) filter (where l.kind = 'order_fee'),
           max(l.created_at) filter (where l.kind = 'payment')
      from public.drivers d
      join public.profiles p on p.id = d.id
      left join public.driver_ledger l on l.driver_id = d.id
     group by d.id, p.full_name, p.phone, d.status
    having count(l.id) > 0 or d.status = 'approved'
     order by coalesce(sum(l.amount), 0) desc, p.full_name;
end $$;
comment on function public.admin_balances() is
  'Per distributor: fees booked, payments received, adjustments and the balance still owed. Any staff role.';

-- ---------------------------------------------------------------- privileges
do $$
declare
  fn text;
begin
  foreach fn in array array[
    'public.my_staff_role()',
    'public.submit_driver_document(public.document_kind, text, date)',
    'public.admin_set_driver_status(uuid, public.driver_status, text)',
    'public.admin_review_document(bigint, boolean, text)',
    'public.admin_set_account_active(uuid, boolean, text)',
    'public.admin_cancel_order(uuid, text)',
    'public.admin_assign_order(uuid, uuid, text)',
    'public.record_driver_payment(uuid, numeric, text)',
    'public.admin_adjust_balance(uuid, numeric, text)',
    'public.admin_update_service(smallint, numeric, boolean, text, text, text, text, text, smallint)',
    'public.admin_create_service(text, text, text, numeric, text, text, text)',
    'public.admin_set_fees(numeric, numeric, timestamptz, text)',
    'public.admin_update_config(jsonb)',
    'public.admin_set_city_active(smallint, boolean)',
    'public.admin_set_flag(text, boolean)',
    'public.admin_save_staff(text, public.staff_role)',
    'public.admin_remove_staff(uuid)',
    'public.admin_whoami()',
    'public.admin_overview()',
    'public.admin_live_map()',
    'public.admin_list_drivers(public.driver_status, text, uuid)',
    'public.admin_list_customers(text, integer, integer)',
    'public.admin_search_orders(text, text[], smallint, uuid, uuid, timestamptz, timestamptz, integer, integer)',
    'public.admin_order_detail(uuid)',
    'public.admin_balances()'
  ] loop
    execute format('revoke execute on function %s from public, anon', fn);
    execute format('grant execute on function %s to authenticated', fn);
  end loop;
end $$;
