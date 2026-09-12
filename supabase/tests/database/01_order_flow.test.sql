-- Order lifecycle, fees, ledger and the state machine.
-- Run with: supabase test db   (local Supabase with all migrations applied)
begin;
select plan(14);

-- ---------------------------------------------------------------- fixtures
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-00000000c001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'cust@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Test Customer","phone":"+962790000001","city_id":1}', now(), now()),
  ('00000000-0000-0000-0000-00000000d001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'drv@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Test Driver","phone":"+962780000001","city_id":1,"account_type":"driver","vehicle_plate":"1-1","vehicle_type":"pickup","agency_name":"A"}', now(), now());

select is(
  (select role::text from public.profiles where id = '00000000-0000-0000-0000-00000000d001'),
  'driver', 'driver sign-up creates a driver profile');
select is(
  (select is_verified from public.drivers where id = '00000000-0000-0000-0000-00000000d001'),
  false, 'new drivers start unverified');

update public.drivers
   set is_verified = true, is_online = true, lat = 31.9539, lng = 35.9106, cylinders_on_board = 5
 where id = '00000000-0000-0000-0000-00000000d001';

-- ---------------------------------------------------------------- customer orders
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000c001","role":"authenticated"}';

insert into public.orders (customer_id, service_id, quantity, payment_method, delivery_lat, delivery_lng, total_price)
values ('00000000-0000-0000-0000-00000000c001', 1, 2, 'cash', 31.9580, 35.9150, 0.01);

select is(
  (select total_price from public.orders where customer_id = '00000000-0000-0000-0000-00000000c001'),
  14.100::numeric, 'server sets the total: 2 x 7.000 + 0.100 service fee');
select is(
  (select driver_fee from public.orders where customer_id = '00000000-0000-0000-0000-00000000c001'),
  0.050::numeric, 'distributor fee is copied onto the order');

select throws_ok(
  $$ insert into public.orders (customer_id, service_id, quantity, payment_method, delivery_lat, delivery_lng)
     values ('00000000-0000-0000-0000-00000000c001', 1, 1, 'cash', 31.95, 35.91) $$,
  '23505', null, 'a second open order is refused');

select throws_ok(
  $$ update public.orders set status = 'delivered' where customer_id = '00000000-0000-0000-0000-00000000c001' $$,
  '42501', null, 'customers cannot update orders directly');

-- ---------------------------------------------------------------- distributor
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000d001","role":"authenticated"}';

select ok(
  exists (select 1 from public.nearby_orders(31.9539, 35.9106)),
  'the order appears in nearby_orders');

select is(
  (select status::text from public.accept_order(
     (select id from public.orders where customer_id = '00000000-0000-0000-0000-00000000c001'))),
  'accepted', 'distributor accepts');

select is(
  (select status::text from public.complete_order(
     (select id from public.orders where customer_id = '00000000-0000-0000-0000-00000000c001'))),
  'delivered', 'distributor delivers');

select is(
  (select service_fee + driver_fee from public.orders where customer_id = '00000000-0000-0000-0000-00000000c001'),
  0.150::numeric, 'the delivered order carries 0.150 of platform fees');

select is(
  (select cylinders_on_board from public.drivers where id = '00000000-0000-0000-0000-00000000d001'),
  3::smallint, 'stock drops by the quantity');

select throws_like(
  $$ select public.start_delivery(
       (select id from public.orders where customer_id = '00000000-0000-0000-0000-00000000c001')) $$,
  '%INVALID_TRANSITION%', 'a delivered order cannot go back on the way');

-- ---------------------------------------------------------------- state machine as system
reset role;
select throws_like(
  $$ update public.orders set status = 'pending' where customer_id = '00000000-0000-0000-0000-00000000c001' $$,
  '%INVALID_TRANSITION%', 'even the owner role cannot make an unlisted transition');

select is(
  (select count(*)::int from public.order_events
    where order_id = (select id from public.orders where customer_id = '00000000-0000-0000-0000-00000000c001')),
  3, 'three status events recorded: pending, accepted, delivered');

select * from finish();
rollback;
