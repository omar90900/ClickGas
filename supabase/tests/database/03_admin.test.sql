-- Staff roles, audit trail and staff actions (Phase 1 admin core).
-- Run with: supabase test db
begin;
select plan(45);

-- ---------------------------------------------------------------- fixtures
-- owner c001, support c002, customer c003, distributor c004
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-0000000c0001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'owner@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Test Owner","phone":"+962770000101","city_id":1}', now(), now()),
  ('00000000-0000-0000-0000-0000000c0002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'support@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Test Support","phone":"+962770000102","city_id":1}', now(), now()),
  ('00000000-0000-0000-0000-0000000c0003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'customer@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Test Customer","phone":"+962770000103","city_id":1}', now(), now()),
  ('00000000-0000-0000-0000-0000000c0004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'driver@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Test Driver","phone":"+962770000104","city_id":1,"account_type":"driver","vehicle_plate":"1-1","vehicle_type":"pickup","agency_name":"A"}', now(), now());

update public.profiles set role = 'admin'
 where id in ('00000000-0000-0000-0000-0000000c0001', '00000000-0000-0000-0000-0000000c0002');
insert into public.staff_members (user_id, role) values
  ('00000000-0000-0000-0000-0000000c0001', 'owner'),
  ('00000000-0000-0000-0000-0000000c0002', 'support');
update public.drivers set cylinders_on_board = 1 where id = '00000000-0000-0000-0000-0000000c0004';

select is(
  (select status::text from public.drivers where id = '00000000-0000-0000-0000-0000000c0004'),
  'pending', 'a new distributor waits for approval');

-- ---------------------------------------------------------------- customer
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000c0003","role":"authenticated"}';

insert into public.orders (id, customer_id, service_id, quantity, payment_method, delivery_lat, delivery_lng)
values ('00000000-0000-0000-0000-0000000d0001', '00000000-0000-0000-0000-0000000c0003', 1, 2, 'cash', 31.95, 35.91);

select is((select count(*)::int from public.admin_actions), 0, 'customers cannot read the audit trail');
select is((select count(*)::int from public.admin_whoami()), 0, 'whoami is empty for a customer');
select throws_ok($$ select public.admin_overview() $$, 'P0001', 'PERMISSION_DENIED',
  'customers cannot open the dashboard');
select throws_ok($$ select public.admin_cancel_order('00000000-0000-0000-0000-0000000d0001', 'no reason') $$,
  'P0001', 'PERMISSION_DENIED', 'customers cannot use staff actions');

-- ---------------------------------------------------------------- support
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000c0002","role":"authenticated"}';

select is((select role::text from public.admin_whoami()), 'support', 'whoami returns the staff role');
select ok((select count(*) from public.profiles) >= 4, 'staff read every profile');
select throws_ok(
  $$ select public.admin_set_driver_status('00000000-0000-0000-0000-0000000c0004', 'approved') $$,
  'P0001', 'PERMISSION_DENIED', 'support cannot approve distributors');
select throws_ok(
  $$ select public.admin_create_charge('00000000-0000-0000-0000-0000000c0004', 'fine', 'Late', 1, 'late delivery') $$,
  'P0001', 'PERMISSION_DENIED', 'support cannot raise charges');
select throws_ok(
  $$ select public.admin_set_account_active('00000000-0000-0000-0000-0000000c0003', false) $$,
  'P0001', 'REASON_REQUIRED', 'blocking needs a reason');
select throws_ok(
  $$ select public.admin_set_account_active('00000000-0000-0000-0000-0000000c0004', false, 'fraud check') $$,
  'P0001', 'PERMISSION_DENIED', 'support cannot block distributors');
select throws_ok(
  $$ select public.admin_set_fees(0.2, 0.1) $$,
  'P0001', 'PERMISSION_DENIED', 'only the owner changes fees');

-- ---------------------------------------------------------------- owner: distributors
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000c0001","role":"authenticated"}';

select ok((public.admin_overview() ->> 'orders_today')::int >= 1, 'the owner opens the dashboard');
select is(jsonb_array_length(public.admin_overview() -> 'last_14_days'), 14, 'the dashboard has a 14-day series');
select throws_ok(
  $$ select public.admin_set_driver_status('00000000-0000-0000-0000-0000000c0004', 'rejected') $$,
  'P0001', 'REASON_REQUIRED', 'rejecting needs a reason');
select is(
  (select status::text from public.admin_set_driver_status('00000000-0000-0000-0000-0000000c0004', 'approved')),
  'approved', 'the owner approves a distributor');
select is(
  (select is_verified from public.drivers where id = '00000000-0000-0000-0000-0000000c0004'),
  true, 'approval sets is_verified');
select is(
  (select count(*)::int from public.admin_actions where action = 'driver.set_status'),
  1, 'the approval is in the audit trail');
select ok(
  exists (select 1 from public.admin_list_drivers() where id = '00000000-0000-0000-0000-0000000c0004'),
  'the distributor list returns the distributor');

-- ---------------------------------------------------------------- owner: orders
select throws_ok(
  $$ select public.admin_assign_order('00000000-0000-0000-0000-0000000d0001', '00000000-0000-0000-0000-0000000c0004', 'closest') $$,
  'P0001', 'NOT_ENOUGH_CYLINDERS', 'assigning checks the stock on board');

reset role;
update public.drivers set cylinders_on_board = 5 where id = '00000000-0000-0000-0000-0000000c0004';
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000c0001","role":"authenticated"}';

select is(
  (select driver_id from public.admin_assign_order('00000000-0000-0000-0000-0000000d0001', '00000000-0000-0000-0000-0000000c0004', 'closest')),
  '00000000-0000-0000-0000-0000000c0004'::uuid, 'staff assigns the order to a distributor');
select is(
  (select status::text from public.admin_assign_order('00000000-0000-0000-0000-0000000d0001', null, 'truck broke down')),
  'pending', 'staff puts the order back in the queue');
select throws_ok(
  $$ select public.admin_cancel_order('00000000-0000-0000-0000-0000000d0001', '') $$,
  'P0001', 'REASON_REQUIRED', 'cancelling needs a reason');
select is(
  (select status::text from public.admin_cancel_order('00000000-0000-0000-0000-0000000d0001', 'customer called to cancel')),
  'cancelled', 'staff cancels the order');
select ok(
  jsonb_array_length(public.admin_order_detail('00000000-0000-0000-0000-0000000d0001') -> 'events') >= 4,
  'the inspector lists every status change');
select is(
  (select count(*)::int from public.admin_search_orders(p_search := '+962770000103')),
  1, 'orders can be found by customer phone');
select ok(
  exists (select 1 from public.admin_list_customers() where id = '00000000-0000-0000-0000-0000000c0003'),
  'the customer list returns the customer');
select ok(public.admin_live_map() ? 'drivers', 'the live map returns distributors and orders');

-- ---------------------------------------------------------------- owner: money and settings
select throws_ok(
  $$ select public.admin_create_charge('00000000-0000-0000-0000-0000000c0004', 'fine', 'Late delivery', 2.5) $$,
  'P0001', 'REASON_REQUIRED', 'a charge needs an explanation');
select is(
  (select status::text from public.admin_create_charge(
     '00000000-0000-0000-0000-0000000c0004', 'fine', 'Late delivery', 2.5, 'Arrived two hours late')),
  'open', 'the owner raises a charge');
select is(
  (select open_charges from public.admin_list_drivers(p_driver_id := '00000000-0000-0000-0000-0000000c0004')),
  2.500::numeric, 'open charges show on the distributor');
select is(
  (select status::text from public.admin_settle_charge((select max(id) from public.driver_charges), 'paid')),
  'paid', 'a charge is marked paid');
select throws_ok(
  $$ select public.admin_settle_charge((select max(id) from public.driver_charges), 'waived', 'duplicate') $$,
  'P0001', 'CHARGE_NOT_OPEN', 'a settled charge cannot change');
select is(
  (public.admin_finance(now() - interval '1 day', now() + interval '1 day') -> 'charges' ->> 'paid_amount')::numeric,
  2.5::numeric, 'the finance report counts the paid charge');
select throws_ok($$ select public.admin_update_config('{"nope": 1}') $$,
  'P0001', 'INVALID_SETTING', 'unknown settings are refused');
select throws_ok($$ select public.admin_update_config('{"driver_radius_km": "far"}') $$,
  'P0001', 'INVALID_SETTING', 'badly typed settings are refused');
select is(
  (select driver_radius_km from public.admin_update_config('{"driver_radius_km": 3}')),
  3.00::numeric, 'the owner changes the dispatch radius');
select is(
  (select customer_fee from public.admin_set_fees(0.2, 0.1, null, 'test')),
  0.200::numeric, 'the owner sets new fees');
select is((select customer_fee from public.current_fees), 0.200::numeric, 'new fees are in force');
select is(
  (select price from public.admin_update_service(1::smallint, 7.5)),
  7.500::numeric, 'the owner changes a price');
select ok((select count(*) from public.price_history where service_id = 1) >= 2, 'the price change is kept in history');

-- ---------------------------------------------------------------- owner: staff
select throws_ok(
  $$ select public.admin_remove_staff('00000000-0000-0000-0000-0000000c0001') $$,
  'P0001', 'LAST_OWNER', 'the last owner cannot be removed');
select throws_ok($$ select public.admin_save_staff('+962770000104', 'support') $$,
  'P0001', 'INVALID_TARGET', 'distributor accounts cannot become staff');

-- ---------------------------------------------------------------- distributor documents
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000c0004","role":"authenticated"}';

select throws_ok(
  $$ select public.submit_driver_document('national_id', 'someone-else/id.jpg') $$,
  'P0001', 'PERMISSION_DENIED', 'documents must be in the distributor''s own folder');
select is(
  (select status::text from public.submit_driver_document('national_id', '00000000-0000-0000-0000-0000000c0004/national_id-1.jpg')),
  'pending', 'an uploaded document waits for review');

select * from finish();
rollback;
