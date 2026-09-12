# 0006. 0.150 JOD fee per delivered order, cash with a ledger

- Status: Fee amounts accepted; the ledger is superseded by [0011](0011-revenue-and-charges.md)
- Date: 2026-09-12

## Context

The owner decided the platform earns a fee per **delivered order**, not per
cylinder: 15 piasters (0.150 JOD), of which the customer pays 10 (0.100) and
the distributor 5 (0.050). Electronic payment is postponed, so all money is
cash handed to the distributor.

## Decision

- `fee_settings` holds the fee pair with an `effective_from` date; the view
  `current_fees` returns the pair in force.
- `prepare_new_order()` copies both fees onto the order (`service_fee`,
  `driver_fee`) and adds the customer fee to `total_price`.
- `complete_order()` books `service_fee + driver_fee` as an `order_fee` row in
  `driver_ledger` (one per order, enforced by a unique index).
- Staff record money received with `record_driver_payment()` (a negative row).
- `driver_balance()` = what the distributor owes now.
- Cancelled, expired and released orders are never charged.

## Consequences

- A fee change never rewrites history: each order keeps its own copy.
- The distributor app can show exactly what is owed and why.
- When card payment arrives, the platform will collect the customer fee
  directly; the ledger then records it as already settled instead of owed.
