-- =============================================================================
-- ClickGas - wallet payments
-- (run once, after 20260913180000_stats_and_plain_notifications.sql)
--
-- The customer pays the distributor straight from a Jordanian e-wallet
-- (Orange Money, Zain Cash, Umniah) or CliQ, at the door. ClickGas never holds
-- the money: it shows the distributor's details and records who said what.
--   1. payment_method 'wallet'
--   2. wallet_providers: the wallets and how the customer app opens them
--   3. driver_wallets: each distributor's receiving accounts, saved only after
--      they accept that ClickGas is not liable for wrong details
--   4. order_payments: one per wallet order once a distributor has it, with a
--      copy of that distributor's accounts and the state
--        awaiting -> claimed (customer: "I've paid") -> confirmed (distributor)
--        | disputed (distributor: not received) | cash (paid in cash instead)
--   5. rules: a wallet order goes only to a distributor with an active wallet,
--      and can't be marked delivered until its payment is confirmed or cash
--   6. customer, distributor and staff functions
--   7. notifications
--
-- 'wallet' is compared as text below: a new enum value can't be used as an
-- enum literal in the same transaction that adds it.
-- Documentation: docs/decisions/0015-wallet-payments.md
-- =============================================================================

-- ---------------------------------------------------------------- 1. payment method
alter type public.payment_method add value if not exists 'wallet';

-- ---------------------------------------------------------------- 2. providers
create table public.wallet_providers (
  code text primary key check (code ~ '^[a-z_]{2,30}$'),
  name_ar text not null,
  name_en text not null,
  android_package text check (android_package is null or android_package ~ '^[A-Za-z0-9_.]{3,100}$'),
  store_url text check (store_url is null or store_url ~ '^https://'),
  is_active boolean not null default true,
  sort_order smallint not null default 0
);
comment on table public.wallet_providers is
  'Wallets a distributor can receive with. android_package opens the wallet app from the customer app; store_url is the fallback. Owner edits with admin_save_wallet_provider.';

insert into public.wallet_providers (code, name_ar, name_en, store_url, sort_order) values
  ('orange_money', 'أورنج موني', 'Orange Money', 'https://play.google.com/store/search?q=Orange%20Money%20Jordan&c=apps', 1),
  ('zain_cash', 'زين كاش', 'Zain Cash', 'https://play.google.com/store/search?q=Zain%20Cash%20Jordan&c=apps', 2),
  ('umniah', 'محفظة أمنية', 'Umniah Wallet', 'https://play.google.com/store/search?q=Umniah%20wallet&c=apps', 3),
  ('cliq', 'CliQ', 'CliQ', null, 4);

alter table public.wallet_providers enable row level security;
create policy "everyone signed in reads wallet providers" on public.wallet_providers
  for select to authenticated using (true);
revoke insert, update, delete on public.wallet_providers from anon, authenticated;

-- ---------------------------------------------------------------- 3. distributor accounts
create table public.driver_wallets (
  id bigint generated always as identity primary key,
  driver_id uuid not null references public.drivers (id) on delete cascade,
  provider text not null references public.wallet_providers (code),
  account_name text not null check (char_length(account_name) between 2 and 80),
  wallet_number text check (wallet_number is null or wallet_number ~ '^\+?[0-9]{8,15}$'),
  cliq_alias text check (cliq_alias is null or char_length(cliq_alias) between 2 and 50),
  is_active boolean not null default true,
  terms_accepted_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (driver_id, provider),
  check (wallet_number is not null or cliq_alias is not null)
);
comment on table public.driver_wallets is
  'A distributor''s receiving accounts, one per wallet. Written with save_my_wallet, which requires accepting that ClickGas is not liable for wrong details (terms_accepted_at).';

alter table public.driver_wallets enable row level security;
create policy "distributors and staff read wallets" on public.driver_wallets
  for select to authenticated
  using (driver_id = (select auth.uid()) or (select public.is_staff()));
revoke insert, update, delete on public.driver_wallets from anon, authenticated;

