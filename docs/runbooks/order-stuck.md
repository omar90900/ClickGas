# An order stays "waiting for a distributor"

Start with the order number the customer sees (for example 1042).

## 1. Look at the order

```sql
select id, status, created_at, delivery_lat, delivery_lng, quantity, city_id
  from orders where order_number = 1042;
```

If the status is not `pending`, the customer's app is out of date: ask them to
reopen it (Realtime reconnects).

## 2. Is any distributor able to see it?

Online, verified distributors and their distance from the order:

```sql
select p.full_name, d.cylinders_on_board, d.location_updated_at,
       round(distance_m(d.lat, d.lng, o.delivery_lat, o.delivery_lng)) as metres
  from orders o, drivers d join profiles p on p.id = d.id
 where o.order_number = 1042 and d.is_online and d.is_verified
 order by metres;
```

| What you see | Cause | Fix |
|---|---|---|
| No rows | Nobody online | Ask a distributor to go online |
| All `metres` > `driver_radius_km × 1000` (2000) | Nobody within range | Raise `app_config.driver_radius_km` temporarily |
| `location_updated_at` minutes old | The distributor's app stopped sending location | They reopen the app, or switch off and on |
| `cylinders_on_board` < quantity | Out of stock | They update the count after restocking |

## 3. Is the distributor at the limit?

```sql
select count(*) from orders where driver_id = '<driver id>' and status in ('accepted','on_the_way');
```

At `max_active_orders` (3), they can't accept until they deliver one.

## 4. History of the order

```sql
select status, actor_id, created_at from order_events
 where order_id = (select id from orders where order_number = 1042)
 order by created_at;
```

A `pending` after `accepted` means a distributor gave it back (see `order_releases`).
