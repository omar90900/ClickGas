# Staff accounts and distributor approval

## Create the first owner

Needs `supabase/migrations/20260912150000_admin_core.sql` applied and the
secret key in `.secrets/supabase.env`.

```sh
node tools/admin/create-staff.mjs --email owner@example.com --name "Full Name" \
     --phone 0791234567 --role owner
```

- If the email has no account yet, one is created with a generated password,
  printed **once**. Store it in a password manager.
- If the email already belongs to a customer account, that account becomes
  staff and keeps its password.
- Distributor accounts can't be staff; use another email.

Then open the dashboard (`apps/admin`, **Admin (dev)** in VS Code, or the
built `build/web`) and sign in with email and password.

## Add more staff (owner)

1. The person creates an account in the customer app (or run the script
   above with their details).
2. Dashboard › **Staff** › **Add staff**: their email or phone, and a role:
   - **Owner**: everything.
   - **Operations**: orders, distributor approvals, payments.
   - **Support**: customers, read-only on money.
3. They sign in to the dashboard with their email and password.

Change a role with the dropdown; **Remove from staff** turns the account back
into a customer. There must always be one owner (`LAST_OWNER`).

## Someone can't sign in to the dashboard

| They see | Check |
|---|---|
| "Wrong email or password" | They must use email, not phone. Reset the password in Supabase › Authentication › Users. |
| "This account is not staff" | `select * from staff_members where user_id = '<id>'` and `profiles.role = 'admin'`, `is_active = true`. Add them from Staff. |
| "Couldn't load your staff account" | Migration 5 missing: `select to_regclass('public.staff_members')` returns null. Apply it. |

## Approve a distributor (operations)

1. Dashboard › Overview shows "Distributors awaiting approval". Click
   **Review**, or open **Distributors** › *Awaiting approval*.
2. Open the distributor. Under **Documents**, click **View** on each paper
   (a private link valid for 10 minutes) and approve or reject it with a note.
3. **Approve** the distributor. They can go online immediately; the app
   refreshes its status when they pull the banner's refresh button or reopen.
4. Or **Reject** with a reason: they see it in the app and can upload new
   documents, which puts them back in the queue.

To take a distributor off the road: **Suspend** (with a reason). To stop an
account completely: **Block account**.

## Find who did something

Dashboard › **Audit log**, filter by what was changed, expand a row to see
the before/after detail. In SQL:

```sql
select created_at, actor_name, actor_role, action, target_type, target_id, reason, detail
  from admin_actions
 order by created_at desc
 limit 50;
```
