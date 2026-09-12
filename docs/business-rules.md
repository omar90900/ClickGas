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
- New distributors are **unverified** and cannot go online or see orders until
  staff sets `drivers.is_verified = true`, unless
  `app_config.auto_verify_drivers` is on.
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
| pending | cancelled | customer, staff | `cancel_order`, admin |
| pending | expired | system | expiry job (Phase 3) |
| accepted | on the way | assigned distributor | `start_delivery` |
| accepted / on the way | pending | assigned distributor | `release_order` (logged as cancelled in their sales) |
| accepted / on the way | delivered | assigned distributor | `complete_order` |
| accepted / on the way | cancelled | staff | admin |

Anything else is rejected with `INVALID_TRANSITION`. *(table `order_transitions`)*

- After "delivered", the customer is asked to **confirm receipt** and to rate.
  Confirmation does not block the distributor.

## Dispatch

- A distributor sees pending orders within **`driver_radius_km` = 2 km** of
  their position, nearest first, with the customer's name and notes.
- They can hold **`max_active_orders` = 3** accepted or on-the-way orders. A slot
  frees the moment they mark an order delivered.
- They can accept only while **online**, only if **cylinders on board** cover
  the open orders plus the new one, and only within 1.25 × the radius of their
  last reported position.
- Two distributors can't take the same order: the order row is locked while
  one accepts it.
- Delivering lowers **cylinders on board** by the order quantity.
- A distributor may give an order back (release); it returns to pending for
  others and is recorded in `order_releases`.

## Fees

- **0.150 JOD per delivered order**, not per cylinder: the customer pays
  **0.100** (shown as "Service fee"), the distributor **0.050**. *(ADR 0006)*
- The customer pays everything in cash to the distributor, who therefore owes
  the platform **0.150** per delivery. This is booked in `driver_ledger` when
  the order is marked delivered.
- Cancelled, expired and released orders are never charged.
- Staff record payments from distributors (`record_driver_payment`); the
  distributor sees the balance in the Sales tab.
- Money has 3 decimals (fils). *(ADR 0007)*

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

## Notifications

- Customer: accepted, on the way, delivered, dropped by the distributor.
- Distributor: new order near you, customer confirmed receipt.
- Shown while the app is running; push when closed arrives in Phase 2.
