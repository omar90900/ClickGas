# Design system

One look for the customer app, the distributor app and the admin dashboard.
Everything here lives in `packages/clickgas_core` ([ADR 0013](decisions/0013-design-system.md)).

## Colours

| Token | Light | Dark | Use |
|---|---|---|---|
| `AppColors.brand` | #2CE881 | #2CE881 | Fills: primary buttons, switches, selection, badges, FAB |
| `AppColors.onBrand` | #04301A | #04301A | Text and icons on the brand fill |
| `AppColors.brandDeep` | #0A7A3D | – | Green text and icons on light surfaces |
| `context.accent` | #0A7A3D | #2CE881 | "Green text here" in either mode |
| background | #F4F7F5 | #141517 | Scaffold |
| card (`context.card`) | #FFFFFF | #1C1E21 | Cards, tiles, sheets, dialogs |
| card alt | #ECF1EE | #25282C | Inputs (dark), chips, secondary fills |
| outline | #DFE6E2 | #30343A | Hairline borders, dividers |
| text | #0E1511 | #F3F5F4 | Body text |
| muted (`context.muted`) | #5D6B64 | #A0A8A4 | Secondary text, idle icons |
| `AppColors.danger` | #EF4444 | | Errors, destructive actions, sign-out |
| `AppColors.warning` | #F59E0B | | Waiting, expiring, released |
| `AppColors.info` | #3B82F6 | | Neutral information |

Contrast (WCAG): text on background 16:1 (dark) / 17:1 (light); muted 7.5:1 /
5.2:1; `brandDeep` on white 5.4:1; `onBrand` on brand 9:1. **Never put the
brand green as text on a light surface.**

## Shape and type

- Radii (`AppRadius`): `sm` 10, `md` 14 (inputs, tiles), `lg` 20 (cards), `xl` 28 (sheets, profile header).
- Cards are flat: no shadow, 1 px outline.
- Font: Cairo (Arabic and Latin) from `google_fonts`; titles bold (800–900).
- Buttons: 52 px high, radius 16; primary = brand fill, secondary = outlined accent.

## Components

```dart
ProfileHeader(
  avatar: UserAvatar(url: p.avatarUrl, name: p.fullName, radius: 46, editable: true, onTap: ...),
  name: p.fullName,
  lines: [phone, city],
  badge: StatusPill(label: 'Verified', color: AppColors.brandDeep),
  stats: [ProfileStat(label: 'Orders', value: '12'), ...],
  onEdit: ..., editLabel: 'Edit profile',
);

SettingsGroup(title: 'Account', footer: 'Optional note', children: [
  SettingsTile(icon: Icons.lock_outline_rounded, title: 'Change password', onTap: ...),
  SettingsTile(icon: Icons.translate_rounded, title: 'Language', value: 'العربية', onTap: ...),
  SettingsSwitchTile(icon: Icons.notifications_active_outlined, title: 'New orders', value: on, onChanged: ...),
  SettingsTile(icon: Icons.logout_rounded, title: 'Sign out', destructive: true, onTap: ...),
]);

ThemeModePicker(value: mode, onChanged: settings.setThemeMode,
  systemLabel: ..., lightLabel: ..., darkLabel: ...);

NotificationInbox(repository: ..., emptyTitle: ..., emptyBody: ...,
  timeAgo: (t) => ..., errorBuilder: (context, error, retry) => ...);
```

The shared package has no strings: apps pass their translated texts.

## Rules

- Colours come from the theme (`context.colors`, `context.accent`,
  `context.muted`, `context.card`) or `AppColors`, never `Color(0x...)` in a
  screen.
- Check every new screen in light and dark, Arabic (RTL) and English.
- Phone numbers and plates inside Arabic text are wrapped as left-to-right.
