-- Wallet payments (20260913200000_wallet_payments).
-- Run with: supabase test db
begin;
select plan(19);

-- ---------------------------------------------------------------- fixtures
-- customer 8001, distributor with a wallet 8002, distributor without 8003
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-0000000a8001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'customer8@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Customer Eight","phone":"+962770000801","city_id":1}', now(), now()),
  ('00000000-0000-0000-0000-0000000a8002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'driver8@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Driver Eight","phone":"+962770000802","city_id":1,"account_type":"driver","vehicle_plate":"8-2","vehicle_type":"pickup"}', now(), now()),
  ('00000000-0000-0000-0000-0000000a8003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'nowallet8@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"No Wallet","phone":"+962770000803","city_id":1,"account_type":"driver","vehicle_plate":"8-3","vehicle_type":"pickup"}', now(), now());
update public.app_config set driver_radius_km = 2, radius_step_km = 2, radius_step_minutes = 5, max_radius_km = 6;
update public.drivers
   set status = 'approved', is_online = true, lat = 31.9550, lng = 35.9110,
       location_updated_at = now(), cylinders_on_board = 5
 where id in ('00000000-0000-0000-0000-0000000a8002', '00000000-0000-0000-0000-0000000a8003');

-- ---------------------------------------------------------------- distributor wallet
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a8002","role":"authenticated"}';
select throws_ok(
  $$select public.save_my_wallet('orange_money', 'Driver Eight', '+962790000802', null, false)$$,
  'P0001', 'TERMS_NOT_ACCEPTED', 'a wallet is saved only after accepting the disclaimer');
select lives_ok(
  $$select public.save_my_wallet('orange_money', 'Driver Eight', '+962790000802', null, true)$$,
  'the distributor saves an Orange Money wallet');
reset role;
select ok(exists (
  select 1 from public.notifications
   where user_id = '00000000-0000-0000-0000-0000000a8002' and kind = 'wallet_saved'),
  'and is reminded that ClickGas is not liable for wrong details');

-- ---------------------------------------------------------------- wallet order
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a8001","role":"authenticated"}';
insert into public.orders (id, customer_id, service_id, quantity, payment_method, delivery_lat, delivery_lng)
values ('00000000-0000-0000-0000-0000000b8001', '00000000-0000-0000-0000-0000000a8001', 1, 1, 'wallet', 31.9539, 35.9106);

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a8003","role":"authenticated"}';
select throws_ok(
  $$select public.accept_order('00000000-0000-0000-0000-0000000b8001')$$,
  'P0001', 'NO_WALLET_ACCOUNT', 'a distributor without a wallet cannot take a wallet order');

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a8002","role":"authenticated"}';
select lives_ok(
  $$select public.accept_order('00000000-0000-0000-0000-0000000b8001')$$,
  'a distributor with a wallet takes it');
select is((select status from public.order_payments where order_id = '00000000-0000-0000-0000-0000000b8001'),
  'awaiting', 'the payment waits for the customer');
select is((select jsonb_array_length(payees) from public.order_payments where order_id = '00000000-0000-0000-0000-0000000b8001'),
  1, 'with a copy of the distributor''s wallet');
reset role;
select ok(exists (
  select 1 from public.notifications
   where user_id = '00000000-0000-0000-0000-0000000a8001' and kind = 'order_pay_on_arrival'),
  'the customer is told to pay when the distributor arrives');

-- ---------------------------------------------------------------- no delivery before payment
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a8002","role":"authenticated"}';
do $$ begin perform public.start_delivery('00000000-0000-0000-0000-0000000b8001'); end $$;
select throws_ok(
  $$select public.complete_order('00000000-0000-0000-0000-0000000b8001')$$,
  'P0001', 'PAYMENT_NOT_CONFIRMED', 'an unpaid wallet order cannot be delivered');

-- ---------------------------------------------------------------- claim, dispute, confirm
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a8001","role":"authenticated"}';
select lives_ok(
  $$select public.claim_wallet_payment('00000000-0000-0000-0000-0000000b8001', 'orange_money', 'TX123')$$,
  'the customer says they paid');
select is((select reference from public.order_payments where order_id = '00000000-0000-0000-0000-0000000b8001'),
  'TX123', 'with the transaction number');
reset role;
select ok(exists (
  select 1 from public.notifications
   where user_id = '00000000-0000-0000-0000-0000000a8002' and kind = 'order_payment_claimed'),
  'the distributor is told to check their wallet');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a8002","role":"authenticated"}';
select lives_ok(
  $$select public.dispute_wallet_payment('00000000-0000-0000-0000-0000000b8001', 'nothing arrived')$$,
  'the distributor says it has not arrived');
select is((select status from public.order_payments where order_id = '00000000-0000-0000-0000-0000000b8001'),
  'disputed', 'the payment is disputed');
select lives_ok(
  $$select public.confirm_wallet_payment('00000000-0000-0000-0000-0000000b8001')$$,
  'then confirms once the money shows up');
select lives_ok(
  $$select public.complete_order('00000000-0000-0000-0000-0000000b8001')$$,
  'a paid wallet order can be delivered');
select is((select status::text from public.orders where id = '00000000-0000-0000-0000-0000000b8001'),
  'delivered', 'and is delivered');

-- ---------------------------------------------------------------- who can see it
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a8001","role":"authenticated"}';
select is((select count(*) from public.order_payments), 1::bigint, 'the customer sees their payment');
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a8003","role":"authenticated"}';
select is((select count(*) from public.order_payments), 0::bigint, 'another distributor does not');
select is((select count(*) from public.driver_wallets), 0::bigint, 'nor anyone else''s wallet');

select * from finish();
rollback;
