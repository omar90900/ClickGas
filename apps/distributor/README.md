# ClickGas - distributor app

The distributor side of ClickGas: register with vehicle and agency, go online,
accept nearby orders (up to 3 at a time within 2 km), deliver, and follow sales
and fees owed.

Setup, commands and documentation live at the repository root:
[README.md](../../README.md) · [docs/architecture.md](../../docs/architecture.md) ·
[docs/business-rules.md](../../docs/business-rules.md).

```sh
flutter run --dart-define-from-file=../../env/dev.json
```

Package: `com.clickgas.driver`. Screens are in `lib/features/`, dispatch calls
in `lib/data/driver_repository.dart`, live location in
`lib/data/tracking_service.dart`. Translations: `lib/l10n/app_ar.arb`,
`lib/l10n/app_en.arb`.
