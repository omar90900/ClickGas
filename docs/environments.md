# Environments

| Name | Supabase project | Used for |
|---|---|---|
| `dev` | `rggjsueryxymukcnqawd` | development and the current test phones |
| `staging` | *to create* | testing migrations before production data exists |
| `demo` | *to create in Phase 5* | presentations, reset with demo data before each one |

## App settings

Apps read three values at build time:

| Key | Meaning |
|---|---|
| `APP_ENV` | `dev`, `staging` or `demo`; written into diagnostics uploads |
| `SUPABASE_URL` | the project URL |
| `SUPABASE_PUBLISHABLE_KEY` | the publishable (client) key - safe to ship |

They live in `env/<name>.json` and are passed with:

```sh
flutter run --dart-define-from-file=../../env/dev.json
```

Without the flag, apps fall back to `dev` (see `SupabaseConfig`). Optional:
`APP_VERSION` for diagnostics.

`env/*.json` files hold **only** publishable values. Anything secret goes in
`.secrets/` (never committed) - see [runbooks/secrets.md](runbooks/secrets.md).

## Per-machine files (never committed)

| File | Holds |
|---|---|
| `apps/*/android/local.properties` | Android SDK path, `MAPS_API_KEY` |
| `.secrets/supabase.env` | `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY` for tools |

## Supabase project settings that matter

- Authentication › Providers › Email › **Confirm email: off** (users sign in
  right after sign-up).
- Database migrations applied in order (see [runbooks/migrations.md](runbooks/migrations.md)).
- Realtime publication includes `orders` and `drivers` (done by the init migration).
