import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/order_repository.dart';
import '../../widgets/common.dart';

/// Placed -> Accepted -> On the way -> Delivered, with timestamps.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});
  final GasOrder order;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = order.status;
    final cancelled = s.isClosedWithoutDelivery;
    final steps = cancelled
        ? [
            (l.stepPlaced, order.createdAt, true, false),
            (l.statusCancelled, order.cancelledAt, true, true),
          ]
        : [
            (l.stepPlaced, order.createdAt, true, false),
            (
              l.stepAccepted,
              order.acceptedAt,
              s == OrderStatus.accepted ||
                  s == OrderStatus.onTheWay ||
                  s == OrderStatus.delivered,
              false,
            ),
            (
              l.stepOnTheWay,
              order.onTheWayAt,
              s == OrderStatus.onTheWay || s == OrderStatus.delivered,
              false,
            ),
            (l.stepDelivered, order.deliveredAt, s == OrderStatus.delivered, false),
          ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _Step(
              label: steps[i].$1,
              time: Fmt.time(context, steps[i].$2),
              done: steps[i].$3,
              error: steps[i].$4,
              first: i == 0,
              last: i == steps.length - 1,
              nextDone: i < steps.length - 1 && steps[i + 1].$3,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.time,
    required this.done,
    required this.error,
    required this.first,
    required this.last,
    required this.nextDone,
  });

  final String label;
  final String time;
  final bool done;
  final bool error;
  final bool first;
  final bool last;
  final bool nextDone;

  @override
  Widget build(BuildContext context) {
    final active = error ? AppColors.danger : AppColors.brand;
    final idle = context.colors.outlineVariant;
    Widget line(bool on) => Expanded(
          child: Container(height: 3, color: on ? active : idle),
        );
    return Column(
      children: [
        Row(
          children: [
            first ? const Spacer() : line(done),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: done ? active : context.colors.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: done ? active : idle, width: 2),
              ),
              child: done
                  ? Icon(
                      error ? Icons.close_rounded : Icons.check_rounded,
                      size: 16,
                      color: error ? Colors.white : AppColors.onBrand,
                    )
                  : null,
            ),
            last ? const Spacer() : line(nextDone),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.text.labelMedium?.copyWith(
            fontWeight: done ? FontWeight.w700 : null,
            color: done ? null : context.colors.onSurfaceVariant,
          ),
        ),
        if (time.isNotEmpty)
          Text(
            time,
            style: context.text.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.order});
  final GasOrder order;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InfoRow(
              label: '${order.serviceName(context.lang)} × ${order.quantity}',
              value: Fmt.money(context, order.unitPrice * order.quantity),
            ),
            InfoRow(
              label: l.deliveryFee,
              value: order.deliveryFee == 0
                  ? l.free
                  : Fmt.money(context, order.deliveryFee),
            ),
            if (order.serviceFee > 0)
              InfoRow(
                label: l.serviceFee,
                value: Fmt.money(context, order.serviceFee),
              ),
            InfoRow(
              label: l.paymentMethod,
              value: paymentMethodLabel(l, order.paymentMethod),
            ),
            if (order.deliveryAddress != null &&
                order.deliveryAddress!.isNotEmpty)
              InfoRow(label: l.deliveryAddress, value: order.deliveryAddress!),
            if (order.notes != null && order.notes!.isNotEmpty)
              InfoRow(label: l.notes, value: order.notes!),
            const Divider(height: 20),
            InfoRow(
              label: l.total,
              value: Fmt.money(context, order.totalPrice),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for 1-5 stars + comment and saves through the `rate_order` RPC.
Future<void> showRatingSheet(BuildContext context, GasOrder order) async {
  final result = await showModalBottomSheet<(int, String)>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _RatingSheet(),
  );
  if (result == null || !context.mounted) return;
  try {
    await context.read<OrderRepository>().rate(order.id, result.$1, result.$2);
    if (context.mounted) showSnack(context, context.l10n.thanksForRating);
  } catch (_) {
    if (context.mounted) {
      showSnack(context, context.l10n.errorGeneric, error: true);
    }
  }
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet();

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 5;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.rateTitle,
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 40,
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(
                    i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(hintText: l.rateHint),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context, (_stars, _comment.text)),
            child: Text(l.submitRating),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.skip),
          ),
        ],
      ),
    );
  }
}

/// Shown after the driver marks the order delivered: the customer confirms
/// receipt (which frees the driver's slot), then is asked to rate.
class ConfirmReceiptView extends StatefulWidget {
  const ConfirmReceiptView({super.key, required this.order});
  final GasOrder order;

  @override
  State<ConfirmReceiptView> createState() => _ConfirmReceiptViewState();
}

class _ConfirmReceiptViewState extends State<ConfirmReceiptView> {
  bool _busy = false;

  Future<void> _confirm() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await context.read<OrderRepository>().confirmDelivery(widget.order.id);
      if (!mounted) return;
      showSnack(context, l.receiptConfirmed);
      if (widget.order.rating == null) await showRatingSheet(context, widget.order);
    } catch (_) {
      if (mounted) showSnack(context, l.errorGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_rounded, size: 48, color: context.accent),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l.confirmReceiptTitle,
          textAlign: TextAlign.center,
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          l.confirmReceiptBody(widget.order.orderNumber),
          textAlign: TextAlign.center,
          style: context.text.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        OrderTimeline(order: widget.order),
        const SizedBox(height: 16),
        OrderSummaryCard(order: widget.order),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : _confirm,
          icon: _busy
              ? const ButtonSpinner()
              : const Icon(Icons.check_circle_rounded),
          label: Text(l.confirmReceipt),
        ),
      ],
    );
  }
}
