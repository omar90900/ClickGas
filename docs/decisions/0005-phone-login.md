# 0005. Phone login via a password-checking database function

- Status: Accepted (supersedes the `email_for_phone` lookup)
- Date: 2026-09-12

## Context

Users sign in with phone + password or email + password. Supabase Auth's phone
login requires SMS, which is postponed. The first version called
`email_for_phone(phone)`, which returned the email of **any** registered phone
without a password - a privacy leak.

## Decision

`login_email_for_phone(phone, password)`:

- checks the password against `auth.users.encrypted_password` with `crypt()`
  inside the database;
- returns the email only when the password matches, otherwise `null`;
- counts failures per phone in `private.login_attempts` and raises
  `TOO_MANY_ATTEMPTS` after 5 failures in 15 minutes.

The app then signs in with Supabase Auth using that email and password.

`is_phone_registered(phone)` stays for sign-up ("this phone is already
registered"). It does reveal whether a number has an account - an accepted
trade-off common in consumer apps, revisited when SMS verification arrives.

## Consequences

- No email is revealed without the right password.
- Brute force per phone is capped; Supabase Auth adds its own limits on the
  second step.
- The password travels twice over HTTPS (RPC, then Auth). Acceptable for the
  proof of concept; SMS one-time codes replace this later.
