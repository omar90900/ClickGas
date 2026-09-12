# 0008. Local notifications now, push (FCM) in Phase 2

- Status: Accepted
- Date: 2026-09-11

## Context

Customers must hear when their order is accepted, on the way or delivered;
distributors must hear about new nearby orders. Supabase has no push service.

## Decision

- Now: `NotificationService` (flutter_local_notifications) shows a
  notification with sound when the app receives an event through Realtime or
  polling. The distributor app keeps running in the background while online
  because of its location foreground service, so it keeps notifying.
- Phase 2: an Edge Function sends Firebase Cloud Messaging pushes, triggered
  by database changes, so notifications arrive when an app is fully closed.
  Controlled by the `push_notifications` feature flag.

## Consequences

- No external account is needed for the current demo.
- A customer who closes the app misses notifications until Phase 2.
