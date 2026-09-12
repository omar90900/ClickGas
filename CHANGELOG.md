# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/). Versions follow the
apps' `pubspec.yaml` version.

## [Unreleased] - Profile, settings, new design and push notifications

### Added
- **Push notifications** that arrive when the app is closed
  ([ADR 0014](docs/decisions/0014-push-notifications.md)): the database writes
  a message for each event (order accepted / on the way / delivered /
  released / expired / cancelled, new order nearby, assigned, confirmed,
  account decisions, charges, document reviews) in Arabic and English; the
  Edge Function `send-push` delivers them through Firebase
  (`20260913150000_push_notifications.sql`,
  [setup runbook](docs/runbooks/push-notifications.md), `tools/push/setup.mjs`).
- Notification history in both apps (bell icon in Settings, unread badge).
- Notification preferences: order updates; distributors also new orders
  nearby. The language of pushes follows the app language.
- Change password in both apps.
- Profile header with photo, status, and stats (customer: orders, delivered,
  member since; distributor: deliveries, rating, cylinders on board).
- Call support from Settings (`app_config.support_phone`).

### Changed
- **New design system** ([ADR 0013](docs/decisions/0013-design-system.md),
  [design-system.md](docs/design-system.md)): brand green #2CE881, a soft
  black dark mode, flat cards, one set of Profile & Settings components shared
  by both phone apps; theme picker with previews; language picker sheet.
- The apps' own notifications show only while the app is on screen when the
  phone receives pushes, so nothing arrives twice.

## [Unreleased] - Coverage and demo readiness

### Fixed
- The customer app stayed on the launch image: its APK had been built without
  the `jni` native library (two builds at once), so plugin registration
  stopped and Supabase could not start. All apps now start through
  `runGuardedApp`, which shows a clear bilingual error screen instead of
  hanging (docs/runbooks/app-stuck-on-launch.md).
- CI uses the same Flutter version as development (3.47.3).
- A distributor whose phone stopped reporting stayed "online" forever and
  showed on the customer map. Customers now only see positions under 10
  minutes old, and the every-minute job switches off distributors silent for
  15 minutes (`20260913120000_auto_offline.sql`); the distributor app
  re-confirms "online" with each position.

### Added
- Widening search: a waiting order is offered 2 → 4 → 6 km away (every 5
  minutes); the dispatch radius is back to 2 km.
- Order expiry after 20 minutes (pg_cron, every minute, logged in
  `job_runs`); the customer is notified and can "Order again".
- Coverage check before ordering ("no distributor online near this spot" or
  "N distributors nearby") and recorded coverage gaps.
- Dashboard **Coverage** page: acceptance rate, expired orders, median time to
  accept per city, unserved-demand map, expiry job runs. Live map shows each
  waiting order's search circle. New settings for the search and expiry.
- Demo tooling: `tools/demo/seed.mjs` (1 owner, 5 distributors, 12
  customers, 15 past orders), `simulate.mjs` (trucks driving real roads,
  accepting and delivering), `reset.mjs`; "Hide demo data" in the dashboard;
  demo tags in lists.
- Release signing for both Android apps; runbooks for demo and release
  builds; a 10-minute presentation script in English and Arabic.

## Revenue model and session fix

### Fixed
- Apps stopped working after about an hour (expired login token while the
  distributor app tracked in the background or a dashboard tab was hidden).
  `SessionKeeper` renews the token even in the background, `guard()` retries
  once after renewing, and order streams reconnect after errors
  (docs/runbooks/session-expired.md).

### Changed
- ClickGas earns only the service fee per delivered order; delivery no longer
  creates a debt for the distributor (ADR 0011).
- Dashboard: **Balances** is replaced by **Finance**: income by day, agency and
  distributor, customer and distributor fees, order value, and charges.

### Added
- Charges: fines or fees for particular items raised against a distributor
  with an explanation, open → paid or waived; shown in the distributor's Sales
  tab, the distributor panel and the order inspector.

### Removed
- `driver_ledger`, `driver_balance`, `record_driver_payment`,
  `admin_adjust_balance`, `admin_balances`, and the "fees owed" card.

## Phase 1: Admin core

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
