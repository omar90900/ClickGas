# Someone didn't get a notification

Two paths deliver notifications ([ADR 0014](../decisions/0014-push-notifications.md)):

- **Push**, from the server, also when the app is closed: needs a build with
  `google-services.json` and the setup in
  [push-notifications.md](push-notifications.md).
- **In-app**, shown by the app itself from Realtime while it is open (and, for
  a distributor, while online in the background).

Every message is also in the user's history: Settings › bell icon.

## Checks, in order

| Check | How |
|---|---|
| Did the event happen? | `select status, actor_id, created_at from order_events where order_id = '<order id>' order by created_at;` |
| Was a message written? | `select kind, push_status, push_error, created_at, sent_at from notifications where user_id = '<user id>' order by id desc limit 10;` No row: the event has no message (see the list in ADR 0014) or the account is blocked |
| `push_status` | `muted`: the user turned it off in Settings › Notifications. `no_device`: no phone registered (build without Firebase, or permission denied). `failed` / `queued`: [push-notifications.md › Troubleshooting](push-notifications.md#troubleshooting) |
| Is the phone registered? | `select app, platform, last_seen_at from device_tokens where user_id = '<user id>';` |
| Are notifications allowed? | Phone settings › Apps › ClickGas › Notifications: on, "Order updates" channel: on |
| Do Not Disturb / battery saver? | Silences sound; some phones (Infinix, Xiaomi) also delay pushes to "optimized" apps: set battery to "No restrictions" |
| Distributor: new orders | Only online, approved distributors within the order's search radius get "new order near you", nearest 20 |

Still unclear: ask for **Send diagnostics** and look for `push_*` and
`failure` events around the time ([diagnostics.md](diagnostics.md)).
