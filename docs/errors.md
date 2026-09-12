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

## Distributor documents

| Code | Raised by | Meaning | What to check |
|---|---|---|---|
| `DOCUMENT_EXPIRED` | `submit_driver_document` | The expiry date given is in the past | Ask for a valid document |

## Staff (admin dashboard)

| Code | Raised by | Meaning | What to check |
|---|---|---|---|
| `REASON_REQUIRED` | reject, suspend, block, cancel, reassign, reject document, adjust balance | No reason, or under 3 characters | The reason goes to `admin_actions.reason` |
| `INVALID_AMOUNT` | `record_driver_payment`, `admin_adjust_balance`, `admin_set_fees`, services | Amount missing, zero, negative or out of range (payment ≤ 10 000, fee 0-5, price 0-1000) | Detail shows the value |
| `INVALID_SETTING` | `admin_update_config`, services, `admin_set_fees` | Unknown key, wrong type, out of range, duplicate service code, fee date in the past | Detail names the setting and its range |
| `INVALID_TARGET` | `admin_set_account_active`, `admin_save_staff` | Blocking a staff account, or making a distributor staff | Use the Staff page for staff |
| `LAST_OWNER` | `admin_save_staff`, `admin_remove_staff` | The change would leave no owner | Add another owner first |
| `NOT_FOUND` | staff functions | The distributor, user, order, service, city or flag doesn't exist | Refresh; it may have been deleted |
| `PERMISSION_DENIED` | every staff function | Not staff, or the role can't do this ([business-rules.md](business-rules.md#staff)) | `staff_members.role`, `profiles.is_active` |

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
