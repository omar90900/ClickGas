# 0015. Wallet payments go straight to the distributor

- Status: Accepted
- Date: 2026-09-13

## Context

Customers asked to pay from their e-wallets (Orange Money, Zain Cash,
Umniah) instead of cash. An integrated payment, where the app starts the
transfer and learns that it succeeded, needs a registered business, a
merchant account with each wallet or a payment gateway, and a contract. None
of these exist for the proof of concept, and personal wallet accounts offer
no API. ClickGas also does not want to hold customers' money (it earns only
the service fee, ADR 0011).

## Decision

- A customer can choose **Wallet** instead of cash when ordering. They pay
  the distributor directly, **when the distributor arrives**.
- Each distributor saves their wallets (Orange Money, Zain Cash, Umniah,
  CliQ alias) in the distributor app. Saving requires accepting that
  **ClickGas is not responsible for mistakes in wallet details**, and sends a
  notification that says so (`terms_accepted_at`, kind `wallet_saved`).
- Only a distributor with an active wallet can take a wallet order
  (`NO_WALLET_ACCOUNT`). When they take it, their accounts are copied into
  `order_payments.payees`, so later edits don't change what the customer saw.
- The customer app shows the invoice, the distributor's details with copy
  buttons and a button that opens the wallet app (`wallet_providers.android_package`,
  falling back to the store link). CliQ is paid from any bank or wallet app.
- The customer taps **I've paid** (optionally with the transaction number).
  The distributor checks their wallet and taps **Received**, **Not received**
  (with a note) or **Paid in cash**. The order cannot be marked delivered
  until the payment is confirmed or cash (`PAYMENT_NOT_CONFIRMED`).
- Staff see every wallet payment, settle disputes with a reason (audited),
  pause a distributor's wallet, and (owner) set how each wallet app opens.

## Consequences

- No money passes through ClickGas and no payment licence is needed.
- Confirmation is manual: the distributor is the only check that money
  arrived. Refunds after a cancellation are made by the distributor.
- Wallet app package names are data, not code: once a wallet's Android
  package is known, the owner sets it in the dashboard and every customer
  app opens it without a release.
- Personal wallets may have monthly limits or terms against regular business
  income; distributors should check with their wallet before relying on it.
- Moving to an integrated gateway later replaces the claim/confirm steps with
  a gateway callback; `order_payments` keeps the same role.
