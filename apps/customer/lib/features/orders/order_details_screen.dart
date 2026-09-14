import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/order_repository.dart';
import '../../state/my_orders_controller.dart';
import '../../widgets/common.dart';
import 'order_widgets.dart';
import 'reorder.dart';

/// Reads the order from the live list, so it updates in real time too.
class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.onTrack,
  });

  final String orderId;
  final VoidCallback onTrack;

  Future<void> _cancel(BuildContext context, GasOrder order) async {
    final l = context.l10n;
    if (!await confirmDialog(context, l.cancelOrderConfirm,
        confirmLabel: l.cancelOrder, destructive: true)) {
      return;
    }
    if (!context.mounted) return;
    try {
      await context.read<OrderRepository>().cancel(order.id);
      if (context.mounted) showSnack(context, l.orderCancelled);
    } catch (_) {
      if (context.mounted) showSnack(context, l.errorGeneric, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final order = context.watch<MyOrdersController>().byId(orderId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          order == null ? l.orderDetails : l.orderNumber(order.orderNumber),
        ),
      ),
      body: order == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Fmt.dateTime(context, order.createdAt),
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    StatusChip(order.status),
                  ],
                ),
                const SizedBox(height: 20),
                SectionTitle(l.orderTimeline),
                OrderTimeline(order: order),
                const SizedBox(height: 20),
                OrderSummaryCard(order: order),
                const SizedBox(height: 16),
                if (order.rating != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.star_rounded,
                          color: AppColors.warning),
                      title: Text(l.yourRating),
                      trailing: RatingStars(
                        value: order.rating!.toDouble(),
                        size: 20,
                      ),
                    ),
                  ),
                if (order.status == OrderStatus.expired) ...[
                  Card(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    child: ListTile(
                      leading: const Icon(Icons.timer_off_rounded, color: AppColors.warning),
                      title: Text(l.expiredTitle),
                      subtitle: Text(l.expiredBody),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () async {
                      if (await reorder(context, order) && context.mounted) {
                        Navigator.of(context).pop();
                        onTrack();
                      }
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(l.orderAgain),
                  ),
                ],
                if (order.status.isOpen) ...[
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onTrack();
                    },
                    icon: const Icon(Icons.map_rounded),
                    label: Text(l.trackIt),
                  ),
                  if (order.status == OrderStatus.pending) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      onPressed: () => _cancel(context, order),
                      icon: const Icon(Icons.close_rounded),
                      label: Text(l.cancelOrder),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}
