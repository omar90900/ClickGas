-- Push notifications (20260913150000_push_notifications).
-- Run with: supabase test db
begin;
select plan(21);

-- ---------------------------------------------------------------- fixtures
-- customer 6001, distributor near 6002, distributor far 6003, owner 6004
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-0000000a6001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'customer6@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Customer Six","phone":"+962770000601","city_id":1}', now(), now()),
  ('00000000-0000-0000-0000-0000000a6002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'near6@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Driver Six","phone":"+962770000602","city_id":1,"account_type":"driver","vehicle_plate":"6-2","vehicle_type":"pickup"}', now(), now()),
  ('00000000-0000-0000-0000-0000000a6003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'far6@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Far Driver","phone":"+962770000603","city_id":1,"account_type":"driver","vehicle_plate":"6-3","vehicle_type":"pickup"}', now(), now()),
  ('00000000-0000-0000-0000-0000000a6004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'owner6@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Owner Six","phone":"+962770000604","city_id":1}', now(), now());
update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-0000000a6004';
insert into public.staff_members (user_id, role) values ('00000000-0000-0000-0000-0000000a6004', 'owner');
update public.app_config set driver_radius_km = 2, radius_step_km = 2, radius_step_minutes = 5, max_radius_km = 6;
update public.drivers
   set status = 'approved', is_online = true, lat = 31.9550, lng = 35.9110,
       location_updated_at = now(), cylinders_on_board = 5
 where id = '00000000-0000-0000-0000-0000000a6002';
update public.drivers
   set status = 'approved', is_online = true, lat = 32.1000, lng = 35.9110,
       location_updated_at = now(), cylinders_on_board = 5
 where id = '00000000-0000-0000-0000-0000000a6003';

select is((select locale from public.profiles where id = '00000000-0000-0000-0000-0000000a6001'),
  'ar', 'notifications default to Arabic');

-- ---------------------------------------------------------------- devices
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a6001","role":"authenticated"}';
select lives_ok(
  $$select public.register_device('test-token-customer-000000000001', 'customer', 'android')$$,
  'a customer registers their phone');
select throws_ok(
  $$select public.register_device('test-token-customer-000000000002', 'admin', 'android')$$,
  'P0001', 'INVALID_SETTING', 'only the customer and distributor apps register');

-- ---------------------------------------------------------------- new order
insert into public.orders (id, customer_id, service_id, quantity, payment_method, delivery_lat, delivery_lng)
values ('00000000-0000-0000-0000-0000000b6001', '00000000-0000-0000-0000-0000000a6001', 1, 1, 'cash', 31.9539, 35.9106);

reset role;
set local request.jwt.claims = '';
select ok(exists (
  select 1 from public.notifications
   where user_id = '00000000-0000-0000-0000-0000000a6002' and kind = 'new_order'
     and data ->> 'order_id' = '00000000-0000-0000-0000-0000000b6001'),
  'the distributor nearby is told about the new order');
select ok(not exists (
  select 1 from public.notifications
   where user_id = '00000000-0000-0000-0000-0000000a6003' and kind = 'new_order'),
  'the distributor 16 km away is not');
select is((select push_status from public.notifications
            where user_id = '00000000-0000-0000-0000-0000000a6002' and kind = 'new_order'),
  'no_device', 'no phone registered: kept in the history, not pushed');

-- ---------------------------------------------------------------- status changes
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a6002","role":"authenticated"}';
do $$ begin perform public.accept_order('00000000-0000-0000-0000-0000000b6001'); end $$;
reset role;
select is((select push_status from public.notifications
            where user_id = '00000000-0000-0000-0000-0000000a6001' and kind = 'order_accepted'),
  'queued', 'the customer''s phone gets "accepted"');
select ok((select body_ar like '%Driver Six%' from public.notifications
            where user_id = '00000000-0000-0000-0000-0000000a6001' and kind = 'order_accepted'),
  'the message names the distributor');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a6001","role":"authenticated"}';
select lives_ok(
  $$update public.profiles set notify_order_updates = false, locale = 'en'
     where id = '00000000-0000-0000-0000-0000000a6001'$$,
  'a user changes their notification preferences');

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a6002","role":"authenticated"}';
do $$ begin perform public.start_delivery('00000000-0000-0000-0000-0000000b6001'); end $$;
reset role;
select is((select push_status from public.notifications
            where user_id = '00000000-0000-0000-0000-0000000a6001' and kind = 'order_on_the_way'),
  'muted', 'order updates turned off: history only');

-- ---------------------------------------------------------------- privacy and read state
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a6002","role":"authenticated"}';
select is((select count(*) from public.notifications
            where user_id = '00000000-0000-0000-0000-0000000a6001'),
  0::bigint, 'nobody reads another user''s notifications');

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a6001","role":"authenticated"}';
select is(public.mark_notifications_read(), 2, 'marking read returns how many were unread');
select throws_ok($$select * from public.push_claim(10)$$, '42501', null, 'apps cannot claim pushes');

-- ---------------------------------------------------------------- delivery
reset role;
set local request.jwt.claims = '';
select is((select title from public.push_claim(10) where kind = 'order_accepted'),
  'Your order was accepted', 'claimed in the recipient''s language');
select is(public.push_report(jsonb_build_array(jsonb_build_object(
    'id', (select id from public.notifications
            where user_id = '00000000-0000-0000-0000-0000000a6001' and kind = 'order_accepted'),
    'ok', true, 'sent_count', 1,
    'invalid_tokens', jsonb_build_array('test-token-customer-000000000001')))),
  1, 'the Edge Function reports back');
select is((select push_status from public.notifications
            where user_id = '00000000-0000-0000-0000-0000000a6001' and kind = 'order_accepted'),
  'sent', 'the push is marked sent');
select ok(not exists (select 1 from public.device_tokens where token = 'test-token-customer-000000000001'),
  'tokens Firebase rejects are deleted');

-- ---------------------------------------------------------------- staff actions
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a6004","role":"authenticated"}';
do $$
begin
  perform public.admin_create_charge('00000000-0000-0000-0000-0000000a6002', 'fine', 'Late delivery', 1.5,
    'The customer waited 40 minutes');
  perform public.admin_set_driver_status('00000000-0000-0000-0000-0000000a6003', 'suspended', 'Documents expired');
  perform public.admin_cancel_order('00000000-0000-0000-0000-0000000b6001', 'Customer asked by phone');
end $$;
reset role;
select ok(exists (select 1 from public.notifications
                   where user_id = '00000000-0000-0000-0000-0000000a6002' and kind = 'charge_created'),
  'a distributor is told about a new charge');
select ok((select body_en like '%Documents expired%' from public.notifications
            where user_id = '00000000-0000-0000-0000-0000000a6003' and kind = 'account_suspended'),
  'a suspension carries the reason');
select is((select count(*) from public.notifications
            where kind = 'order_cancelled' and data ->> 'order_id' = '00000000-0000-0000-0000-0000000b6001'),
  2::bigint, 'staff cancelling tells the customer and the distributor');

-- ---------------------------------------------------------------- seed mode
set local clickgas.seed = 'on';
do $$ begin perform private.notify('00000000-0000-0000-0000-0000000a6001', 'customer', 'order_accepted', 'x', 'x', 'x', 'x'); end $$;
set local clickgas.seed = '';
select is((select count(*) from public.notifications
            where user_id = '00000000-0000-0000-0000-0000000a6001' and kind = 'order_accepted'),
  1::bigint, 'demo seeding writes no notifications');

select * from finish();
rollback;
