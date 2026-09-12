-- =============================================================================
-- ClickGas - push notifications
-- (run once, after 20260913120000_auto_offline.sql)
--
-- The database decides who is told what, in their language:
--   1. profiles.locale and notification preferences (order updates, new orders)
--   2. device_tokens: the phones signed in to each app (register_device)
--   3. notifications: every message, kept 60 days as the in-app history,
--      with its push state (queued -> sending -> sent | muted | no_device |
--      failed | expired)
--   4. triggers on orders, drivers, driver_charges and driver_documents
--      write the messages (never in seed mode, never blocking the change)
--   5. delivery: after each insert, pg_net calls the Edge Function send-push
--      (URL and shared secret from Vault); pg_cron "clickgas-push-flush"
--      retries every minute. Without the Vault secrets nothing is sent and
--      the history still works.
--
-- Documentation: docs/decisions/0014-push-notifications.md,
-- docs/runbooks/push-notifications.md
-- =============================================================================

-- ---------------------------------------------------------------- 1. preferences
alter table public.profiles
  add column locale text not null default 'ar' check (locale in ('ar', 'en')),
  add column notify_order_updates boolean not null default true,
  add column notify_new_orders boolean not null default true;
comment on column public.profiles.locale is 'Language of notifications sent to this user (ar / en); the apps keep it equal to the app language.';
comment on column public.profiles.notify_order_updates is 'Push the status of the user''s orders (kinds order_*). Account and charge messages are always sent.';
comment on column public.profiles.notify_new_orders is 'Distributors: push new orders nearby (kind new_order).';
grant update (locale, notify_order_updates, notify_new_orders) on public.profiles to authenticated;

-- ---------------------------------------------------------------- 2. devices
create table public.device_tokens (
  token text primary key check (char_length(token) between 20 and 4096),
  user_id uuid not null references public.profiles (id) on delete cascade,
  app text not null check (app in ('customer', 'distributor')),
  platform text not null default 'android' check (platform in ('android', 'ios')),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);
comment on table public.device_tokens is
  'Firebase Cloud Messaging tokens of the phones signed in to each app. Written by register_device(); removed at sign-out or when Firebase reports them invalid.';
create index device_tokens_user_idx on public.device_tokens (user_id, app);

alter table public.device_tokens enable row level security;
create policy "read own devices" on public.device_tokens
  for select to authenticated using (user_id = (select auth.uid()));
revoke insert, update, delete on public.device_tokens from anon, authenticated;

create or replace function public.register_device(p_token text, p_app text, p_platform text default 'android')
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'PERMISSION_DENIED' using detail = 'sign in first';
  end if;
  if coalesce(p_app, '') not in ('customer', 'distributor')
     or coalesce(p_platform, '') not in ('android', 'ios')
     or char_length(coalesce(p_token, '')) not between 20 and 4096 then
    raise exception 'INVALID_SETTING' using detail = 'app, platform or token is not valid';
  end if;
  -- A phone that changes hands moves to the new account.
  insert into public.device_tokens (token, user_id, app, platform)
  values (p_token, v_uid, p_app, p_platform)
  on conflict (token) do update
    set user_id = excluded.user_id, app = excluded.app,
        platform = excluded.platform, last_seen_at = now();
  -- The 5 most recent phones per user and app.
  delete from public.device_tokens t
   where t.user_id = v_uid and t.app = p_app
     and t.token not in (select x.token from public.device_tokens x
                          where x.user_id = v_uid and x.app = p_app
                          order by x.last_seen_at desc limit 5);
end $$;
comment on function public.register_device(text, text, text) is
  'The app registers this phone''s push token for the signed-in user (app: customer | distributor). Errors: PERMISSION_DENIED, INVALID_SETTING.';

create or replace function public.unregister_device(p_token text)
returns void language sql security definer set search_path = '' as $$
  delete from public.device_tokens where token = p_token and user_id = auth.uid();
$$;
comment on function public.unregister_device(text) is 'Called before sign-out so the next person on this phone gets no pushes for this account.';

