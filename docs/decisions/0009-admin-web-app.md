# 0009. Admin dashboard as a Flutter web app with OpenStreetMap

- Status: Accepted
- Date: 2026-09-12

## Context

Staff need a desktop dashboard: live operations, distributor approvals,
orders, customers, balances and settings. Options were a Flutter web app in
the monorepo, a separate React/Next.js app, or the Supabase table editor.

The live map needs tiles. The phone apps use Google Maps with a key in
`local.properties`. A web page would expose its Maps key to every visitor
and the repository is public.

## Decision

- `apps/admin` is a Flutter web app in the same pub workspace, using
  `clickgas_core` (models, `AppFailure`, `guard`, `Log`, theme, `UserAvatar`)
  and the same `provider` pattern as the phone apps.
- It talks only to Supabase with the publishable key; everything it can see
  or do is decided by RLS and the audited `admin_*` functions (ADR 0010).
- The map uses `flutter_map` with OpenStreetMap tiles: no key, no billing.
  The tile URL is one line in `live_map_page.dart`; a paid provider (or
  Google with a referrer-restricted key) can replace it before real traffic.
- Pages refresh by polling (overview 30 s, live map 10 s), the same reason
  as the distributor app: Realtime can't report rows leaving a filter.

## Consequences

- One language, one set of models and error codes across all three apps.
- Flutter web bundles are larger than a typical web page (a few MB) - fine
  for an internal dashboard.
- OpenStreetMap's public tile server is for light use; a busy production
  dashboard must switch to a tile provider.
- Admin-only models and the repository live in `apps/admin/lib/data`, not
  in the shared package, so the phone apps don't carry them.
