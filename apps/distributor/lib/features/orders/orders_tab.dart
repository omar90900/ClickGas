import 'dart:async';

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/driver_repository.dart';
import '../../data/tracking_service.dart';
import '../../state/active_orders_controller.dart';
import '../../state/driver_session.dart';
import '../../widgets/common.dart';

/// My accepted orders on top (max 3), nearby pending orders below.
class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  static const _pollEvery = Duration(seconds: 10);

  Timer? _poll;
  List<NearbyOrder> _nearby = const [];
  bool _loadingNearby = false;
  String? _busyId;

  /// Order ids already seen, to notify only about new nearby orders
  /// (null until the first successful load, which never notifies).
  Set<String>? _seenIds;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(_pollEvery, (_) => _loadNearby());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNearby());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _loadNearby() async {
    if (!mounted) return;
    final tracking = context.read<TrackingService>();
    final p = tracking.position;
    if (!tracking.isOnline || p == null) {
      if (_nearby.isNotEmpty) setState(() => _nearby = const []);
      return;
    }
    setState(() => _loadingNearby = true);
    final l = context.l10n;
    try {
      final list =
          await context.read<DriverRepository>().nearby(p.latitude, p.longitude);
      // Sound + notification for orders that weren't in the previous poll.
      final seen = _seenIds;
      final fresh = seen == null
          ? const <NearbyOrder>[]
          : list.where((o) => !seen.contains(o.id)).toList();
      _seenIds = {...?seen, ...list.map((o) => o.id)};
      if (mounted && fresh.isNotEmpty) {
        final o = fresh.first;
        NotificationService.instance.show(
          l.notifNewOrderTitle,
          l.notifNewOrderBody(
            o.customerName,
            Fmt.distance(context, o.distanceM),
            l.quantityCount(o.quantity),
          ),
        );
      }
      if (mounted) setState(() => _nearby = list);
    } catch (e) {
      debugPrint('Nearby orders failed: $e');
    } finally {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      context.read<ActiveOrdersController>().refresh(),
      _loadNearby(),
    ]);
  }

  /// Runs an order action, then refreshes both lists and the driver row
  /// (a delivery lowers the cylinder count).
  Future<void> _run(String orderId, Future<void> Function() action,
      {String? success}) async {
    final l = context.l10n;
    final maxOrders = context.read<AppConfig>().maxActiveOrders;
    final session = context.read<DriverSession>();
    setState(() => _busyId = orderId);
    try {
      await action();
      if (mounted && success != null) showSnack(context, success);
    } on AppFailure catch (f) {
      if (mounted) {
        showSnack(context, failureText(context, f, maxOrders: maxOrders),
            error: true);
      }
    } catch (_) {
      if (mounted) showSnack(context, l.errorGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
      await _refreshAll();
      await session.refreshDriver();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final driver = context.watch<DriverSession>().driver!;
    final tracking = context.watch<TrackingService>();
    final active = context.watch<ActiveOrdersController>();
    final config = context.watch<AppConfig>();
    final repo = context.read<DriverRepository>();
    final wallets = context.read<WalletRepository>();
    final me = tracking.position;
    final full = active.count >= config.maxActiveOrders;

    double? distanceTo(double lat, double lng) => me == null
        ? null
        : LocationService.distanceMeters(me.latitude, me.longitude, lat, lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabOrders),
        actions: [
          IconButton(
            onPressed: _refreshAll,
            icon: _loadingNearby || active.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: !driver.isVerified
          ? Center(
              child: EmptyState(
                icon: Icons.hourglass_top_rounded,
                title: l.pendingApprovalTitle,
                message: l.pendingApprovalBody,
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (active.count > 0) ...[
                    SectionTitle(
                      l.myActiveOrders(active.count, config.maxActiveOrders),
                    ),
                    for (final o in active.orders) ...[
                      _PaymentWatch(
                        key: ValueKey(o.id),
                        orderId: o.paymentMethod == PaymentMethod.wallet ? o.id : null,
                        builder: (payment) => _ActiveOrderCard(
                          order: o,
                          payment: payment,
                          distance: distanceTo(o.lat, o.lng),
                          busy: _busyId == o.id,
                          onStart: () => _run(o.id, () => repo.startDelivery(o.id)),
                          onDelivered: () async {
                            if (await confirmDialog(context, l.markDeliveredConfirm,
                                confirmLabel: l.markDelivered)) {
                              await _run(o.id, () => repo.complete(o.id));
                            }
                          },
                          onRelease: () async {
                            if (await confirmDialog(context, l.releaseOrderConfirm,
                                confirmLabel: l.releaseOrder, destructive: true)) {
                              await _run(o.id, () => repo.release(o.id),
                                  success: l.orderReleased);
                            }
                          },
                          onConfirmPayment: () async {
                            if (await confirmDialog(
                                context, l.confirmPaymentConfirm(Fmt.money(context, o.totalPrice)),
                                confirmLabel: l.paymentReceived)) {
                              await _run(o.id, () => wallets.confirmPayment(o.id),
                                  success: l.paymentConfirmedSnack);
                            }
                          },
                          onCashPayment: () async {
                            if (await confirmDialog(context, l.cashInsteadConfirm,
                                confirmLabel: l.paidInCashInstead)) {
                              await _run(o.id, () => wallets.confirmPayment(o.id, inCash: true),
                                  success: l.paymentConfirmedSnack);
                            }
                          },
                          onDisputePayment: () async {
                            final note = await _askNote(context);
                            if (note != null) {
                              await _run(o.id, () => wallets.disputePayment(o.id, note));
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                  ],
                  SectionTitle(l.nearbyOrders(Fmt.km(config.driverRadiusKm))),
                  if (!tracking.isOnline)
                    EmptyState(
                      icon: Icons.wifi_tethering_off_rounded,
                      title: l.goOnlineToSeeOrders,
                      message: l.goOnlineToSeeOrdersBody(
                        Fmt.km(config.driverRadiusKm),
                      ),
                    )
                  else if (_nearby.isEmpty)
                    EmptyState(
                      icon: Icons.inbox_rounded,
                      title: l.noNearbyOrders,
                      message: l.noNearbyOrdersBody,
                    )
                  else ...[
                    if (full)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded,
                                color: AppColors.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l.maxOrdersReached(config.maxActiveOrders),
                                style: context.text.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final n in _nearby) ...[
                      _NearbyOrderCard(
                        order: n,
                        locked: full,
                        busy: _busyId == n.id,
                        onAccept: () => _run(n.id, () => repo.accept(n.id),
                            success: l.orderAccepted),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

/// Streams a wallet order's payment for its card; [orderId] is null for cash
/// orders.
class _PaymentWatch extends StatefulWidget {
  const _PaymentWatch({super.key, required this.orderId, required this.builder});

  final String? orderId;
  final Widget Function(OrderPayment? payment) builder;

  @override
  State<_PaymentWatch> createState() => _PaymentWatchState();
}

class _PaymentWatchState extends State<_PaymentWatch> {
  late final Stream<OrderPayment?>? _stream = widget.orderId == null
      ? null
      : context.read<WalletRepository>().watchPayment(widget.orderId!);

  @override
  Widget build(BuildContext context) => _stream == null
      ? widget.builder(null)
      : StreamBuilder<OrderPayment?>(
          stream: _stream,
          builder: (context, snap) => widget.builder(snap.data),
        );
}

/// "Not received": what the distributor sees in their wallet (3+ characters).
Future<String?> _askNote(BuildContext context) {
  final l = context.l10n;
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.disputeTitle),
      content: Form(
        key: form,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(hintText: l.disputeHint),
          validator: (v) => (v ?? '').trim().length < 3 ? l.walletNoteRequired : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) Navigator.pop(ctx, controller.text.trim());
          },
          child: Text(l.paymentNotReceived),
        ),
      ],
    ),
  );
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.order,
    required this.payment,
    required this.distance,
    required this.busy,
    required this.onStart,
    required this.onDelivered,
    required this.onRelease,
    required this.onConfirmPayment,
    required this.onCashPayment,
    required this.onDisputePayment,
  });

  final DriverOrder order;
  final OrderPayment? payment;
  final double? distance;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onDelivered;
  final VoidCallback onRelease;
  final VoidCallback onConfirmPayment;
  final VoidCallback onCashPayment;
  final VoidCallback onDisputePayment;

  /// A wallet order is handed over only once its payment is confirmed.
  bool get _unpaid =>
      order.paymentMethod == PaymentMethod.wallet && !(payment?.status.isSettled ?? false);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final statusColor = switch (order.status) {
      OrderStatus.onTheWay => AppColors.info,
      OrderStatus.delivered => AppColors.warning,
      _ => context.accent,
    };
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.orderNumber(order.orderNumber),
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Tag(orderStatusLabel(l, order.status), statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ServiceBadge(serviceCode: order.serviceCode),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.serviceName(context.lang)} × ${order.quantity}',
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        order.customerName,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (distance != null)
                  Text(Fmt.distance(context, distance!),
                      style: context.text.labelLarge),
              ],
            ),
            const SizedBox(height: 10),
            OrderFactRow(
              icon: Icons.payments_rounded,
              text: '${Fmt.money(context, order.totalPrice)} · '
                  '${paymentMethodLabel(l, order.paymentMethod)}',
              emphasize: true,
            ),
            if ((order.address ?? '').isNotEmpty)
              OrderFactRow(
                icon: Icons.place_rounded,
                text: order.address!,
              ),
            if ((order.notes ?? '').isNotEmpty)
              CustomerNote(note: order.notes!),
            if (order.paymentMethod == PaymentMethod.wallet)
              _WalletPaymentBox(
                payment: payment,
                amount: order.totalPrice,
                busy: busy,
                onConfirm: onConfirmPayment,
                onCash: onCashPayment,
                onDispute: onDisputePayment,
              ),
            const SizedBox(height: 12),
            if (order.awaitingConfirmation)
              Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(l.awaitingConfirmation, style: context.text.bodyMedium),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: order.customerPhone.isEmpty
                          ? null
                          : () => callPhone(order.customerPhone),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text(l.call),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: () => openNavigation(order.lat, order.lng),
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: Text(l.navigate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    onPressed: busy ? null : onRelease,
                    child: Text(l.releaseOrder),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: busy
                          ? null
                          : order.status == OrderStatus.accepted
                              ? onStart
                              : _unpaid
                                  ? null
                                  : onDelivered,
                      icon: busy
                          ? const ButtonSpinner()
                          : Icon(order.status == OrderStatus.accepted
                              ? Icons.play_arrow_rounded
                              : Icons.task_alt_rounded),
                      label: Text(order.status == OrderStatus.accepted
                          ? l.startDelivery
                          : l.markDelivered),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NearbyOrderCard extends StatelessWidget {
  const _NearbyOrderCard({
    required this.order,
    required this.locked,
    required this.busy,
    required this.onAccept,
  });

  final NearbyOrder order;
  final bool locked;
  final bool busy;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Opacity(
      opacity: locked ? 0.5 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceBadge(serviceCode: order.serviceCode),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${order.serviceName(context.lang)} × ${order.quantity}',
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tag(Fmt.distance(context, order.distanceM), context.accent),
                      ],
                    ),
                    Text(
                      order.customerName,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OrderFactRow(
                      icon: Icons.payments_rounded,
                      text: '${Fmt.money(context, order.totalPrice)} · '
                          '${paymentMethodLabel(l, order.paymentMethod)}',
                      emphasize: true,
                    ),
                    if ((order.address ?? '').isNotEmpty)
                      OrderFactRow(
                        icon: Icons.place_rounded,
                        text: order.address!,
                      ),
                    if ((order.notes ?? '').isNotEmpty)
                      CustomerNote(note: order.notes!),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(88, 46)),
                onPressed: locked || busy ? null : onAccept,
                child: busy
                    ? const ButtonSpinner()
                    : locked
                        ? const Icon(Icons.lock_rounded)
                        : Text(l.accept),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wallet order: pay-on-arrival reminder, what the customer said, and the
/// distributor's answer. "Mark delivered" stays off until this is settled.
class _WalletPaymentBox extends StatelessWidget {
  const _WalletPaymentBox({
    required this.payment,
    required this.amount,
    required this.busy,
    required this.onConfirm,
    required this.onCash,
    required this.onDispute,
  });

  final OrderPayment? payment;
  final double amount;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onCash;
  final VoidCallback onDispute;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = payment?.status;
    final (color, icon, text) = switch (status) {
      PaymentStatus.confirmed => (context.accent, Icons.verified_rounded, l.paymentConfirmedDone),
      PaymentStatus.cash => (context.accent, Icons.payments_rounded, l.paymentCashDone),
      PaymentStatus.claimed => (AppColors.warning, Icons.account_balance_wallet_rounded, l.paymentClaimedHint),
      PaymentStatus.disputed => (AppColors.danger, Icons.report_gmailerrorred_rounded, l.paymentDisputedWait),
      _ => (AppColors.info, Icons.account_balance_wallet_rounded, l.payOnArrivalHint(Fmt.money(context, amount))),
    };
    final open = status != null && !status.isSettled;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(text, style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (payment?.reference != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 4),
              child: Text(l.paymentReferenceValue(payment!.reference!), style: context.text.bodySmall),
            ),
          if (open) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton.tonalIcon(
                  onPressed: busy ? null : onConfirm,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(l.paymentReceived),
                ),
                if (status == PaymentStatus.claimed)
                  OutlinedButton(
                    onPressed: busy ? null : onDispute,
                    child: Text(l.paymentNotReceived),
                  ),
                TextButton(
                  onPressed: busy ? null : onCash,
                  child: Text(l.paidInCashInstead),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
