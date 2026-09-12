import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../state/my_orders_controller.dart';
import '../../widgets/common.dart';
import '../home/home_tab.dart';
import '../orders/orders_tab.dart';
import '../settings/settings_tab.dart';
import '../tracking/tracking_tab.dart';

/// Lets any tab switch to another (e.g. "Order gas" on the empty tracking
/// screen, or jumping to tracking right after placing an order).
class ShellTabs extends ChangeNotifier {
  static const home = 0, tracking = 1, orders = 2, settings = 3;

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
  late final MyOrdersController _orders = context.read<MyOrdersController>();
  Map<String, OrderStatus>? _lastStatuses;

  @override
  void initState() {
    super.initState();
    _orders.addListener(_onOrdersChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermission();
      _onOrdersChanged();
    });
  }

  @override
  void dispose() {
    _orders.removeListener(_onOrdersChanged);
    super.dispose();
  }

  /// Sound + notification whenever one of the customer's orders changes
  /// status (accepted, on the way, delivered, dropped by the driver,
  /// expired because nobody accepted it).
  void _onOrdersChanged() {
    if (!mounted || _orders.loading || _orders.error != null) return;
    final now = {for (final o in _orders.orders) o.id: o.status};
    final before = _lastStatuses;
    _lastStatuses = now;
    if (before == null) return; // first load: nothing new happened

    final l = context.l10n;
    for (final o in _orders.orders) {
      final was = before[o.id];
      if (was == null || was == o.status) continue;
      final (title, body) = switch (o.status) {
        OrderStatus.accepted => (l.notifAcceptedTitle, l.notifAcceptedBody(o.orderNumber)),
        OrderStatus.onTheWay => (l.notifOnTheWayTitle, l.notifOnTheWayBody(o.orderNumber)),
        OrderStatus.delivered => (l.notifDeliveredTitle, l.notifDeliveredBody(o.orderNumber)),
        OrderStatus.pending when was.hasDriver =>
          (l.notifReleasedTitle, l.notifReleasedBody(o.orderNumber)),
        OrderStatus.expired => (l.notifExpiredTitle, l.notifExpiredBody(o.orderNumber)),
        _ => (null, null),
      };
      if (title != null && body != null) {
        NotificationService.instance.show(title, body);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tabs = context.watch<ShellTabs>();
    final hasOpenOrder = context.select<MyOrdersController, bool>(
        (c) => c.openOrder != null || c.awaitingConfirmation != null);

    return Scaffold(
      body: IndexedStack(
        index: tabs.index,
        children: const [HomeTab(), TrackingTab(), OrdersTab(), SettingsTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.index,
        onDestinationSelected: tabs.go,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l.tabHome,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: hasOpenOrder,
              smallSize: 9,
              child: const Icon(Icons.map_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: hasOpenOrder,
              smallSize: 9,
              child: const Icon(Icons.map_rounded),
            ),
            label: l.tabTracking,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: l.tabOrders,
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
