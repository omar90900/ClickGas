# Runbooks

Step-by-step guides for the problems that come up most. Each starts from what
the person reporting it can tell you (an order number, a phone number, a
diagnostics reference) and ends with a fix or a clear next step.

| Runbook | Use when |
|---|---|
| [diagnostics.md](diagnostics.md) | A user sent diagnostics, or you need to see what happened on a phone |
| [order-stuck.md](order-stuck.md) | An order stays "waiting for a distributor" |
| [driver-cannot-go-online.md](driver-cannot-go-online.md) | A distributor can't switch online or sees no orders |
| [notifications-missing.md](notifications-missing.md) | Someone didn't get a notification |
| [push-notifications.md](push-notifications.md) | Setting up Firebase push, the Edge Function and Vault; push states |
| [app-stuck-on-launch.md](app-stuck-on-launch.md) | An app stays on the launch image or shows "ClickGas could not start" |
| [session-expired.md](session-expired.md) | An app stops working after about an hour ("JWT expired") |
| [staff-accounts.md](staff-accounts.md) | Creating staff, dashboard sign-in problems, approving distributors, the audit log |
| [demo.md](demo.md) | Seeding, simulating and resetting demo data; presentation checklist |
| [release-builds.md](release-builds.md) | Signing key, Maps key fingerprints, building release APKs |
| [migrations.md](migrations.md) | Applying or checking database changes |
| [secrets.md](secrets.md) | Keys: where they are, how to rotate them |

All SQL below runs in Supabase › SQL Editor (as the project owner).
