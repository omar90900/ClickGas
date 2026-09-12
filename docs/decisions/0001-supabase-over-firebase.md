# 0001. Supabase instead of Firebase

- Status: Accepted
- Date: 2026-09-11

## Context

The first prototype used Firebase (Firestore, Auth, Cloud Functions). The
owner switched to Supabase before any real data existed. The domain is
relational: customers, distributors, orders, fees and ratings reference each
other, and rules such as "a distributor holds at most three orders" need
transactions.

## Decision

Use Supabase: Postgres with Row Level Security, Supabase Auth (email +
password), Realtime for live updates, Storage for photos.

## Consequences

- Rules are written once in SQL and hold for every client.
- Transactions, constraints and joins are available (for example
  `accept_order()` locks the order row so two distributors can't take it).
- Push notifications need an external service (FCM) called from an Edge
  Function; see [0008](0008-notifications.md).
- Schema changes must go through migrations ([runbooks/migrations.md](../runbooks/migrations.md)).
