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
                      _ActiveOrderCard(
                        order: o,
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

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.order,
    required this.distance,
    required this.busy,
    required this.onStart,
    required this.onDelivered,
    required this.onRelease,
  });

  final DriverOrder order;
  final double? distance;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onDelivered;
  final VoidCallback onRelease;

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
                UserAvatar(
                  url: order.customerAvatar,
                  name: order.customerName,
                  radius: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (distance != null)
                  Text(Fmt.distance(context, distance!),
                      style: context.text.labelLarge),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${order.serviceName(context.lang)} · '
              '${l.quantityCount(order.quantity)} · '
              '${Fmt.money(context, order.totalPrice)} · '
              '${order.paymentMethod == PaymentMethod.cash ? l.cash : l.card}',
              style: context.text.bodyMedium,
            ),
            if ((order.address ?? '').isNotEmpty || (order.notes ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [order.address, order.notes]
                      .whereType<String>()
                      .where((s) => s.isNotEmpty)
                      .join(' — '),
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
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
    final description = [
      '${order.serviceName(context.lang)} · ${l.quantityCount(order.quantity)}',
      if ((order.address ?? '').isNotEmpty) order.address!,
      if ((order.notes ?? '').isNotEmpty) order.notes!,
    ].join('\n');
    return Opacity(
      opacity: locked ? 0.5 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              UserAvatar(
                url: order.customerAvatar,
                name: order.customerName,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.customerName,
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
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Fmt.money(context, order.totalPrice),
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
