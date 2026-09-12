import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Building blocks for the Profile and Settings screens of every app, so they
/// look and behave the same. Texts come from the app (core has no strings).

/// A titled group of tiles on one rounded card, separated by thin lines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children, this.footer});

  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(const Divider(indent: 64, height: 1));
      items.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 8),
              child: Text(
                title!,
                style: context.text.labelLarge?.copyWith(
                  color: context.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          Card(clipBehavior: Clip.antiAlias, child: Column(children: items)),
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
              child: Text(footer!, style: context.text.bodySmall?.copyWith(color: context.muted)),
            ),
        ],
      ),
    );
  }
}

/// The icon badge at the start of a settings row.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon(this.icon, {super.key, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.accent;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: c.withValues(alpha: context.isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      ),
      child: Icon(icon, size: 20, color: c),
    );
  }
}

/// One tappable row: icon badge, title, optional subtitle, and a value or
/// chevron at the end. [destructive] paints it red (sign out, delete).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.color,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Short current value shown before the chevron ("العربية", "Dark").
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? AppColors.danger : color;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
        child: Row(
          children: [
            SettingsIcon(icon, color: tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: destructive ? AppColors.danger : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.text.bodySmall?.copyWith(color: context.muted)),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: context.text.bodyMedium?.copyWith(color: context.muted),
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 8), trailing!]
            else if (onTap != null && !destructive) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: context.muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// A settings row with a switch.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class ProfileStat {
  const ProfileStat({required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final IconData? icon;
}

/// The top of a Profile screen: photo, name, contact lines, an optional
/// status badge and a row of stats, on a softly branded card.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.avatar,
    required this.name,
    this.lines = const [],
    this.badge,
    this.stats = const [],
    this.onEdit,
    this.editLabel,
  });

  final Widget avatar;
  final String name;

  /// Phone, email, city... Phone numbers should already be formatted.
  final List<String> lines;
  final Widget? badge;
  final List<ProfileStat> stats;
  final VoidCallback? onEdit;
  final String? editLabel;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: dark
              ? const [Color(0xFF173A27), AppColors.darkCard]
              : const [Color(0xFFDDF9E8), AppColors.lightCard],
        ),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Column(
        children: [
          avatar,
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.muted),
              ),
            ),
          if (badge != null) ...[const SizedBox(height: 10), badge!],
          if (onEdit != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  backgroundColor: AppColors.brand.withValues(alpha: dark ? 0.18 : 0.22),
                  foregroundColor: context.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: const StadiumBorder(),
                ),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(editLabel ?? ''),
              ),
            ),
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.card.withValues(alpha: dark ? 0.6 : 0.9),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0)
                      Container(width: 1, height: 34, color: context.colors.outlineVariant),
                    Expanded(child: _StatCell(stat: stats[i])),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});
  final ProfileStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stat.icon != null) ...[
              Icon(stat.icon, size: 16, color: context.accent),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(stat.value, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall?.copyWith(color: context.muted),
        ),
      ],
    );
  }
}

/// Three preview cards to pick System / Light / Dark.
class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.systemLabel,
    required this.lightLabel,
    required this.darkLabel,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;
  final String systemLabel;
  final String lightLabel;
  final String darkLabel;

  @override
  Widget build(BuildContext context) {
    Widget option(ThemeMode mode, String label) => Expanded(
          child: _ThemePreview(
            mode: mode,
            label: label,
            selected: value == mode,
            onTap: () => onChanged(mode),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Row(
        children: [
          option(ThemeMode.system, systemLabel),
          const SizedBox(width: 10),
          option(ThemeMode.light, lightLabel),
          const SizedBox(width: 10),
          option(ThemeMode.dark, darkLabel),
        ],
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.mode, required this.label, required this.selected, required this.onTap});

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  Widget _mock(Color bg, Color card, Color line) => Container(
        color: bg,
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 6, width: 30, decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 5),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(5)),
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 4, color: line),
                    const SizedBox(height: 3),
                    FractionallySizedBox(widthFactor: 0.6, child: Container(height: 4, color: line)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final light = _mock(AppColors.lightBackground, AppColors.lightCard, AppColors.lightOutline);
    final dark = _mock(AppColors.darkBackground, AppColors.darkCard, AppColors.darkOutline);
    final preview = switch (mode) {
      ThemeMode.light => light,
      ThemeMode.dark => dark,
      ThemeMode.system => Row(
          children: [
            Expanded(child: ClipRect(child: Align(alignment: AlignmentDirectional.centerStart, widthFactor: 1, child: light))),
            Expanded(child: ClipRect(child: Align(alignment: AlignmentDirectional.centerEnd, widthFactor: 1, child: dark))),
          ],
        ),
    };
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected ? AppColors.brand : context.colors.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  preview,
                  if (selected)
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: Container(
                        decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.check_rounded, size: 14, color: AppColors.onBrand),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: context.text.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? context.accent : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact status pill (verified, under review...).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.2 : 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 5)],
          Text(label, style: context.text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
