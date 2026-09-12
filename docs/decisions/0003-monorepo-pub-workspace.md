# 0003. One repository, one pub workspace, one shared package

- Status: Accepted
- Date: 2026-09-12

## Context

The customer and distributor apps started as separate folders with a shared
package referenced by path, each with its own lockfile. Versions could drift,
and the database, docs and apps lived in different places.

## Decision

- One git repository: `apps/`, `packages/`, `supabase/`, `docs/`, `tools/`.
- A Dart pub workspace at the root: one `pubspec.lock`, `flutter pub get` once.
- One shared package, `clickgas_core`, for models, repositories, errors,
  logging, theme and small shared widgets.

The roadmap mentioned a separate `clickgas_ui` package. It is deferred: today
the shared UI is three small pieces (theme, `UserAvatar`, `MapIcons`), and a
split would only add imports. Split when the admin app needs UI the phone apps
don't, or when non-UI consumers (scripts, tests) want core without Flutter
widgets.

## Consequences

- A change to a model or repository reaches every app in one commit.
- CI analyzes and tests everything together.
- All members must agree on dependency versions (a feature, not a bug).
