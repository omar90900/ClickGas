import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../widgets/common.dart';

/// Opens a wallet app by package name (MainActivity.kt).
const _apps = MethodChannel('clickgas/apps');

/// For a wallet order: the invoice, the distributor's wallet details with copy
/// buttons, a button to each wallet app and "I've paid". The money goes
/// straight to the distributor, who confirms it arrived
/// (docs/decisions/0015-wallet-payments.md).
class WalletPaymentCard extends StatefulWidget {
  const WalletPaymentCard({super.key, required this.order});
  final GasOrder order;

  @override
  State<WalletPaymentCard> createState() => _WalletPaymentCardState();
}

class _WalletPaymentCardState extends State<WalletPaymentCard> {
  late final Stream<OrderPayment?> _payment =
      context.read<WalletRepository>().watchPayment(widget.order.id);
  // Fresh each time: staff may have just set how a wallet app opens.
  late final Future<List<WalletProvider>> _providers =
      context.read<WalletRepository>().providers(refresh: true);
  bool _busy = false;

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showSnack(context, context.l10n.copied);
  }

  Future<void> _open(WalletProvider p) async {
    var opened = false;
    final package = p.androidPackage;
    if (package != null) {
      try {
        opened = await _apps.invokeMethod<bool>('open', {'package': package}) ?? false;
      } on PlatformException {
        opened = false;
      } on MissingPluginException {
        opened = false;
      }
    }
    if (!opened && p.storeUrl != null) {
      opened = await launchUrl(Uri.parse(p.storeUrl!), mode: LaunchMode.externalApplication);
    }
    if (!opened && mounted) showSnack(context, context.l10n.walletOpenManually);
  }

  Future<void> _claim(OrderPayment payment, List<WalletProvider> providers) async {
    final l = context.l10n;
    final result = await showDialog<(String?, String)>(
      context: context,
      builder: (_) => _ClaimDialog(payment: payment, providers: providers),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<WalletRepository>().claimPayment(
            widget.order.id,
            provider: result.$1,
            reference: result.$2,
          );
      if (mounted) showSnack(context, l.paymentClaimedWait);
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WalletProvider>>(
      future: _providers,
      builder: (context, providers) => StreamBuilder<OrderPayment?>(
        stream: _payment,
        builder: (context, snap) {
          final payment = snap.data;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: payment == null
                  ? _Line(
                      icon: Icons.account_balance_wallet_rounded,
                      color: context.colors.onSurfaceVariant,
                      text: context.l10n.walletDetailsPending,
                    )
                  : _body(context, payment, providers.data ?? const []),
            ),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, OrderPayment payment, List<WalletProvider> providers) {
    final l = context.l10n;
    final order = widget.order;
    final status = payment.status;
    final canClaim = status == PaymentStatus.awaiting || status == PaymentStatus.disputed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: context.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.walletPayTitle,
                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            _StatusTag(status: status),
          ],
        ),
        if (!status.isSettled) ...[
          const SizedBox(height: 10),
          _Banner(color: AppColors.info, icon: Icons.schedule_rounded, text: l.walletPayOnArrival),
        ],
        const SizedBox(height: 12),
        InfoRow(
          label: '${order.serviceName(context.lang)} × ${order.quantity}',
          value: Fmt.money(context, order.unitPrice * order.quantity),
        ),
        if (order.deliveryFee > 0)
          InfoRow(label: l.deliveryFee, value: Fmt.money(context, order.deliveryFee)),
        if (order.serviceFee > 0)
          InfoRow(label: l.serviceFee, value: Fmt.money(context, order.serviceFee)),
        const Divider(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(l.walletAmount, style: context.text.titleSmall),
            ),
            Text(
              Fmt.money(context, payment.amount),
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: context.accent,
              ),
            ),
            IconButton(
              tooltip: l.copy,
              onPressed: () => _copy(payment.amount.toStringAsFixed(3)),
              icon: const Icon(Icons.copy_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(l.walletPayTo, style: context.text.labelLarge),
        for (final payee in payment.payees)
          _PayeeTile(
            payee: payee,
            provider: providers.where((p) => p.code == payee.provider).firstOrNull,
            onCopy: _copy,
            onOpen: _open,
          ),
        const SizedBox(height: 12),
        switch (status) {
          PaymentStatus.claimed => _Banner(
              color: AppColors.warning,
              icon: Icons.hourglass_top_rounded,
              text: [
                l.paymentClaimedWait,
                if (payment.reference != null) l.paymentReferenceValue(payment.reference!),
              ].join('\n'),
            ),
          PaymentStatus.confirmed => _Banner(
              color: context.accent,
              icon: Icons.verified_rounded,
              text: l.paymentConfirmed,
            ),
          PaymentStatus.cash => _Banner(
              color: context.accent,
              icon: Icons.payments_rounded,
              text: l.paymentCashDone,
            ),
          PaymentStatus.disputed => _Banner(
              color: AppColors.danger,
              icon: Icons.report_gmailerrorred_rounded,
              text: '${l.paymentDisputed(payment.note ?? '')}\n${l.paymentDisputedHelp}',
            ),
          PaymentStatus.awaiting => const SizedBox.shrink(),
        },
        if (canClaim) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _busy ? null : () => _claim(payment, providers),
            icon: _busy ? const ButtonSpinner() : const Icon(Icons.check_circle_rounded),
            label: Text(l.iPaid),
          ),
        ],
      ],
    );
  }
}

