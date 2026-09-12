import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../state/staff_session.dart';
import '../../widgets/common.dart';
import '../audit/audit_page.dart';
import '../balances/balances_page.dart';
import '../customers/customers_page.dart';
import '../drivers/drivers_page.dart';
import '../live/live_map_page.dart';
import '../orders/orders_page.dart';
import '../overview/overview_page.dart';
import '../settings/settings_page.dart';
import '../staff/staff_page.dart';

/// Dashboard pages. [ownerOnly] pages are hidden from other roles (the
/// database refuses their writes anyway).
enum AdminPage {
  overview(Icons.space_dashboard_rounded),
  live(Icons.map_rounded),
  orders(Icons.receipt_long_rounded),
  drivers(Icons.local_shipping_rounded),
  customers(Icons.people_alt_rounded),
  balances(Icons.account_balance_wallet_rounded),
  settings(Icons.tune_rounded, ownerOnly: true),
  staff(Icons.badge_rounded, ownerOnly: true),
  audit(Icons.history_rounded);

  const AdminPage(this.icon, {this.ownerOnly = false});
  final IconData icon;
  final bool ownerOnly;

  String label(AppLocalizations l) => switch (this) {
        overview => l.navOverview,
        live => l.navLive,
        orders => l.navOrders,
        drivers => l.navDrivers,
        customers => l.navCustomers,
        balances => l.navBalances,
        settings => l.navSettings,
        staff => l.navStaff,
        audit => l.navAudit,
      };
}

/// Lets any page switch to another (e.g. Overview -> pending distributors).
class AdminNavigator extends InheritedWidget {
  const AdminNavigator({super.key, required this.go, required super.child});

  final void Function(AdminPage page, {DriverStatus? driverFilter}) go;

  static AdminNavigator of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminNavigator>()!;

  @override
  bool updateShouldNotify(AdminNavigator oldWidget) => false;
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminPage _page = AdminPage.overview;
  DriverStatus? _driverFilter;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _go(AdminPage page, {DriverStatus? driverFilter}) {
    setState(() {
      _page = page;
      _driverFilter = driverFilter;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.of(context).pop();
  }

  Widget _content() => switch (_page) {
        AdminPage.overview => const OverviewPage(),
        AdminPage.live => const LiveMapPage(),
        AdminPage.orders => const OrdersPage(),
        AdminPage.drivers => DriversPage(key: ValueKey(_driverFilter), initialStatus: _driverFilter),
        AdminPage.customers => const CustomersPage(),
        AdminPage.balances => const BalancesPage(),
        AdminPage.settings => const SettingsPage(),
        AdminPage.staff => const StaffPage(),
        AdminPage.audit => const AuditPage(),
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<StaffSession>();
    final pages = AdminPage.values.where((p) => !p.ownerOnly || session.role.isOwner).toList();
    if (!pages.contains(_page)) _page = AdminPage.overview;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1100;
    final useRail = width >= 760;

    final rail = NavigationRail(
      extended: wide,
      minExtendedWidth: 220,
      selectedIndex: pages.indexOf(_page),
      onDestinationSelected: (i) => _go(pages[i]),
      labelType: wide ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: wide
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 36),
                  const SizedBox(width: 10),
                  Text(l.appName, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                ],
              )
            : const BrandLogo(size: 36),
      ),
      destinations: [
        for (final p in pages)
          NavigationRailDestination(icon: Icon(p.icon), label: Text(p.label(l))),
      ],
    );

    return AdminNavigator(
      go: _go,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: useRail
            ? null
            : Drawer(
                child: SafeArea(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const BrandLogo(size: 32),
                        title: Text(l.appName, style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      const Divider(),
                      for (final p in pages)
                        ListTile(
                          leading: Icon(p.icon),
                          title: Text(p.label(l)),
                          selected: p == _page,
                          onTap: () => _go(p),
                        ),
                    ],
                  ),
                ),
              ),
        appBar: AppBar(
          title: Text(_page.label(l)),
          actions: [_AccountMenu(session: session), const SizedBox(width: 8)],
        ),
        body: Row(
          children: [
            if (useRail) ...[rail, const VerticalDivider(width: 1)],
            Expanded(child: KeyedSubtree(key: ValueKey(_page), child: _content())),
          ],
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.session});
  final StaffSession session;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.watch<AppSettings>();
    final me = session.me!;
    return PopupMenuButton<String>(
      tooltip: l.account,
      position: PopupMenuPosition.under,
      onSelected: (value) {
        switch (value) {
          case 'ar' || 'en':
            settings.setLocale(Locale(value));
          case 'light':
            settings.setThemeMode(ThemeMode.light);
          case 'dark':
            settings.setThemeMode(ThemeMode.dark);
          case 'system':
            settings.setThemeMode(ThemeMode.system);
          case 'diagnostics':
            sendDiagnostics(context);
          case 'signout':
            session.signOut();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(me.fullName),
            subtitle: Text(me.email ?? ''),
          ),
        ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(value: 'ar', checked: context.lang == 'ar', child: Text(l.arabic)),
        CheckedPopupMenuItem(value: 'en', checked: context.lang == 'en', child: Text(l.english)),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
            value: 'system', checked: settings.themeMode == ThemeMode.system, child: Text(l.themeSystem)),
        CheckedPopupMenuItem(
            value: 'light', checked: settings.themeMode == ThemeMode.light, child: Text(l.themeLight)),
        CheckedPopupMenuItem(
            value: 'dark', checked: settings.themeMode == ThemeMode.dark, child: Text(l.themeDark)),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'diagnostics',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(l.sendDiagnostics),
          ),
        ),
        PopupMenuItem(
          value: 'signout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text(l.signOut, style: const TextStyle(color: AppColors.danger)),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tag(staffRoleLabel(l, me.role), me.role.isOwner ? context.accent : AppColors.info),
            const SizedBox(width: 8),
            UserAvatar(url: null, name: me.fullName, radius: 16),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }
}
