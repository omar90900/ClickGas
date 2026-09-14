import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../state/my_orders_controller.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';
import 'order_details_screen.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  Future<CustomerOrderStats>? _stats;
  int _lastDelivered = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload the totals whenever another order has been delivered.
    final delivered = context
        .watch<MyOrdersController>()
        .orders
        .where((o) => o.status == OrderStatus.delivered)
        .length;
    if (_stats == null || delivered != _lastDelivered) {
      _lastDelivered = delivered;
      _stats = context.read<ProfileRepository>().myOrderStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.watch<MyOrdersController>();
    final tabs = context.read<ShellTabs>();

    final Widget body;
    if (c.loading) {
      body = const LoadingView();
    } else if (c.error != null) {
      body = ErrorView(onRetry: c.retry);
    } else if (c.orders.isEmpty) {
      body = EmptyState(
        icon: Icons.receipt_long_rounded,
        title: l.noOrdersTitle,
        message: l.noOrdersBody,
        action: FilledButton.icon(
          onPressed: () => tabs.go(ShellTabs.home),
          icon: const Icon(Icons.propane_tank_rounded),
          label: Text(l.orderGasCta),
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: c.orders.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return FutureBuilder<CustomerOrderStats>(
              future: _stats,
              builder: (context, snap) => _DeliveredStatsCard(stats: snap.data),
            );
          }
          final order = c.orders[i - 1];
          return _OrderTile(
            order: order,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(
                  orderId: order.id,
                  onTrack: () => tabs.go(ShellTabs.tracking),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.tabOrders)),
      body: body,
    );
  }
}

/// Cylinders received and money paid for delivered orders, this month and this
/// year. The delivery fee is left out: this is what the gas itself cost.
class _DeliveredStatsCard extends StatelessWidget {
  const _DeliveredStatsCard({required this.stats});
  final CustomerOrderStats? stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Period(
                label: l.statsThisMonth,
                cylinders: stats?.monthCylinders,
                paid: stats?.monthPaid,
              ),
            ),
            Container(
              width: 1,
              height: 46,
              color: context.colors.outlineVariant,
            ),
            Expanded(
              child: _Period(
                label: l.statsThisYear,
                cylinders: stats?.yearCylinders,
                paid: stats?.yearPaid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Period extends StatelessWidget {
  const _Period({
    required this.label,
    required this.cylinders,
    required this.paid,
  });

  final String label;
  final int? cylinders;
  final double? paid;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          paid == null ? '–' : Fmt.money(context, paid!),
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: context.accent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          cylinders == null ? '–' : l.statsCylindersCount(cylinders!),
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});
  final GasOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: context.colors.primaryContainer,
                foregroundColor: context.accent,
                child: Icon(serviceIcon(
                  order.serviceCode == 'new_cylinder' ? 'new' : 'exchange',
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.serviceName(context.lang)} × ${order.quantity}',
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l.orderNumber(order.orderNumber)} · '
                      '${Fmt.dateTime(context, order.createdAt)}',
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Fmt.money(context, order.totalPrice),
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusChip(order.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
