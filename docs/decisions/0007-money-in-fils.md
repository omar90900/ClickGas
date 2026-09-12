# 0007. Money stored with 3 decimals (fils)

- Status: Accepted
- Date: 2026-09-12

## Context

The Jordanian dinar has 1,000 fils. The first schema used `numeric(10,2)`,
which cannot hold 0.150 or 0.050 exactly as fils amounts and displays prices
the way no Jordanian receipt does.

## Decision

- Every money column is `numeric(12,3)` in JOD.
- Apps format money with three decimals (`7.000 د.أ`).
- Amounts are computed in the database; apps display, never calculate what is
  charged.

## Consequences

- Fees such as 0.050 are stored exactly.
- Dart `double` is used only for display; totals shown in the app are labelled
  as estimates until the server returns the order.