revoke execute on function public.register_device(text, text, text) from public, anon;
revoke execute on function public.unregister_device(text) from public, anon;
grant execute on function public.register_device(text, text, text) to authenticated;
grant execute on function public.unregister_device(text) to authenticated;

-- ---------------------------------------------------------------- 3. notifications
create table public.notifications (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  app text not null check (app in ('customer', 'distributor')),
  kind text not null check (char_length(kind) between 3 and 40),
  title_ar text not null,
  body_ar text not null,
  title_en text not null,
  body_en text not null,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  push_status text not null default 'queued' check (push_status in
    ('queued', 'sending', 'sent', 'muted', 'no_device', 'failed', 'expired')),
  push_attempts smallint not null default 0,
  push_claimed_at timestamptz,
  push_error text,
  sent_at timestamptz
);
comment on table public.notifications is
  'Every message to a user (in-app history, 60 days) and its push delivery state. Written only by database triggers; delivered by the Edge Function send-push.';
comment on column public.notifications.app is 'The app that shows it: customer or distributor.';
comment on column public.notifications.data is 'For the app: order_id, order_number, charge_id... Sent with the push as FCM data.';
comment on column public.notifications.push_status is
  'queued (waiting) -> sending -> sent; muted (user turned the kind off), no_device (no phone registered), failed (5 attempts), expired (not sent within 30 minutes).';
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_queue_idx on public.notifications (id) where push_status in ('queued', 'sending');

alter table public.notifications enable row level security;
create policy "read own notifications" on public.notifications
  for select to authenticated using (user_id = (select auth.uid()));
revoke insert, update, delete on public.notifications from anon, authenticated;

-- The apps show an unread badge from Realtime (RLS applies there too).
do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception when others then
  raise notice 'realtime publication not changed: %', sqlerrm;
end $$;

create or replace function public.mark_notifications_read()
returns integer language sql security definer set search_path = '' as $$
  with done as (
    update public.notifications set read_at = now()
     where user_id = auth.uid() and read_at is null
    returning 1
  )
  select count(*)::int from done;
$$;
comment on function public.mark_notifications_read() is 'Marks the signed-in user''s notifications read; returns how many were unread.';
revoke execute on function public.mark_notifications_read() from public, anon;
grant execute on function public.mark_notifications_read() to authenticated;

-- ---------------------------------------------------------------- 4. writing messages
-- One message to one user. Preferences only stop the push: the message
-- stays in the history.
create or replace function private.notify(
  p_user uuid, p_app text, p_kind text,
  p_title_ar text, p_body_ar text, p_title_en text, p_body_en text,
  p_data jsonb default '{}'::jsonb
) returns void language plpgsql security definer set search_path = '' as $$
declare
  pr public.profiles;
  v_status text := 'queued';
begin
  if p_user is null or private.seeding() then
    return;
  end if;
  select * into pr from public.profiles where id = p_user;
  if not found or not pr.is_active then
    return;
  end if;
  if (p_kind = 'new_order' and not pr.notify_new_orders)
     or (left(p_kind, 6) = 'order_' and not pr.notify_order_updates) then
    v_status := 'muted';
  elsif not exists (select 1 from public.device_tokens t where t.user_id = p_user and t.app = p_app) then
    v_status := 'no_device';
  end if;
  insert into public.notifications (user_id, app, kind, title_ar, body_ar, title_en, body_en, data, push_status)
  values (p_user, p_app, p_kind, p_title_ar, coalesce(p_body_ar, ''), p_title_en, coalesce(p_body_en, ''),
          coalesce(p_data, '{}'::jsonb), v_status);
end $$;

-- Online, approved distributors within the order's current search radius
-- (the same rule as nearby_orders), nearest 20.
create or replace function private.notify_nearby_drivers(o public.orders, p_except uuid)
returns integer language plpgsql security definer set search_path = '' as $$
declare
  v_radius numeric := public.order_radius_km(o.created_at);
  d record;
  v_count int := 0;
