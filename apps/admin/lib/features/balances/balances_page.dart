import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../state/staff_session.dart';
import '../../widgets/common.dart';
import '../drivers/driver_detail.dart';

/// What each distributor owes from delivery fees, what they paid, and a
/// button to record cash received (docs/decisions/0006).
class BalancesPage extends StatelessWidget {
  const BalancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    final role = context.watch<StaffSession>().role;

    return AsyncView<List<Balance>>(
      load: repo.balances,
      builder: (context, rows, reload) {
        final owed = rows.fold<double>(0, (s, b) => s + (b.balance > 0 ? b.balance : 0));
        final fees = rows.fold<double>(0, (s, b) => s + b.fees);
        final paid = rows.fold<double>(0, (s, b) => s + b.payments);

        Future<void> pay(Balance b) async {
          final result = await askAmount(
            context,
            title: l.paymentTitle(b.fullName),
            message: l.paymentMessage,
            confirmLabel: l.recordPayment,
          );
          if (result == null || !context.mounted) return;
          final ok = await runAction(
            context,
            () => repo.recordPayment(b.driverId, result.amount, note: result.note.isEmpty ? null : result.note),
            success: l.paymentRecorded,
          );
          if (ok) await reload();
        }

        return PageBody(
          children: [
            Text(l.balancesNote, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
            const SizedBox(height: 12),
            ResponsiveGrid(
              children: [
                KpiCard(label: l.totalOwed, value: Fmt.money(context, owed), icon: Icons.account_balance_wallet_rounded, color: AppColors.danger),
                KpiCard(label: l.totalFees, value: Fmt.money(context, fees), icon: Icons.receipt_rounded),
                KpiCard(label: l.totalPayments, value: Fmt.money(context, paid), icon: Icons.payments_rounded, color: AppColors.info),
              ],
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              EmptyState(icon: Icons.account_balance_wallet_outlined, title: l.noBalances)
            else
              TableCard(
                columns: [
                  DataColumn(label: Text(l.colName)),
                  DataColumn(label: Text(l.colStatus)),
                  DataColumn(label: Text(l.colDeliveries), numeric: true),
                  DataColumn(label: Text(l.colFees), numeric: true),
                  DataColumn(label: Text(l.colPaid), numeric: true),
                  DataColumn(label: Text(l.colAdjustments), numeric: true),
                  DataColumn(label: Text(l.colBalance), numeric: true),
                  DataColumn(label: Text(l.colLastPayment)),
                  if (role.canOperate) const DataColumn(label: SizedBox.shrink()),
                ],
                rows: [
                  for (final b in rows)
                    DataRow(
                      onSelectChanged: (_) => showDriverDetail(context, b.driverId, onChanged: reload),
                      cells: [
                        DataCell(TwoLine(b.fullName, Fmt.phone(b.phone), ltrSubtitle: true)),
                        DataCell(DriverStatusTag(b.status)),
                        DataCell(Text('${b.deliveries}')),
                        DataCell(Text(Fmt.amount(b.fees))),
                        DataCell(Text(Fmt.amount(b.payments))),
                        DataCell(Text(Fmt.amount(b.adjustments))),
                        DataCell(Text(
                          Fmt.amount(b.balance),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: b.balance > 0 ? AppColors.danger : AppColors.brandDeep,
                          ),
                        )),
                        DataCell(Text(b.lastPaymentAt == null ? '-' : Fmt.date(context, b.lastPaymentAt))),
                        if (role.canOperate)
                          DataCell(TextButton.icon(
                            onPressed: () => pay(b),
                            icon: const Icon(Icons.payments_rounded, size: 18),
                            label: Text(l.recordPayment),
                          )),
                      ],
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
