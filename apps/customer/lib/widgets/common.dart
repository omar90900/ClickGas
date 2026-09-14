import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../data/models/models.dart';
import '../l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
}

/// Translated message for any error. Codes come from docs/errors.md; an
/// unmapped code is shown so support can look it up.
String failureText(BuildContext context, Object error) {
  final l = context.l10n;
  final f = AppFailure.from(error);
  return switch (f.code) {
    FailureCode.invalidCredentials => l.invalidCredentials,
    FailureCode.tooManyAttempts => l.tooManyAttempts,
    FailureCode.emailNotConfirmed => l.emailNotConfirmed,
    FailureCode.emailTaken => l.emailTaken,
    FailureCode.phoneTaken => l.phoneTaken,
    FailureCode.weakPassword => l.passwordTooShort,
    FailureCode.samePassword => l.samePassword,
    FailureCode.openOrderExists => l.activeOrderExists,
    FailureCode.serviceUnavailable => l.servicesUnavailable,
    FailureCode.invalidTransition ||
    FailureCode.orderNotCancellable ||
    FailureCode.orderNotConfirmable ||
    FailureCode.orderNotRateable =>
      l.orderChanged,
    FailureCode.sessionExpired => l.sessionExpired,
    FailureCode.permissionDenied => l.permissionDenied,
    FailureCode.network => l.networkError,
    FailureCode.paymentNotOpen => l.orderChanged,
    _ => l.errorWithCode(f.code.value),
  };
}

String paymentMethodLabel(AppLocalizations l, PaymentMethod m) => switch (m) {
      PaymentMethod.cash => l.cash,
      PaymentMethod.card => l.card,
      PaymentMethod.wallet => l.wallet,
    };

String orderStatusLabel(AppLocalizations l, OrderStatus status) =>
    switch (status) {
      OrderStatus.pending => l.statusPending,
      OrderStatus.accepted => l.statusAccepted,
      OrderStatus.onTheWay => l.statusOnTheWay,
      OrderStatus.delivered => l.statusDelivered,
      OrderStatus.cancelled => l.statusCancelled,
      OrderStatus.expired => l.statusExpired,
    };

Color orderStatusColor(BuildContext context, OrderStatus status) =>
    switch (status) {
      OrderStatus.pending => AppColors.warning,
      OrderStatus.accepted || OrderStatus.onTheWay => AppColors.info,
      OrderStatus.delivered => context.accent,
      OrderStatus.cancelled => AppColors.danger,
      OrderStatus.expired => context.colors.outline,
    };

IconData serviceIcon(String icon) => switch (icon) {
      'new' => Icons.local_shipping_rounded,
      _ => Icons.autorenew_rounded,
    };

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : null,
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context,
  String message, {
  String? confirmLabel,
  bool destructive = false,
}) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message, style: ctx.text.titleMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        TextButton(
          style: destructive
              ? TextButton.styleFrom(foregroundColor: AppColors.danger)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? l.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Settings > Send diagnostics (docs/runbooks/diagnostics.md).
Future<void> sendDiagnostics(BuildContext context) async {
  final l = context.l10n;
  if (!await confirmDialog(context, l.sendDiagnosticsBody,
      confirmLabel: l.sendDiagnostics)) {
    return;
  }
  if (!context.mounted) return;
  try {
    final id = await context.read<DiagnosticsRepository>().send();
    if (context.mounted) showSnack(context, l.diagnosticsSent(id));
  } catch (e) {
    if (context.mounted) showSnack(context, failureText(context, e), error: true);
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 88});
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.24);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDeep.withValues(alpha: 0.18),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/icon/app_icon.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        orderStatusLabel(context.l10n, status),
        style: context.text.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: context.accent),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : context.text.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: style?.copyWith(
              color: emphasize ? null : context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.onRetry, this.message});
  final VoidCallback? onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: message ?? context.l10n.errorGeneric,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.value, this.size = 18});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size, color: AppColors.warning),
        const SizedBox(width: 2),
        Text(
          value == 0 ? '-' : value.toStringAsFixed(1),
          style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Bottom sheet: take a photo / choose from gallery / remove, then upload to
/// the `avatars` bucket. [onChanged] receives the new URL (or null).
Future<void> changeAvatar(
  BuildContext context, {
  required AvatarRepository repo,
  required String userId,
  required bool hasPhoto,
  required ValueChanged<String?> onChanged,
}) async {
  final l = context.l10n;
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.changePhoto, style: ctx.text.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: Text(l.takePhoto),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text(l.chooseFromGallery),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.danger),
              title: Text(l.removePhoto,
                  style: const TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (action == null) return;
  try {
    if (action == 'remove') {
      await repo.remove(userId);
      onChanged(null);
    } else {
      final bytes = await repo.pick(
        action == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
      if (bytes == null) return;
      onChanged(await repo.upload(userId, bytes));
    }
    if (context.mounted) showSnack(context, l.photoUpdated);
  } catch (e) {
    if (context.mounted) showSnack(context, failureText(context, e), error: true);
  }
}

class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.onBrand,
        ),
      );
}
