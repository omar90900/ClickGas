import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/active_orders_controller.dart';
import '../../widgets/common.dart';
import '../home/home_tab.dart';
import '../orders/orders_tab.dart';
import '../sales/sales_tab.dart';
import '../settings/settings_tab.dart';

class ShellTabs extends ChangeNotifier {
  static const home = 0, orders = 1, sales = 2, settings = 3;

  int _index = home;
  int get index => _index;

  void go(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShellTabs(),
      child: const _ShellView(),
    );
  }
}

class _ShellView extends StatefulWidget {
  const _ShellView();

  @override
  State<_ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<_ShellView> {
  late final ActiveOrdersController _active =
      context.read<ActiveOrdersController>();

  @override
  void initState() {
    super.initState();
    _active.onCustomerConfirmed = (order) {
      if (!mounted) return;
      final l = context.l10n;
      NotificationService.instance.show(
        l.notifConfirmedTitle,
        l.notifConfirmedBody(order.orderNumber),
      );
    };
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => NotificationService.instance.requestPermission(),
    );
  }

  @override
  void dispose() {
    _active.onCustomerConfirmed = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tabs = context.watch<ShellTabs>();
    final active = context.select<ActiveOrdersController, int>((c) => c.count);

    return Scaffold(
      body: IndexedStack(
        index: tabs.index,
        children: const [HomeTab(), OrdersTab(), SalesTab(), SettingsTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.index,
        onDestinationSelected: tabs.go,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map_rounded),
            label: l.tabHome,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: active > 0,
              label: Text('$active'),
              child: const Icon(Icons.assignment_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: active > 0,
              label: Text('$active'),
              child: const Icon(Icons.assignment_rounded),
            ),
            label: l.tabOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: l.tabSales,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l.tabSettings,
          ),
        ],
      ),
    );
  }
}
