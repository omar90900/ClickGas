# 0014. Push notifications: the database decides, an Edge Function delivers through FCM

- Status: Accepted (supersedes the "Phase 2" part of [0008](0008-notifications.md))
- Date: 2026-09-12

## Context

Until now the apps showed their own notifications from Realtime, so a customer
who closed the app heard nothing about their order, and a distributor who was
offline never heard about account decisions or charges. Supabase has no push
service; Android push means Firebase Cloud Messaging (FCM). The rules for who
should be told what already live in the database ([0002](0002-database-enforces-rules.md)).

## Decision

1. **Triggers write the messages.** `orders`, `drivers`, `driver_charges` and
   `driver_documents` triggers call `private.notify()`, which writes one row to
   `notifications` per recipient, in Arabic and English. The row is also the
   in-app history (60 days). Seed mode writes nothing; a failing notification
   never blocks the change that caused it.
2. **Messages**:

   | To | Kind | When |
   |---|---|---|
   | Customer | `order_accepted`, `order_on_the_way`, `order_delivered` | status changes |
   | Customer | `order_released` | back to waiting (distributor dropped it, or staff took it back) |
   | Customer | `order_expired`, `order_cancelled` (by staff) | |
   | Distributor | `new_order` | a waiting order within its current search radius; nearest 20 online, approved distributors; again when an order is released (not to the one who released it) |
   | Distributor | `order_assigned`, `order_unassigned`, `order_cancelled`, `order_confirmed` | staff assign / reassign / cancel; the customer confirms receipt |
   | Distributor | `account_approved`, `account_rejected`, `account_suspended` | with the staff reason |
   | Distributor | `charge_created`, `charge_paid`, `charge_waived`, `document_approved`, `document_rejected` | |

3. **Preferences** on `profiles`: `locale` (follows the app language),
   `notify_order_updates` (kinds `order_*`), `notify_new_orders`. Turning a kind
   off stops the push but keeps the history. Account and charge messages
   can't be turned off.
4. **Delivery.** A statement-level trigger on `notifications` calls the Edge
   Function through `pg_net` (one call per statement, so a new order announced
   to 20 distributors is one call). URL and shared secret come from Vault;
   without them nothing is sent and nothing breaks. The function claims queued
   rows (`push_claim`, localized to each recipient), sends with the FCM HTTP v1
   API using a service account (OAuth token signed in the function with
   WebCrypto: no SDK), and reports back (`push_report`), deleting tokens FCM
   says are gone. pg_cron `clickgas-push-flush` retries every minute, gives up
   after 5 attempts, and expires messages older than 30 minutes.
5. **Apps.** `PushService` (shared package) initializes Firebase if the build
   has `google-services.json`, asks permission, and registers the token
   (`register_device`) after sign-in; sign-out removes it. When pushes are
   active, the app's own notifications show only while it is on screen, so
   nothing arrives twice.

### Considered

- **Supabase Database Webhooks**, one HTTP call per row: simpler, but one call
  per recipient and no retry or history.
- **Sending from the phone** (the app calls FCM): needs the service account in
  the app, which anyone could extract.
- **OneSignal or similar**: another account and another place for user data,
  and still FCM underneath.

## Consequences

- The apps depend on `firebase_core` and `firebase_messaging`. Firebase is used
  only for delivery; accounts and data stay in Supabase ([0001](0001-supabase-over-firebase.md)).
- Setup needs a Firebase project, `google-services.json` for both apps, and a
  service-account key in Edge Function secrets
  ([runbook](../runbooks/push-notifications.md)).
- Cost: FCM is free; one Edge Function call per notifying statement plus at
  most one per minute while something is queued (free tier: 500,000 a month).
- Not yet: iOS (needs an APNs key in Firebase); tapping a push opens the app
  but not the order; distributors who come into range when a search widens
  are not pushed again (they still see the order in the app).
- The `push_notifications` feature flag from 0008 is not used: the setup
  itself (Vault secrets present or not) is the switch.
