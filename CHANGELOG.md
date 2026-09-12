# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/). Versions follow the
apps' `pubspec.yaml` version.

## [Unreleased] - Phase 1: Admin core

### Added
- Admin dashboard (`apps/admin`, Flutter web, Arabic/English): overview with
  today's numbers and a 14-day chart, live map of open orders and
  distributors (OpenStreetMap), order search and inspector, distributor
  approvals with documents, customers with block/unblock, balances with cash
  payments, prices, fees, dispatch settings, cities, feature flags, staff and
  an audit log.
- Staff roles (owner, operations, support) enforced in the database; every
  staff action is written to `admin_actions` (ADR 0010).
- Distributor approval status (pending, approved, rejected, suspended) with a
  reason shown in the distributor app.
- Distributor documents: Settings › Documents in the distributor app, private
  `driver-docs` bucket, review in the dashboard.
- Staff can cancel an order with a reason, reassign it, or put it back in the
  queue.
- `price_history`, `admin_adjust_balance`, `tools/admin/create-staff.mjs`,
  database tests for staff (`03_admin.test.sql`), admin tests and web build
  in CI.
- Docs: ADR 0009 and 0010, staff API, staff rules, runbook for staff
  accounts and approvals.

### Changed
- `record_driver_payment` is limited to owner and operations and audited.
- Feature flags are changed through `admin_set_flag` instead of a direct
  update.

## Phase 0: Foundation

### Added
- Monorepo with a Dart pub workspace: `apps/customer`, `apps/distributor`,
  `packages/clickgas_core`, `supabase/`, `docs/`, `tools/`.
- Service fee per delivered order: customer 0.100 JOD (shown at checkout and on
  receipts), distributor 0.050 JOD. Fees are booked in `driver_ledger`; the
  distributor's Sales tab shows what is owed.
- Order state machine (`order_transitions` + trigger); new `expired` status.
- Error catalog: every failure is an `AppFailure` with a stable code, shown in
  the user's language (docs/errors.md).
- Structured logging and **Settings › Send diagnostics** in both apps.
- `diagnostics`, `job_runs` and `feature_flags` tables; minimum app versions.
- Documentation: architecture, 8 decision records, API, data model, business
  rules, errors, environments, runbooks, glossary, contributing guide.
- CI (analyze, test, database tests), environment files, VS Code run configs,
  end-to-end order test, SQL syntax check.

### Changed
- Money is stored and shown with 3 decimals (fils).
- Phone login checks the password in the database and limits failed attempts
  to 5 per 15 minutes.

### Removed
- `email_for_phone`, which revealed the email of any registered phone.

### Security
- Secrets moved to a git-ignored `.secrets/` folder; rotation steps in
  docs/runbooks/secrets.md.

## [0.3.0] - 2026-09-11
- Distributor slot frees on "Delivered"; profile photos; notifications with
  sound; distributor app icon.

## [0.2.0] - 2026-09-11
- Distributor app: sign-up with vehicle and agency, online switch, live
  location, nearby orders within 2 km, up to 3 orders, sales log.
- Customer app: receipt confirmation; white welcome screen.

## [0.1.0] - 2026-09-11
- Customer app on Supabase: sign-up and login by phone or email, live map,
  ordering, tracking, history, ratings, settings; Arabic and English.
