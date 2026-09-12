import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../widgets/common.dart';
import '../orders/orders_page.dart';

/// Customers, newest first: search, order history, reliability flag, and
/// block/unblock (any staff role).
class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  static const _pageSize = 50;
  String _search = '';
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 360,
              child: SearchField(
                hint: l.searchCustomersHint,
                onSubmitted: (v) => setState(() {
                  _search = v;
                  _offset = 0;
                }),
              ),
            ),
          ),
        ),
        Expanded(
          child: AsyncView<Paged<AdminCustomer>>(
            key: ValueKey('$_search|$_offset'),
            load: () => repo.customers(search: _search, limit: _pageSize, offset: _offset),
            builder: (context, page, reload) => PageBody(
              children: [
                if (page.items.isEmpty)
                  EmptyState(icon: Icons.people_outline_rounded, title: l.noCustomers)
                else
                  TableCard(
                    footer: Pager(
                      offset: _offset,
                      count: page.items.length,
                      total: page.total,
                      pageSize: _pageSize,
                      onPage: (o) => setState(() => _offset = o),
                    ),
                    columns: [
                      DataColumn(label: Text(l.colName)),
                      DataColumn(label: Text(l.email)),
                      DataColumn(label: Text(l.colOrders), numeric: true),
                      DataColumn(label: Text(l.colDelivered), numeric: true),
                      DataColumn(label: Text(l.colCancelled), numeric: true),
                      DataColumn(label: Text(l.colLastOrder)),
                      DataColumn(label: Text(l.colStatus)),
                      DataColumn(label: Text(l.colJoined)),
                    ],
                    rows: [
                      for (final c in page.items)
                        DataRow(
                          onSelectChanged: (_) => showSidePanel(
                            context,
                            builder: (_) => _CustomerPanel(customer: c, onChanged: reload),
                          ),
                          cells: [
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                UserAvatar(url: c.avatarUrl, name: c.fullName, radius: 16),
                                const SizedBox(width: 10),
                                TwoLine(c.fullName, Fmt.phone(c.phone), ltrSubtitle: true),
                              ],
                            )),
                            DataCell(Text(c.email ?? '-')),
                            DataCell(Text('${c.ordersTotal}')),
                            DataCell(Text('${c.delivered}')),
                            DataCell(Text('${c.cancelled}')),
                            DataCell(Text(Fmt.ago(context, c.lastOrderAt))),
                            DataCell(Wrap(spacing: 6, children: [
                              c.isActive ? Tag(l.active, context.accent) : Tag(l.blocked, AppColors.danger),
                              if (c.oftenCancels) Tag(l.oftenCancels, AppColors.warning),
                            ])),
                            DataCell(Text(Fmt.date(context, c.createdAt))),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerPanel extends StatefulWidget {
  const _CustomerPanel({required this.customer, required this.onChanged});

  final AdminCustomer customer;
  final VoidCallback onChanged;

  @override
  State<_CustomerPanel> createState() => _CustomerPanelState();
}

class _CustomerPanelState extends State<_CustomerPanel> {
  late bool _active = widget.customer.isActive;

  Future<void> _toggle() async {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    final c = widget.customer;
    bool ok;
    if (_active) {
      final reason = await askReason(
        context,
        title: l.blockTitle,
        message: l.blockMessageCustomer,
        confirmLabel: l.blockAccount,
        destructive: true,
      );
      if (reason == null || !mounted) return;
      ok = await runAction(context, () => repo.setAccountActive(c.id, false, reason: reason),
          success: l.accountBlockedDone);
    } else {
      if (!await confirmDialog(context, l.unblockConfirm, confirmLabel: l.unblockAccount)) return;
      if (!mounted) return;
      ok = await runAction(context, () => repo.setAccountActive(c.id, true), success: l.accountUnblocked);
    }
    if (ok && mounted) {
      setState(() => _active = !_active);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = widget.customer;
    return PanelScaffold(
      title: c.fullName,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _active ? Tag(l.active, context.accent) : Tag(l.blocked, AppColors.danger),
            if (c.oftenCancels) Tag(l.oftenCancels, AppColors.warning),
            Text(l.joinedOn(Fmt.date(context, c.createdAt)), style: context.text.bodySmall),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              UserAvatar(url: c.avatarUrl, name: c.fullName, radius: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(Fmt.phone(c.phone),
                        textDirection: TextDirection.ltr, style: context.text.titleMedium),
                    if (c.email != null) SelectableText(c.email!, style: context.text.bodySmall),
                  ],
                ),
              ),
              _active
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      onPressed: _toggle,
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: Text(l.blockAccount),
                    )
                  : FilledButton.icon(
                      onPressed: _toggle,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: Text(l.unblockAccount),
                    ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            minTileWidth: 140,
            children: [
              _Stat(label: l.colOrders, value: c.ordersTotal),
              _Stat(label: l.colDelivered, value: c.delivered),
              _Stat(label: l.colCancelled, value: c.cancelled),
              _Stat(label: l.colOpen, value: c.openOrders),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l.recentOrders,
            padding: const EdgeInsets.only(bottom: 8),
            child: OrdersMiniList(query: OrderQuery(customerId: c.id, limit: 20), onChanged: widget.onChanged),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text('$value', style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              Text(label, style: context.text.bodySmall),
            ],
          ),
        ),
      );
}