begin
  if o.status <> 'pending' then
    return 0;
  end if;
  for d in
    select dr.id, round((public.distance_m(dr.lat, dr.lng, o.delivery_lat, o.delivery_lng) / 1000)::numeric, 1) as km
      from public.drivers dr
     where dr.status = 'approved' and dr.is_online
       and dr.lat is not null and dr.lng is not null
       and dr.location_updated_at > now() - interval '15 minutes'
       and dr.id is distinct from p_except
       and public.distance_m(dr.lat, dr.lng, o.delivery_lat, o.delivery_lng) <= v_radius * 1000
     order by 2
     limit 20
  loop
    perform private.notify(d.id, 'distributor', 'new_order',
      'طلب غاز جديد قريب منك',
      format('%s × %s · على بعد %s كم', o.service_name_ar, o.quantity, d.km),
      'New gas order near you',
      format('%s × %s · %s km away', o.service_name_en, o.quantity, d.km),
      jsonb_build_object('order_id', o.id, 'order_number', o.order_number));
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;

create or replace function private.order_notifications()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_n text := new.order_number::text;
  v_data jsonb := jsonb_build_object('order_id', new.id, 'order_number', new.order_number);
  v_driver text;
begin
  if private.seeding() then
    return new;
  end if;
  begin
    if tg_op = 'INSERT' then
      perform private.notify_nearby_drivers(new, null);
      return new;
    end if;

    if new.status is distinct from old.status then
      case new.status
        when 'accepted' then
          select full_name into v_driver from public.profiles where id = new.driver_id;
          perform private.notify(new.customer_id, 'customer', 'order_accepted',
            'تم قبول طلبك', format('قبل %s طلبك رقم #%s وسيتوجه إليك.', v_driver, v_n),
            'Your order was accepted', format('%s accepted order #%s and will head to you.', v_driver, v_n),
            v_data);
        when 'on_the_way' then
          perform private.notify(new.customer_id, 'customer', 'order_on_the_way',
            'الموزع في الطريق', format('طلبك رقم #%s في الطريق إليك.', v_n),
            'Distributor on the way', format('Order #%s is on its way to you.', v_n),
            v_data);
        when 'delivered' then
          perform private.notify(new.customer_id, 'customer', 'order_delivered',
            'تم توصيل طلبك', format('يرجى تأكيد استلام الطلب رقم #%s وتقييم الخدمة.', v_n),
            'Your order was delivered', format('Please confirm you received order #%s and rate the service.', v_n),
            v_data);
        when 'pending' then
          -- Back in the queue: the distributor released it or staff took it back.
          perform private.notify(new.customer_id, 'customer', 'order_released',
            'نبحث عن موزع آخر', format('اعتذر الموزع عن الطلب رقم #%s، ونبحث لك عن موزع آخر.', v_n),
            'Finding another distributor', format('The distributor dropped order #%s; we are finding you another one.', v_n),
            v_data);
          perform private.notify_nearby_drivers(new, old.driver_id);
        when 'expired' then
          perform private.notify(new.customer_id, 'customer', 'order_expired',
            'لا يوجد موزّع متاح', format('لم يقبل أحد الطلب رقم #%s. يمكنك إعادة الطلب في أي وقت.', v_n),
            'No distributor available', format('Nobody accepted order #%s. You can order again any time.', v_n),
            v_data);
        when 'cancelled' then
          if v_actor is distinct from new.customer_id then
            perform private.notify(new.customer_id, 'customer', 'order_cancelled',
              format('تم إلغاء طلبك #%s', v_n), coalesce(new.cancel_reason, ''),
              format('Order #%s was cancelled', v_n), coalesce(new.cancel_reason, ''),
              v_data);
          end if;
          if old.driver_id is not null and v_actor is distinct from old.driver_id then
            perform private.notify(old.driver_id, 'distributor', 'order_cancelled',
              format('أُلغي الطلب #%s', v_n), 'لم يعد عليك توصيل هذا الطلب.',
              format('Order #%s was cancelled', v_n), 'You no longer need to deliver it.',
              v_data);
          end if;
        else
          null;
      end case;
    end if;

    -- Staff gave the order to a distributor, or moved it to another one.
    if new.driver_id is not null and new.driver_id is distinct from old.driver_id
       and v_actor is distinct from new.driver_id then
      perform private.notify(new.driver_id, 'distributor', 'order_assigned',
        'تم إسناد طلب إليك', format('الطلب رقم #%s: %s × %s', v_n, new.service_name_ar, new.quantity),
        'An order was assigned to you', format('Order #%s: %s × %s', v_n, new.service_name_en, new.quantity),
        v_data);
    end if;
    if old.driver_id is not null and new.driver_id is distinct from old.driver_id
       and new.status in ('pending', 'accepted', 'on_the_way')
       and v_actor is distinct from old.driver_id then
      perform private.notify(old.driver_id, 'distributor', 'order_unassigned',
        format('الطلب #%s لم يعد لديك', v_n), 'أعادت الإدارة إسناد هذا الطلب.',
        format('Order #%s is no longer yours', v_n), 'Operations reassigned this order.',
        v_data);
    end if;

    if new.customer_confirmed_at is not null and old.customer_confirmed_at is null
       and new.driver_id is not null then
      perform private.notify(new.driver_id, 'distributor', 'order_confirmed',
        'العميل أكد الاستلام', format('تم تأكيد استلام الطلب رقم #%s.', v_n),
        'Customer confirmed receipt', format('Order #%s was confirmed as received.', v_n),
        v_data);
    end if;
  exception when others then
    -- A notification must never stop an order from moving.
    raise warning 'order notification failed for %: %', new.id, sqlerrm;
  end;
  return new;
