import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../state/staff_session.dart';
import '../../widgets/common.dart';
import '../drivers/driver_detail.dart';

/// Charges: fines or fees for particular items raised against a distributor,
/// each with an explanation they see in their app (ADR 0011).

/// Raises a charge. With no [driverId], asks which distributor first.
/// Returns true when saved.
Future<bool> raiseCharge(
  BuildContext context, {
  String? driverId,
  String? driverName,
  String? orderId,
  int? orderNumber,
}) async {
  final l = context.l10n;
  final repo = context.read<AdminRepository>();
  var id = driverId;
  var name = driverName;
  if (id == null) {
    final picked = await showDialog<AdminDriver>(context: context, builder: (_) => const _PickDriver());
    if (picked == null || !context.mounted) return false;
    id = picked.id;
    name = picked.fullName;
  }

  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  var kind = ChargeKind.fine;

  final save = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l.newCharge),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    [?name, if (orderNumber != null) l.chargeForOrder(orderNumber)].join(' · '),
                    style: ctx.text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(l.chargesNote, style: ctx.text.bodySmall),
                  const SizedBox(height: 16),
                  SegmentedButton<ChargeKind>(
                    segments: [
                      for (final k in ChargeKind.values)
                        ButtonSegment(value: k, label: Text(chargeKindLabel(l, k))),
                    ],
                    selected: {kind},
                    onSelectionChanged: (s) => setState(() => kind = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: title,
                    autofocus: true,
                    maxLength: 80,
                    decoration: InputDecoration(labelText: l.chargeTitle, hintText: l.chargeTitleHint),
                    validator: (v) => (v ?? '').trim().length < 2 ? l.fieldRequired : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amount,
                    inputFormatters: [amountInputFormatter],
                    decoration: InputDecoration(labelText: l.amountLabel, suffixText: l.currency),
                    validator: (v) {
                      final a = parseAmount(v ?? '');
                      return a == null || a <= 0 || a > 10000 ? l.invalidAmount : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: note,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: l.chargeNoteLabel),
                    validator: (v) => (v ?? '').trim().length < 3 ? l.reasonRequired : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
  if (save != true || !context.mounted) return false;
  return runAction(
    context,
    () => repo.createCharge(
      driverId: id!,
      kind: kind,
      title: title.text.trim(),
      amount: parseAmount(amount.text)!,
      note: note.text.trim(),
      orderId: orderId,
    ),
    success: l.chargeCreated,
  );
}

/// Marks paid (confirm) or waives (reason). Returns true when saved.
Future<bool> settleCharge(BuildContext context, DriverCharge charge, ChargeStatus to) async {
  final l = context.l10n;
  final repo = context.read<AdminRepository>();
  String? note;
  if (to == ChargeStatus.waived) {
    note = await askReason(context, title: l.waiveTitle, message: charge.title, confirmLabel: l.waive);
    if (note == null) return false;
  } else if (!await confirmDialog(context, '${l.markPaidConfirm}\n${charge.title} · ${Fmt.money(context, charge.amount)}',
      confirmLabel: l.markPaid)) {
    return false;
  }
  if (!context.mounted) return false;
  return runAction(context, () => repo.settleCharge(charge.id, to, note: note), success: l.chargeSettled);
}

class ChargeStatusTag extends StatelessWidget {
  const ChargeStatusTag(this.status, {super.key});
  final ChargeStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (status) {
      ChargeStatus.open => Tag(l.chargeOpen, AppColors.warning),
      ChargeStatus.paid => Tag(l.chargePaid, context.accent),
      ChargeStatus.waived => Tag(l.chargeWaived, Colors.grey),
    };
  }
}

/// A table of charges with Mark paid / Waive for the roles allowed to.
class ChargesTable extends StatelessWidget {
  const ChargesTable({super.key, required this.charges, required this.onChanged, this.showDriver = true});

