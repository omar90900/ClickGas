import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../widgets/common.dart';
import 'driver_detail.dart';

/// All distributors; awaiting approval come first. Filter by status, search
/// by name, phone, plate or agency, and open the detail panel.
class DriversPage extends StatefulWidget {
  const DriversPage({super.key, this.initialStatus});

  final DriverStatus? initialStatus;

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  late DriverStatus? _status = widget.initialStatus;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: SearchField(
                  hint: l.searchDriversHint,
                  onSubmitted: (v) => setState(() => _search = v),
                ),
              ),
              ChoiceChip(
                label: Text(l.all),
                selected: _status == null,
                onSelected: (_) => setState(() => _status = null),
              ),
              for (final s in DriverStatus.values)
                ChoiceChip(
                  label: Text(driverStatusLabel(l, s)),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<AdminDriver>>(
            key: ValueKey('$_status|$_search'),
            load: () => repo.drivers(status: _status, search: _search),
            refreshEvery: const Duration(seconds: 60),
            builder: (context, drivers, reload) => PageBody(
              children: [
                if (drivers.isEmpty)
                  EmptyState(icon: Icons.local_shipping_outlined, title: l.noDrivers)
                else
                  _DriversTable(drivers: drivers, onChanged: reload),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DriversTable extends StatelessWidget {
  const _DriversTable({required this.drivers, required this.onChanged});

  final List<AdminDriver> drivers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    return TableCard(
      columns: [
        DataColumn(label: Text(l.colName)),
        DataColumn(label: Text(l.colVehicle)),
        DataColumn(label: Text(l.colAgency)),
        DataColumn(label: Text(l.colStatus)),
        DataColumn(label: Text(l.colOnline)),
        DataColumn(label: Text(l.colOpen), numeric: true),
        DataColumn(label: Text(l.colDelivered), numeric: true),
        DataColumn(label: Text(l.colOwes), numeric: true),
        DataColumn(label: Text(l.colDocuments)),
        DataColumn(label: Text(l.colJoined)),
      ],
      rows: [
        for (final d in drivers)
          DataRow(
            onSelectChanged: (_) => showDriverDetail(context, d.id, onChanged: onChanged),
            cells: [
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(url: d.avatarUrl, name: d.fullName, radius: 16),
                  const SizedBox(width: 10),
                  TwoLine(d.fullName, Fmt.phone(d.phone), ltrSubtitle: true),
                  if (!d.isActive) ...[const SizedBox(width: 8), Tag(l.blocked, AppColors.danger)],
                ],
              )),
              DataCell(TwoLine(d.vehiclePlate.isEmpty ? '-' : d.vehiclePlate, vehicleTypeLabel(l, d.vehicleType))),
              DataCell(Text(d.agencyName.isEmpty ? '-' : d.agencyName)),
              DataCell(DriverStatusTag(d.status)),
              DataCell(_OnlineCell(driver: d, now: now)),
              DataCell(Text('${d.openOrders}')),
              DataCell(Text('${d.deliveredOrders}')),
              DataCell(Text(
                Fmt.amount(d.balance),
                style: TextStyle(
                  color: d.balance > 0 ? AppColors.danger : null,
                  fontWeight: FontWeight.w700,
                ),
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${d.documentsTotal}/${DocumentKind.values.length}'),
                  if (d.documentsPending > 0) ...[
                    const SizedBox(width: 8),
                    Tag(l.docsToReview(d.documentsPending), AppColors.warning),
                  ],
                ],
              )),
              DataCell(Text(Fmt.date(context, d.createdAt))),
            ],
          ),
      ],
    );
  }
}

class _OnlineCell extends StatelessWidget {
  const _OnlineCell({required this.driver, required this.now});
  final AdminDriver driver;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final at = driver.locationUpdatedAt;
    final stale = at == null || now.difference(at) > const Duration(minutes: 2);
    final color = !driver.isOnline ? Colors.grey : (stale ? AppColors.warning : AppColors.brandDeep);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dot(color),
        const SizedBox(width: 6),
        Text(driver.isOnline ? (stale ? l.legendStale : l.online) : l.offline),
      ],
    );
  }
}
