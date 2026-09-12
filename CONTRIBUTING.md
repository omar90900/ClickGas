# Contributing

## Branches and commits

- `main` always builds and passes CI.
- Work on a branch: `feature/complaints`, `fix/order-stuck-refresh`, `docs/runbooks`.
- Commit messages: `type(scope): what changed`, for example
  `feat(distributor): show fee balance`, `fix(db): reject delivery of cancelled orders`.
  Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `db`.
- One logical change per pull request, with its docs and tests.

## Code rules

- **Layering:** screens → controllers → repositories → Supabase. Screens never
  import `supabase_flutter` for data access.
- **Errors:** repositories wrap every call in `guard('area.action', ...)` and
  throw only `AppFailure`. Screens show `failureText(context, error)`.
- **Logging:** `Log.i/w/e(event, {...})` with order numbers and codes. Never log
  passwords, tokens, full addresses or phone numbers.
- **Strings:** every user-facing string in both `app_ar.arb` and `app_en.arb`,
  Arabic first. No hard-coded text in widgets.
- **Money:** display with `Fmt.money` (3 decimals); never compute what is charged in the app.
- **Shared code** goes to `packages/clickgas_core`; app-specific code stays in the app.
- **Secrets:** never in code, `env/`, or commits. See [docs/runbooks/secrets.md](docs/runbooks/secrets.md).

## Database rules

See [docs/runbooks/migrations.md](docs/runbooks/migrations.md). In short: a new
numbered file, never edit an applied one, RLS on every table, `comment on`
everything, error codes documented.

## Before you open a pull request

- [ ] `flutter analyze apps packages` shows no issues
- [ ] tests pass in every package you touched
- [ ] new SQL passes `node tools/sql-check/check.mjs`
- [ ] order-flow changes pass `node tools/e2e/order_cycle.mjs` on dev or staging
- [ ] docs updated (api, business rules, data model, errors as relevant)
- [ ] a line in `CHANGELOG.md` under *Unreleased*

## Definition of done

A feature is done when it works in both languages and both themes, its errors
have codes and messages, its rules are enforced by the database, it has tests,
and the docs describe it.
