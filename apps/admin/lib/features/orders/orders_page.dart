import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../widgets/common.dart';
import 'order_inspector.dart';

/// Search every order by number, phone or name, filter by status and date,
/// and open the inspector.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  OrderQuery _query = const OrderQuery();

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: now,
      initialDateRange: _query.from == null
          ? null
          : DateTimeRange(start: _query.from!, end: _query.to!.subtract(const Duration(days: 1))),
    );
    if (range == null) return;
    setState(() => _query = _query.copyWith(
          from: range.start,
          to: DateTime(range.end.year, range.end.month, range.end.day + 1),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    final dates = _query.from == null
        ? l.anyDate
        : '${Fmt.date(context, _query.from)} – ${Fmt.date(context, _query.to!.subtract(const Duration(days: 1)))}';

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
                  hint: l.searchOrdersHint,
                  initial: _query.search,
                  onSubmitted: (v) => setState(() => _query = _query.copyWith(search: v)),
                ),
              ),
              for (final s in OrderStatus.values)
                FilterChip(
                  label: Text(orderStatusLabel(l, s)),
                  selected: _query.statuses.contains(s),
                  onSelected: (on) => setState(() {
                    final next = {..._query.statuses};
                    on ? next.add(s) : next.remove(s);
                    _query = _query.copyWith(statuses: next);
                  }),
                ),
              ActionChip(
                avatar: const Icon(Icons.date_range_rounded, size: 18),
                label: Text(dates),
                onPressed: _pickDates,
              ),
              if (_query.from != null)
                IconButton(
                  tooltip: l.clear,
                  onPressed: () => setState(() => _query = _query.copyWith(clearDates: true)),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<Paged<AdminOrder>>(
            key: ValueKey(_query.key),
            load: () => repo.searchOrders(_query),
            builder: (context, page, reload) => PageBody(
              children: [
                if (page.items.isEmpty)
                  EmptyState(icon: Icons.receipt_long_outlined, title: l.noOrdersFound)
                else
                  OrdersTable(
                    orders: page.items,
                    onChanged: reload,
                    footer: _Pager(
                      offset: _query.offset,
                      count: page.items.length,
                      total: page.total,
                      onPage: (offset) => setState(() => _query = _query.copyWith(offset: offset)),
                      pageSize: _query.limit,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OrdersTable extends StatelessWidget {
  const OrdersTable({super.key, required this.orders, this.onChanged, this.footer, this.compact = false});

  final List<AdminOrder> orders;
  final VoidCallback? onChanged;
  final Widget? footer;

  /// Fewer columns, for detail panels.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return TableCard(
      footer: footer,
      columns: [
        DataColumn(label: Text(l.colOrder)),
        if (!compact) DataColumn(label: Text(l.colCustomer)),
        if (!compact) DataColumn(label: Text(l.colDriver)),
        DataColumn(label: Text(l.colService)),
        DataColumn(label: Text(l.colTotal), numeric: true),
        DataColumn(label: Text(l.colStatus)),
        DataColumn(label: Text(l.colPlaced)),
      ],
      rows: [
        for (final o in orders)
          DataRow(
            onSelectChanged: (_) => showOrderInspector(context, o.id, onChanged: onChanged),
            cells: [
              DataCell(Text('#${o.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w800))),
              if (!compact) DataCell(TwoLine(o.customerName, Fmt.phone(o.customerPhone), ltrSubtitle: true)),
              if (!compact)
                DataCell(o.driverName == null
                    ? const Text('-')
                    : TwoLine(o.driverName!, Fmt.phone(o.driverPhone ?? ''), ltrSubtitle: true)),
              DataCell(Text(l.qtyTimes(o.quantity, o.serviceName(context.lang)))),
              DataCell(Text(Fmt.money(context, o.totalPrice))),
              DataCell(OrderStatusTag(o.status)),
              DataCell(Text(Fmt.dateTime(context, o.createdAt))),
            ],
          ),
      ],
    );
  }
}

/// The last orders of one distributor or customer (detail panels).
class OrdersMiniList extends StatelessWidget {
  const OrdersMiniList({super.key, required this.query, this.onChanged});

  final OrderQuery query;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return AsyncView<Paged<AdminOrder>>(
      load: () => repo.searchOrders(query),
      builder: (context, page, reload) => page.items.isEmpty
          ? Padding(padding: const EdgeInsets.all(8), child: Text(context.l10n.noOrdersFound))
          : OrdersTable(
              orders: page.items,
              compact: true,
              onChanged: () {
                reload();
                onChanged?.call();
              },
            ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.offset,
    required this.count,
    required this.total,
    required this.pageSize,
    required this.onPage,
  });

  final int offset;
  final int count;
  final int total;
  final int pageSize;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(l.pageRange(offset + 1, offset + count, total))),
          IconButton(
            tooltip: l.previousPage,
            onPressed: offset == 0 ? null : () => onPage((offset - pageSize).clamp(0, total)),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: l.nextPage,
            onPressed: offset + count >= total ? null : () => onPage(offset + pageSize),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// Re-exported for the customers page.
typedef Pager = _Pager;
