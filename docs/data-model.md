# Data model

Postgres schema in Supabase, built by the files in `supabase/migrations/`.
Every table has Row Level Security. Money is `numeric(12,3)` JOD. Times are
`timestamptz` (UTC in the database, Asia/Amman on screen).

```mermaid
erDiagram
  auth_users ||--|| profiles : "sign-up trigger"
  profiles ||--o| drivers : "distributors only"
  cities ||--o{ profiles : ""
  profiles ||--o{ orders : "customer"
  drivers ||--o{ orders : "assigned"
  services ||--o{ orders : ""
  orders ||--o{ order_events : "status history"
  orders ||--o{ order_releases : "given back"
  drivers ||--o{ order_releases : ""
  drivers ||--o{ driver_charges : "fines, item fees"
  orders ||--o{ driver_charges : "about"
  profiles ||--o{ diagnostics : "uploads"
  profiles ||--o| staff_members : "staff only"
  profiles ||--o{ admin_actions : "did"
  drivers ||--o{ driver_documents : "papers"
  services ||--o{ price_history : "prices"
```

## Tables

| Table | One row per | Key columns |
|---|---|---|
| `profiles` | account | `role` (customer/driver/admin), `full_name`, `phone` (unique), `email`, `city_id`, `avatar_url`, `is_active` |
| `drivers` | distributor | `status` (pending/approved/rejected/suspended), `status_reason`, `is_verified` (= approved), `is_online`, `lat`, `lng`, `location_updated_at`, `cylinders_on_board`, `vehicle_plate`, `vehicle_model` (vehicle type code), `agency_name`, `rating_sum`, `rating_count` |
| `orders` | order | `order_number` (from 1001), `status`, `service_*` (snapshot), `quantity`, `unit_price`, `delivery_fee`, `service_fee`, `driver_fee`, `total_price`, `payment_method`, `delivery_lat/lng`, `delivery_address`, `notes`, `rating`, `customer_confirmed_at`, one timestamp per status |
| `order_events` | status change | `order_id`, `status`, `actor_id`, `created_at` |
| `order_transitions` | allowed change | `from_status`, `to_status`, `actor`, `via` |
| `order_releases` | order a distributor gave back | snapshot of number, service, quantity, total |
| `driver_charges` | fine or item fee raised by staff | `kind` (fine/item_fee/other), `title`, `note` (explanation shown to the distributor), `amount`, `status` (open/paid/waived), `order_id`, `created_by`, `settled_by`, `settle_note` |
| `fee_settings` | fee change | `customer_fee`, `driver_fee`, `effective_from` |
| `services` | thing to order | `code`, names, descriptions, `price`, `badge` |
| `cities` | Jordanian city | names, `lat`, `lng` |
| `app_config` | (single row) | `delivery_fee`, `max_quantity`, `driver_radius_km`, `max_active_orders`, `auto_verify_drivers`, `min_*_version` |
| `diagnostics` | uploaded log | `app`, `app_version`, `environment`, `platform`, `logs` (jsonb), `note` |
| `job_runs` | scheduled job run | `job`, `started_at`, `finished_at`, `ok`, `detail` |
| `feature_flags` | switch | `key`, `enabled`, `description` |
| `private.login_attempts` | failed phone login | `phone`, `attempted_at` (not reachable from the API) |
| `staff_members` | staff account | `user_id`, `role` (owner/operations/support) |
| `admin_actions` | staff action (audit trail) | `actor_id`, `actor_name`, `actor_role`, `action` (e.g. `order.cancel`), `target_type`, `target_id`, `reason`, `detail` (jsonb before/after) |
| `driver_documents` | current paper per distributor and kind | `kind`, `file_path`, `status` (pending/approved/rejected), `expires_on`, `review_note` |
| `price_history` | service price | `service_id`, `old_price`, `new_price`, `changed_by`, `changed_at` (written by trigger) |

## Views

| View | Returns |
|---|---|
| `current_fees` | the `fee_settings` row in force now |

## Storage

| Bucket | Path | Access |
|---|---|---|
| `avatars` (public) | `<user id>/avatar.jpg` | anyone reads; owner writes |
| `driver-docs` (private, 5 MB, images/PDF) | `<driver id>/<kind>-<timestamp>.jpg` | the distributor uploads and reads own; staff read all |

## Enums

- `user_role`: customer, driver, admin
- `order_status`: pending, accepted, on_the_way, delivered, cancelled, expired
- `payment_method`: cash, card
- `charge_kind`: fine, item_fee, other
- `charge_status`: open, paid, waived
- `staff_role`: owner, operations, support
- `driver_status`: pending, approved, rejected, suspended
- `document_kind`: national_id, driving_licence, vehicle_registration, agency_letter
- `document_status`: pending, approved, rejected

## Migrations

| File | Adds |
|---|---|
| `20260911000000_init.sql` | core tables, RLS, order RPCs, cities and services |
| `20260911120000_driver_app.sql` | distributor sign-up, multi-order dispatch, releases, receipt confirmation |
| `20260911180000_slots_avatars.sql` | slot frees on delivery, avatars bucket, photos in RPCs |
| `20260912090000_foundation.sql` | fils, fees + ledger, state machine, safe phone login, diagnostics, job runs, flags, descriptions |
| `20260912150000_admin_core.sql` | staff roles, audit trail, staff read access, distributor status and documents, staff actions, price history, dashboard functions |
| `20260912200000_revenue_and_charges.sql` | fees are revenue only; ledger removed; `driver_charges`; `admin_finance` |
