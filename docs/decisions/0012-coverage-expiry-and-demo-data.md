# 0012. Widening search, order expiry, and demo data in the same project

- Status: Accepted
- Date: 2026-09-13

## Context

ClickGas is general: in an area, some distributors use the app and others
don't. A customer may order where nobody is online, and a fixed 2 km radius
either misses distributors slightly further away or, if set wide (it had
been set to 20 km), sends everyone orders from across the city. Orders
nobody takes stayed pending forever.

For presentations the product needs a populated dashboard and moving trucks.
The owner chose to keep everything in the one Supabase project (free tier),
with a small amount of demo data.

## Decision

- **Widening search:** an order is offered within `driver_radius_km` (2 km),
  plus `radius_step_km` (2 km) every `radius_step_minutes` (5), up to
  `max_radius_km` (6 km). `order_radius_km(created_at)` is the single rule,
  used by `nearby_orders` and `accept_order`.
- **Expiry:** `expire_stale_orders()` runs every minute (pg_cron) and expires
  pending orders older than `order_expiry_minutes` (20) as the system. Runs
  are logged in `job_runs` (successes kept 2 days).
- **Coverage:** before ordering, the customer app calls `coverage_check`,
  which says whether anyone is online within the widest radius and records
  a `coverage_gaps` row when not (at most one per customer per 10 minutes).
  `admin_coverage` turns gaps and expired orders into an unserved-demand map
  and acceptance rates per city.
- **Demo data:** demo profiles and their orders carry `is_demo`. Staff can
  hide demo data (`staff_members.hide_demo`, applied inside the dashboard
  functions). `demo_seed_order` writes backdated history under a seed mode
  that only it can switch on (a transaction-local setting clients can't set),
  and only the service role may call it. `demo_reset_data` plus the reset
  script remove exactly the demo rows and accounts.

## Consequences

- Coverage is visible: the dashboard shows where distributors are missing,
  which is what agencies and recruiters need.
- Customers are told the truth up front and get a clear "order again" when
  nobody came, instead of waiting forever.
- Demo and real data share tables; everything real is untouched by reset,
  and the dashboard can hide demo rows. Simulated distributors can accept
  real orders during a simulation (`--demo-orders-only` prevents it).
- pg_cron must be available; if it isn't, the migration still applies and
  the Coverage page says the job hasn't run.
