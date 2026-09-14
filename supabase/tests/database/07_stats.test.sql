-- Stats, order-card fields and plain notification text
-- (20260913180000_stats_and_plain_notifications).
-- Run with: supabase test db
begin;
select plan(10);

-- ---------------------------------------------------------------- fixtures
-- customer 7001, distributor 7002
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-0000000a7001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'customer7@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Customer Seven","phone":"+962770000701","city_id":1}', now(), now()),
  ('00000000-0000-0000-0000-0000000a7002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'driver7@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Driver Seven","phone":"+962770000702","city_id":1,"account_type":"driver","vehicle_plate":"7-2","vehicle_type":"pickup"}', now(), now());
update public.app_config set driver_radius_km = 2, radius_step_km = 2, radius_step_minutes = 5, max_radius_km = 6;
update public.drivers
   set status = 'approved', is_online = true, lat = 31.9550, lng = 35.9110,
       location_updated_at = now(), cylinders_on_board = 5
 where id = '00000000-0000-0000-0000-0000000a7002';

-- ---------------------------------------------------------------- empty stats
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a7001","role":"authenticated"}';
select is((select total_orders from public.my_order_stats()), 0,
  'a customer with nothing delivered has zero orders (not one empty row counted)');
select is((select month_paid from public.my_order_stats()), 0::numeric,
  'and has paid nothing this month');

insert into public.orders (id, customer_id, service_id, quantity, payment_method, delivery_lat, delivery_lng)
values ('00000000-0000-0000-0000-0000000b7001', '00000000-0000-0000-0000-0000000a7001', 1, 2, 'cash', 31.9539, 35.9106);

-- ---------------------------------------------------------------- distributor side
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a7002","role":"authenticated"}';
select is((select service_code from public.nearby_orders(31.9550, 35.9110)
            where id = '00000000-0000-0000-0000-0000000b7001'),
  'exchange', 'nearby orders say whether they are an exchange');
do $$ begin perform public.accept_order('00000000-0000-0000-0000-0000000b7001'); end $$;
select is((select service_code from public.driver_active_orders()
            where id = '00000000-0000-0000-0000-0000000b7001'),
  'exchange', 'accepted orders say so too');
do $$ begin perform public.start_delivery('00000000-0000-0000-0000-0000000b7001'); end $$;
do $$ begin perform public.complete_order('00000000-0000-0000-0000-0000000b7001'); end $$;
select is((select month_deliveries from public.driver_earnings_stats()), 1,
  'the distributor''s month counts the delivery');
select is((select year_cylinders from public.driver_earnings_stats()), 2,
  'and its two cylinders for the year');

-- ---------------------------------------------------------------- customer stats
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000a7001","role":"authenticated"}';
select is((select month_cylinders from public.my_order_stats()), 2,
  'the customer''s month counts two cylinders');
select is((select month_paid from public.my_order_stats()),
  (select total_price - delivery_fee from public.orders where id = '00000000-0000-0000-0000-0000000b7001'),
  'money paid leaves out the delivery fee');

-- ---------------------------------------------------------------- message text
reset role;
select ok(not exists (
  select 1 from public.notifications
   where data ->> 'order_id' = '00000000-0000-0000-0000-0000000b7001'
     and (title_en like '%#%' or body_en like '%#%' or title_ar like '%#%' or body_ar like '%#%')),
  'no message quotes the order number');
select is((select body_en from public.notifications
            where user_id = '00000000-0000-0000-0000-0000000a7001' and kind = 'order_on_the_way'),
  'The distributor is on their way.', 'the on-the-way message is plain');

select * from finish();
rollback;
