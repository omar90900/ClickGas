-- =============================================================================
-- ClickGas - distributors whose app stopped reporting go offline
-- (run once, after 20260913090000_coverage_and_demo.sql)
--
-- A distributor stays "online" in the database if their phone dies, loses
-- signal or the app is killed without going offline. They then show on the
-- customer map, count as online on the dashboard, and receive nothing.
-- The every-minute job now also switches off anyone whose position is older
-- than 15 minutes. The distributor app re-confirms is_online with every
-- position it sends, so an active distributor is never switched off.
--
-- Documentation: docs/business-rules.md#dispatch, docs/runbooks/driver-cannot-go-online.md
-- =============================================================================

create or replace function public.expire_stale_orders()
returns integer language plpgsql security definer set search_path = '' as $$
declare
  v_run bigint;
  v_numbers bigint[];
  v_offline int;
begin
  insert into public.job_runs (job) values ('expire_orders') returning id into v_run;

  with expired as (
    update public.orders o
       set status = 'expired'
     where o.status = 'pending'
       and o.created_at < now() - make_interval(
             mins => (select c.order_expiry_minutes from public.app_config c where c.id))
    returning o.order_number
  )
  select coalesce(array_agg(order_number), '{}') into v_numbers from expired;

  with gone as (
    update public.drivers d
       set is_online = false
     where d.is_online
       and (d.location_updated_at is null or d.location_updated_at < now() - interval '15 minutes')
    returning d.id
  )
  select count(*) into v_offline from gone;

  update public.job_runs
     set finished_at = now(), ok = true,
         detail = jsonb_build_object(
           'expired', cardinality(v_numbers),
           'orders', to_jsonb(v_numbers),
           'drivers_offline', v_offline)
   where id = v_run;
  -- Keep the log small: successful runs for 2 days, failures for 30.
  delete from public.job_runs
   where job = 'expire_orders'
     and ((ok and started_at < now() - interval '2 days') or started_at < now() - interval '30 days');
  return cardinality(v_numbers);
exception when others then
  insert into public.job_runs (job, finished_at, ok, detail)
  values ('expire_orders', now(), false, jsonb_build_object('error', sqlerrm));
  return 0;
end $$;
comment on function public.expire_stale_orders() is
  'Scheduled every minute: pending orders older than order_expiry_minutes become expired (as the system), and distributors silent for 15 minutes go offline. Logs each run in job_runs.';
revoke execute on function public.expire_stale_orders() from public, anon, authenticated;
grant execute on function public.expire_stale_orders() to service_role;
