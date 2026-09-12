-- Wider search, order expiry, coverage checks and demo data.
-- Run with: supabase test db
begin;
select plan(23);

-- ---------------------------------------------------------------- fixtures
-- owner e001, customer e002, distributor e003
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-0000000e0001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'owner4@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Owner Four","phone":"+962770000401","city_id":1}', now(), now()),
  ('00000000-0000-0000-0000-0000000e0002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'customer4@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Customer Four","phone":"+962770000402","city_id":1}', now(), now()),
  ('00000000-0000-0000-0000-0000000e0003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'driver4@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Driver Four","phone":"+962770000403","city_id":1,"account_type":"driver","vehicle_plate":"4-4","vehicle_type":"pickup"}', now(), now());
update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-0000000e0001';
insert into public.staff_members (user_id, role) values ('00000000-0000-0000-0000-0000000e0001', 'owner');
update public.app_config
   set driver_radius_km = 2, radius_step_km = 2, radius_step_minutes = 5, max_radius_km = 6, order_expiry_minutes = 20;
update public.drivers
   set status = 'approved', is_online = true, lat = 31.9539, lng = 35.9106,
       location_updated_at = now(), cylinders_on_board = 5
 where id = '00000000-0000-0000-0000-0000000e0003';

-- ---------------------------------------------------------------- search radius
select is(public.order_radius_km(now()), 2::numeric, 'a new order is offered within 2 km');
select is(public.order_radius_km(now() - interval '6 minutes'), 4::numeric, 'after 5 minutes it widens to 4 km');
select is(public.order_radius_km(now() - interval '45 minutes'), 6::numeric, 'it never goes beyond 6 km');

-- A customer about 3.5 km north of the distributor.
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000e0002","role":"authenticated"}';
insert into public.orders (id, customer_id, service_id, quantity, payment_method, delivery_lat, delivery_lng)
values ('00000000-0000-0000-0000-0000000f0001', '00000000-0000-0000-0000-0000000e0002', 1, 1, 'cash', 31.9854, 35.9106);

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000e0003","role":"authenticated"}';
select ok(
  not exists (select 1 from public.nearby_orders(31.9539, 35.9106) where id = '00000000-0000-0000-0000-0000000f0001'),
  'a fresh order 3.5 km away is not offered yet');

reset role;
update public.orders set created_at = now() - interval '6 minutes' where id = '00000000-0000-0000-0000-0000000f0001';
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000e0003","role":"authenticated"}';
select ok(
  exists (select 1 from public.nearby_orders(31.9539, 35.9106) where id = '00000000-0000-0000-0000-0000000f0001'),
  'after 5 minutes the distributor 3.5 km away sees it');

-- ---------------------------------------------------------------- expiry
-- The scheduled job runs with no signed-in user (the "system" actor).
reset role;
set local request.jwt.claims = '';
update public.orders set created_at = now() - interval '25 minutes' where id = '00000000-0000-0000-0000-0000000f0001';
select is(public.expire_stale_orders(), 1, 'orders waiting over 20 minutes expire');
select is(
  (select status::text from public.orders where id = '00000000-0000-0000-0000-0000000f0001'),
  'expired', 'the order is now expired');
select ok(
  exists (select 1 from public.job_runs where job = 'expire_orders' and ok and (detail ->> 'expired')::int = 1),
  'the run is logged in job_runs');
select is(
  (select actor_id from public.order_events
    where order_id = '00000000-0000-0000-0000-0000000f0001' and status = 'expired'),
  null::uuid, 'the system made the change');

-- ---------------------------------------------------------------- coverage
update public.drivers set is_online = false where id = '00000000-0000-0000-0000-0000000e0003';
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000e0002","role":"authenticated"}';
select is((public.coverage_check(31.9539, 35.9106) ->> 'nearby')::int, 0, 'no distributor online: nobody nearby');
select is((public.coverage_check(31.9539, 35.9106) ->> 'expiry_minutes')::int, 20, 'the check tells the customer the waiting time');

reset role;
select is((select count(*)::int from public.coverage_gaps where customer_id = '00000000-0000-0000-0000-0000000e0002'),
  1, 'one coverage gap is recorded (not one per check)');
update public.drivers set is_online = true, location_updated_at = now() where id = '00000000-0000-0000-0000-0000000e0003';
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000e0002","role":"authenticated"}';
select is((public.coverage_check(31.9539, 35.9106) ->> 'nearby')::int, 1, 'an online distributor is counted');

-- ---------------------------------------------------------------- demo data
select throws_ok($$ select public.demo_seed_order('{}') $$, '42501', null, 'apps cannot seed demo data');

reset role;
set local role service_role;
select throws_ok(
  $$ select public.demo_seed_order('{"customer_id":"00000000-0000-0000-0000-0000000e0002"}') $$,
  'P0001', 'INVALID_TARGET', 'only demo customers get demo orders');

reset role;
update public.profiles set is_demo = true where id = '00000000-0000-0000-0000-0000000e0002';
set local role service_role;
select isnt(
  public.demo_seed_order(jsonb_build_object(
    'customer_id', '00000000-0000-0000-0000-0000000e0002',
    'driver_id', '00000000-0000-0000-0000-0000000e0003',
    'status', 'delivered', 'quantity', 2, 'lat', 31.96, 'lng', 35.92, 'rating', 5,
    'created_at', now() - interval '3 days',
    'accepted_at', now() - interval '3 days' + interval '2 minutes',
    'delivered_at', now() - interval '3 days' + interval '25 minutes')),
  null, 'the seed writes a past order');

reset role;
select is(
  (select count(*)::int from public.order_events e join public.orders o on o.id = e.order_id
    where o.is_demo and o.status = 'delivered'),
  4, 'with its four status events');
select ok(
  (select created_at < now() - interval '2 days' and is_demo and service_fee = 0.1
     from public.orders where is_demo and status = 'delivered'),
  'keeps its date, is marked demo and carries the fees');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000e0001","role":"authenticated"}';
select is(public.admin_set_hide_demo(true), true, 'staff can hide demo data');
select is(
  (select count(*)::int from public.admin_search_orders(
     p_customer_id := '00000000-0000-0000-0000-0000000e0002', p_statuses := array['delivered'])),
  0, 'hidden demo orders are left out of the dashboard');
select throws_ok(
  $$ select public.admin_update_config('{"max_radius_km": 1}') $$,
  'P0001', 'INVALID_SETTING', 'the widest radius cannot be smaller than the dispatch radius');
select ok(
  public.admin_coverage(now() - interval '1 day', now() + interval '1 day') ? 'by_city',
  'the coverage report runs');

reset role;
set local role service_role;
select ok((public.demo_reset_data() ->> 'orders')::int >= 1, 'the demo reset removes demo orders');

select * from finish();
rollback;
