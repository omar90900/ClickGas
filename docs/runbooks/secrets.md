# Secrets

## Inventory

| Secret | Where it lives | Who needs it |
|---|---|---|
| Supabase **secret** key (`sb_secret_…`) | `.secrets/supabase.env` (git-ignored), password manager | tools (`tools/e2e`), never apps |
| Supabase **publishable** key (`sb_publishable_…`) | `env/*.json`, app defaults | apps - safe to ship |
| Google Maps API key | `apps/*/android/local.properties` (git-ignored) | Android builds |
| Database password | password manager | Supabase CLI `db push` |
| Android release keystore | `.secrets/clickgas-release.jks` + `android/key.properties` (git-ignored) | release builds ([release-builds.md](release-builds.md)) |
| Firebase service-account key | `.secrets/firebase-service-account.json`, then Edge Function secret `FCM_SERVICE_ACCOUNT` | `send-push` only: it can push to every user |
| Push shared secret | `.secrets/push.env` (`PUSH_WEBHOOK_SECRET`), Edge Function secrets, Vault `clickgas_push_secret` | database → `send-push` calls |
| `google-services.json` | `apps/*/android/app/` (git-ignored) | Android builds with push; identifies the Firebase project, not a secret, kept out of the public repo anyway |

Rotating the push secrets: [push-notifications.md › Rotating](push-notifications.md#rotating).

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