-- ---------------------------------------------------------------- 4. order payments
create table public.order_payments (
  order_id uuid primary key references public.orders (id) on delete cascade,
  driver_id uuid not null references public.drivers (id) on delete cascade,
  amount numeric(12, 3) not null,
  payees jsonb not null default '[]'::jsonb,
  status text not null default 'awaiting'
    check (status in ('awaiting', 'claimed', 'confirmed', 'disputed', 'cash')),
  paid_with text references public.wallet_providers (code),
  reference text check (reference is null or char_length(reference) <= 60),
  note text check (note is null or char_length(note) <= 300),
  claimed_at timestamptz,
  confirmed_at timestamptz,
  disputed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.order_payments is
  'Wallet payment of one order. payees copies the distributor''s active accounts when they get the order, so later edits do not change what the customer was shown.';
comment on column public.order_payments.status is
  'awaiting -> claimed (customer says paid) -> confirmed (distributor received it); disputed = distributor says not received; cash = paid in cash instead.';
create index order_payments_driver_idx on public.order_payments (driver_id);
create index order_payments_open_idx on public.order_payments (status) where status in ('claimed', 'disputed');

alter table public.order_payments enable row level security;
create policy "order parties and staff read payments" on public.order_payments
  for select to authenticated
  using (
    driver_id = (select auth.uid())
    or exists (select 1 from public.orders o where o.id = order_id and o.customer_id = (select auth.uid()))
    or (select public.is_staff())
  );
revoke insert, update, delete on public.order_payments from anon, authenticated;

do $$
begin
  alter publication supabase_realtime add table public.order_payments;
exception when others then
  raise notice 'realtime publication not changed: %', sqlerrm;
end $$;

-- ---------------------------------------------------------------- 5. rules
-- Whenever a wallet order changes hands (accept, release, staff reassign),
-- replace its payment with the new distributor's accounts. Raising here makes
-- accept_order and staff reassignment refuse distributors without a wallet.
create or replace function private.sync_order_payment()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_payees jsonb;
begin
  if new.payment_method::text <> 'wallet' or private.seeding()
     or new.driver_id is not distinct from old.driver_id then
    return new;
  end if;
  delete from public.order_payments where order_id = new.id;
  if new.driver_id is null then
    return new;
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
           'provider', w.provider,
           'account_name', w.account_name,
           'wallet_number', w.wallet_number,
           'cliq_alias', w.cliq_alias) order by p.sort_order), '[]'::jsonb)
    into v_payees
    from public.driver_wallets w
    join public.wallet_providers p on p.code = w.provider
   where w.driver_id = new.driver_id and w.is_active and p.is_active;
  if v_payees = '[]'::jsonb then
    raise exception 'NO_WALLET_ACCOUNT'
      using detail = format('distributor %s has no active wallet for order %s', new.driver_id, new.order_number);
  end if;
  insert into public.order_payments (order_id, driver_id, amount, payees)
  values (new.id, new.driver_id, new.total_price, v_payees);
  return new;
end $$;

create trigger orders_wallet_payment after update of driver_id on public.orders
  for each row execute function private.sync_order_payment();

create or replace function private.require_wallet_payment()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'delivered' and old.status is distinct from 'delivered'
     and new.payment_method::text = 'wallet' and not private.seeding()
     and not exists (select 1 from public.order_payments p
                      where p.order_id = new.id and p.status in ('confirmed', 'cash')) then
    raise exception 'PAYMENT_NOT_CONFIRMED'
      using detail = format('order %s: the distributor has not confirmed the wallet payment', new.order_number);
  end if;
  return new;
end $$;

create trigger orders_wallet_paid before update of status on public.orders
  for each row execute function private.require_wallet_payment();

-- ---------------------------------------------------------------- 6a. distributor
create or replace function public.save_my_wallet(
  p_provider text,
  p_account_name text,
  p_wallet_number text,
  p_cliq_alias text,
  p_accept_terms boolean
) returns public.driver_wallets language plpgsql security definer set search_path = '' as $$
declare
  w public.driver_wallets;
