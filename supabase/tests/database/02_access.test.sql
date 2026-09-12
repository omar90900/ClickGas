-- Who can see and change what (Row Level Security, grants, phone login).
-- Run with: supabase test db
begin;
select plan(8);

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-00000000a001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'a@test.local', extensions.crypt('secret1', extensions.gen_salt('bf')), now(),
   '{"full_name":"Customer A","phone":"+962770000001","city_id":1}', now(), now()),
  ('00000000-0000-0000-0000-00000000b001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'b@test.local', extensions.crypt('secret2', extensions.gen_salt('bf')), now(),
   '{"full_name":"Customer B","phone":"+962770000002","city_id":1}', now(), now());

-- ---------------------------------------------------------------- anon
set local role anon;
select ok((select count(*) from public.cities) > 0, 'anon can read cities (sign-up form)');
select is((select count(*)::int from public.profiles), 0, 'anon cannot read any profile');

select is(public.login_email_for_phone('+962770000001', 'secret1'), 'a@test.local',
  'phone login returns the email with the right password');
select is(public.login_email_for_phone('+962770000001', 'nope'), null,
  'phone login returns null with a wrong password');

-- ---------------------------------------------------------------- customer A
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000a001","role":"authenticated"}';

select is((select count(*)::int from public.profiles), 1, 'a customer sees only their own profile');

select throws_ok(
  $$ update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-00000000a001' $$,
  '42501', null, 'a customer cannot change their own role');

select throws_ok(
  $$ insert into public.driver_ledger (driver_id, kind, amount)
     values ('00000000-0000-0000-0000-00000000a001', 'payment', -1) $$,
  '42501', null, 'nobody writes the ledger directly');

select throws_ok(
  $$ select public.record_driver_payment('00000000-0000-0000-0000-00000000a001', 1) $$,
  'P0001', 'PERMISSION_DENIED', 'only staff record payments');

select * from finish();
rollback;