end $$;

create trigger orders_notify_insert after insert on public.orders
  for each row execute function private.order_notifications();
create trigger orders_notify_update after update on public.orders
  for each row
  when (old.status is distinct from new.status
        or old.driver_id is distinct from new.driver_id
        or old.customer_confirmed_at is distinct from new.customer_confirmed_at)
  execute function private.order_notifications();

create or replace function private.driver_status_notifications()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if private.seeding() then
    return new;
  end if;
  begin
    case new.status
      when 'approved' then
        perform private.notify(new.id, 'distributor', 'account_approved',
          'تم اعتماد حسابك', 'يمكنك الآن الاتصال واستقبال الطلبات.',
          'Your account is approved', 'You can now go online and take orders.');
      when 'rejected' then
        perform private.notify(new.id, 'distributor', 'account_rejected',
          'لم يُعتمد حسابك', coalesce(new.status_reason, 'راجع وثائقك وأرسلها من جديد.'),
          'Your account was not approved', coalesce(new.status_reason, 'Check your documents and send them again.'));
      when 'suspended' then
        perform private.notify(new.id, 'distributor', 'account_suspended',
          'تم إيقاف حسابك مؤقتاً', coalesce(new.status_reason, ''),
          'Your account is suspended', coalesce(new.status_reason, ''));
      else
        null;
    end case;
  exception when others then
    raise warning 'driver status notification failed for %: %', new.id, sqlerrm;
  end;
  return new;
end $$;

create trigger drivers_notify_status after update on public.drivers
  for each row when (old.status is distinct from new.status)
  execute function private.driver_status_notifications();

create or replace function private.charge_notifications()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_amount text := to_char(new.amount, 'FM999990.000');
  v_data jsonb := jsonb_build_object('charge_id', new.id, 'order_id', new.order_id);
begin
  if private.seeding() then
    return new;
  end if;
  begin
    if tg_op = 'INSERT' then
      perform private.notify(new.driver_id, 'distributor', 'charge_created',
        format('مطالبة جديدة: %s', new.title), format('%s د.أ — %s', v_amount, new.note),
        format('New charge: %s', new.title), format('%s JOD — %s', v_amount, new.note),
        v_data);
    elsif new.status = 'paid' then
      perform private.notify(new.driver_id, 'distributor', 'charge_paid',
        'تم تسجيل دفع مطالبة', format('%s · %s د.أ', new.title, v_amount),
        'Charge marked as paid', format('%s · %s JOD', new.title, v_amount),
        v_data);
    elsif new.status = 'waived' then
      perform private.notify(new.driver_id, 'distributor', 'charge_waived',
        'تم إعفاؤك من مطالبة', format('%s · %s د.أ', new.title, v_amount),
        'A charge was waived', format('%s · %s JOD', new.title, v_amount),
        v_data);
    end if;
  exception when others then
    raise warning 'charge notification failed for %: %', new.id, sqlerrm;
  end;
  return new;