begin
  if not exists (select 1 from public.drivers where id = auth.uid()) then
    raise exception 'PERMISSION_DENIED' using detail = 'distributors only';
  end if;
  if not coalesce(p_accept_terms, false) then
    raise exception 'TERMS_NOT_ACCEPTED' using detail = 'accept that ClickGas is not liable for wrong wallet details';
  end if;
  if not exists (select 1 from public.wallet_providers where code = p_provider and is_active) then
    raise exception 'INVALID_WALLET' using detail = format('unknown or inactive wallet %s', p_provider);
  end if;
  begin
    insert into public.driver_wallets
      (driver_id, provider, account_name, wallet_number, cliq_alias, terms_accepted_at)
    values (auth.uid(), p_provider, trim(p_account_name),
            nullif(trim(coalesce(p_wallet_number, '')), ''),
            nullif(trim(coalesce(p_cliq_alias, '')), ''), now())
    on conflict (driver_id, provider) do update
       set account_name = excluded.account_name,
           wallet_number = excluded.wallet_number,
           cliq_alias = excluded.cliq_alias,
           is_active = true,
           terms_accepted_at = excluded.terms_accepted_at,
           updated_at = now()
    returning * into w;
  exception when check_violation or not_null_violation then
    raise exception 'INVALID_WALLET' using detail = sqlerrm;
  end;
  perform private.notify(auth.uid(), 'distributor', 'wallet_saved',
    'تم حفظ بيانات المحفظة',
    'راجع بياناتك جيدًا: كليك غاز غير مسؤولة عن أي خطأ في بيانات محفظتك ولا عن المبالغ التي تُرسل إلى بيانات خاطئة.',
    'Wallet details saved',
    'Check them carefully: ClickGas is not responsible for mistakes in your wallet details or for money sent to wrong details.',
    jsonb_build_object('provider', p_provider));
  return w;
end $$;
comment on function public.save_my_wallet(text, text, text, text, boolean) is
  'Distributor adds or updates their account for one wallet. Errors: PERMISSION_DENIED, TERMS_NOT_ACCEPTED, INVALID_WALLET.';

create or replace function public.set_my_wallet_active(p_provider text, p_active boolean)
returns public.driver_wallets language plpgsql security definer set search_path = '' as $$
declare
  w public.driver_wallets;
begin
  update public.driver_wallets set is_active = p_active, updated_at = now()
   where driver_id = auth.uid() and provider = p_provider
  returning * into w;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('wallet %s', p_provider);
  end if;
  return w;
end $$;
comment on function public.set_my_wallet_active(text, boolean) is
  'Distributor pauses or resumes one of their wallets. Error: NOT_FOUND.';

