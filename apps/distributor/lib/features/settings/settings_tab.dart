import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/tracking_service.dart';
import '../../state/driver_session.dart';
import '../../widgets/common.dart';
import 'documents_screen.dart';
import 'edit_profile_screen.dart';

const kAppVersion = '1.0.0';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final Future<List<City>> _cities =
      context.read<CatalogRepository>().cities();

  Future<void> _logout() async {
    final l = context.l10n;
    if (!await confirmDialog(context, l.logoutConfirm,
        confirmLabel: l.logout, destructive: true)) {
      return;
    }
    if (!mounted) return;
    final tracking = context.read<TrackingService>();
    final session = context.read<DriverSession>();
    await tracking.goOffline();
    await session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<DriverSession>();
    final settings = context.watch<AppSettings>();
    final profile = session.profile!;
    final driver = session.driver!;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UserAvatar(
                    url: profile.avatarUrl,
                    name: profile.fullName,
                    radius: 32,
                    editable: true,
                    onTap: () => changeAvatar(
                      context,
                      repo: context.read<AvatarRepository>(),
                      userId: profile.id,
                      hasPhoto: profile.avatarUrl != null,
                      onChanged: (url) =>
                          session.setProfile(profile.withAvatar(url)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          JordanPhone.display(profile.phone),
                          textDirection: TextDirection.ltr,
                        ),
                        if (profile.email != null)
                          Text(
                            profile.email!,
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        FutureBuilder<List<City>>(
                          future: _cities,
                          builder: (context, snap) {
                            final city = snap.data
                                ?.where((c) => c.id == profile.cityId)
                                .firstOrNull;
                            return city == null
                                ? const SizedBox.shrink()
                                : Text(city.name(context.lang),
                                    style: context.text.bodySmall);
                          },
                        ),
                      ],
                    ),
                  ),
                  DriverStatusTag(driver: driver),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InfoRow(label: l.vehiclePlate, value: driver.vehiclePlate),
                  InfoRow(
                    label: l.vehicleType,
                    value: vehicleTypeLabel(l, driver.vehicleType),
                  ),
                  InfoRow(label: l.agencyName, value: driver.agencyName),
                  InfoRow(
                    label: l.rating,
                    value: driver.ratingCount == 0
                        ? '-'
                        : '${driver.ratingAvg.toStringAsFixed(1)} (${driver.ratingCount})',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionTitle(l.account),
          Card(
            child: ListTile(
              leading: Icon(Icons.edit_rounded, color: context.accent),
              title: Text(l.editProfile),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      EditProfileScreen(profile: profile, driver: driver),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.badge_rounded, color: context.accent),
              title: Text(l.documentsTitle),
              subtitle: Text(l.documentsSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DocumentsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionTitle(l.preferences),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.language, style: context.text.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'ar', label: Text(l.arabic)),
                      ButtonSegment(value: 'en', label: Text(l.english)),
                    ],
                    selected: {context.lang},
                    onSelectionChanged: (s) =>
                        settings.setLocale(Locale(s.first)),
                  ),
                  const SizedBox(height: 16),
                  Text(l.theme, style: context.text.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                          value: ThemeMode.system, label: Text(l.themeSystem)),
                      ButtonSegment(
                          value: ThemeMode.light, label: Text(l.themeLight)),
                      ButtonSegment(
                          value: ThemeMode.dark, label: Text(l.themeDark)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => settings.setThemeMode(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.bug_report_outlined, color: context.accent),
              title: Text(l.sendDiagnostics),
              subtitle: Text(l.sendDiagnosticsBody),
              isThreeLine: true,
              onTap: () => sendDiagnostics(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded, color: context.accent),
              title: Text(l.aboutApp),
              subtitle: Text(l.version(kAppVersion)),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: Text(l.logout),
          ),
        ],
      ),
    );
  }
}
