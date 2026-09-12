# 0010. Staff roles checked in the database, every action audited

- Status: Accepted
- Date: 2026-09-12

## Context

Phase 1 gives staff real power: approving distributors, blocking accounts,
cancelling and reassigning orders, recording cash, changing prices and fees.
The roadmap asks for three roles (owner, operations, support) and a record of
who did what. Hiding buttons in the dashboard is not protection: anyone with
the publishable key can call the API directly.

## Decision

- A staff member is a profile with `role = admin`, `is_active`, and a row in
  `staff_members(user_id, role)`. `my_staff_role()` returns the role;
  `is_staff()` (used by RLS) is true for any role.
- Staff **read** through RLS policies (`using ((select public.is_staff()))`)
  and a few read functions for aggregated views.
- Staff **write** only through `security definer` functions named `admin_*`
  (plus the existing `record_driver_payment`). Each one:
  1. calls `private.require_staff(<allowed roles>)` - the owner always passes;
  2. validates input and raises a stable code (`REASON_REQUIRED`,
     `INVALID_AMOUNT`, `INVALID_SETTING`, ...);
  3. makes the change (the order state machine still applies);
  4. calls `private.audit(action, target_type, target_id, reason, detail)`,
     which stores the actor's name and role at that moment and a before/after
     snapshot in `admin_actions`.
- No staff table is writable directly (`revoke insert, update, delete`).
- Destructive actions need a reason. The last owner can't be removed.
- The first owner is created with `tools/admin/create-staff.mjs`, which uses
  the secret key; afterwards the owner adds staff from the dashboard.

## Consequences

- The dashboard can't do more than the role allows even if it has a bug, and
  a new admin tool gets the same rules for free.
- The audit log is complete by construction: a change without an audit row
  would need a new function, which is reviewed in a migration.
- Role checks are one line per function, so adding a role (for example
  "finance") means editing the functions that should allow it.
- Staff read access is broad (any role sees all profiles and orders). If
  support should see less, add narrower policies later.
