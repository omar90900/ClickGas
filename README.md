# ClickGas · كليك غاز

Gas-cylinder delivery for Jordan. A customer orders a 12.5 kg LPG cylinder, the
nearest distributor accepts it, and the customer follows the truck live until
it arrives. Built with Flutter on Supabase.

> **Status:** proof of concept for presentations (not published to the stores).
> Electronic payments, SMS verification and store release are postponed.
> The plan and architecture are in the
> [ClickGas Roadmap](https://claude.ai/code/artifact/c106a4d5-10a9-4712-9702-0d9112b0c80c).

## What's in this repository

```
apps/customer/          customer app (Flutter, Android first)
apps/distributor/       distributor app (Flutter, Android first)
apps/admin/             staff dashboard (Flutter web)
packages/clickgas_core/ shared models, repositories, errors, logging, theme
supabase/migrations/    database schema, in the order it was applied
supabase/tests/         database tests (pgTAP)
docs/                   architecture, rules, API, runbooks, decisions
tools/                  end-to-end test, SQL syntax check
env/                    per-environment app settings (no secrets)
```

## Run it locally

**You need:** Flutter 3.47+ (Dart 3.13), JDK 17, the Android SDK, Node.js 20+
(for the tools only), and an Android phone or emulator.

1. Get the dependencies for every app at once, from the repository root:
   ```sh
   flutter pub get
   ```
2. Add the Google Maps key to each app (this file is never committed):
   ```sh
   # apps/customer/android/local.properties and apps/distributor/android/local.properties
   MAPS_API_KEY=AIza...
   ```
3. Run an app against the development project:
   ```sh
   cd apps/customer
   flutter run --dart-define-from-file=../../env/dev.json
   ```
   In VS Code, pick **Customer (dev)**, **Distributor (dev)** or **Admin (dev)**
   in Run and Debug. The admin dashboard runs in Chrome:
   `cd apps/admin && flutter run -d chrome --dart-define-from-file=../../env/dev.json`.
   Its first owner account is created with `node tools/admin/create-staff.mjs`
   ([docs/runbooks/staff-accounts.md](docs/runbooks/staff-accounts.md)).

The database already exists in Supabase. To set up a new project, run the files
in `supabase/migrations/` in order; see [docs/runbooks/migrations.md](docs/runbooks/migrations.md).

## Everyday commands

| What | Command (from the repository root) |
|---|---|
| Analyze everything | `flutter analyze apps packages` |
| Unit tests | `cd packages/clickgas_core && flutter test` (same in each app) |
| Regenerate translations | `cd apps/customer && flutter gen-l10n` |
| Debug APK | `cd apps/distributor && flutter build apk --debug --dart-define-from-file=../../env/dev.json` |
| Admin web build | `cd apps/admin && flutter build web --release --dart-define-from-file=../../env/dev.json` |
| Create a staff account | `node tools/admin/create-staff.mjs --email ... --role owner` |
| End-to-end order test | `node tools/e2e/order_cycle.mjs` (needs `.secrets/supabase.env`) |
| SQL syntax check | `node tools/sql-check/check.mjs supabase/migrations/<file>.sql` |
| Database tests | `supabase start && supabase test db` (needs Docker) |

## Documentation

| Read this | When you want to know |
|---|---|
| [docs/architecture.md](docs/architecture.md) | How the pieces fit and where new code goes |
| [docs/business-rules.md](docs/business-rules.md) | Dispatch radius, order limits, fees, statuses, in plain language |
| [docs/api.md](docs/api.md) | Every database function the apps call |
| [docs/data-model.md](docs/data-model.md) | Every table and how they relate |
| [docs/errors.md](docs/errors.md) | What an error code means and what to check |
| [docs/environments.md](docs/environments.md) | Dev, staging and demo settings |
| [docs/runbooks/](docs/runbooks/) | Step-by-step fixes for common problems |
| [docs/decisions/](docs/decisions/) | Why things are the way they are |
| [docs/glossary.md](docs/glossary.md) | Arabic and English terms |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Rules for code, migrations and commits |
| [CHANGELOG.md](CHANGELOG.md) | What changed, version by version |
