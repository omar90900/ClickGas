import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/driver_session.dart';
import '../../widgets/common.dart';

/// The wallets customers who pay by wallet send money to. Saving needs the
/// distributor to accept that ClickGas is not liable for wrong details
/// (docs/decisions/0015-wallet-payments.md).
class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  late Future<(List<WalletProvider>, List<DriverWallet>)> _data = _load();

  Future<(List<WalletProvider>, List<DriverWallet>)> _load() {
    final repo = context.read<WalletRepository>();
    final id = context.read<DriverSession>().driver!.id;
    return (repo.providers(), repo.myWallets(id)).wait;
  }

  void _reload() => setState(() => _data = _load());

  Future<void> _edit(List<WalletProvider> providers, List<DriverWallet> mine, [DriverWallet? wallet]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _WalletForm(
          providers: providers,
          taken: {for (final w in mine) if (w.id != wallet?.id) w.provider},
          wallet: wallet,
        ),
      ),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _toggle(DriverWallet w, bool active) async {
    try {
      await context.read<WalletRepository>().setWalletActive(w.provider, active);
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e), error: true);
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.walletsTitle)),
      body: FutureBuilder<(List<WalletProvider>, List<DriverWallet>)>(
        future: _data,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: failureText(context, snap.error!),
                action: OutlinedButton(onPressed: _reload, child: Text(l.retry)),
              ),
            );
          }
          if (!snap.hasData) return const LoadingView();
          final (providers, mine) = snap.data!;
          String name(String code) =>
              providers.where((p) => p.code == code).firstOrNull?.name(context.lang) ?? code;
          final canAdd = providers.any((p) => p.isActive && !mine.any((w) => w.provider == p.code));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const WalletDisclaimer(),
              const SizedBox(height: 12),
              Text(
                l.walletsHelp,
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (mine.isEmpty)
                EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l.noWallets,
                  message: l.noWalletsBody,
                ),
              for (final w in mine)
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: w.isActive ? context.accent : context.colors.outline,
                    ),
                    title: Text(
                      w.isActive ? name(w.provider) : '${name(w.provider)} · ${l.walletPaused}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      [
                        w.accountName,
                        if (w.walletNumber != null) JordanPhone.display(w.walletNumber!),
                        if (w.cliqAlias != null) 'CliQ: ${w.cliqAlias}',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: Switch(value: w.isActive, onChanged: (v) => _toggle(w, v)),
                    onTap: () => _edit(providers, mine, w),
                  ),
                ),
              if (canAdd) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _edit(providers, mine),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l.addWallet),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// ClickGas is not liable for wrong wallet details.
class WalletDisclaimer extends StatelessWidget {
  const WalletDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.walletDisclaimerTitle,
                    style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(l.walletDisclaimer, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletForm extends StatefulWidget {
  const _WalletForm({required this.providers, required this.taken, this.wallet});

  final List<WalletProvider> providers;

  /// Wallets the distributor already has (one account per wallet).
  final Set<String> taken;
  final DriverWallet? wallet;

  @override
  State<_WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends State<_WalletForm> {
  final _form = GlobalKey<FormState>();
  late String? _provider = widget.wallet?.provider ??
      widget.providers.where((p) => p.isActive && !widget.taken.contains(p.code)).firstOrNull?.code;
  late final _name = TextEditingController(
    text: widget.wallet?.accountName ?? context.read<DriverSession>().profile?.fullName ?? '',
  );
  late final _number = TextEditingController(
    text: widget.wallet?.walletNumber == null ? '' : JordanPhone.display(widget.wallet!.walletNumber!),
  );
  late final _alias = TextEditingController(text: widget.wallet?.cliqAlias ?? '');
  bool _accepted = false;
  bool _termsError = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _number, _alias]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _form.currentState!.validate();
    setState(() => _termsError = !_accepted);
    if (!valid || !_accepted) return;
    setState(() => _saving = true);
    final l = context.l10n;
    final navigator = Navigator.of(context);
    try {
      final number = _number.text.trim();
      final alias = _alias.text.trim();
      await context.read<WalletRepository>().saveWallet(
            provider: _provider!,
            accountName: _name.text.trim(),
            walletNumber: number.isEmpty ? null : JordanPhone.normalize(number),
            cliqAlias: alias.isEmpty ? null : alias,
            acceptTerms: true,
          );
      if (!mounted) return;
      showSnack(context, l.walletSaved);
      navigator.pop(true);
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    final l = context.l10n;
    final wallet = widget.wallet!;
    if (!await confirmDialog(context, l.removeWalletConfirm,
        confirmLabel: l.removeWallet, destructive: true)) {
      return;
    }
    if (!mounted) return;
    final navigator = Navigator.of(context);
    try {
      await context.read<WalletRepository>().removeWallet(wallet.provider);
      if (!mounted) return;
      showSnack(context, l.walletRemoved);
      navigator.pop(true);
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const gap = SizedBox(height: 14);
    final choices = widget.providers
        .where((p) => (p.isActive && !widget.taken.contains(p.code)) || p.code == widget.wallet?.provider)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.wallet == null ? l.addWallet : l.editWallet)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const WalletDisclaimer(),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _provider,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.walletProvider,
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
              ),
              items: [
                for (final p in choices)
                  DropdownMenuItem(value: p.code, child: Text(p.name(context.lang))),
              ],
              onChanged: widget.wallet == null ? (v) => setState(() => _provider = v) : null,
              validator: (v) => v == null ? l.fieldRequired : null,
            ),
            gap,
            TextFormField(
              controller: _name,
              validator: (v) => (v ?? '').trim().length < 2 ? l.invalidName : null,
              decoration: InputDecoration(
                labelText: l.walletAccountName,
                prefixIcon: const Icon(Icons.person_rounded),
              ),
            ),
            gap,
            TextFormField(
              controller: _number,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              validator: (v) {
                final number = (v ?? '').trim();
                if (number.isEmpty) {
                  return _alias.text.trim().isEmpty ? l.walletNumberOrAlias : null;
                }
                return JordanPhone.normalize(number) == null ? l.invalidPhone : null;
              },
              decoration: InputDecoration(
                labelText: l.walletNumber,
                prefixIcon: const Icon(Icons.phone_iphone_rounded),
              ),
            ),
            gap,
            TextFormField(
              controller: _alias,
              textDirection: TextDirection.ltr,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: l.cliqAlias,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _accepted,
              onChanged: (v) => setState(() {
                _accepted = v ?? false;
                if (_accepted) _termsError = false;
              }),
              title: Text(l.walletAcceptTerms, style: context.text.bodyMedium),
              subtitle: _termsError
                  ? Text(l.walletTermsRequired, style: const TextStyle(color: AppColors.danger))
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const ButtonSpinner() : Text(l.save),
            ),
            if (widget.wallet != null) ...[
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: _saving ? null : _remove,
                child: Text(l.removeWallet),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
