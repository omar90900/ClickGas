# ClickGas - customer app

The customer side of ClickGas: sign up, order a gas cylinder on a live map,
track the distributor, confirm receipt, rate.

Setup, commands and documentation live at the repository root:
[README.md](../../README.md) · [docs/architecture.md](../../docs/architecture.md).

```sh
flutter run --dart-define-from-file=../../env/dev.json
```

Package: `com.clickgas.app`. Screens are in `lib/features/`, shared state in
`lib/state/`. Translations: `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`.
