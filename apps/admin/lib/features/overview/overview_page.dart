import 'dart:math' as math;

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../widgets/common.dart';
import '../shell/admin_shell.dart';

/// Today's numbers (Jordan time), what needs attention now, and 14 days.
/// Refreshes every 30 seconds.
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncView<Overview>(
      load: context.read<AdminRepository>().overview,
      refreshEvery: const Duration(seconds: 30),
      builder: (context, overview, _) => _OverviewBody(o: overview),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.o});
  final Overview o;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = AdminNavigator.of(context);
    final median = o.medianAcceptSeconds;
    final fees14 = o.days.fold<double>(0, (sum, d) => sum + d.fees);

    return PageBody(
      children: [
        if (o.pendingOver10m > 0)
          _Banner(
            icon: Icons.warning_amber_rounded,
            color: AppColors.danger,
            text: l.alertLateOrders(o.pendingOver10m),
            actionLabel: l.openLiveMap,
            onAction: () => nav.go(AdminPage.live),
          ),
        if (o.driversAwaitingApproval > 0)
          _Banner(
            icon: Icons.how_to_reg_rounded,
            color: AppColors.warning,
            text: l.alertApprovals(o.driversAwaitingApproval),
            actionLabel: l.review,
            onAction: () => nav.go(AdminPage.drivers, driverFilter: DriverStatus.pending),
          ),
        _Heading(l.today),
        ResponsiveGrid(
          children: [
            KpiCard(
              label: l.kpiOrdersToday,
              value: '${o.ordersToday}',
              icon: Icons.receipt_long_rounded,
              onTap: () => nav.go(AdminPage.orders),
            ),
            KpiCard(
              label: l.kpiDelivered,
              value: '${o.deliveredToday}',
              icon: Icons.check_circle_rounded,
            ),
            KpiCard(
              label: l.kpiCancelled,
              value: '${o.cancelledToday + o.expiredToday}',
              icon: Icons.cancel_rounded,
              color: AppColors.danger,
              caption: l.cancelledExpired(o.cancelledToday, o.expiredToday),
            ),
            KpiCard(
              label: l.kpiFeesToday,
              value: Fmt.money(context, o.feesToday),
              icon: Icons.payments_rounded,
            ),
            KpiCard(
              label: l.kpiFeesMonth,
              value: Fmt.money(context, o.feesMonth),
              icon: Icons.calendar_month_rounded,
              onTap: () => nav.go(AdminPage.finance),
            ),
            KpiCard(
              label: l.kpiSalesToday,
              value: Fmt.money(context, o.salesToday),
              icon: Icons.point_of_sale_rounded,
              caption: l.salesCaption,
            ),
            KpiCard(
              label: l.kpiMedianAccept,
              value: median == null ? '-' : Fmt.duration(context, Duration(seconds: median.round())),
              icon: Icons.timer_rounded,
              color: AppColors.info,
              caption: l.medianCaption,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Heading(l.rightNow),
        ResponsiveGrid(
          children: [
            KpiCard(
              label: l.kpiWaiting,
              value: '${o.pending}',
              icon: Icons.hourglass_top_rounded,
              alert: o.pendingOver10m > 0,
              caption: o.pendingOver10m > 0 ? l.waitingOver10(o.pendingOver10m) : null,
              onTap: () => nav.go(AdminPage.live),
            ),
            KpiCard(
              label: l.kpiInProgress,
              value: '${o.inProgress}',
              icon: Icons.local_shipping_rounded,
              color: AppColors.info,
              onTap: () => nav.go(AdminPage.live),
            ),
            KpiCard(
              label: l.kpiDriversOnline,
              value: '${o.driversOnline}',
              icon: Icons.wifi_tethering_rounded,
              caption: l.ofApproved(o.driversApproved),
              onTap: () => nav.go(AdminPage.live),
            ),
            KpiCard(
              label: l.kpiAwaitingApproval,
              value: '${o.driversAwaitingApproval}',
              icon: Icons.how_to_reg_rounded,
              color: AppColors.warning,
              caption: o.documentsToReview > 0 ? l.docsToReview(o.documentsToReview) : null,
              onTap: () => nav.go(AdminPage.drivers, driverFilter: DriverStatus.pending),
            ),
            KpiCard(
              label: l.kpiCustomers,
              value: '${o.customersTotal}',
              icon: Icons.people_alt_rounded,
              caption: l.newToday(o.customersNewToday),
              onTap: () => nav.go(AdminPage.customers),
            ),
            KpiCard(
              label: l.kpiOpenCharges,
              value: Fmt.money(context, o.chargesOpen),
              icon: Icons.receipt_rounded,
              color: AppColors.warning,
              onTap: () => nav.go(AdminPage.finance),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: l.last14Days,
          subtitle: l.feesInPeriod(Fmt.money(context, fees14)),
          child: _DaysChart(days: o.days),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(text, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w700))),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

/// Orders placed vs delivered per day, with the day's fees in the tooltip.
class _DaysChart extends StatelessWidget {
  const _DaysChart({required this.days});
  final List<DayStat> days;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (days.isEmpty) return Text(l.noData);
    final top = math.max(1, days.map((d) => math.max(d.orders, d.delivered)).reduce(math.max));

    Widget bar(double fraction, Color color) => FractionallySizedBox(
          heightFactor: fraction <= 0 ? 0.01 : fraction,
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
        );

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in days)
                Expanded(
                  child: Tooltip(
                    message: '${Fmt.date(context, d.day)}\n'
                        '${l.legendOrders}: ${d.orders}\n'
                        '${l.legendDelivered}: ${d.delivered}\n'
                        '${l.legendFees}: ${Fmt.money(context, d.fees)}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: bar(d.orders / top, AppColors.brand)),
                          const SizedBox(width: 2),
                          Expanded(child: bar(d.delivered / top, AppColors.brandDeep)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final d in days)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(Fmt.shortDay(context, d.day), style: context.text.labelSmall),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _LegendItem(color: AppColors.brand, label: l.legendOrders),
            _LegendItem(color: AppColors.brandDeep, label: l.legendDelivered),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Text(label, style: context.text.bodySmall),
        ],
      );
}