create or replace function public.remove_my_wallet(p_provider text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  delete from public.driver_wallets where driver_id = auth.uid() and provider = p_provider;
end $$;
comment on function public.remove_my_wallet(text) is 'Distributor deletes one of their wallets.';

-- The payment belongs to an order the distributor is still delivering.
create or replace function private.lock_driver_payment(p_order_id uuid)
returns public.order_payments language plpgsql security definer set search_path = '' as $$
declare
  pay public.order_payments;
begin
  select p.* into pay
    from public.order_payments p
    join public.orders o on o.id = p.order_id
   where p.order_id = p_order_id and p.driver_id = auth.uid() and o.driver_id = auth.uid()
     and o.status in ('accepted', 'on_the_way')
   for update of p;
  if not found then
    raise exception 'PAYMENT_NOT_OPEN' using detail = format('order=%s', p_order_id);
  end if;
  return pay;
end $$;

create or replace function public.confirm_wallet_payment(p_order_id uuid, p_in_cash boolean default false)
returns public.order_payments language plpgsql security definer set search_path = '' as $$
declare
  pay public.order_payments := private.lock_driver_payment(p_order_id);
begin
  if pay.status not in ('awaiting', 'claimed', 'disputed') then
    raise exception 'PAYMENT_NOT_OPEN' using detail = format('order=%s status=%s', p_order_id, pay.status);
  end if;
  update public.order_payments
     set status = case when coalesce(p_in_cash, false) then 'cash' else 'confirmed' end,
         confirmed_at = now(), updated_at = now()
   where order_id = p_order_id
  returning * into pay;
  return pay;
end $$;
comment on function public.confirm_wallet_payment(uuid, boolean) is
  'Distributor confirms the wallet payment arrived, or (p_in_cash) that the customer paid cash instead. Only then can the order be delivered. Error: PAYMENT_NOT_OPEN.';

create or replace function public.dispute_wallet_payment(p_order_id uuid, p_note text)
returns public.order_payments language plpgsql security definer set search_path = '' as $$
declare
  pay public.order_payments := private.lock_driver_payment(p_order_id);
  v_note text := private.require_reason(p_note);
begin
  if pay.status <> 'claimed' then
    raise exception 'PAYMENT_NOT_OPEN' using detail = format('order=%s status=%s', p_order_id, pay.status);
  end if;
  update public.order_payments
     set status = 'disputed', disputed_at = now(), note = v_note, updated_at = now()
   where order_id = p_order_id
  returning * into pay;
  return pay;
end $$;
comment on function public.dispute_wallet_payment(uuid, text) is
  'Distributor says the payment the customer claimed has not arrived. Errors: PAYMENT_NOT_OPEN, REASON_REQUIRED.';

-- ---------------------------------------------------------------- 6b. customer
create or replace function public.claim_wallet_payment(
  p_order_id uuid,
  p_provider text default null,
  p_reference text default null
) returns public.order_payments language plpgsql security definer set search_path = '' as $$
declare
  pay public.order_payments;
begin
  select p.* into pay
    from public.order_payments p
    join public.orders o on o.id = p.order_id
   where p.order_id = p_order_id and o.customer_id = auth.uid()
     and o.status in ('accepted', 'on_the_way')
   for update of p;
  if not found or pay.status not in ('awaiting', 'disputed') then
    raise exception 'PAYMENT_NOT_OPEN' using detail = format('order=%s status=%s', p_order_id, pay.status);
  end if;
  update public.order_payments
     set status = 'claimed',
         claimed_at = now(),
         disputed_at = null,
         paid_with = (select code from public.wallet_providers where code = p_provider),
         reference = nullif(left(trim(coalesce(p_reference, '')), 60), ''),
         updated_at = now()
   where order_id = p_order_id
  returning * into pay;
  return pay;
end $$;
comment on function public.claim_wallet_payment(uuid, text, text) is
  'Customer says they paid the distributor from a wallet (optionally which one and the transaction number). Error: PAYMENT_NOT_OPEN.';

-- ---------------------------------------------------------------- 6c. staff
create or replace function public.admin_wallet_payments(
  p_status text default null,
  p_order_id uuid default null,
  p_limit integer default 200
) returns table (
  order_id uuid, order_number bigint, order_status public.order_status,
  customer_id uuid, customer_name text, customer_phone text,
  driver_id uuid, driver_name text, driver_phone text,
  amount numeric, payees jsonb, status text, paid_with text, reference text, note text,
  claimed_at timestamptz, confirmed_at timestamptz, disputed_at timestamptz, created_at timestamptz
) language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
begin
  perform private.require_staff();
  return query
    select p.order_id, o.order_number, o.status,
           o.customer_id, c.full_name, c.phone,
           p.driver_id, d.full_name, d.phone,
           p.amount, p.payees, p.status, p.paid_with, p.reference, p.note,
           p.claimed_at, p.confirmed_at, p.disputed_at, p.created_at
      from public.order_payments p
      join public.orders o on o.id = p.order_id
      left join public.profiles c on c.id = o.customer_id
      left join public.profiles d on d.id = p.driver_id
     where (p_status is null or p.status = p_status)
       and (p_order_id is null or p.order_id = p_order_id)
     order by (p.status in ('disputed', 'claimed')) desc, p.created_at desc
     limit least(greatest(coalesce(p_limit, 200), 1), 500);
end $$;
comment on function public.admin_wallet_payments(text, uuid, integer) is
  'Staff: wallet payments, disputed and claimed first. Error: PERMISSION_DENIED.';

create or replace function public.admin_resolve_wallet_payment(p_order_id uuid, p_status text, p_reason text)
returns public.order_payments language plpgsql security definer set search_path = '' as $$
declare
  v_reason text;
  before public.order_payments;
  pay public.order_payments;
begin
  perform private.require_staff(array['operations']::public.staff_role[]);
  v_reason := private.require_reason(p_reason);
  if p_status not in ('awaiting', 'confirmed', 'disputed', 'cash') then
    raise exception 'INVALID_SETTING' using detail = format('payment status %s', p_status);
  end if;
  select * into before from public.order_payments where order_id = p_order_id for update;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('payment for order %s', p_order_id);
  end if;
  update public.order_payments
     set status = p_status,
         confirmed_at = case when p_status in ('confirmed', 'cash') then now() else null end,
         disputed_at = case when p_status = 'disputed' then now() else disputed_at end,
         note = case when p_status = 'disputed' then v_reason else note end,
         updated_at = now()
   where order_id = p_order_id
  returning * into pay;
  perform private.audit('payment.resolve', 'order', p_order_id::text, v_reason,
    jsonb_build_object('from', before.status, 'to', p_status));
  return pay;
end $$;
comment on function public.admin_resolve_wallet_payment(uuid, text, text) is
  'Operations: settle a wallet payment (awaiting, confirmed, disputed or cash) with a reason; audited. Errors: PERMISSION_DENIED, REASON_REQUIRED, INVALID_SETTING, NOT_FOUND.';

create or replace function public.admin_set_wallet_active(p_wallet_id bigint, p_active boolean, p_reason text)
returns public.driver_wallets language plpgsql security definer set search_path = '' as $$
declare
  v_reason text;
  w public.driver_wallets;
begin
  perform private.require_staff(array['operations']::public.staff_role[]);
  v_reason := private.require_reason(p_reason);
  update public.driver_wallets set is_active = p_active, updated_at = now()
   where id = p_wallet_id
  returning * into w;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('wallet %s', p_wallet_id);
  end if;
  perform private.audit('wallet.set_active', 'driver', w.driver_id::text, v_reason,
    jsonb_build_object('provider', w.provider, 'active', p_active));
  return w;
end $$;
comment on function public.admin_set_wallet_active(bigint, boolean, text) is
  'Operations: pause or resume a distributor''s wallet with a reason; audited. Errors: PERMISSION_DENIED, REASON_REQUIRED, NOT_FOUND.';

create or replace function public.admin_save_wallet_provider(
  p_code text,
  p_android_package text,
  p_store_url text,
  p_is_active boolean
) returns public.wallet_providers language plpgsql security definer set search_path = '' as $$
declare
  before public.wallet_providers;
  w public.wallet_providers;
begin
  perform private.require_owner();
  select * into before from public.wallet_providers where code = p_code;
  if not found then
    raise exception 'NOT_FOUND' using detail = format('wallet provider %s', p_code);
  end if;
  begin
    update public.wallet_providers
       set android_package = nullif(trim(coalesce(p_android_package, '')), ''),
           store_url = nullif(trim(coalesce(p_store_url, '')), ''),
           is_active = coalesce(p_is_active, is_active)
     where code = p_code
    returning * into w;
  exception when check_violation then
    raise exception 'INVALID_SETTING' using detail = sqlerrm;
  end;
  perform private.audit('wallet_provider.save', 'config', p_code, null,
    jsonb_build_object('before', to_jsonb(before), 'after', to_jsonb(w)));
  return w;
end $$;
comment on function public.admin_save_wallet_provider(text, text, text, boolean) is
  'Owner: set how the customer app opens a wallet (Android package, store link) or switch it off; audited. Errors: PERMISSION_DENIED, NOT_FOUND, INVALID_SETTING.';

revoke execute on function public.save_my_wallet(text, text, text, text, boolean) from public, anon;
revoke execute on function public.set_my_wallet_active(text, boolean) from public, anon;
revoke execute on function public.remove_my_wallet(text) from public, anon;
revoke execute on function public.confirm_wallet_payment(uuid, boolean) from public, anon;
revoke execute on function public.dispute_wallet_payment(uuid, text) from public, anon;
revoke execute on function public.claim_wallet_payment(uuid, text, text) from public, anon;
revoke execute on function public.admin_wallet_payments(text, uuid, integer) from public, anon;
revoke execute on function public.admin_resolve_wallet_payment(uuid, text, text) from public, anon;
revoke execute on function public.admin_set_wallet_active(bigint, boolean, text) from public, anon;
revoke execute on function public.admin_save_wallet_provider(text, text, text, boolean) from public, anon;
grant execute on function public.save_my_wallet(text, text, text, text, boolean) to authenticated;
grant execute on function public.set_my_wallet_active(text, boolean) to authenticated;
grant execute on function public.remove_my_wallet(text) to authenticated;
grant execute on function public.confirm_wallet_payment(uuid, boolean) to authenticated;
grant execute on function public.dispute_wallet_payment(uuid, text) to authenticated;
grant execute on function public.claim_wallet_payment(uuid, text, text) to authenticated;
grant execute on function public.admin_wallet_payments(text, uuid, integer) to authenticated;
grant execute on function public.admin_resolve_wallet_payment(uuid, text, text) to authenticated;
grant execute on function public.admin_set_wallet_active(bigint, boolean, text) to authenticated;
grant execute on function public.admin_save_wallet_provider(text, text, text, boolean) to authenticated;

-- ---------------------------------------------------------------- 7. notifications
create or replace function private.order_payment_notifications()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
  v_data jsonb;
  v_names_ar text;
  v_names_en text;
begin
  begin
    select * into o from public.orders where id = new.order_id;
    v_data := jsonb_build_object('order_id', o.id, 'order_number', o.order_number);
    if tg_op = 'INSERT' then
      select string_agg(p.name_ar, '، ' order by p.sort_order),
             string_agg(p.name_en, ', ' order by p.sort_order)
        into v_names_ar, v_names_en
        from jsonb_array_elements(new.payees) e
        join public.wallet_providers p on p.code = e ->> 'provider';
      perform private.notify(o.customer_id, 'customer', 'order_pay_on_arrival',
        'ادفع عند وصول الموزع',
        format('ادفع %s د.أ من محفظتك (%s) عندما يصل الموزع، وانتظر حتى يؤكد استلام المبلغ.', new.amount, v_names_ar),
        'Pay when the distributor arrives',
        format('Pay %s JOD from your wallet (%s) when the distributor arrives, then wait for them to confirm they received it.', new.amount, v_names_en),
        v_data);
    elsif new.status is distinct from old.status then
      case new.status
        when 'claimed' then
          perform private.notify(new.driver_id, 'distributor', 'order_payment_claimed',
            'العميل يقول إنه دفع',
            format('دفع العميل %s د.أ%s. تحقق من محفظتك ثم أكّد الاستلام.', new.amount,
              case when new.reference is null then '' else format(' (رقم العملية %s)', new.reference) end),
            'Customer says they paid',
            format('The customer paid %s JOD%s. Check your wallet, then confirm you received it.', new.amount,
              case when new.reference is null then '' else format(' (transaction %s)', new.reference) end),
            v_data);
        when 'confirmed' then
          perform private.notify(o.customer_id, 'customer', 'order_payment_confirmed',
            'تم تأكيد الدفع', 'أكّد الموزع أنه استلم المبلغ.',
            'Payment confirmed', 'The distributor confirmed they received your payment.',
            v_data);
        when 'disputed' then
          perform private.notify(o.customer_id, 'customer', 'order_payment_disputed',
            'لم يصل المبلغ للموزع',
            format('يقول الموزع إن الدفعة لم تصله: %s. تحقق من محفظتك أو ادفع نقدًا.', coalesce(new.note, '')),
            'Payment not received',
            format('The distributor says the payment has not arrived: %s. Check your wallet or pay in cash.', coalesce(new.note, '')),
            v_data);
        else
          null;
      end case;
    end if;
  exception when others then
    -- A notification must never block a payment update.
    raise warning 'payment notification failed for %: %', new.order_id, sqlerrm;
  end;
  return new;
end $$;

create trigger order_payments_notify after insert or update of status on public.order_payments
  for each row execute function private.order_payment_notifications();
