# Reading a diagnostics upload

Users send diagnostics from **Settings › Send diagnostics**. They get a
reference number; the upload lands in the `diagnostics` table with the last 300
log events from the phone.

## Find the upload

By reference number:

```sql
select id, created_at, app, app_version, environment, platform, locale, note
  from diagnostics where id = 123;
```

By phone number (latest first):

```sql
select d.id, d.created_at, d.app, d.app_version
  from diagnostics d join profiles p on p.id = d.user_id
 where p.phone = '+962791234567'
 order by d.created_at desc limit 5;
```

## Read the log

```sql
select e ->> 'at' as at, e ->> 'level' as level, e ->> 'event' as event, e -> 'data' as data
  from diagnostics, jsonb_array_elements(logs) e
 where id = 123
 order by e ->> 'at';
```

Look for `level = 'warn'` or `'error'` first.

| Event | Meaning |
|---|---|
| `app_start` | The app opened (`data.app`) |
| `supabase_ready` | Connected to the project (`data.env`) |
| `signed_in` / `signed_out` | Session changes (`data.method` = phone or email) |
| `order_created` | Customer placed an order (`data.order` = order number) |
| `order_accepted` / `order_delivered` / `order_released` | Distributor actions |
| `went_online` / `went_offline` | Distributor switch |
| `failure` | A server call failed: `data.op` (what), `data.code` (see [errors.md](../errors.md)), `data.detail` |
| `flutter_error` / `uncaught_error` | A crash or bug, with a short stack trace |

## Next steps

- A `failure` with a known code: follow [errors.md](../errors.md).
- `NETWORK` failures in a row: the phone was offline.
- `flutter_error`: copy the stack into a bug report with the app version.
