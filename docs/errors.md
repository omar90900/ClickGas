# Error catalog

Every failure reaches the apps as an `AppFailure` with one of these codes
(`packages/clickgas_core/lib/src/errors.dart`). Database functions raise the
same strings; the detail (after `using detail =`) is logged, not shown.

When a user reports "code XYZ", find it here, then open
[runbooks/](runbooks/) or the user's diagnostics upload.

## Sign-in and accounts

| Code | Raised by | Meaning | What to check |
|---|---|---|---|
| `INVALID_CREDENTIALS` | `login_email_for_phone` (returns null), Supabase Auth | Wrong phone/email or password | The user may have signed up with another number |
| `TOO_MANY_ATTEMPTS` | `login_email_for_phone`, Supabase Auth | 5 wrong passwords for this phone in 15 minutes | Wait 15 minutes; `private.login_attempts` |
| `EMAIL_NOT_CONFIRMED` | Supabase Auth | Email confirmation is on and the link wasn't opened | Auth › Providers › Email › Confirm email |
| `EMAIL_TAKEN` | Supabase Auth | Email already has an account | Sign in instead |
| `PHONE_TAKEN` | sign-up check, unique index `profiles_phone_key` | Phone already has an account | Sign in instead |
| `WEAK_PASSWORD` | Supabase Auth | Password under the minimum length | 6+ characters |

## Orders (customer)

| Code | Raised by | Meaning | What to check |
|---|---|---|---|
| `SERVICE_UNAVAILABLE` | `prepare_new_order` | The chosen service is inactive or missing | `services.is_active` |
| `OPEN_ORDER_EXISTS` | unique index `orders_one_open_per_customer` | The customer already has a pending / accepted / on-the-way order | The open order in the Tracking tab |
| `ORDER_NOT_CANCELLABLE` | `cancel_order` | Only pending orders can be cancelled by the customer | Order status |
| `ORDER_NOT_RATEABLE` | `rate_order` | Not delivered, not theirs, or already rated | `orders.rating` |
| `INVALID_RATING` | `rate_order` | Rating outside 1-5 | App bug |
| `ORDER_NOT_CONFIRMABLE` | `confirm_delivery` | Not delivered or already confirmed | `orders.customer_confirmed_at` |

## Dispatch (distributor)

| Code | Raised by | Meaning | What to check |
|---|---|---|---|
| `NOT_A_VERIFIED_DRIVER` | `accept_order`, `nearby_orders` | Account not approved yet (or suspended) | `drivers.is_verified`, `profiles.is_active` |
| `DRIVER_OFFLINE` | `accept_order` | The online switch is off | `drivers.is_online` |
| `MAX_ACTIVE_ORDERS` | `accept_order` | Already holding `app_config.max_active_orders` (3) accepted/on-the-way orders | `driver_active_orders()` |
| `ORDER_NOT_AVAILABLE` | `accept_order` | Another distributor took it, or it was cancelled | `order_events` for the order |
| `NOT_ENOUGH_CYLINDERS` | `accept_order` | Stock on board doesn't cover open orders + this one | `drivers.cylinders_on_board` |
| `ORDER_TOO_FAR` | `accept_order` | More than 1.25 × `driver_radius_km` from the distributor's last position | `drivers.lat/lng`, location freshness |

## Any role

| Code | Raised by | Meaning | What to check |
|---|---|---|---|
| `INVALID_TRANSITION` | `check_order_transition` trigger, driver RPCs | A status change not listed in `order_transitions` (for example delivering a cancelled order) | Detail shows `order N: from -> to by actor` |
| `PERMISSION_DENIED` | Postgres `42501`, staff functions | Row Level Security or a column grant refused the change | The caller's role |
| `NETWORK` | the app | No connection or timeout | Phone connectivity |
| `UNKNOWN` | the app | Anything not mapped; shown as "code UNKNOWN" | The diagnostics upload has the full error |

## Adding a code

1. Raise it in SQL: `raise exception 'NEW_CODE' using detail = format(...)`.
2. Add it to `FailureCode` in `errors.dart`.
3. Map it in both apps' `failureText` with a string in `app_ar.arb` and `app_en.arb`.
4. Document it here.