class _PayeeTile extends StatelessWidget {
  const _PayeeTile({
    required this.payee,
    required this.provider,
    required this.onCopy,
    required this.onOpen,
  });

  final WalletPayee payee;
  final WalletProvider? provider;
  final ValueChanged<String> onCopy;
  final ValueChanged<WalletProvider> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = provider;
    final name = p?.name(context.lang) ?? payee.provider;
    final number = payee.walletNumber == null
        ? null
        : JordanPhone.display(payee.walletNumber!).replaceAll(' ', '');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text(payee.accountName, style: context.text.bodyMedium),
          if (number != null)
            _CopyLine(label: l.walletNumber, value: number, onCopy: onCopy),
          if (payee.cliqAlias != null)
            _CopyLine(label: l.cliqAlias, value: payee.cliqAlias!, onCopy: onCopy),
          if (p != null && p.isCliq)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8, top: 4),
              child: Text(l.cliqHowTo, style: context.text.bodySmall),
            )
          else if (p != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8, top: 6),
              child: OutlinedButton.icon(
                onPressed: () => onOpen(p),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(l.openWallet(name)),
              ),
            ),
        ],
      ),
    );
  }
}

class _CopyLine extends StatelessWidget {
  const _CopyLine({required this.label, required this.value, required this.onCopy});
  final String label;
  final String value;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            textDirection: TextDirection.ltr,
            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: context.l10n.copy,
          onPressed: () => onCopy(value),
          icon: const Icon(Icons.copy_rounded, size: 18),
        ),
      ],
    );
  }
}

/// "I've paid": which wallet (when the distributor has several) and the
/// optional transaction number. Pops (provider, reference).
class _ClaimDialog extends StatefulWidget {
  const _ClaimDialog({required this.payment, required this.providers});
  final OrderPayment payment;
  final List<WalletProvider> providers;

  @override
  State<_ClaimDialog> createState() => _ClaimDialogState();
}

class _ClaimDialogState extends State<_ClaimDialog> {
  late String? _provider = widget.payment.payees.firstOrNull?.provider;
  final _reference = TextEditingController();

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  String _name(String code) =>
      widget.providers.where((p) => p.code == code).firstOrNull?.name(context.lang) ?? code;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final codes = {for (final p in widget.payment.payees) p.provider}.toList();
    return AlertDialog(
      title: Text(l.iPaidTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (codes.length > 1) ...[
            DropdownButtonFormField<String>(
              initialValue: _provider,
              decoration: InputDecoration(labelText: l.paidWith),
              items: [
                for (final c in codes) DropdownMenuItem(value: c, child: Text(_name(c))),
              ],
              onChanged: (v) => setState(() => _provider = v),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _reference,
            maxLength: 60,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: l.paymentReference),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_provider, _reference.text.trim())),
          child: Text(l.iPaid),
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (text, color) = switch (status) {
      PaymentStatus.awaiting => (l.paymentStatusAwaiting, context.colors.outline),
      PaymentStatus.claimed => (l.paymentStatusClaimed, AppColors.warning),
      PaymentStatus.confirmed => (l.paymentStatusConfirmed, context.accent),
      PaymentStatus.disputed => (l.paymentStatusDisputed, AppColors.danger),
      PaymentStatus.cash => (l.paymentStatusCash, context.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: context.text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _Line(icon: icon, color: color, text: text),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
