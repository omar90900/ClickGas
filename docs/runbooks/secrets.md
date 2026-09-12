# Secrets

## Inventory

| Secret | Where it lives | Who needs it |
|---|---|---|
| Supabase **secret** key (`sb_secret_…`) | `.secrets/supabase.env` (git-ignored), password manager | tools (`tools/e2e`), never apps |
| Supabase **publishable** key (`sb_publishable_…`) | `env/*.json`, app defaults | apps - safe to ship |
| Google Maps API key | `apps/*/android/local.properties` (git-ignored) | Android builds |
| Database password | password manager | Supabase CLI `db push` |
| Android release keystore | not created yet (Phase 5) | release builds |

The apps only ever contain the publishable key. Row Level Security is what
protects the data.

## Rotating the Supabase secret key

Do this now: the current key was shared in a chat and stored in a project file.

1. Supabase › Project Settings › API Keys › **Create new secret key**.
2. Put it in `.secrets/supabase.env` as `SUPABASE_SECRET_KEY=...` and in the
   password manager.
3. Run `node tools/e2e/order_cycle.mjs` to confirm tools work with the new key.
4. Delete the old secret key in the dashboard.
5. Delete `.secrets/server` and `.secrets/supabase.txt` (old copies).

## Rotating the Maps key

Google Cloud › APIs & Services › Credentials: create a new key restricted to
the two Android package names (`com.clickgas.app`, `com.clickgas.driver`) and
their SHA-1 fingerprints, update both `local.properties`, rebuild, then delete
the old key.

## If a secret leaks

Rotate immediately (above), then check Supabase › Logs for unusual API use
since the leak.
