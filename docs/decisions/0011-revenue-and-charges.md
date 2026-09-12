# 0011. Fees are platform revenue; charges replace the distributor ledger

- Status: Accepted (supersedes the ledger part of [0006](0006-per-order-fee-cash-ledger.md))
- Date: 2026-09-12

## Context

ClickGas is a service platform. Gas distribution agencies and their
distributors own and sell the cylinders; ClickGas owns no goods and does not
collect the sale price. Its only income is the service fee on each delivered
order (0.100 JOD from the customer, 0.050 JOD from the distributor, ADR 0006).

Phase 1 booked 0.150 JOD per delivery as a debt in `driver_ledger` and let
staff record cash paid back. The owner decided this "claim from the
distributor" is not needed. What staff do need is to raise a specific
charge against a distributor, such as a fine or a fee for a particular item,
with an explanation.

## Decision

- Each order keeps its fee snapshot (`service_fee`, `driver_fee`); delivered
  orders are the platform's revenue. `complete_order` no longer books
  anything else.
- `driver_ledger`, `driver_balance`, `record_driver_payment`,
  `admin_adjust_balance` and `admin_balances` are removed.
- `driver_charges`: kind (fine / item fee / other), title, amount,
  explanation (required, shown to the distributor), optional order, status
  open → paid | waived, who raised and settled it.
- Owner and operations raise charges and mark them paid. Only the owner waives
  one, with a reason. Everything is audited.
- `admin_finance(from, to)` reports revenue (customer fees, distributor
  fees, order value, per day, per agency, per distributor) and charges.

## Consequences

- The finance page shows what the platform earns, not what distributors owe.
- How fees are actually collected with cash-only payment (for example a
  monthly invoice to each agency) happens outside the app for now; the
  finance report per agency is the basis for it.
- Distributors see their charges and the reasons in the Sales tab.
- Past ledger rows (test data) are dropped with the table.
