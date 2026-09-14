import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../state/staff_session.dart';
import '../../widgets/common.dart';
import '../drivers/driver_detail.dart';
import '../finance/charges.dart';
import '../payments/payments_page.dart';

/// Opens the order inspector; [onChanged] runs after a staff action so the
/// page underneath can refresh.
Future<void> showOrderInspector(BuildContext context, String orderId, {VoidCallback? onChanged}) =>
    showSidePanel(context, builder: (_) => OrderInspector(orderId: orderId, onChanged: onChanged));

/// Everything about one order: parties, money, every status change and who
/// made it, releases, fees booked and staff actions - plus reassign/cancel.
class OrderInspector extends StatelessWidget {
  const OrderInspector({super.key, required this.orderId, this.onChanged});

  final String orderId;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return AsyncView<OrderDetail>(
      load: () => repo.orderDetail(orderId),
      builder: (context, d, reload) => _InspectorBody(
        detail: d,
        onChanged: () async {
          await reload();
          onChanged?.call();
        },
      ),
    );
  }
}

class _InspectorBody extends StatelessWidget {
  const _InspectorBody({required this.detail, required this.onChanged});

  final OrderDetail detail;
  final Future<void> Function() onChanged;

  GasOrder get o => detail.order;

  Future<void> _cancel(BuildContext context) async {
    final l = context.l10n;
    final reason = await askReason(
      context,
      title: l.cancelOrderTitle,
      message: l.cancelOrderMessage,
      confirmLabel: l.cancelOrder,
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => context.read<AdminRepository>().cancelOrder(o.id, reason),
      success: l.orderCancelled,
    );
    if (ok) await onChanged();
  }

  Future<void> _returnToQueue(BuildContext context) async {
    final l = context.l10n;
    final reason = await askReason(context, title: l.returnTitle, message: l.returnMessage, confirmLabel: l.returnToQueue);
    if (reason == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => context.read<AdminRepository>().assignOrder(o.id, null, reason),
      success: l.orderReturned,
    );
    if (ok) await onChanged();
  }

