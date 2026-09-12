# App stops working after about an hour

## Symptom

After roughly an hour of use (often with the screen off or the tab in the
background), calls start failing. The terminal or diagnostics show lines
like:

```
PostgrestException(message: JWT expired, code: PGRST303 ...)
Location write failed: ... JWT expired
RealtimeSubscribeException ... InvalidJWTToken: Token has expired
```

A distributor stays "online" on the live map but their position stops
updating.

## Cause

The Supabase login token lasts one hour. The SDK renews it only while the
app is in the foreground and pauses when the app goes to the background.
The distributor app keeps sending its location from a foreground service
and a dashboard tab keeps polling while hidden, so both kept using the old
token once it expired.

## Fix (since 2026-09-12)

`SessionKeeper` (`packages/clickgas_core/lib/src/session_keeper.dart`),
installed in each app's `main()`:

- renews the token every minute when under 5 minutes are left, even in the
  background;
- `guard()` renews and retries once when a call still gets an expired token;
- if the session can't be renewed (password changed, account deleted), the
  app signs out and shows its sign-in screen (`SESSION_EXPIRED`).

The customer and distributor order streams reconnect by themselves after
an error (2 s, 4 s, 8 s ... up to 30 s).

## If it happens again

1. Ask for **Send diagnostics** (or copy the terminal). Look for
   `session_refreshed`, `session_refresh_failed` and `session_expired_retry`
   events.
2. `session_refresh_failed` with code `refresh_token_not_found` or
   `session_not_found`: the session was revoked (password reset, user
   deleted, signed in too many times). Signing in again is expected.
3. `session_refresh_offline`: no connection when renewal was due; it retries
   every minute.
4. Check Supabase › Authentication › Sessions settings (time-box, inactivity
   timeout) if sessions end sooner than expected.