end $$;

create trigger driver_charges_notify_insert after insert on public.driver_charges
  for each row execute function private.charge_notifications();
create trigger driver_charges_notify_settle after update on public.driver_charges
  for each row when (old.status is distinct from new.status)
  execute function private.charge_notifications();

create or replace function private.document_notifications()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_ar text := case new.kind
    when 'national_id' then 'الهوية الشخصية'
    when 'driving_licence' then 'رخصة القيادة'
    when 'vehicle_registration' then 'رخصة المركبة'
    else 'كتاب الوكالة' end;
  v_en text := case new.kind
    when 'national_id' then 'National ID'
    when 'driving_licence' then 'Driving licence'
    when 'vehicle_registration' then 'Vehicle registration'
    else 'Agency letter' end;
begin
  if private.seeding() then
    return new;
  end if;
  begin
    if new.status = 'approved' then
      perform private.notify(new.driver_id, 'distributor', 'document_approved',
        format('تم قبول %s', v_ar), 'تمت مراجعة الوثيقة وقبولها.',
        format('%s approved', v_en), 'Your document was reviewed and approved.',
        jsonb_build_object('document_id', new.id));
    elsif new.status = 'rejected' then
      perform private.notify(new.driver_id, 'distributor', 'document_rejected',
        format('رُفضت %s', v_ar), coalesce(new.review_note, 'يرجى رفعها من جديد.'),
        format('%s rejected', v_en), coalesce(new.review_note, 'Please upload it again.'),
        jsonb_build_object('document_id', new.id));
    end if;
  exception when others then
    raise warning 'document notification failed for %: %', new.id, sqlerrm;
  end;
  return new;
end $$;

create trigger driver_documents_notify_review after update on public.driver_documents
  for each row when (old.status is distinct from new.status)
  execute function private.document_notifications();

-- ---------------------------------------------------------------- 5. delivery
-- Asks the Edge Function to send what is queued. pg_net sends the request
-- after the transaction commits, so the function sees the new rows.
create or replace function private.dispatch_push()
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'clickgas_push_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'clickgas_push_secret';
  if v_url is null or v_secret is null then
    return; -- not configured: rows stay queued (docs/runbooks/push-notifications.md)
  end if;
  perform net.http_post(
    url := v_url,
    body := '{}'::jsonb,
    headers := jsonb_build_object('content-type', 'application/json', 'x-push-secret', v_secret),
    timeout_milliseconds := 10000);
exception when others then
  raise warning 'push dispatch skipped: %', sqlerrm;
end $$;

create or replace function private.notifications_inserted()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if exists (select 1 from new_rows where push_status = 'queued') then
    perform private.dispatch_push();
  end if;
  return null;
end $$;

-- Once per statement: a new order announced to 20 distributors is one call.
create trigger notifications_dispatch after insert on public.notifications
  referencing new table as new_rows
  for each statement execute function private.notifications_inserted();

-- Edge Function: take up to p_limit queued messages, in each recipient's
-- language, with the tokens of the app they belong to.
create or replace function public.push_claim(p_limit integer default 100)
returns table (id bigint, kind text, title text, body text, data jsonb, tokens text[])
language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
begin
  return query
    with picked as (
      select n.id from public.notifications n
       where n.push_status = 'queued'
       order by n.id
       limit least(greatest(coalesce(p_limit, 100), 1), 500)
       for update skip locked
    ), claimed as (
      update public.notifications n
         set push_status = 'sending', push_attempts = n.push_attempts + 1, push_claimed_at = now()
        from picked
       where n.id = picked.id
      returning n.id, n.user_id, n.app, n.kind, n.title_ar, n.body_ar, n.title_en, n.body_en, n.data
    )
    select c.id, c.kind,
           case when p.locale = 'en' then c.title_en else c.title_ar end,
           case when p.locale = 'en' then c.body_en else c.body_ar end,
           c.data,
           array(select t.token from public.device_tokens t where t.user_id = c.user_id and t.app = c.app)
      from claimed c
      join public.profiles p on p.id = c.user_id
     order by c.id;
