# 0004. `provider` + `ChangeNotifier` for app state

- Status: Accepted
- Date: 2026-09-11

## Context

The apps have little shared state: the session (who is signed in), the live
order list, the distributor's active orders and tracking state. Most screens
read one of these and call a repository.

## Decision

Use `provider` for dependency injection and `ChangeNotifier` controllers for
shared state. Providers are created above `MaterialApp` so pushed routes can
reach them.

## Consequences

- Small, well-known API; easy for a new developer.
- No code generation.
- If state grows (for example offline caching or many cross-screen streams),
  revisit with Riverpod; the repository layer would not change.
