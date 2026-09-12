# Database migrations

Every change to the database is a file in `supabase/migrations/`, named
`YYYYMMDDHHMMSS_description.sql`, applied **once, in order**.

## Rules

- Never edit a file after it has been applied anywhere. Fix forward with a new file.
- Each file starts with a header comment: what it does and what it depends on.
- New tables: enable RLS, add policies, revoke what clients must not do, and add
  `comment on table` / `comment on column`.
- New functions: `security definer set search_path = ''`, fully qualified names,
  `revoke execute ... from public, anon` then grant what's needed, `comment on function`.
- Error codes: `raise exception 'CODE' using detail = ...`, documented in [errors.md](../errors.md).
- Check syntax before sharing: `node tools/sql-check/check.mjs <file>`.

## Applying

**SQL Editor (current way):** open the file, copy all of it, paste in Supabase ›
SQL Editor › New query, Run. The editor runs it as one transaction: either all
of it applies, or none of it.

**Supabase CLI (once linked):**

```sh
npx supabase login
npx supabase link --project-ref rggjsueryxymukcnqawd
npx supabase db push
```

## Checking what's applied

```sql
select 'staff_members' as marker, to_regclass('public.staff_members') is not null as applied -- admin_core
union all select 'fee_settings', to_regclass('public.fee_settings') is not null              -- foundation
union all select 'avatars bucket', exists(select 1 from storage.buckets where id = 'avatars') -- slots_avatars
union all select 'order_releases', to_regclass('public.order_releases') is not null;         -- driver_app
```

## Applied so far (dev)

| File | Applied |
|---|---|
| `20260911000000_init.sql` | 2026-09-11 |
| `20260911120000_driver_app.sql` | 2026-09-11 |
| `20260911180000_slots_avatars.sql` | 2026-09-11 |
| `20260912090000_foundation.sql` | 2026-09-12 (verified by `tools/e2e/order_cycle.mjs`, 16/16) |
| `20260912150000_admin_core.sql` | 2026-09-12 (verified by `tools/e2e/admin_cycle.mjs`, 42/42, and `order_cycle.mjs`, 16/16) |

If a run fails with "already exists", the file was applied before; check with
the query above instead of running it again.