end $$;
comment on function public.push_claim(integer) is
  'send-push only (service role): claims up to p_limit queued notifications (max 500) with the localized title/body and device tokens.';

-- Edge Function: [{id, ok, sent_count, error, invalid_tokens[]}] per message.
create or replace function public.push_report(p_results jsonb)
returns integer language plpgsql security definer set search_path = '' as $$
declare
  r jsonb;
  v_ok boolean;
  v_sent int;
  v_count int := 0;
begin
  for r in select value from jsonb_array_elements(coalesce(p_results, '[]'::jsonb)) loop
    v_ok := coalesce((r ->> 'ok')::boolean, false);
    v_sent := coalesce((r ->> 'sent_count')::int, 0);
    update public.notifications n
       set push_status = case
             when v_ok and v_sent > 0 then 'sent'
             when v_ok then 'no_device'
             when n.push_attempts >= 5 then 'failed'
             else 'queued' end,
           sent_at = case when v_ok and v_sent > 0 then now() end,
           push_error = case when v_ok then null else left(r ->> 'error', 300) end
     where n.id = (r ->> 'id')::bigint and n.push_status = 'sending';
    if found then
      v_count := v_count + 1;
    end if;
    delete from public.device_tokens t
     where t.token in (select jsonb_array_elements_text(coalesce(r -> 'invalid_tokens', '[]'::jsonb)));
  end loop;
  return v_count;
end $$;
comment on function public.push_report(jsonb) is
  'send-push only (service role): records the outcome of each claimed notification and deletes tokens Firebase reported as invalid. Returns rows updated.';

-- Every minute: retry what is left, give up on stale messages, trim history.
create or replace function public.push_flush()
returns integer language plpgsql security definer set search_path = '' as $$
declare
  v_queued int;
begin
  -- A send that never reported back (function crashed or timed out).
  update public.notifications
     set push_status = case when push_attempts >= 5 then 'failed' else 'queued' end
   where push_status = 'sending' and push_claimed_at < now() - interval '2 minutes';
  -- "On the way" half an hour later helps nobody: history only.
  update public.notifications
     set push_status = 'expired'
   where push_status = 'queued' and created_at < now() - interval '30 minutes';
  delete from public.notifications where created_at < now() - interval '60 days';
  select count(*) into v_queued from public.notifications where push_status = 'queued';
  if v_queued > 0 then
    perform private.dispatch_push();
  end if;
  return v_queued;
end $$;
comment on function public.push_flush() is
  'Scheduled every minute (pg_cron clickgas-push-flush): re-queues stuck sends, expires messages older than 30 minutes, deletes history older than 60 days, and calls send-push if anything is queued.';

revoke execute on function public.push_claim(integer) from public, anon, authenticated;
revoke execute on function public.push_report(jsonb) from public, anon, authenticated;
revoke execute on function public.push_flush() from public, anon, authenticated;
grant execute on function public.push_claim(integer) to service_role;
grant execute on function public.push_report(jsonb) to service_role;
grant execute on function public.push_flush() to service_role;

do $$
begin
  create extension if not exists pg_net with schema extensions;
exception when others then
  raise notice 'pg_net not available (%) - pushes stay queued', sqlerrm;
end $$;

do $$
begin
  perform cron.schedule('clickgas-push-flush', '* * * * *', 'select public.push_flush()');
exception when others then
  raise notice 'pg_cron not available (%) - schedule public.push_flush() manually', sqlerrm;
end $$;
