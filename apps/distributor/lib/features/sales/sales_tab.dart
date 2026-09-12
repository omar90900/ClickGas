import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/driver_repository.dart';
import '../../state/active_orders_controller.dart';
import '../../state/driver_session.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

class _Entry {
  final int orderNumber;
  final String serviceName;
  final int quantity;
  final double amount;
  final DateTime? at;
  final bool delivered;
  const _Entry(this.orderNumber, this.serviceName, this.quantity, this.amount,
      this.at, this.delivered);
}

class _Sales {
  final List<GasOrder> delivered;
  final List<OrderRelease> releases;
  final List<DriverCharge> charges;
  const _Sales(this.delivered, this.releases, this.charges);
}

/// Charges from the team, delivered and cancelled orders, daily / monthly
/// totals.
class SalesTab extends StatefulWidget {
  const SalesTab({super.key});

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  Future<_Sales>? _data;
  int? _lastTab;
  int? _lastActive;

  Future<_Sales> _load() {
    final id = context.read<DriverSession>().driver!.id;
    final repo = context.read<DriverRepository>();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    return (
      repo.deliveredSince(id, monthStart),
      repo.releasesSince(id, monthStart),
      repo.charges(id),
    ).wait.then((r) => _Sales(r.$1, r.$2, r.$3));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when the tab is opened or an order leaves the active list.
    final tab = context.watch<ShellTabs>().index;
    final active = context.watch<ActiveOrdersController>().count;
    if (_data == null ||
        (tab == ShellTabs.sales && tab != _lastTab) ||
        (active != _lastActive && _lastActive != null)) {
      _data = _load();
    }
    _lastTab = tab;
    _lastActive = active;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.salesTitle)),
      body: FutureBuilder<_Sales>(
        future: _data,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: failureText(context, snap.error!),
                action: OutlinedButton(
                  onPressed: () => setState(() => _data = _load()),
                  child: Text(l.retry),
                ),
              ),
            );
          }
          if (!snap.hasData) return const LoadingView();
          final sales = snap.data!;
          final now = DateTime.now();
          final today = sales.delivered
              .where((o) => DateUtils.isSameDay(o.deliveredAt, now))
              .toList();
          final lang = context.lang;
          final entries = <_Entry>[
            for (final o in sales.delivered)
              _Entry(o.orderNumber, o.serviceName(lang), o.quantity,
                  o.totalPrice, o.deliveredAt, true),
            for (final r in sales.releases)
              _Entry(r.orderNumber, r.serviceName(lang), r.quantity,
                  r.totalPrice, r.createdAt, false),
          ]..sort((a, b) =>
              (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _data = _load());
              await _data;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (sales.charges.isNotEmpty) ...[
                  _ChargesCard(charges: sales.charges),
                  const SizedBox(height: 12),
                ],
                _StatsCard(title: l.today, orders: today),
                const SizedBox(height: 12),
                _StatsCard(title: l.thisMonth, orders: sales.delivered),
                const SizedBox(height: 16),
                SectionTitle(l.salesLog),
                if (entries.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: l.noSales,
                    message: l.noSalesBody,
                  )
                else
                  for (final e in entries) ...[
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (e.delivered
                                  ? AppColors.brand
                                  : AppColors.danger)
                              .withValues(alpha: 0.15),
                          foregroundColor:
                              e.delivered ? context.accent : AppColors.danger,
                          child: Icon(e.delivered
                              ? Icons.task_alt_rounded
                              : Icons.close_rounded),
                        ),
                        title: Text(
                          '${l.orderNumber(e.orderNumber)} · ${l.quantityCount(e.quantity)}',
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${e.serviceName}\n${Fmt.dateTime(context, e.at)}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Fmt.money(context, e.amount),
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                decoration: e.delivered
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Tag(
                              e.delivered ? l.delivered : l.cancelled,
                              e.delivered ? context.accent : AppColors.danger,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Fines or item fees from the team, each with its explanation
/// (docs/business-rules.md#charges). Shown only when there are any.
class _ChargesCard extends StatelessWidget {
  const _ChargesCard({required this.charges});
  final List<DriverCharge> charges;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final open = charges.where((c) => c.isOpen).fold<double>(0, (s, c) => s + c.amount);
    return Card(
      color: open > 0 ? AppColors.warning.withValues(alpha: 0.08) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_rounded, color: open > 0 ? AppColors.warning : context.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.chargesTitle,
                    style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (open > 0)
                  Text(
                    l.openChargesTotal(Fmt.money(context, open)),
                    style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.chargesBody,
              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            for (final c in charges.take(10)) ...[
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(c.note, style: context.text.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          [
                            chargeKindLabel(l, c.kind),
                            if (c.orderNumber != null) l.orderNumber(c.orderNumber!),
                            Fmt.dateTime(context, c.createdAt),
                          ].join(' · '),
                          style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Fmt.money(context, c.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          decoration: c.status == ChargeStatus.waived ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      switch (c.status) {
                        ChargeStatus.open => Tag(l.chargeOpen, AppColors.warning),
                        ChargeStatus.paid => Tag(l.chargePaid, context.accent),
                        ChargeStatus.waived => Tag(l.chargeWaived, Colors.grey),
                      },
                    ],
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

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.title, required this.orders});
  final String title;
  final List<GasOrder> orders;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cylinders = orders.fold<int>(0, (s, o) => s + o.quantity);
    final revenue = orders.fold<double>(0, (s, o) => s + o.totalPrice);
    Widget stat(IconData icon, String label, String value) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: context.accent),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(
                  value,
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                stat(Icons.propane_tank_rounded, l.cylindersSold, '$cylinders'),
                stat(Icons.payments_rounded, l.revenue,
                    Fmt.money(context, revenue)),
                stat(Icons.task_alt_rounded, l.deliveredOrders,
                    '${orders.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
