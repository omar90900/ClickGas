# 0002. Business rules are enforced in the database

- Status: Accepted
- Date: 2026-09-11

## Context

Two apps (and soon an admin dashboard) change the same orders. If prices,
limits or status rules lived in app code, each app would need the same logic,
and anyone with the publishable key could bypass it with a direct API call.

## Decision

- Prices and fees are set by the `prepare_new_order()` trigger; anything the app
  sends for them is overwritten.
- Status changes happen only through RPC functions (`accept_order`,
  `complete_order`, …); direct `update` on `orders` is revoked.
- Every status change is checked against the `order_transitions` table by the
  `check_order_transition()` trigger, including changes made by staff.
- Visibility is Row Level Security; helper checks are `security definer`
  functions so policies never recurse.
- Functions raise stable error codes (`raise exception 'ORDER_TOO_FAR' using
  detail = ...`) that the apps translate.

## Consequences

- Apps stay thin and can't break rules; the admin dashboard inherits them.
- Business logic changes need a migration and a pgTAP test.
- Error codes are a contract: renaming one means updating `FailureCode`, both
  apps and [errors.md](../errors.md).
