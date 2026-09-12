# Demo: seed, simulate, present, reset

Everything runs against the normal Supabase project. Demo data is small
(1 owner, 5 distributors, 12 customers, 15 past orders) and flagged
`is_demo`, so it can be hidden in the dashboard and removed completely.

Needs: migration `20260913090000_coverage_and_demo.sql`, Node 20+,
`.secrets/supabase.env`.

## 1. Seed (once, or after a reset)

```sh
node tools/demo/seed.mjs
```

Creates the accounts, 15 orders over the last 14 days (11 delivered, 2
cancelled, 2 expired), 2 charges and 3 coverage gaps. Logins are written to
`.secrets/demo-accounts.md` (all demo accounts share one password, stored in
`.secrets/demo.env`).

| Role | Login |
|---|---|
| Owner (dashboard) | `owner@demo.clickgas.app` |
| Distributors | `d1` … `d4@demo.clickgas.app` (approved), `d5@…` (awaiting approval) |
| Customers | `c01` … `c12@demo.clickgas.app` |

Phones are in the range `079 000 09xx`; the apps accept phone or email.

## 2. Simulate (during the presentation)

```sh
node tools/demo/simulate.mjs --minutes 30
```

- 4 demo distributors go online around Abdoun, Khalda, Tabarbour and Jabal
  Al-Hussein, drive along real roads, and accept, deliver and carry on.
- Add `--orders 3` to have demo customers place 3 orders (one every 90 s) so
  the map moves without touching a phone.
- Add `--demo-orders-only` if real customers' orders must be left to real
  distributors.
- `--speed 3` (default) drives 3× faster than real traffic.
- Ctrl+C takes everyone offline cleanly.

The PC must stay online. Each distributor writes one position every 5 s.

## 3. Presentation checklist

1. The day before: `node tools/demo/reset.mjs --reseed` (fresh dates).
2. Install the release APKs (docs/runbooks/release-builds.md) on the demo
   phones; sign in as `c01` (customer) and, if showing it live, `d1`
   (distributor).
3. Open the dashboard as `owner@demo.clickgas.app`. Keep **Hide demo data**
   off (account menu).
4. Start the simulation 5 minutes before you begin.
5. Follow docs/demo/presentation-script.md.

## 4. Reset

```sh
node tools/demo/reset.mjs            # remove all demo data
node tools/demo/reset.mjs --reseed   # remove and seed again
```

Removes demo orders, gaps, demo staff actions, then the demo accounts (and
with them their distributor rows, charges and documents). Real accounts,
their orders and settings are not touched. Orders a simulated distributor
delivered for a real customer stay (with the distributor removed).

## Troubleshooting

| Problem | Check |
|---|---|
| `Demo data already exists` | Run `reset.mjs` first, or `reset.mjs --reseed` |
| `demo_reset_data failed` / `demo_seed_order` 404 | Migration 7 not applied |
| Simulated trucks never accept | They only see orders within the search radius of their position; check Settings › dispatch radius, and that orders are pending |
| Straight-line driving | The public routing server (router.project-osrm.org) was unreachable; the simulation falls back to straight lines |
| Coverage page: "expiry job hasn't run" | pg_cron not enabled: Supabase › Database › Extensions › pg_cron, then re-run the `cron.schedule` line from migration 7 |
