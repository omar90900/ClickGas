# Someone didn't get a notification

Today notifications are shown by the app itself when it receives an update
([ADR 0008](../decisions/0008-notifications.md)). Push to a closed app arrives
in Phase 2.

| Check | How |
|---|---|
| Was the app running? | A customer who swiped the app away gets nothing until Phase 2 |
| Are notifications allowed? | Phone settings › Apps › ClickGas › Notifications: on, "Order updates" channel: on |
| Do Not Disturb? | Silences the sound but still shows the notification |
| Did the event happen? | `select status, created_at from order_events where order_id = ... order by created_at;` |
| Distributor: was it online? | The "new order near you" alert needs the online switch on (polls every 10 s) |

Still unclear: ask for **Send diagnostics** and look for `failure` events
around the time ([diagnostics.md](diagnostics.md)).