  Future<void> _reassign(BuildContext context) async {
    final l = context.l10n;
    final picked = await showDialog<AdminDriver>(
      context: context,
      builder: (_) => _PickDriverDialog(order: o),
    );
    if (picked == null || !context.mounted) return;
    final reason = await askReason(context, title: l.assignReasonTitle, message: l.assignTo(picked.fullName));
    if (reason == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => context.read<AdminRepository>().assignOrder(o.id, picked.id, reason),
      success: l.orderAssigned,
    );
    if (ok) await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = context.watch<StaffSession>().role;
    final customer = detail.customer;
    final driver = detail.driver;

    return PanelScaffold(
      title: l.orderTitle(o.orderNumber),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OrderStatusTag(o.status),
            Text(Fmt.dateTime(context, o.createdAt), style: context.text.bodySmall),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (role.canOperate && o.status.isOpen) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _reassign(context),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(l.reassign),
                ),
                if (o.status.hasDriver)
                  OutlinedButton.icon(
                    onPressed: () => _returnToQueue(context),
                    icon: const Icon(Icons.undo_rounded),
                    label: Text(l.returnToQueue),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: () => _cancel(context),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l.cancelOrder),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (detail.cancelReason != null) ...[
            _Note(color: AppColors.danger, text: l.cancelReason(detail.cancelReason!)),
            const SizedBox(height: 12),
          ],
          SectionCard(
            title: l.customer,
            child: customer == null
                ? const Text('-')
                : _PersonRow(person: customer),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l.distributor,
            child: driver == null
                ? Text(l.noDistributor)
                : _PersonRow(
                    person: driver,
                    extra: [
                      '${driver.vehiclePlate} · ${vehicleTypeLabel(l, driver.vehicleType)}',
                      l.lastSeen(Fmt.ago(context, driver.locationUpdatedAt)),
                    ],
                    onTap: () => showDriverDetail(context, driver.id, onChanged: onChanged),
                  ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l.items,
            child: Column(
              children: [
                InfoRow(
                  label: l.qtyTimes(o.quantity, o.serviceName(context.lang)),
                  value: Fmt.money(context, o.unitPrice * o.quantity),
                ),
                if (o.deliveryFee > 0) InfoRow(label: l.deliveryFee, value: Fmt.money(context, o.deliveryFee)),
                InfoRow(label: l.serviceFee, value: Fmt.money(context, o.serviceFee)),
                const Divider(),
                InfoRow(label: l.total, value: Fmt.money(context, o.totalPrice), emphasize: true),
                InfoRow(label: l.distributorFee, value: Fmt.money(context, o.driverFee)),
                InfoRow(label: l.payment, value: paymentMethodLabel(l, o.paymentMethod)),
              ],
            ),
          ),
          if (o.paymentMethod == PaymentMethod.wallet) ...[
            const SizedBox(height: 12),
            WalletPaymentSection(orderId: o.id, canOperate: role.canOperate, onChanged: onChanged),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: l.address,
            actions: [
              TextButton.icon(
                onPressed: () => openInMaps(o.deliveryLat, o.deliveryLng),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(l.openInMaps),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.deliveryAddress?.isNotEmpty == true
                    ? o.deliveryAddress!
                    : '${o.deliveryLat.toStringAsFixed(5)}, ${o.deliveryLng.toStringAsFixed(5)}'),
                if (o.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text('${l.notes}: ${o.notes}', style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l.timeline,
            child: Column(
              children: [
                for (final e in detail.events)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Dot(orderStatusColor(e.status), size: 12),
                    title: Text(orderStatusLabel(l, e.status)),
                    subtitle: Text([actorLabel(l, e.actorRole), ?e.actorName].join(' · ')),
                    trailing: Text(Fmt.dateTime(context, e.at), style: context.text.bodySmall),
                  ),
                if (o.customerConfirmedAt != null)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.verified_rounded, size: 18, color: AppColors.brandDeep),
                    title: Text(l.receiptConfirmed),
                    trailing: Text(Fmt.dateTime(context, o.customerConfirmedAt), style: context.text.bodySmall),
                  ),
                if (o.rating != null)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                    title: Text(l.ratingValue(o.rating!)),
                    subtitle: detail.ratingComment == null ? null : Text(detail.ratingComment!),
                  ),
              ],
            ),
          ),
          if (detail.releases.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l.releases,
              child: Column(
                children: [
                  for (final r in detail.releases)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.undo_rounded, size: 18),
                      title: Text(r.driverName ?? '-'),
                      subtitle: r.reason == null ? null : Text(r.reason!),
                      trailing: Text(Fmt.dateTime(context, r.at), style: context.text.bodySmall),
                    ),
                ],
              ),
            ),
          ],
          if (detail.charges.isNotEmpty || (role.canOperate && driver != null)) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l.charges,
              padding: const EdgeInsets.only(bottom: 8),
              actions: [
                if (role.canOperate && driver != null)
                  TextButton.icon(
                    onPressed: () async {
                      if (await raiseCharge(
                        context,
                        driverId: driver.id,
                        driverName: driver.fullName,
                        orderId: o.id,
                        orderNumber: o.orderNumber,
                      )) {
                        await onChanged();
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.chargeDistributor),
                  ),
              ],
              child: detail.charges.isEmpty
                  ? Padding(padding: const EdgeInsets.all(16), child: Text(l.noCharges))
                  : ChargesTable(charges: detail.charges, showDriver: false, onChanged: onChanged),
            ),
          ],
          if (detail.actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l.staffActions,
              child: Column(
                children: [
                  for (final a in detail.actions)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                      title: Text(actionLabel(l, a.action)),
                      subtitle: Text([l.byName(a.actorName ?? '-'), ?a.reason].join(' · ')),
                      trailing: Text(Fmt.dateTime(context, a.createdAt), style: context.text.bodySmall),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: context.text.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
      );
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, this.extra = const [], this.onTap});

  final PersonCard person;
  final List<String> extra;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          UserAvatar(url: person.avatarUrl, name: person.fullName, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(person.fullName,
                          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    if (!person.isActive) ...[const SizedBox(width: 8), Tag(l.blocked, AppColors.danger)],
                  ],
                ),
                SelectableText(Fmt.phone(person.phone), textDirection: TextDirection.ltr),
                for (final line in extra)
                  Text(line, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

/// Approved, active distributors sorted by distance to the order, with
/// their open slots; full ones are shown but can't be picked.
class _PickDriverDialog extends StatelessWidget {
  const _PickDriverDialog({required this.order});
  final GasOrder order;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    return AlertDialog(
      title: Text(l.pickDistributor),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: 520,
        height: 480,
        child: AsyncView<(List<AdminDriver>, ConfigSettings)>(
          load: () async {
            final r = await Future.wait<Object>([
              repo.drivers(status: DriverStatus.approved),
              repo.config(),
            ]);
            return (r[0] as List<AdminDriver>, r[1] as ConfigSettings);
          },
          builder: (context, data, _) {
            final (drivers, config) = data;
            double? km(AdminDriver d) => d.lat == null || d.lng == null
                ? null
                : distanceKm(d.lat!, d.lng!, order.deliveryLat, order.deliveryLng);
            final list = drivers.where((d) => d.isActive).toList()
              ..sort((a, b) => (km(a) ?? 1e9).compareTo(km(b) ?? 1e9));
            if (list.isEmpty) {
              return EmptyState(icon: Icons.local_shipping_outlined, title: l.noEligibleDrivers);
            }
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final d = list[i];
                final distance = km(d);
                final current = d.id == order.driverId;
                final full = d.openOrders >= config.maxActiveOrders;
                return ListTile(
                  enabled: !current && !full,
                  leading: UserAvatar(url: d.avatarUrl, name: d.fullName, radius: 18),
                  title: Text(d.fullName),
                  subtitle: Text([
                    d.vehiclePlate,
                    l.cylindersShort(d.cylindersOnBoard),
                    l.slots(d.openOrders, config.maxActiveOrders),
                    distance == null ? l.locationUnknown : l.kmAway(distance.toStringAsFixed(1)),
                  ].join(' · ')),
                  trailing: current
                      ? Tag(l.currentDriver, AppColors.info)
                      : full
                          ? Tag(l.full, AppColors.danger)
                          : Dot(d.isOnline ? AppColors.brandDeep : Colors.grey,
                              tooltip: d.isOnline ? l.online : l.offline),
                  onTap: () => Navigator.pop(context, d),
                );
              },
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel))],
    );
  }
}
