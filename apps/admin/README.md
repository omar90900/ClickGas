# ClickGas Admin

The staff dashboard, a Flutter web app on the same Supabase project and the
shared `clickgas_core` package as the customer and distributor apps.

| Page | For | What it does |
|---|---|---|
| Overview | all staff | Today's orders, deliveries, fees, waiting orders, distributors online, 14-day chart |
| Live map | all staff | Open orders coloured by age and distributors on one map; open an order to inspect, reassign or cancel it |
| Orders | all staff | Search by number, phone, name, status, date; order inspector with every event |
| Distributors | all staff (actions: owner, operations) | Approval queue with documents; approve, reject, suspend, block |
| Customers | all staff | Search, order history, block and unblock |
| Finance | all staff (charges: owner, operations; waive: owner) | Platform income from service fees by day, agency and distributor; charges (fines, item fees) with explanations |
| Settings | owner | Prices, service fees, dispatch settings, cities, feature flags |
| Staff | owner | Add staff and set roles |
| Audit log | all staff | Every staff action with who, when and why |

The database enforces every rule and records every action in `admin_actions`,
so the page is only a view: see [docs/api.md](../../docs/api.md#staff) and
[ADR 0010](../../docs/decisions/0010-staff-roles-and-audit.md).

## Run

```sh
# from the repository root, once
flutter pub get

cd apps/admin
flutter gen-l10n
flutter run -d chrome --dart-define-from-file=../../env/dev.json
```

or use the **Admin (dev)** configuration in VS Code.

## First staff account

See [docs/runbooks/staff-accounts.md](../../docs/runbooks/staff-accounts.md).

## Build and host

```sh
flutter build web --release --dart-define-from-file=../../env/dev.json
```

Serve `build/web` from any static host. The page holds only the publishable
key; everything it shows is filtered by Row Level Security for the signed-in
staff member.

## Map

The live map uses [flutter_map](https://pub.dev/packages/flutter_map) with
OpenStreetMap tiles, so the dashboard needs no Maps API key
([ADR 0009](../../docs/decisions/0009-admin-web-app.md)).
