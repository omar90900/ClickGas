import 'dart:math' as math;

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../widgets/common.dart';
import '../drivers/driver_detail.dart';
import 'charges.dart';

enum _Range { today, week, month30, thisMonth, custom }

/// Platform income (service fees on delivered orders) for a period, by day,
/// agency and distributor, plus charges raised against distributors.
class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  _Range _range = _Range.thisMonth;
  DateTimeRange? _custom;

  /// [from, to) in local time; days start at local midnight.
  (DateTime, DateTime) get _period {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return switch (_range) {
      _Range.today => (DateTime(now.year, now.month, now.day), tomorrow),
      _Range.week => (tomorrow.subtract(const Duration(days: 7)), tomorrow),
      _Range.month30 => (tomorrow.subtract(const Duration(days: 30)), tomorrow),
      _Range.thisMonth => (DateTime(now.year, now.month), tomorrow),
      _Range.custom => (
          _custom!.start,
          DateTime(_custom!.end.year, _custom!.end.month, _custom!.end.day + 1),
        ),
    };
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: now,
      initialDateRange: _custom,
    );
    if (picked != null) {
      setState(() {
        _custom = picked;
        _range = _Range.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    final (from, to) = _period;
    String label(_Range r) => switch (r) {
          _Range.today => l.rangeToday,
          _Range.week => l.range7,
          _Range.month30 => l.range30,
          _Range.thisMonth => l.rangeMonth,
          _Range.custom => _custom == null
              ? l.rangeCustom
              : '${Fmt.date(context, _custom!.start)} – ${Fmt.date(context, _custom!.end)}',
        };

    return PageBody(
      children: [
        Text(l.financeNote, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in _Range.values)
              ChoiceChip(
                label: Text(label(r)),
                selected: _range == r,
                onSelected: (_) => r == _Range.custom ? _pickCustom() : setState(() => _range = r),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AsyncView<FinanceReport>(
          key: ValueKey('$from|$to'),
          load: () => repo.finance(from, to),
          builder: (context, report, _) => _Report(report: report),
        ),
        const SizedBox(height: 16),
        const ChargesSection(),
      ],
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.report});
  final FinanceReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          children: [
            KpiCard(
              label: l.kpiPlatformFees,
              value: Fmt.money(context, r.platformFees),
              icon: Icons.insights_rounded,
              caption: l.platformFeesCaption,
            ),
            KpiCard(label: l.kpiCustomerFees, value: Fmt.money(context, r.customerFees), icon: Icons.person_rounded),
            KpiCard(
              label: l.kpiDistributorFees,
              value: Fmt.money(context, r.distributorFees),
              icon: Icons.local_shipping_rounded,
            ),
            KpiCard(
              label: l.kpiDeliveredOrders,
              value: '${r.deliveredOrders}',
              icon: Icons.task_alt_rounded,
              color: AppColors.info,
            ),
            KpiCard(
              label: l.kpiAvgFee,
              value: Fmt.money(context, r.averageFee),
              icon: Icons.calculate_rounded,
              color: AppColors.info,
            ),
            KpiCard(
              label: l.kpiOrderValue,
              value: Fmt.money(context, r.orderValue),
              icon: Icons.point_of_sale_rounded,
              color: Colors.grey,
              caption: l.orderValueCaption,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(title: l.feesByDay, child: _FeesChart(days: r.days)),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final agency = SectionCard(
            title: l.byAgency,
            padding: const EdgeInsets.only(bottom: 8),
            child: r.agencies.isEmpty
                ? Padding(padding: const EdgeInsets.all(16), child: Text(l.noDeliveries))
                : TableCard(
                    columns: [
                      DataColumn(label: Text(l.colAgency)),
                      DataColumn(label: Text(l.colDistributors), numeric: true),
                      DataColumn(label: Text(l.colDelivered), numeric: true),
                      DataColumn(label: Text(l.colFees), numeric: true),
                    ],
                    rows: [
                      for (final a in r.agencies)
                        DataRow(cells: [
                          DataCell(Text(a.agency.isEmpty ? l.noAgency : a.agency)),
                          DataCell(Text('${a.distributors}')),
                          DataCell(Text('${a.delivered}')),
                          DataCell(Text(Fmt.amount(a.fees), style: const TextStyle(fontWeight: FontWeight.w800))),
                        ]),
                    ],
                  ),
          );
          final distributors = SectionCard(
            title: l.byDistributor,
            padding: const EdgeInsets.only(bottom: 8),
            child: r.distributors.isEmpty
                ? Padding(padding: const EdgeInsets.all(16), child: Text(l.noDeliveries))
                : TableCard(
                    columns: [
                      DataColumn(label: Text(l.colName)),
                      DataColumn(label: Text(l.colDelivered), numeric: true),
                      DataColumn(label: Text(l.colOrderValue), numeric: true),
                      DataColumn(label: Text(l.colFees), numeric: true),
                    ],
                    rows: [
                      for (final d in r.distributors)
                        DataRow(
                          onSelectChanged: d.driverId.isEmpty
                              ? null
                              : (_) => showDriverDetail(context, d.driverId),
                          cells: [
                            DataCell(TwoLine(d.fullName, d.agency.isEmpty ? l.noAgency : d.agency)),
                            DataCell(Text('${d.delivered}')),
                            DataCell(Text(Fmt.amount(d.orderValue))),
                            DataCell(Text(Fmt.amount(d.fees), style: const TextStyle(fontWeight: FontWeight.w800))),
                          ],
                        ),
                    ],
                  ),
          );
          return c.maxWidth >= 1000
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: agency),
                    const SizedBox(width: 16),
                    Expanded(child: distributors),
                  ],
                )
              : Column(children: [agency, const SizedBox(height: 16), distributors]);
        }),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minTileWidth: 200,
          children: [
            KpiCard(
              label: l.kpiOpenCharges,
              value: Fmt.money(context, r.charges.openAmount),
              icon: Icons.receipt_rounded,
              color: AppColors.warning,
              caption: '${r.charges.openCount}',
            ),
            KpiCard(label: l.chargesRaised, value: Fmt.money(context, r.charges.raisedAmount), icon: Icons.add_card_rounded),
            KpiCard(label: l.chargesPaidTotal, value: Fmt.money(context, r.charges.paidAmount), icon: Icons.check_rounded),
            KpiCard(
              label: l.chargesWaivedTotal,
              value: Fmt.money(context, r.charges.waivedAmount),
              icon: Icons.money_off_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }
}

/// Daily income bars; the tooltip shows deliveries and income.
class _FeesChart extends StatelessWidget {
  const _FeesChart({required this.days});
  final List<DayStat> days;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (days.isEmpty) return Text(l.noData);
    final top = math.max(0.001, days.map((d) => d.fees).reduce(math.max));
    final showLabels = days.length <= 31;
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in days)
                Expanded(
                  child: Tooltip(
                    message: '${Fmt.date(context, d.day)}\n'
                        '${l.kpiDeliveredOrders}: ${d.delivered}\n'
                        '${l.kpiPlatformFees}: ${Fmt.money(context, d.fees)}',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: days.length > 60 ? 0.5 : 2),
                      child: FractionallySizedBox(
                        heightFactor: d.fees <= 0 ? 0.01 : d.fees / top,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.brandDeep,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showLabels) ...[
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
        ],
      ],
    );
  }
}
