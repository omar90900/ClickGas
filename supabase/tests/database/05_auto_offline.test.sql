-- Distributors whose app stopped reporting go offline (20260913120000_auto_offline).
-- Run with: supabase test db
begin;
select plan(3);

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-0000000a5001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'silent@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Silent Driver","phone":"+962770000501","city_id":1,"account_type":"driver","vehicle_plate":"5-1","vehicle_type":"pickup"}', now(), now()),
  ('00000000-0000-0000-0000-0000000a5002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'active@test.local', extensions.crypt('pass123', extensions.gen_salt('bf')), now(),
   '{"full_name":"Active Driver","phone":"+962770000502","city_id":1,"account_type":"driver","vehicle_plate":"5-2","vehicle_type":"pickup"}', now(), now());

update public.drivers
   set status = 'approved', is_online = true, lat = 31.95, lng = 35.91,
       location_updated_at = now() - interval '20 minutes'
 where id = '00000000-0000-0000-0000-0000000a5001';
update public.drivers
   set status = 'approved', is_online = true, lat = 31.96, lng = 35.92,
       location_updated_at = now() - interval '1 minute'
 where id = '00000000-0000-0000-0000-0000000a5002';

set local request.jwt.claims = '';
select is(public.expire_stale_orders(), 0, 'nothing to expire');
select is(
  (select is_online from public.drivers where id = '00000000-0000-0000-0000-0000000a5001'),
  false, 'a distributor silent for 15 minutes goes offline');
select is(
  (select is_online from public.drivers where id = '00000000-0000-0000-0000-0000000a5002'),
  true, 'an active distributor stays online');

select * from finish();
rollback;