  final List<DriverCharge> charges;
  final Future<void> Function() onChanged;
  final bool showDriver;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = context.watch<StaffSession>().role;
    return TableCard(
      columns: [
        DataColumn(label: Text(l.colDate)),
        if (showDriver) DataColumn(label: Text(l.colDriver)),
        DataColumn(label: Text(l.colCharge)),
        DataColumn(label: Text(l.colExplanation)),
        DataColumn(label: Text(l.colAmount), numeric: true),
        DataColumn(label: Text(l.colStatus)),
        const DataColumn(label: SizedBox.shrink()),
      ],
      rows: [
        for (final c in charges)
          DataRow(cells: [
            DataCell(TwoLine(Fmt.date(context, c.createdAt), c.createdByName)),
            if (showDriver)
              DataCell(
                TwoLine(c.driverName ?? '-', c.agencyName),
                onTap: () => showDriverDetail(context, c.driverId, onChanged: onChanged),
              ),
            DataCell(TwoLine(
              c.title,
              [chargeKindLabel(l, c.kind), if (c.orderNumber != null) l.chargeForOrder(c.orderNumber!)].join(' · '),
            )),
            DataCell(ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Tooltip(
                message: [c.note, if (c.settleNote != null) c.settleNote!].join('\n'),
                child: Text(c.note, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            )),
            DataCell(Text(
              Fmt.amount(c.amount),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                decoration: c.status == ChargeStatus.waived ? TextDecoration.lineThrough : null,
              ),
            )),
            DataCell(Tooltip(
              message: c.settledAt == null
                  ? ''
                  : '${Fmt.dateTime(context, c.settledAt)}${c.settledByName == null ? '' : ' · ${l.byName(c.settledByName!)}'}',
              child: ChargeStatusTag(c.status),
            )),
            DataCell(!c.isOpen
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (role.canOperate)
                        TextButton(
                          onPressed: () async {
                            if (await settleCharge(context, c, ChargeStatus.paid)) await onChanged();
                          },
                          child: Text(l.markPaid),
                        ),
                      if (role.isOwner)
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.grey),
                          onPressed: () async {
                            if (await settleCharge(context, c, ChargeStatus.waived)) await onChanged();
                          },
                          child: Text(l.waive),
                        ),
                    ],
                  )),
          ]),
      ],
    );
  }
}

/// Charges with a status filter and "New charge"; for all distributors or
/// one ([driverId]).
class ChargesSection extends StatefulWidget {
  const ChargesSection({super.key, this.driverId, this.driverName, this.onChanged});

  final String? driverId;
  final String? driverName;
  final VoidCallback? onChanged;

  @override
  State<ChargesSection> createState() => _ChargesSectionState();
}

class _ChargesSectionState extends State<ChargesSection> {
  ChargeStatus? _status = ChargeStatus.open;
  int _version = 0;

  void _changed() {
    setState(() => _version++);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    final role = context.watch<StaffSession>().role;
    return SectionCard(
      title: l.charges,
      subtitle: l.chargesNote,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        if (role.canOperate)
          TextButton.icon(
            onPressed: () async {
              if (await raiseCharge(context, driverId: widget.driverId, driverName: widget.driverName)) {
                _changed();
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(l.newCharge),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final s in [ChargeStatus.open, ChargeStatus.paid, ChargeStatus.waived, null])
                ChoiceChip(
                  label: Text(switch (s) {
                    ChargeStatus.open => l.chargeOpen,
                    ChargeStatus.paid => l.chargePaid,
                    ChargeStatus.waived => l.chargeWaived,
                    null => l.all,
                  }),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AsyncView<Paged<DriverCharge>>(
            key: ValueKey('$_status|$_version|${widget.driverId}'),
            load: () => repo.charges(status: _status, driverId: widget.driverId),
            builder: (context, page, reload) => page.items.isEmpty
                ? Padding(padding: const EdgeInsets.all(8), child: Text(l.noCharges))
                : ChargesTable(
                    charges: page.items,
                    showDriver: widget.driverId == null,
                    onChanged: () async => _changed(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PickDriver extends StatelessWidget {
  const _PickDriver();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.pickDistributor),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: 480,
        height: 440,
        child: AsyncView<List<AdminDriver>>(
          load: () => context.read<AdminRepository>().drivers(),
          builder: (context, drivers, _) => drivers.isEmpty
              ? EmptyState(icon: Icons.local_shipping_outlined, title: l.noDrivers)
              : ListView(
                  children: [
                    for (final d in drivers)
                      ListTile(
                        leading: UserAvatar(url: d.avatarUrl, name: d.fullName, radius: 18),
                        title: Text(d.fullName),
                        subtitle: Text([Fmt.phone(d.phone), if (d.agencyName.isNotEmpty) d.agencyName].join(' · ')),
                        trailing: DriverStatusTag(d.status),
                        onTap: () => Navigator.pop(context, d),
                      ),
                  ],
                ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel))],
    );
  }
}
