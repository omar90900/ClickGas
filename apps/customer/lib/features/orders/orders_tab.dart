import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../state/my_orders_controller.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';
import 'order_details_screen.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

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
        itemCount: c.orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final order = c.orders[i];
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
