-- =============================================================================
-- ClickGas - customer/distributor stats, order-card fields, plainer notifications
-- (run once, after 20260913150000_push_notifications.sql)
--
--   1. my_order_stats: what the customer got and paid this month, this year
--      and since they joined. Delivery fees are excluded from the money:
--      the customer asked for what the gas itself cost them.
--   2. driver_earnings_stats: the distributor's deliveries and takings for the
--      month and the year, for the profile header.
--   3. nearby_orders / driver_active_orders also return service_code, so the
--      distributor app can show an exchange or new-cylinder icon instead of
--      the customer's photo.
--   4. order_notifications: messages no longer quote the order number, which
--      means nothing to the reader. The order id stays in the payload so
--      tapping the notification still opens the order.
-- =============================================================================

-- ------------------------------------------------- 1. customer order stats
create or replace function public.my_order_stats()
returns table (
  month_cylinders integer,
  month_paid numeric,
  year_cylinders integer,
  year_paid numeric,
  total_orders integer,
  total_cylinders integer,
  total_paid numeric
) language sql stable security definer set search_path = '' as $$
  with mine as (
    select o.quantity, o.total_price - o.delivery_fee as paid, o.delivered_at
      from public.orders o
     where o.customer_id = auth.uid()
       and o.status = 'delivered'
       and o.delivered_at is not null
  ), bounds as (
    select date_trunc('month', now()) as month_start,
           date_trunc('year', now()) as year_start
  )
  select
    coalesce(sum(m.quantity) filter (where m.delivered_at >= b.month_start), 0)::integer,
    coalesce(sum(m.paid) filter (where m.delivered_at >= b.month_start), 0)::numeric,
    coalesce(sum(m.quantity) filter (where m.delivered_at >= b.year_start), 0)::integer,
    coalesce(sum(m.paid) filter (where m.delivered_at >= b.year_start), 0)::numeric,
    count(m.delivered_at)::integer,
    coalesce(sum(m.quantity), 0)::integer,
    coalesce(sum(m.paid), 0)::numeric
    from bounds b left join mine m on true
   group by b.month_start, b.year_start;
$$;
comment on function public.my_order_stats() is
  'Delivered-order totals for the signed-in customer: cylinders and money paid (delivery fee excluded) this month, this year and in total.';
revoke execute on function public.my_order_stats() from public, anon;
grant execute on function public.my_order_stats() to authenticated;

-- ------------------------------------------------- 2. distributor earnings
create or replace function public.driver_earnings_stats()
returns table (
  month_deliveries integer,
  month_cylinders integer,
  month_earned numeric,
  year_deliveries integer,
  year_cylinders integer,
  year_earned numeric
) language sql stable security definer set search_path = '' as $$
  with mine as (
    select o.quantity, o.total_price as earned, o.delivered_at
      from public.orders o
     where o.driver_id = auth.uid()
       and o.status = 'delivered'
       and o.delivered_at is not null
  ), bounds as (
    select date_trunc('month', now()) as month_start,
           date_trunc('year', now()) as year_start
  )
  select
    count(m.delivered_at) filter (where m.delivered_at >= b.month_start)::integer,
    coalesce(sum(m.quantity) filter (where m.delivered_at >= b.month_start), 0)::integer,
    coalesce(sum(m.earned) filter (where m.delivered_at >= b.month_start), 0)::numeric,
    count(m.delivered_at) filter (where m.delivered_at >= b.year_start)::integer,
    coalesce(sum(m.quantity) filter (where m.delivered_at >= b.year_start), 0)::integer,
    coalesce(sum(m.earned) filter (where m.delivered_at >= b.year_start), 0)::numeric
    from bounds b left join mine m on true
   group by b.month_start, b.year_start;
$$;
comment on function public.driver_earnings_stats() is
  'Delivered-order totals for the signed-in distributor: deliveries, cylinders and takings this month and this year.';
revoke execute on function public.driver_earnings_stats() from public, anon;
grant execute on function public.driver_earnings_stats() to authenticated;

-- ------------------------------------------------- 3. service_code on the order cards
drop function if exists public.driver_active_orders();
create function public.driver_active_orders()
returns table (
  id uuid, order_number bigint, status public.order_status,
  customer_name text, customer_phone text, customer_avatar text,
  service_code text, service_name_ar text, service_name_en text, quantity smallint,
  total_price numeric, payment_method public.payment_method,
  delivery_lat double precision, delivery_lng double precision,
  delivery_address text, notes text, created_at timestamptz,
  accepted_at timestamptz, delivered_at timestamptz, customer_confirmed_at timestamptz
) language sql stable security definer set search_path = '' as $$
  select o.id, o.order_number, o.status, p.full_name, p.phone, p.avatar_url,
         o.service_code, o.service_name_ar, o.service_name_en, o.quantity, o.total_price,
         o.payment_method, o.delivery_lat, o.delivery_lng, o.delivery_address,
         o.notes, o.created_at, o.accepted_at, o.delivered_at, o.customer_confirmed_at
    from public.orders o
    join public.profiles p on p.id = o.customer_id
   where o.driver_id = auth.uid()
     and o.status in ('accepted', 'on_the_way')
   order by o.accepted_at;
$$;
comment on function public.driver_active_orders() is
  'The calling distributor''s accepted and on-the-way orders with customer contact.';
revoke execute on function public.driver_active_orders() from public, anon;
grant execute on function public.driver_active_orders() to authenticated;

