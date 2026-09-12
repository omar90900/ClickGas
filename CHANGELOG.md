# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/). Versions follow the
apps' `pubspec.yaml` version.

## [Unreleased] - Phase 0: Foundation

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
