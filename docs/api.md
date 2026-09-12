# API reference

What the apps call on Supabase. Tables are reached through PostgREST with Row
Level Security; rules that need logic are RPC functions (`supabase.rpc(name,
params)`). Every function is also described in the database itself
(`comment on function`), visible in the Supabase dashboard.

Errors are listed by code; see [errors.md](errors.md).

## Public (no sign-in)

### `is_phone_registered(p_phone text) → boolean`
Sign-up check. Accepted trade-off: reveals whether a number has an account ([ADR 0005](decisions/0005-phone-login.md)).

### `login_email_for_phone(p_phone text, p_password text) → text | null`
Phone login step 1. Returns the account email when the password matches,
otherwise `null`. Errors: `TOO_MANY_ATTEMPTS`.
```dart
final email = await supabase.rpc('login_email_for_phone',
    params: {'p_phone': '+962791234567', 'p_password': password});
```

## Customer

### Place an order: `insert into orders`
Send `customer_id` (own id), `service_id`, `quantity`, `payment_method`,
`delivery_lat`, `delivery_lng`, optional `delivery_address`, `notes`.
Price, fees, status and timestamps are set by the server.
Errors: `SERVICE_UNAVAILABLE`, `OPEN_ORDER_EXISTS`.

### `cancel_order(p_order_id uuid, p_reason text = null) → orders`
Pending orders only. Errors: `ORDER_NOT_CANCELLABLE`.

### `confirm_delivery(p_order_id uuid) → orders`
After the distributor marks it delivered. Errors: `ORDER_NOT_CONFIRMABLE`.

### `rate_order(p_order_id uuid, p_rating smallint, p_comment text = null) → orders`
Once per delivered order. Errors: `INVALID_RATING`, `ORDER_NOT_RATEABLE`.

### `get_order_driver(p_order_id uuid) → table`
`id, full_name, phone, avatar_url, vehicle_plate, vehicle_model, rating_avg, lat, lng, heading`
for the caller's own order.

## Distributor

### `nearby_orders(p_lat float8, p_lng float8) → table`
Pending orders within `driver_radius_km`, nearest first:
`id, order_number, customer_name, customer_avatar, service_name_ar, service_name_en, quantity, total_price, payment_method, delivery_lat, delivery_lng, delivery_address, notes, created_at, distance_m`.
Errors: `NOT_A_VERIFIED_DRIVER`.

### `driver_active_orders() → table`
The caller's accepted and on-the-way orders with `customer_name`, `customer_phone`, `customer_avatar` and delivery details.

### `accept_order(p_order_id uuid) → orders`
Errors: `NOT_A_VERIFIED_DRIVER`, `DRIVER_OFFLINE`, `MAX_ACTIVE_ORDERS`,
`ORDER_NOT_AVAILABLE`, `NOT_ENOUGH_CYLINDERS`, `ORDER_TOO_FAR`.

### `start_delivery(p_order_id uuid) → orders`
accepted → on the way. Errors: `INVALID_TRANSITION`.

### `complete_order(p_order_id uuid) → orders`
→ delivered; lowers stock; books 0.150 in `driver_ledger`. Errors: `INVALID_TRANSITION`.

### `release_order(p_order_id uuid, p_reason text = null) → orders`
Gives the order back to pending; logged in `order_releases`. Errors: `INVALID_TRANSITION`.

### `driver_balance() → numeric`
What the caller owes the platform (JOD).

### Own row: `update drivers`
Allowed columns: `is_online, lat, lng, heading, location_updated_at, vehicle_plate, vehicle_model, wallet_number, cylinders_on_board, agency_name`.

## Staff

### `record_driver_payment(p_driver_id uuid, p_amount numeric, p_note text = null) → driver_ledger`
Records money received from a distributor. Errors: `PERMISSION_DENIED`, `INVALID_AMOUNT`.

## Tables the apps read directly

| Table / view | Who | Notes |
|---|---|---|
| `profiles` | owner (select, update name/phone/city/avatar) | staff read all |
| `drivers` | everyone signed in: online + verified rows; customer: assigned driver; owner: own row | |
| `orders` | customer: own; distributor: assigned | Realtime |
| `order_events` | parties of the order | audit trail |
| `order_releases` | the distributor who released | |
| `driver_ledger` | the distributor (own), staff | |
| `cities`, `services`, `app_config`, `current_fees`, `feature_flags` | everyone, even before sign-in | |
| `diagnostics` | insert own, read own; staff read all | |
| storage `avatars/<user id>/…` | public read, owner write | |

## Helper functions (not for apps)

`is_staff`, `is_active_customer`, `is_verified_driver`, `is_my_assigned_driver`,
`can_view_order` (used by RLS), `driver_committed_orders` (used by
`accept_order`), `distance_m` (haversine metres), `check_order_transition`
(trigger), `prepare_new_order` (trigger), `handle_new_user` (sign-up trigger),
`log_order_event` (trigger).
