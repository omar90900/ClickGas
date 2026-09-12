-- =============================================================================
-- ClickGas - run once, after 20260911120000_driver_app.sql
--
--   1. A driver's slot is freed as soon as they mark the order delivered.
--      The customer still confirms receipt, but that no longer blocks the
--      driver from taking new orders.
--   2. Profile photos: public `avatars` storage bucket (each user writes only
--      their own folder) + photos returned by the driver/customer RPCs.
-- =============================================================================

-- ---------------------------------------------------------------- 1. slots
create or replace function public.driver_committed_orders(p_driver_id uuid)
returns table (order_count int, cylinders int)
language sql stable security definer set search_path = '' as $$
  select count(*)::int, coalesce(sum(o.quantity), 0)::int
    from public.orders o
   where o.driver_id = p_driver_id
     and o.status in ('accepted', 'on_the_way');
$$;
revoke execute on function public.driver_committed_orders(uuid) from public, anon, authenticated;

-- Return types change (photos added), so these are dropped and recreated.
drop function if exists public.driver_active_orders();
create function public.driver_active_orders()
returns table (
  id uuid, order_number bigint, status public.order_status,
  customer_name text, customer_phone text, customer_avatar text,
  service_name_ar text, service_name_en text, quantity smallint,
  total_price numeric, payment_method public.payment_method,
  delivery_lat double precision, delivery_lng double precision,
  delivery_address text, notes text, created_at timestamptz,
  accepted_at timestamptz, delivered_at timestamptz, customer_confirmed_at timestamptz
) language sql stable security definer set search_path = '' as $$
  select o.id, o.order_number, o.status, p.full_name, p.phone, p.avatar_url,
         o.service_name_ar, o.service_name_en, o.quantity, o.total_price,
         o.payment_method, o.delivery_lat, o.delivery_lng, o.delivery_address,
         o.notes, o.created_at, o.accepted_at, o.delivered_at, o.customer_confirmed_at
    from public.orders o
    join public.profiles p on p.id = o.customer_id
   where o.driver_id = auth.uid()
     and o.status in ('accepted', 'on_the_way')
   order by o.accepted_at;
$$;

drop function if exists public.nearby_orders(double precision, double precision);
create function public.nearby_orders(p_lat double precision, p_lng double precision)
returns table (
  id uuid, order_number bigint, customer_name text, customer_avatar text,
  service_name_ar text, service_name_en text, quantity smallint,
  total_price numeric, payment_method public.payment_method,
  delivery_lat double precision, delivery_lng double precision,
  delivery_address text, notes text, created_at timestamptz, distance_m double precision
) language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
begin
  if not public.is_verified_driver() then
    raise exception 'NOT_A_VERIFIED_DRIVER';
  end if;
  return query
    select o.id, o.order_number, p.full_name, p.avatar_url, o.service_name_ar,
           o.service_name_en, o.quantity, o.total_price, o.payment_method,
           o.delivery_lat, o.delivery_lng, o.delivery_address, o.notes,
           o.created_at, x.dist
      from public.orders o
      join public.profiles p on p.id = o.customer_id
      cross join lateral (
        select public.distance_m(p_lat, p_lng, o.delivery_lat, o.delivery_lng) as dist
      ) x
     where o.status = 'pending'
       and x.dist <= (select c.driver_radius_km from public.app_config c where c.id) * 1000
     order by x.dist
     limit 50;
end $$;

drop function if exists public.get_order_driver(uuid);
create function public.get_order_driver(p_order_id uuid)
returns table (
  id uuid, full_name text, phone text, avatar_url text, vehicle_plate text,
  vehicle_model text, rating_avg numeric, lat double precision,
  lng double precision, heading real
) language sql stable security definer set search_path = '' as $$
  select d.id, p.full_name, p.phone, p.avatar_url, d.vehicle_plate, d.vehicle_model,
         case when d.rating_count = 0 then 0
              else round(d.rating_sum::numeric / d.rating_count, 1) end,
         d.lat, d.lng, d.heading
    from public.orders o
    join public.drivers d on d.id = o.driver_id
    join public.profiles p on p.id = d.id
   where o.id = p_order_id and o.customer_id = auth.uid();
$$;

revoke execute on function public.driver_active_orders() from public, anon;
revoke execute on function public.nearby_orders(double precision, double precision) from public, anon;
revoke execute on function public.get_order_driver(uuid) from public, anon;
grant execute on function public.driver_active_orders() to authenticated;
grant execute on function public.nearby_orders(double precision, double precision) to authenticated;
grant execute on function public.get_order_driver(uuid) to authenticated;

-- ---------------------------------------------------------------- 2. avatars
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- Files live at avatars/<user id>/..., readable by anyone (public bucket),
-- writable only by their owner.
create policy "avatars: owner reads" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars: owner uploads" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars: owner updates" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars: owner deletes" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
