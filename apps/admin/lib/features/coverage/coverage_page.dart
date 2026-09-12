import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../widgets/common.dart';
import '../orders/order_inspector.dart';

/// Where customers are not being served: orders that expired because nobody
/// accepted them, "no distributor nearby" checks, acceptance per city, and
/// the expiry job's last runs (docs/business-rules.md#coverage).
class CoveragePage extends StatefulWidget {
  const CoveragePage({super.key});

  @override
  State<CoveragePage> createState() => _CoveragePageState();
}

class _CoveragePageState extends State<CoveragePage> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day + 1);
    final from = to.subtract(Duration(days: _days));

    return PageBody(
      children: [
        Text(l.coverageNote, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final (days, label) in [(1, l.rangeToday), (7, l.range7), (30, l.range30)])
              ChoiceChip(
                label: Text(label),
                selected: _days == days,
                onSelected: (_) => setState(() => _days = days),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AsyncView<CoverageReport>(
          key: ValueKey(_days),
          load: () => repo.coverage(from, to),
          refreshEvery: const Duration(minutes: 1),
          builder: (context, report, reload) => _Report(report: report, onChanged: reload),
        ),
      ],
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.report, required this.onChanged});
  final CoverageReport report;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = report;
    final median = r.medianAcceptSeconds;
    String pct(double v) => '${(v * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          children: [
            KpiCard(label: l.kpiPlaced, value: '${r.placed}', icon: Icons.receipt_long_rounded),
            KpiCard(
              label: l.kpiAcceptance,
              value: pct(r.acceptanceRate),
              icon: Icons.handshake_rounded,
              caption: l.acceptanceCaption(r.accepted, r.placed),
              alert: r.placed >= 5 && r.acceptanceRate < 0.7,
            ),
            KpiCard(
              label: l.kpiExpired,
              value: '${r.expired}',
              icon: Icons.timer_off_rounded,
              color: AppColors.danger,
            ),
            KpiCard(
              label: l.kpiMedianAccept,
              value: median == null ? '-' : Fmt.duration(context, Duration(seconds: median.round())),
              icon: Icons.timer_rounded,
              color: AppColors.info,
            ),
            KpiCard(
              label: l.kpiGaps,
              value: '${r.gaps}',
              icon: Icons.location_off_rounded,
              color: AppColors.warning,
              caption: l.gapsCaption,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l.unservedMap,
          padding: EdgeInsets.zero,
          child: SizedBox(height: 420, child: _GapsMap(points: r.points, onChanged: onChanged)),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l.byCity,
          padding: const EdgeInsets.only(bottom: 8),
          child: r.cities.isEmpty
              ? Padding(padding: const EdgeInsets.all(16), child: Text(l.noData))
              : TableCard(
                  columns: [
                    DataColumn(label: Text(l.colCity)),
                    DataColumn(label: Text(l.colOrders), numeric: true),
                    DataColumn(label: Text(l.kpiAcceptance), numeric: true),
                    DataColumn(label: Text(l.colExpired), numeric: true),
                    DataColumn(label: Text(l.colGaps), numeric: true),
                    DataColumn(label: Text(l.kpiMedianAccept)),
                  ],
                  rows: [
                    for (final c in r.cities)
                      DataRow(cells: [
                        DataCell(Text(c.cityId == null ? l.unknownCity : c.name(context.lang))),
                        DataCell(Text('${c.placed}')),
                        DataCell(Text(
                          pct(c.acceptanceRate),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: c.placed >= 3 && c.acceptanceRate < 0.7 ? AppColors.danger : null,
                          ),
                        )),
                        DataCell(Text('${c.expired}')),
                        DataCell(Text('${c.gaps}')),
                        DataCell(Text(c.medianAcceptSeconds == null
                            ? '-'
                            : Fmt.duration(context, Duration(seconds: c.medianAcceptSeconds!.round())))),
                      ]),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l.jobRuns,
          child: r.jobRuns.isEmpty
              ? Text(l.noJobRuns)
              : Column(
                  children: [
                    for (final j in r.jobRuns)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          j.ok == false ? Icons.error_rounded : Icons.check_circle_rounded,
                          color: j.ok == false ? AppColors.danger : AppColors.brandDeep,
                          size: 20,
                        ),
                        title: Text(j.ok == false ? '${l.jobRunFailed}: ${j.error ?? ''}' : l.jobRunOk(j.expired)),
                        trailing: Text(Fmt.dateTime(context, j.startedAt), style: context.text.bodySmall),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _GapsMap extends StatelessWidget {
  const _GapsMap({required this.points, required this.onChanged});
  final List<CoveragePoint> points;
  final Future<void> Function() onChanged;

  static const _amman = LatLng(31.9539, 35.9106);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final center = points.isEmpty
        ? _amman
        : LatLng(
            points.map((p) => p.lat).reduce((a, b) => a + b) / points.length,
            points.map((p) => p.lng).reduce((a, b) => a + b) / points.length,
          );
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 12, minZoom: 6),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.clickgas.admin',
            ),
            MarkerLayer(
              markers: [
                for (final p in points)
                  Marker(
                    point: LatLng(p.lat, p.lng),
                    width: 22,
                    height: 22,
                    child: Tooltip(
                      message: [
                        p.isExpiredOrder ? l.legendExpired : l.legendGap,
                        if (p.orderNumber != null) '#${p.orderNumber}',
                        Fmt.dateTime(context, p.at),
                      ].join(' · '),
                      child: MouseRegion(
                        cursor: p.orderId == null ? MouseCursor.defer : SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: p.orderId == null
                              ? null
                              : () => showOrderInspector(context, p.orderId!, onChanged: onChanged),
                          child: Container(
                            decoration: BoxDecoration(
                              color: (p.isExpiredOrder ? AppColors.danger : AppColors.warning)
                                  .withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => openExternal('https://www.openstreetmap.org/copyright'),
                ),
              ],
            ),
          ],
        ),
        PositionedDirectional(
          top: 12,
          start: 12,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(color: AppColors.danger, label: l.legendExpired),
                  _LegendDot(color: AppColors.warning, label: l.legendGap),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Dot(color, size: 12),
            const SizedBox(width: 8),
            Text(label, style: context.text.labelMedium),
          ],
        ),
      );
}
