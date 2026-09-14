import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../state/staff_session.dart';
import '../../widgets/common.dart';
import '../finance/charges.dart';
import '../payments/payments_page.dart';
import '../orders/orders_page.dart';

Future<void> showDriverDetail(BuildContext context, String driverId, {VoidCallback? onChanged}) =>
    showSidePanel(context, width: 760, builder: (_) => DriverDetail(driverId: driverId, onChanged: onChanged));

class _DriverData {
  const _DriverData(this.driver, this.documents);
  final AdminDriver driver;
  final List<DriverDocument> documents;
}

/// One distributor: approval with documents, account state, workload,
/// charges, and recent orders.
class DriverDetail extends StatelessWidget {
  const DriverDetail({super.key, required this.driverId, this.onChanged});

  final String driverId;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    final docs = context.read<DriverDocumentsRepository>();
    return AsyncView<_DriverData>(
      load: () async {
        final r = await Future.wait<Object>([
          repo.driver(driverId),
          docs.list(driverId),
        ]);
        return _DriverData(r[0] as AdminDriver, r[1] as List<DriverDocument>);
      },
      builder: (context, data, reload) => _Body(
        data: data,
        onChanged: () async {
          await reload();
          onChanged?.call();
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data, required this.onChanged});

  final _DriverData data;
  final Future<void> Function() onChanged;

  AdminDriver get d => data.driver;

  Future<void> _act(BuildContext context, Future<void> Function() action, String success) async {
    if (await runAction(context, action, success: success)) await onChanged();
  }

  Future<void> _approve(BuildContext context) async {
    final l = context.l10n;
    if (!await confirmDialog(context, l.approveConfirm(d.fullName), confirmLabel: l.approve)) return;
    if (!context.mounted) return;
    await _act(
      context,
      () => context.read<AdminRepository>().setDriverStatus(d.id, DriverStatus.approved),
      l.saved,
    );
  }

  Future<void> _refuse(BuildContext context, DriverStatus status) async {
    final l = context.l10n;
    final reject = status == DriverStatus.rejected;
    final reason = await askReason(
      context,
      title: reject ? l.rejectTitle : l.suspendTitle,
      message: reject ? l.rejectMessage : l.suspendMessage,
      confirmLabel: reject ? l.reject : l.suspend,
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    await _act(
      context,
      () => context.read<AdminRepository>().setDriverStatus(d.id, status, reason: reason),
      l.saved,
    );
  }

  Future<void> _block(BuildContext context) async {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    if (d.isActive) {
      final reason = await askReason(
        context,
        title: l.blockTitle,
        message: l.blockMessage,
        confirmLabel: l.blockAccount,
        destructive: true,
      );
      if (reason == null || !context.mounted) return;
      await _act(context, () => repo.setAccountActive(d.id, false, reason: reason), l.accountBlockedDone);
    } else {
      if (!await confirmDialog(context, l.unblockConfirm, confirmLabel: l.unblockAccount)) return;
      if (!context.mounted) return;
      await _act(context, () => repo.setAccountActive(d.id, true), l.accountUnblocked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = context.watch<StaffSession>().role;
    final ops = role.canOperate;

    return PanelScaffold(
      title: d.fullName,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DriverStatusTag(d.status),
            if (!d.isActive) Tag(l.blocked, AppColors.danger),
            Text(l.joinedOn(Fmt.date(context, d.createdAt)), style: context.text.bodySmall),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              UserAvatar(url: d.avatarUrl, name: d.fullName, radius: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(Fmt.phone(d.phone),
                        textDirection: TextDirection.ltr, style: context.text.titleMedium),
                    if (d.email != null) SelectableText(d.email!, style: context.text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (d.statusReason != null && d.status != DriverStatus.approved) ...[
            const SizedBox(height: 12),
            _Box(color: driverStatusColor(d.status), text: l.statusReason(d.statusReason!)),
          ],
          if (ops) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (d.status != DriverStatus.approved)
                  FilledButton.icon(
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(d.status == DriverStatus.pending ? l.approve : l.reinstate),
                  ),
                if (d.status == DriverStatus.pending)
                  _DangerButton(
                    label: l.reject,
                    icon: Icons.block_rounded,
                    onPressed: () => _refuse(context, DriverStatus.rejected),
                  ),
                if (d.status == DriverStatus.approved)
                  _DangerButton(
                    label: l.suspend,
                    icon: Icons.pause_circle_outline_rounded,
                    onPressed: () => _refuse(context, DriverStatus.suspended),
                  ),
                TextButton.icon(
                  onPressed: () => _block(context),
                  icon: Icon(d.isActive ? Icons.lock_outline_rounded : Icons.lock_open_rounded),
                  label: Text(d.isActive ? l.blockAccount : l.unblockAccount),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SectionCard(
            title: l.documents,
            child: Column(
              children: [
                for (final kind in DocumentKind.values)
                  _DocumentRow(
                    kind: kind,
                    doc: data.documents.where((x) => x.kind == kind).firstOrNull,
                    canReview: ops,
                    onChanged: onChanged,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l.vehicleSection,
            child: Column(
              children: [
                InfoRow(label: l.vehiclePlate, value: d.vehiclePlate.isEmpty ? '-' : d.vehiclePlate),
                InfoRow(label: l.vehicleType, value: vehicleTypeLabel(l, d.vehicleType)),
                InfoRow(label: l.agency, value: d.agencyName.isEmpty ? '-' : d.agencyName),
                InfoRow(
                  label: l.rating,
                  value: d.ratingCount == 0 ? '-' : l.ratingAvgCount(d.ratingAvg.toStringAsFixed(1), d.ratingCount),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l.workload,
            child: Column(
              children: [
                InfoRow(label: l.colOnline, value: d.isOnline ? l.online : l.offline),
                InfoRow(label: l.lastLocation, value: Fmt.ago(context, d.locationUpdatedAt)),
                InfoRow(label: l.cylindersOnBoard, value: '${d.cylindersOnBoard}'),
                InfoRow(label: l.colOpen, value: '${d.openOrders}'),
                InfoRow(label: l.colDelivered, value: '${d.deliveredOrders}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DriverWalletsSection(driverId: d.id, canOperate: ops),
          const SizedBox(height: 12),
          ChargesSection(driverId: d.id, driverName: d.fullName, onChanged: onChanged),
          const SizedBox(height: 12),
          SectionCard(
            title: l.recentOrders,
            padding: const EdgeInsets.only(bottom: 8),
            child: OrdersMiniList(query: OrderQuery(driverId: d.id, limit: 10), onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.kind, required this.doc, required this.canReview, required this.onChanged});

  final DocumentKind kind;
  final DriverDocument? doc;
  final bool canReview;
  final Future<void> Function() onChanged;

  Future<void> _view(BuildContext context) async {
    try {
      final url = await context.read<DriverDocumentsRepository>().viewUrl(doc!.filePath);
      await openExternal(url);
    } catch (e) {
      if (context.mounted) showSnack(context, failureText(context, e), error: true);
    }
  }

  Future<void> _review(BuildContext context, bool approve) async {
    final l = context.l10n;
    String? note;
    if (!approve) {
      note = await askReason(context, title: l.rejectDocTitle, confirmLabel: l.rejectDoc, destructive: true);
      if (note == null || !context.mounted) return;
    }
    final ok = await runAction(
      context,
      () => context.read<AdminRepository>().reviewDocument(doc!.id, approve: approve, note: note),
      success: approve ? l.documentApproved : l.documentRejected,
    );
    if (ok) await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = doc;
    final lines = <String>[
      if (d != null) l.uploadedAgo(Fmt.ago(context, d.uploadedAt)),
      if (d?.expiresOn != null) l.expiresOn(Fmt.date(context, d!.expiresOn)),
      if (d?.reviewNote != null) l.reviewNote(d!.reviewNote!),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            d == null ? Icons.description_outlined : Icons.description_rounded,
            color: d == null ? context.colors.outline : documentStatusColor(d.status),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(documentKindLabel(l, kind), style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (d == null)
                      Tag(l.docMissing, Colors.grey)
                    else
                      Tag(documentStatusLabel(l, d.status), documentStatusColor(d.status)),
                    if (d != null && d.isExpired()) Tag(l.expired, AppColors.danger),
                  ],
                ),
                if (lines.isNotEmpty)
                  Text(lines.join(' · '),
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
            ),
          ),
          if (d != null) ...[
            TextButton(onPressed: () => _view(context), child: Text(l.view)),
            if (canReview && d.status != DocumentStatus.approved)
              IconButton(
                tooltip: l.approveDoc,
                onPressed: () => _review(context, true),
                icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.brandDeep),
              ),
            if (canReview && d.status != DocumentStatus.rejected)
              IconButton(
                tooltip: l.rejectDoc,
                onPressed: () => _review(context, false),
                icon: const Icon(Icons.highlight_off_rounded, color: AppColors.danger),
              ),
          ],
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
}

class _Box extends StatelessWidget {
  const _Box({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );
}
