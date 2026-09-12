# Business rules

The rules ClickGas enforces, in plain language, with where each lives. Numbers
in `app_config` or `fee_settings` can be changed without releasing an app.

## Accounts

- Everyone signs up with full name, Jordanian mobile number, email, password
  and city. Phone format: `+9627[7|8|9]XXXXXXX` (entered as `07X XXX XXXX`).
- The customer app creates **customers**. The distributor app creates
  **distributors** (it sends `account_type = driver`), with vehicle plate,
  vehicle type and distribution agency. **Admin** accounts are never created
  from an app. *(trigger `handle_new_user`)*
- New distributors are **awaiting approval** (`drivers.status = pending`) and
  cannot go online or see orders until operations approves them in the admin
  dashboard, unless `app_config.auto_verify_drivers` is on. They upload their
  papers (national ID, driving licence, vehicle registration, agency letter)
  from Settings › Documents.
- Staff can **reject** (with a reason the distributor sees; new documents put
  them back in the queue) or **suspend** an approved distributor (they go
  offline at once and keep the orders they hold). `is_verified` always equals
  `status = approved`. *(trigger `sync_driver_status`)*
- Staff can **block** a customer or distributor with a reason: they can't sign
  in by phone, order, or take orders.
- A phone number belongs to one account. Login by phone allows 5 wrong passwords
  per 15 minutes. *(ADR 0005)*

## Orders

- A customer can have **one open order** at a time (pending, accepted or on the way).
- Price, delivery fee and service fee are set by the server when the order is
  placed and never change afterwards for that order.
- `total_price = unit_price × quantity + delivery_fee + service_fee`.
- Quantity 1-10 per order; the app offers up to `app_config.max_quantity` (5).

### Statuses

| From | To | Who | How |
|---|---|---|---|
| pending | accepted | verified, online distributor | `accept_order` |
| pending | cancelled | customer, staff | `cancel_order`, `admin_cancel_order` |
| pending | accepted | staff | `admin_assign_order` |
| pending | expired | system | `expire_stale_orders` (every minute, after 20 min) |
| accepted | on the way | assigned distributor | `start_delivery` |
| accepted / on the way | pending | assigned distributor | `release_order` (logged as cancelled in their sales) |
| accepted / on the way | pending | staff | `admin_assign_order` (back to queue) |
| on the way | accepted | staff | `admin_assign_order` (to another distributor) |
| accepted / on the way | delivered | assigned distributor | `complete_order` |
| accepted / on the way | cancelled | staff | `admin_cancel_order` |

Anything else is rejected with `INVALID_TRANSITION`. *(table `order_transitions`)*

- After "delivered", the customer is asked to **confirm receipt** and to rate.
  Confirmation does not block the distributor.

## Dispatch

- A new order is offered to distributors within **`driver_radius_km` = 2 km**
  of it. While nobody accepts, the search **widens** by `radius_step_km`
  (2 km) every `radius_step_minutes` (5), up to **`max_radius_km` = 6 km**:
  2 → 4 → 6 km. *(function `order_radius_km`, ADR 0012)*
- An order nobody accepts within **`order_expiry_minutes` = 20** becomes
  **expired** (checked every minute). The customer is notified and offered
  "Order again".
- A distributor whose app hasn't sent a position for **15 minutes** is
  switched offline by the same every-minute job (phone off, no signal, app
  killed). The app switches them back on with its next position. Customers
  only see distributors whose position is under 10 minutes old.
- A distributor sees pending orders offered to their position, nearest
  first, with the customer's name and notes.
- They can hold **`max_active_orders` = 3** accepted or on-the-way orders. A slot
  frees the moment they mark an order delivered.
- They can accept only while **online**, only if **cylinders on board** cover
  the open orders plus the new one, and only within 1.25 × the order's
  current search radius of their last reported position.

## Coverage

- Some distributors in an area use ClickGas and others don't, so before
  ordering the customer app checks whether any approved distributor is
  online (position under 10 minutes old) within the widest radius. If none
  is, the customer is told so and can still order.
- Each such "no distributor nearby" check is recorded as a coverage gap (at
  most one per customer per 10 minutes). Gaps and expired orders form the
  unserved-demand map on the dashboard's Coverage page.

## Demo data

- Accounts created by `tools/demo` are flagged `is_demo`, and so are their
  orders. Staff can hide demo data in the dashboard (account menu). The demo
  reset removes exactly the demo data. *(ADR 0012, runbooks/demo.md)*
- Two distributors can't take the same order: the order row is locked while
  one accepts it.
- Delivering lowers **cylinders on board** by the order quantity.
- A distributor may give an order back (release); it returns to pending for
  others and is recorded in `order_releases`.

## Fees (platform revenue)

- ClickGas is a service platform: agencies and their distributors own the
  cylinders. The platform's only income is the **service fee per delivered
  order**, not per cylinder: **0.100** from the customer (shown as "Service
  fee") and **0.050** from the distributor. *(ADR 0006, 0011)*
- Each order keeps the fees in force when it was placed; the finance report
  counts them when the order is delivered. Cancelled, expired and released
  orders earn nothing.
- The customer pays in cash to the distributor. Collecting the fees from
  distributors or agencies happens outside the app for now; the finance
  report per agency is the basis.
- Money has 3 decimals (fils). *(ADR 0007)*

## Charges

- Staff can raise a **charge** against a distributor: a fine, a fee for a
  particular item, or other, with a title, an amount and an **explanation the
  distributor sees** in the Sales tab. It may point to one of their orders.
- A charge is **open** until it is **paid** (owner or operations) or
  **waived** (owner only, with a reason). A settled charge can't change.
- Every charge and settlement is in the audit log. *(ADR 0011)*

## Ratings

- The customer can rate a delivered order once, 1-5 stars with a comment.
- The distributor's rating is the average of all ratings (a fairer score is
  planned in Phase 4).

## Location and privacy

- Customers see online, verified distributors on the map, and the assigned
  distributor's name, phone, photo and position during their order.
- Distributors see a customer's name for nearby orders, and their phone only
  after accepting.
- Nobody sees another customer's phone or orders.
- An online distributor's position is saved every 5 seconds while online.

## Staff

Staff use the admin dashboard (`apps/admin`) with email and password. An
account is staff when `profiles.role = admin`, it is active, and it has a row
in `staff_members`. Every staff change is a database function that checks the
role and writes `admin_actions`. *(ADR 0010)*

| Can… | Owner | Operations | Support |
|---|:-:|:-:|:-:|
| See the overview, live map, orders, distributors, customers, finance, audit log | ✓ | ✓ | ✓ |
| Block / unblock customers | ✓ | ✓ | ✓ |
| Approve, reject, suspend distributors; review documents; block distributors | ✓ | ✓ | |
| Cancel or reassign orders | ✓ | ✓ | |
| Raise charges and mark them paid | ✓ | ✓ | |
| Waive a charge | ✓ | | |
| Prices, fees, settings, cities, feature flags | ✓ | | |
| Add, change or remove staff | ✓ | | |

- Blocking, rejecting, suspending, cancelling, reassigning, rejecting a
  document, raising and waiving a charge **need a reason** (saved in the
  audit log).
- There is always at least one owner.
- Staff can reassign an order only to an approved, active distributor with a
  free slot and enough cylinders; online status and distance are not checked
  (staff may have phoned them).
- Fee changes take effect now or at a chosen future time; they can't be
  backdated. Price changes are kept in `price_history`.

## Notifications

- Customer: accepted, on the way, delivered, dropped by the distributor.
- Distributor: new order near you, customer confirmed receipt.
- Shown while the app is running; push when closed arrives in Phase 2.
