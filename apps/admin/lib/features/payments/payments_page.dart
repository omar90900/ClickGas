import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/staff_session.dart';
import '../../widgets/common.dart';
import '../orders/order_inspector.dart';

// Wallet payments (docs/decisions/0015-wallet-payments.md): customers pay
// distributors straight from their wallet; staff see every payment and settle
// the ones in dispute.

String paymentMethodLabel(AppLocalizations l, PaymentMethod m) => switch (m) {
      PaymentMethod.cash => l.paymentCash,
      PaymentMethod.card => l.paymentCard,
      PaymentMethod.wallet => l.paymentWallet,
    };

String paymentStatusLabel(AppLocalizations l, PaymentStatus s) => switch (s) {
      PaymentStatus.awaiting => l.payStatusAwaiting,
      PaymentStatus.claimed => l.payStatusClaimed,
      PaymentStatus.confirmed => l.payStatusConfirmed,
      PaymentStatus.disputed => l.payStatusDisputed,
      PaymentStatus.cash => l.payStatusCash,
    };

Color paymentStatusColor(BuildContext context, PaymentStatus s) => switch (s) {
      PaymentStatus.awaiting => Colors.grey,
      PaymentStatus.claimed => AppColors.warning,
      PaymentStatus.confirmed => context.accent,
      PaymentStatus.disputed => AppColors.danger,
      PaymentStatus.cash => AppColors.info,
    };

/// "orange_money" -> "orange money" when the wallet list isn't at hand.
String _walletCode(String code) => code.replaceAll('_', ' ');

