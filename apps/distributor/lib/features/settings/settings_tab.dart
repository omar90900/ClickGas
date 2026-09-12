import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/tracking_service.dart';
import '../../state/driver_session.dart';
import '../../widgets/common.dart';
import 'change_password_screen.dart';
import 'documents_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';

const kAppVersion = '1.0.0';

/// Keeps phone numbers left-to-right inside Arabic text.
String _ltr(String s) =>
    '${String.fromCharCode(0x2066)}$s${String.fromCharCode(0x2069)}';

/// Profile and settings: account status and stats, vehicle, documents,
/// notifications, appearance, help, and sign-out.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  List<City> _cities = const [];
  Future<OrderCounts>? _counts;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    context.read<CatalogRepository>().cities().then((list) {
      if (mounted) setState(() => _cities = list);
    }).catchError((Object _) {});
  }

  void _refresh() {
    final id = context.read<DriverSession>().profile?.id;
    if (id == null) return;
    _counts = context.read<ProfileRepository>().orderCounts(id, asDriver: true);
    context.read<NotificationsRepository>().unreadCount().then((n) {
      if (mounted) setState(() => _unread = n);
    }).catchError((Object _) {});
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(_refresh);
  }

  void _changePhoto(Profile profile) {
    final session = context.read<DriverSession>();
    changeAvatar(
      context,
      repo: context.read<AvatarRepository>(),
      userId: profile.id,
      hasPhoto: profile.avatarUrl != null,
      onChanged: (url) => session.setProfile(profile.withAvatar(url)),
    );
  }

  Future<void> _setPreference(Future<void> Function() change) async {
    try {
      await change();
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e), error: true);
    }
  }

  Future<void> _pickLanguage(AppSettings settings) async {
    final l = context.l10n;
    final current = context.lang;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (code, label) in [('ar', l.arabic), ('en', l.english)])
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: code == current
                    ? Icon(Icons.check_circle_rounded, color: sheet.accent)
                    : null,
                onTap: () => Navigator.of(sheet).pop(code),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) await settings.setLocale(Locale(picked));
  }

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
    final supportPhone = context.watch<AppConfig>().supportPhone;
    final profile = session.profile!;
    final driver = session.driver!;
    final city = _cities.where((c) => c.id == profile.cityId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
        actions: [
          IconButton(
            tooltip: l.notificationsTitle,
            onPressed: () => _open(const NotificationsScreen()),
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text('$_unread'),
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_refresh);
          await Future.wait([
            session.refreshDriver(),
            if (_counts != null) _counts!.catchError((Object _) => const OrderCounts()),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            FutureBuilder<OrderCounts>(
              future: _counts,
              builder: (context, snap) => ProfileHeader(
                avatar: UserAvatar(
                  url: profile.avatarUrl,
                  name: profile.fullName,
                  radius: 46,
                  editable: true,
                  onTap: () => _changePhoto(profile),
                ),
                name: profile.fullName,
                lines: [
                  _ltr(JordanPhone.display(profile.phone)),
                  [
                    if (driver.agencyName.isNotEmpty) driver.agencyName,
                    if (city != null) city.name(context.lang),
                  ].join(' · '),
                ],
                badge: DriverStatusTag(driver: driver),
                onEdit: () => _open(EditProfileScreen(profile: profile, driver: driver)),
                editLabel: l.editProfile,
                stats: [
                  ProfileStat(
                    label: l.statDeliveries,
                    value: '${snap.data?.delivered ?? '–'}',
                  ),
                  ProfileStat(
                    label: l.rating,
                    icon: Icons.star_rounded,
                    value: driver.ratingCount == 0 ? '–' : driver.ratingAvg.toStringAsFixed(1),
                  ),
                  ProfileStat(label: l.statOnBoard, value: '${driver.cylindersOnBoard}'),
                ],
              ),
            ),
            SettingsGroup(
              title: l.account,
              children: [
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: l.personalInfo,
                  subtitle: profile.email,
                  onTap: () => _open(EditProfileScreen(profile: profile, driver: driver)),
                ),
                SettingsTile(
                  icon: Icons.badge_outlined,
                  title: l.documentsTitle,
                  subtitle: l.documentsSubtitle,
                  onTap: () => _open(const DocumentsScreen()),
                ),
                SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: l.changePassword,
                  onTap: () => _open(const ChangePasswordScreen()),
                ),
              ],
            ),
            SettingsGroup(
              title: l.vehicleInfo,
              children: [
                SettingsTile(
                  icon: Icons.pin_outlined,
                  title: l.vehiclePlate,
                  value: driver.vehiclePlate.isEmpty ? '–' : _ltr(driver.vehiclePlate),
                ),
                SettingsTile(
                  icon: Icons.local_shipping_outlined,
                  title: l.vehicleType,
                  value: vehicleTypeLabel(l, driver.vehicleType),
                ),
                SettingsTile(
                  icon: Icons.storefront_outlined,
                  title: l.agencyName,
                  value: driver.agencyName.isEmpty ? '–' : driver.agencyName,
                ),
              ],
            ),
            SettingsGroup(
              title: l.notificationsTitle,
              footer: PushService.instance.available ? l.notifPushOn : l.notifPushOff,
              children: [
                SettingsSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: l.notifNewOrders,
                  subtitle: l.notifNewOrdersBody,
                  value: profile.notifyNewOrders,
                  onChanged: (v) => _setPreference(() => session.setNotificationPrefs(newOrders: v)),
                ),
                SettingsSwitchTile(
                  icon: Icons.assignment_outlined,
                  title: l.notifOrderUpdates,
                  subtitle: l.notifOrderUpdatesBody,
                  value: profile.notifyOrderUpdates,
                  onChanged: (v) => _setPreference(() => session.setNotificationPrefs(orderUpdates: v)),
                ),
              ],
            ),
            SettingsGroup(
              title: l.appearance,
              children: [
                ThemeModePicker(
                  value: settings.themeMode,
                  onChanged: settings.setThemeMode,
                  systemLabel: l.themeSystem,
                  lightLabel: l.themeLight,
                  darkLabel: l.themeDark,
                ),
                SettingsTile(
                  icon: Icons.translate_rounded,
                  title: l.language,
                  value: context.lang == 'ar' ? l.arabic : l.english,
                  onTap: () => _pickLanguage(settings),
                ),
              ],
            ),
            SettingsGroup(
              title: l.helpSupport,
              children: [
                if (supportPhone != null && supportPhone.isNotEmpty)
                  SettingsTile(
                    icon: Icons.support_agent_rounded,
                    title: l.contactSupport,
                    value: _ltr(supportPhone),
                    onTap: () => launchUrl(Uri(scheme: 'tel', path: supportPhone)),
                  ),
                SettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: l.sendDiagnostics,
                  subtitle: l.sendDiagnosticsBody,
                  onTap: () => sendDiagnostics(context),
                ),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: l.aboutApp,
                  value: l.version(kAppVersion),
                ),
              ],
            ),
            SettingsGroup(
              children: [
                SettingsTile(
                  icon: Icons.logout_rounded,
                  title: l.logout,
                  destructive: true,
                  onTap: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
