# Decision records

One short file per decision that shaped the system: what we chose, what else we
considered, and what it costs us. Add a new file instead of editing an accepted
one; if a decision changes, write a new record that supersedes the old.

| # | Decision | Status |
|---|---|---|
| [0001](0001-supabase-over-firebase.md) | Supabase instead of Firebase | Accepted |
| [0002](0002-database-enforces-rules.md) | Business rules are enforced in the database | Accepted |
| [0003](0003-monorepo-pub-workspace.md) | One repository, one pub workspace, one shared package | Accepted |
| [0004](0004-provider-for-state.md) | `provider` + `ChangeNotifier` for app state | Accepted |
| [0005](0005-phone-login.md) | Phone login via a password-checking database function | Accepted |
| [0006](0006-per-order-fee-cash-ledger.md) | 0.150 JOD fee per delivered order, cash with a ledger | Ledger superseded by 0011 |
| [0007](0007-money-in-fils.md) | Money stored with 3 decimals (fils) | Accepted |
| [0008](0008-notifications.md) | Local notifications now, push (FCM) in Phase 2 | Accepted |
| [0009](0009-admin-web-app.md) | Admin dashboard as a Flutter web app with OpenStreetMap | Accepted |
| [0010](0010-staff-roles-and-audit.md) | Staff roles checked in the database, every action audited | Accepted |
| [0011](0011-revenue-and-charges.md) | Fees are platform revenue; charges replace the distributor ledger | Accepted |

Template:

```md
# NNNN. Title
- Status: Proposed | Accepted | Superseded by NNNN
- Date: YYYY-MM-DD

## Context
## Decision
## Consequences
```
