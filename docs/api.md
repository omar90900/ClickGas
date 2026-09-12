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
`status` (approval) is set only by staff; unapproved distributors are kept offline by a trigger.

### `submit_driver_document(p_kind document_kind, p_file_path text, p_expires_on date = null) → driver_documents`
After uploading the photo to `driver-docs/<own id>/…`. Replaces the previous
file of that kind and puts it back to pending; a rejected distributor goes back
to pending review. Errors: `PERMISSION_DENIED` (not a distributor, or file
outside own folder), `DOCUMENT_EXPIRED`.

## Staff

Used by the admin dashboard (`apps/admin`). Every function checks the caller's
staff role and writes a row to `admin_actions` (who, what, target, reason,
before/after). Roles: **owner** passes every check; **operations** and
**support** as listed ([business-rules.md](business-rules.md#staff)). A caller
who isn't staff gets `PERMISSION_DENIED`. Reasons need 3+ characters
(`REASON_REQUIRED`).

### Reading

| Function | Roles | Returns |
|---|---|---|
| `admin_whoami()` | anyone | own `user_id, full_name, email, role`, or no row when not staff |
| `admin_overview()` | staff | jsonb: today (Asia/Amman) orders placed/delivered/cancelled/expired, fees, cash, median seconds to accept, waiting, waiting > 10 min, distributors online/approved/pending, documents to review, customers, fees outstanding, `last_14_days[]` |
| `admin_live_map()` | staff | jsonb `{orders: [...open orders with position], drivers: [...online or busy with position]}` |
| `admin_list_drivers(p_status = null, p_search = null, p_driver_id = null)` | staff | distributors with status, live state, open/delivered counts, `balance`, document counts; pending first |
| `admin_list_customers(p_search = null, p_limit = 50, p_offset = 0)` | staff | customers with order counts and `total_count` |
| `admin_search_orders(p_search, p_statuses text[], p_city_id, p_driver_id, p_customer_id, p_from, p_to, p_limit = 50, p_offset = 0)` | staff | orders with customer and distributor names/phones and `total_count`; search matches order number, names and phones |
| `admin_order_detail(p_order_id)` | staff | jsonb `{order, customer, driver, events[], releases[], ledger[], actions[]}`. Error: `NOT_FOUND` |
| `admin_balances()` | staff | per distributor: `fees, payments, adjustments, balance, deliveries, last_payment_at` |

Staff also read these tables directly (RLS): `profiles`, `drivers`, `orders`,
`order_events`, `order_releases`, `driver_ledger`, `driver_documents`,
`services` and `cities` (including hidden), `fee_settings`, `price_history`,
`staff_members`, `admin_actions`, `diagnostics`, `job_runs`, and files in
`driver-docs` (signed URLs).

### Distributors and accounts

| Function | Roles | Does | Errors |
|---|---|---|---|
| `admin_set_driver_status(p_driver_id, p_status, p_reason = null)` | owner, operations | approve / reject / suspend / reopen; reason required to reject or suspend | `REASON_REQUIRED`, `NOT_FOUND` |
| `admin_review_document(p_document_id bigint, p_approve boolean, p_note = null)` | owner, operations | approve or reject one document | `REASON_REQUIRED`, `NOT_FOUND` |
| `admin_set_account_active(p_user_id, p_active, p_reason = null)` | staff for customers; owner, operations for distributors | block (reason) or unblock; blocking takes a distributor offline | `REASON_REQUIRED`, `NOT_FOUND`, `INVALID_TARGET` (staff account) |

### Orders

| Function | Roles | Does | Errors |
|---|---|---|---|
| `admin_cancel_order(p_order_id, p_reason)` | owner, operations | cancels an open order | `REASON_REQUIRED`, `ORDER_NOT_CANCELLABLE` |
| `admin_assign_order(p_order_id, p_driver_id, p_reason)` | owner, operations | gives the order to an approved distributor (same slot and stock checks as `accept_order`, not online/distance), or `p_driver_id = null` puts it back in the queue | `REASON_REQUIRED`, `INVALID_TRANSITION`, `NOT_A_VERIFIED_DRIVER`, `MAX_ACTIVE_ORDERS`, `NOT_ENOUGH_CYLINDERS` |

### Money

| Function | Roles | Does | Errors |
|---|---|---|---|
| `record_driver_payment(p_driver_id, p_amount, p_note = null)` | owner, operations | cash received (negative ledger row) | `INVALID_AMOUNT`, `NOT_FOUND` |
| `admin_adjust_balance(p_driver_id, p_amount, p_reason)` | owner | + adds to what is owed, − waives | `REASON_REQUIRED`, `INVALID_AMOUNT`, `NOT_FOUND` |

### Settings (owner)

| Function | Does | Errors |
|---|---|---|
| `admin_update_service(p_service_id, p_price, p_is_active, p_name_ar, p_name_en, p_description_ar, p_description_en, p_badge, p_sort_order)` | null = unchanged, empty text clears; price changes go to `price_history` | `NOT_FOUND`, `INVALID_AMOUNT`, `INVALID_SETTING` |
| `admin_create_service(p_code, p_name_ar, p_name_en, p_price, p_icon, p_description_ar, p_description_en)` | adds an active service | `INVALID_SETTING`, `INVALID_AMOUNT` |
| `admin_set_fees(p_customer_fee, p_driver_fee, p_effective_from = now, p_note)` | new fee pair from now or a later date | `INVALID_AMOUNT`, `INVALID_SETTING` |
| `admin_update_config(p_changes jsonb)` | e.g. `{"driver_radius_km": 3}`; keys: `delivery_fee, max_quantity, search_radius_km, support_phone, driver_radius_km, max_active_orders, auto_verify_drivers, confirm_timeout_minutes, min_customer_version, min_distributor_version` | `INVALID_SETTING` |
| `admin_set_city_active(p_city_id, p_is_active)` | show or hide a city at sign-up | `NOT_FOUND` |
| `admin_set_flag(p_key, p_enabled)` | feature flag on/off | `NOT_FOUND` |
| `admin_save_staff(p_login, p_role)` | makes an existing account (email or +962 phone) staff, or changes its role | `NOT_FOUND`, `INVALID_TARGET` (distributor), `LAST_OWNER` |
| `admin_remove_staff(p_user_id)` | the account becomes a customer | `NOT_FOUND`, `LAST_OWNER` |

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
| `driver_documents` | the distributor (own), staff | written only by `submit_driver_document` / `admin_review_document` |
| storage `driver-docs/<driver id>/…` (private) | the distributor uploads and reads own; staff read all | no overwrite or delete |

## Helper functions (not for apps)

`is_staff`, `my_staff_role`, `private.require_staff`, `private.require_owner`,
`private.require_reason`, `private.audit`, `sync_driver_status` (trigger),
`log_price_change` (trigger), `is_active_customer`, `is_verified_driver`, `is_my_assigned_driver`,
`can_view_order` (used by RLS), `driver_committed_orders` (used by
`accept_order`), `distance_m` (haversine metres), `check_order_transition`
(trigger), `prepare_new_order` (trigger), `handle_new_user` (sign-up trigger),
`log_order_event` (trigger).
