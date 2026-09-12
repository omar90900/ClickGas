# 0013. One design system in the shared package, brand green #2CE881

- Status: Accepted
- Date: 2026-09-12

## Context

The first look used #53ED74 with ad-hoc screens: settings were a stack of
cards and segmented buttons, dark mode was a near-green black, and each app
drew its own rows and headers. The owner chose a new brand green, **#2CE881**,
and a soft black for dark mode, and wants the three apps to look like one
product.

## Decision

- **Tokens** live in `packages/clickgas_core/lib/src/app_theme.dart`
  (`AppColors`, `AppRadius`) and are the only source of colour; every app uses
  `AppTheme.light()` / `AppTheme.dark()`. Reference: [design-system.md](../design-system.md).
- **The bright green is a fill, not a text colour.** It is too light for text
  on white (about 1.6:1), so it fills buttons, switches, selections and
  badges, with dark green text on it (`onBrand`, about 9:1). Green text and
  icons use `brandDeep` #0A7A3D on light surfaces (about 5.4:1) and the brand
  green itself on dark ones (about 11:1). `context.accent` picks the right one.
- **Dark mode is a soft black** (#141517 background, #1C1E21 cards), never
  pure black, with near-white text (#F3F5F4) and the green for accents.
- **Shared components** (`settings_kit.dart`, `notification_inbox.dart`):
  `ProfileHeader`, `SettingsGroup`, `SettingsTile`, `SettingsSwitchTile`,
  `ThemeModePicker`, `StatusPill`, `NotificationInbox`. Both phone apps build
  Profile & Settings from them, so they look and behave the same.
- Cards are flat with a hairline border instead of shadows (cheap to draw,
  clean in both modes); radii 10 / 14 / 20 / 28.

## Consequences

- A colour change is one edit in core and reaches all three apps.
- Screens that still use hard-coded `Colors.*` (mostly in the admin
  dashboard) follow the theme only partly; they are moved to tokens when
  touched.
- Launcher icons and splash still use the earlier artwork; the web manifests
  and theme colours use #2CE881.