/// Sets a payment's status with a reason (audited). Returns true when saved.
Future<bool> resolveWalletPayment(
  BuildContext context,
  AdminWalletPayment payment,
  PaymentStatus to,
) async {
  final l = context.l10n;
  final reason = await askReason(
    context,
    title: l.resolveTitle,
    message: '${l.orderTitle(payment.orderNumber)} → ${paymentStatusLabel(l, to)}',
    destructive: to == PaymentStatus.disputed,
  );
  if (reason == null || !context.mounted) return false;
  return runAction(
    context,
    () => context.read<AdminRepository>().resolveWalletPayment(payment.orderId, to, reason),
    success: l.paymentResolved,
  );
}

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  PaymentStatus? _status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    final role = context.watch<StaffSession>().role;
    return PageBody(
      children: [
        Text(l.walletPaymentsNote,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l.paymentFilterAll),
              selected: _status == null,
              onSelected: (_) => setState(() => _status = null),
            ),
            for (final s in PaymentStatus.values)
              ChoiceChip(
                label: Text(paymentStatusLabel(l, s)),
                selected: _status == s,
                onSelected: (_) => setState(() => _status = s),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AsyncView<List<AdminWalletPayment>>(
          key: ValueKey(_status),
          load: () => repo.walletPayments(status: _status),
          builder: (context, list, reload) => list.isEmpty
              ? EmptyState(icon: Icons.account_balance_wallet_outlined, title: l.noWalletPayments)
              : Column(
                  children: [
                    for (final p in list)
                      _PaymentTile(payment: p, canOperate: role.canOperate, onChanged: reload),
                  ],
                ),
        ),
        if (role.isOwner) ...[
          const SizedBox(height: 16),
          const _WalletAppsSection(),
        ],
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.canOperate, required this.onChanged});

  final AdminWalletPayment payment;
  final bool canOperate;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = payment;
    final color = paymentStatusColor(context, p.status);
    return Card(
      child: ListTile(
        onTap: () => showOrderInspector(context, p.orderId, onChanged: onChanged),
        leading: Icon(Icons.account_balance_wallet_rounded, color: color),
        title: Text(
          '${l.orderTitle(p.orderNumber)} · ${Fmt.money(context, p.amount)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            '${p.customerName} → ${p.driverName}',
            if (p.paidWith != null || p.reference != null)
              [if (p.paidWith != null) _walletCode(p.paidWith!), if (p.reference != null) p.reference!].join(' · '),
            if (p.note != null) '${l.disputeNote}: ${p.note}',
            Fmt.dateTime(context, p.claimedAt ?? p.createdAt),
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tag(paymentStatusLabel(l, p.status), color),
            if (canOperate)
              PopupMenuButton<PaymentStatus>(
                tooltip: l.resolveTitle,
                onSelected: (to) async {
                  if (await resolveWalletPayment(context, p, to)) await onChanged();
                },
                itemBuilder: (_) => [
                  for (final s in const [
                    PaymentStatus.confirmed,
                    PaymentStatus.cash,
                    PaymentStatus.disputed,
                    PaymentStatus.awaiting,
                  ])
                    if (s != p.status)
                      PopupMenuItem(value: s, child: Text(paymentStatusLabel(l, s))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The wallet part of the order inspector.
class WalletPaymentSection extends StatelessWidget {
  const WalletPaymentSection({
    super.key,
    required this.orderId,
    required this.canOperate,
    required this.onChanged,
  });

  final String orderId;
  final bool canOperate;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    return AsyncView<List<AdminWalletPayment>>(
      load: () => repo.walletPayments(orderId: orderId),
      builder: (context, list, reload) {
        final p = list.firstOrNull;
        return SectionCard(
          title: l.walletPaymentSection,
          child: p == null
              ? Text(l.walletNotAssigned)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Tag(paymentStatusLabel(l, p.status), paymentStatusColor(context, p.status)),
                    ),
                    const SizedBox(height: 8),
                    InfoRow(label: l.walletAmountLabel, value: Fmt.money(context, p.amount), emphasize: true),
                    for (final payee in p.payees)
                      InfoRow(
                        label: '${l.payTo} · ${_walletCode(payee.provider)}',
                        value: [
                          payee.accountName,
                          if (payee.walletNumber != null) payee.walletNumber!,
                          if (payee.cliqAlias != null) 'CliQ: ${payee.cliqAlias}',
                        ].join('\n'),
                      ),
                    if (p.paidWith != null) InfoRow(label: l.paidWith, value: _walletCode(p.paidWith!)),
                    if (p.reference != null) InfoRow(label: l.reference, value: p.reference!, ltr: true),
                    if (p.claimedAt != null) InfoRow(label: l.payStatusClaimed, value: Fmt.dateTime(context, p.claimedAt)),
                    if (p.confirmedAt != null)
                      InfoRow(label: l.payStatusConfirmed, value: Fmt.dateTime(context, p.confirmedAt)),
                    if (p.note != null) InfoRow(label: l.disputeNote, value: p.note!),
                    if (canOperate) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in const [
                            PaymentStatus.confirmed,
                            PaymentStatus.cash,
                            PaymentStatus.disputed,
                            PaymentStatus.awaiting,
                          ])
                            if (s != p.status)
                              OutlinedButton(
                                onPressed: () async {
                                  if (await resolveWalletPayment(context, p, s)) {
                                    await reload();
                                    await onChanged();
                                  }
                                },
                                child: Text(paymentStatusLabel(l, s)),
                              ),
                        ],
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

/// A distributor's wallets on their detail page.
class DriverWalletsSection extends StatelessWidget {
  const DriverWalletsSection({super.key, required this.driverId, required this.canOperate});

  final String driverId;
  final bool canOperate;

  Future<void> _toggle(BuildContext context, DriverWallet w, Future<void> Function() reload) async {
    final l = context.l10n;
    final reason = await askReason(
      context,
      title: l.walletActiveTitle,
      message: '${_walletCode(w.provider)} · ${w.accountName}',
      confirmLabel: w.isActive ? l.walletPause : l.walletResume,
      destructive: w.isActive,
    );
    if (reason == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => context.read<AdminRepository>().setWalletActive(w.id, !w.isActive, reason),
    );
    if (ok) await reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    return AsyncView<List<DriverWallet>>(
      load: () => repo.driverWallets(driverId),
      builder: (context, wallets, reload) => SectionCard(
        title: l.walletsSection,
        child: wallets.isEmpty
            ? Text(l.noDriverWallets)
            : Column(
                children: [
                  for (final w in wallets)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: w.isActive ? context.accent : Colors.grey,
                      ),
                      title: Text(
                        w.isActive ? _walletCode(w.provider) : '${_walletCode(w.provider)} · ${l.walletPausedTag}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          w.accountName,
                          if (w.walletNumber != null) w.walletNumber!,
                          if (w.cliqAlias != null) 'CliQ: ${w.cliqAlias}',
                          l.termsAccepted(Fmt.dateTime(context, w.termsAcceptedAt)),
                        ].join('\n'),
                      ),
                      trailing: canOperate
                          ? TextButton(
                              onPressed: () => _toggle(context, w, reload),
                              child: Text(w.isActive ? l.walletPause : l.walletResume),
                            )
                          : null,
                    ),
                ],
              ),
      ),
    );
  }
}

/// Owner: how the customer app opens each wallet app.
class _WalletAppsSection extends StatelessWidget {
  const _WalletAppsSection();

  Future<void> _edit(BuildContext context, WalletProvider p, Future<void> Function() reload) async {
    final l = context.l10n;
    final package = TextEditingController(text: p.androidPackage ?? '');
    final store = TextEditingController(text: p.storeUrl ?? '');
    var active = p.isActive;
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(p.nameEn),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.walletAppsNote, style: ctx.text.bodySmall),
                const SizedBox(height: 12),
                TextField(
                  controller: package,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: l.androidPackage, hintText: 'com.example.wallet'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: store,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: l.storeLink, hintText: 'https://play.google.com/...'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                  title: Text(l.walletAppActive),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
          ],
        ),
      ),
    );
    if (save != true || !context.mounted) return;
    final ok = await runAction(
      context,
      () => context.read<AdminRepository>().saveWalletProvider(
            p.code,
            androidPackage: package.text.trim(),
            storeUrl: store.text.trim(),
            isActive: active,
          ),
      success: l.walletAppSaved,
    );
    if (ok) await reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    return AsyncView<List<WalletProvider>>(
      load: repo.walletProviders,
      builder: (context, providers, reload) => SectionCard(
        title: l.walletApps,
        subtitle: l.walletAppsNote,
        child: Column(
          children: [
            for (final p in providers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.apps_rounded,
                  color: p.isActive ? context.accent : Colors.grey,
                ),
                title: Text('${p.nameEn} · ${p.nameAr}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${l.androidPackage}: ${p.androidPackage ?? '-'}\n${l.storeLink}: ${p.storeUrl ?? '-'}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: l.walletAppEdit,
                  onPressed: () => _edit(context, p, reload),
                  icon: const Icon(Icons.edit_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