drop function if exists public.nearby_orders(double precision, double precision);
create function public.nearby_orders(p_lat double precision, p_lng double precision)
returns table (
  id uuid, order_number bigint, customer_name text, customer_avatar text,
  service_code text, service_name_ar text, service_name_en text, quantity smallint,
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
    select o.id, o.order_number, p.full_name, p.avatar_url, o.service_code,
           o.service_name_ar, o.service_name_en, o.quantity, o.total_price,
           o.payment_method, o.delivery_lat, o.delivery_lng, o.delivery_address,
           o.notes, o.created_at, x.dist
      from public.orders o
      join public.profiles p on p.id = o.customer_id
      cross join lateral (
        select public.distance_m(p_lat, p_lng, o.delivery_lat, o.delivery_lng) as dist
      ) x
     where o.status = 'pending'
       and x.dist <= public.order_radius_km(o.created_at) * 1000
     order by x.dist
     limit 50;
end $$;
comment on function public.nearby_orders(double precision, double precision) is
  'Pending orders within their current search radius (order_radius_km) of the given point, nearest first. Error: NOT_A_VERIFIED_DRIVER.';
revoke execute on function public.nearby_orders(double precision, double precision) from public, anon;
grant execute on function public.nearby_orders(double precision, double precision) to authenticated;

-- ------------------------------------------------- 4. notifications without order numbers
create or replace function private.order_notifications()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_data jsonb := jsonb_build_object('order_id', new.id, 'order_number', new.order_number);
  v_driver text;
begin
  if private.seeding() then
    return new;
  end if;
  begin
    if tg_op = 'INSERT' then
      perform private.notify_nearby_drivers(new, null);
      return new;
    end if;

    if new.status is distinct from old.status then
      case new.status
        when 'accepted' then
          select full_name into v_driver from public.profiles where id = new.driver_id;
          perform private.notify(new.customer_id, 'customer', 'order_accepted',
            'تم قبول طلبك', format('قبل %s طلبك وسيتوجه إليك.', v_driver),
            'Your order was accepted', format('%s accepted your order and will head to you.', v_driver),
            v_data);
        when 'on_the_way' then
          perform private.notify(new.customer_id, 'customer', 'order_on_the_way',
            'الموزع في الطريق', 'الموزع في طريقه إليك.',
            'Distributor on the way', 'The distributor is on their way.',
            v_data);
        when 'delivered' then
          perform private.notify(new.customer_id, 'customer', 'order_delivered',
            'تم توصيل طلبك', 'يرجى تأكيد الاستلام وتقييم الخدمة.',
            'Your order was delivered', 'Please confirm you received it and rate the service.',
            v_data);
        when 'pending' then
          -- Back in the queue: the distributor released it or staff took it back.
          perform private.notify(new.customer_id, 'customer', 'order_released',
            'نبحث عن موزع آخر', 'اعتذر الموزع عن طلبك، ونبحث لك عن موزع آخر.',
            'Finding another distributor', 'The distributor dropped your order; we are finding you another one.',
            v_data);
          perform private.notify_nearby_drivers(new, old.driver_id);
        when 'expired' then
          perform private.notify(new.customer_id, 'customer', 'order_expired',
            'لا يوجد موزّع متاح', 'لم يقبل أحد طلبك. يمكنك إعادة الطلب في أي وقت.',
            'No distributor available', 'Nobody accepted your order. You can order again any time.',
            v_data);
        when 'cancelled' then
          if v_actor is distinct from new.customer_id then
            perform private.notify(new.customer_id, 'customer', 'order_cancelled',
              'تم إلغاء طلبك', coalesce(new.cancel_reason, ''),
              'Your order was cancelled', coalesce(new.cancel_reason, ''),
              v_data);
          end if;
          if old.driver_id is not null and v_actor is distinct from old.driver_id then
            perform private.notify(old.driver_id, 'distributor', 'order_cancelled',
              'أُلغي الطلب', 'لم يعد عليك توصيل هذا الطلب.',
              'The order was cancelled', 'You no longer need to deliver it.',
              v_data);
          end if;
        else
          null;
      end case;
    end if;

    -- Staff gave the order to a distributor, or moved it to another one.
    if new.driver_id is not null and new.driver_id is distinct from old.driver_id
       and v_actor is distinct from new.driver_id then
      perform private.notify(new.driver_id, 'distributor', 'order_assigned',
        'تم إسناد طلب إليك', format('%s × %s', new.service_name_ar, new.quantity),
        'An order was assigned to you', format('%s × %s', new.service_name_en, new.quantity),
        v_data);
    end if;
    if old.driver_id is not null and new.driver_id is distinct from old.driver_id
       and new.status in ('pending', 'accepted', 'on_the_way')
       and v_actor is distinct from old.driver_id then
      perform private.notify(old.driver_id, 'distributor', 'order_unassigned',
        'لم يعد الطلب لديك', 'أعادت الإدارة إسناد هذا الطلب.',
        'The order is no longer yours', 'Operations reassigned this order.',
        v_data);
    end if;

    if new.customer_confirmed_at is not null and old.customer_confirmed_at is null
       and new.driver_id is not null then
      perform private.notify(new.driver_id, 'distributor', 'order_confirmed',
        'العميل أكد الاستلام', 'تم تأكيد استلام الطلب.',
        'Customer confirmed receipt', 'The order was confirmed as received.',
        v_data);
    end if;
  exception when others then
    -- A notification must never stop an order from moving.
    raise warning 'order notification failed for %: %', new.id, sqlerrm;
  end;
  return new;
end $$;
