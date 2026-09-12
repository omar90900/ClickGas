import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/settings/documents_screen.dart';
import '../l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
}

class Fmt {
  /// JOD has 3 decimals (1 JOD = 1000 fils).
  static final _money = NumberFormat('0.000', 'en');

  static String money(BuildContext context, double amount) =>
      context.l10n.price(_money.format(amount));

  static String distance(BuildContext context, double meters) =>
      meters < 1000
          ? context.l10n.distanceM(meters.round().toString())
          : context.l10n.distanceKm((meters / 1000).toStringAsFixed(1));

  static String km(double km) =>
      km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toStringAsFixed(1);

  static String dateTime(BuildContext context, DateTime? value) {
    if (value == null) return '';
    return DateFormat.yMMMd(context.lang).add_jm().format(value);
  }
}

/// Translated message for any error. Codes come from docs/errors.md; an
/// unmapped code is shown so support can look it up.
String failureText(BuildContext context, Object error, {int maxOrders = 3}) {
  final l = context.l10n;
  final f = AppFailure.from(error);
  return switch (f.code) {
    FailureCode.invalidCredentials => l.invalidCredentials,
    FailureCode.tooManyAttempts => l.tooManyAttempts,
    FailureCode.emailNotConfirmed => l.emailNotConfirmed,
    FailureCode.emailTaken => l.emailTaken,
    FailureCode.phoneTaken => l.phoneTaken,
    FailureCode.weakPassword => l.passwordTooShort,
    FailureCode.maxActiveOrders => l.maxOrdersReached(maxOrders),
    FailureCode.notEnoughCylinders => l.notEnoughCylinders,
    FailureCode.orderNotAvailable => l.orderTaken,
    FailureCode.orderTooFar => l.orderTooFar,
    FailureCode.driverOffline => l.driverOffline,
    FailureCode.notVerifiedDriver => l.notVerifiedError,
    FailureCode.invalidTransition => l.orderChanged,
    FailureCode.documentExpired => l.documentExpired,
    FailureCode.permissionDenied => l.permissionDenied,
    FailureCode.network => l.networkError,
    _ => l.errorWithCode(f.code.value),
  };
}

String vehicleTypeLabel(AppLocalizations l, String code) => switch (code) {
      'pickup' => l.vehiclePickup,
      'van' => l.vehicleVan,
      'small_truck' => l.vehicleSmallTruck,
      'truck' => l.vehicleTruck,
      'tricycle' => l.vehicleTricycle,
      _ => code,
    };

String orderStatusLabel(AppLocalizations l, OrderStatus s) => switch (s) {
      OrderStatus.accepted => l.statusAccepted,
      OrderStatus.onTheWay => l.statusOnTheWay,
      OrderStatus.delivered => l.awaitingConfirmation,
      OrderStatus.cancelled || OrderStatus.expired => l.cancelled,
      OrderStatus.pending => l.statusAccepted,
    };

Future<void> openNavigation(double lat, double lng) async {
  final native = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      await canLaunchUrl(native)) {
    await launchUrl(native);
    return;
  }
  await launchUrl(
    Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    ),
    mode: LaunchMode.externalApplication,
  );
}

Future<void> callPhone(String phone) =>
    launchUrl(Uri(scheme: 'tel', path: phone));

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
            color: AppColors.brandDeep.withValues(alpha: 0.15),
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

class Tag extends StatelessWidget {
  const Tag(this.text, this.color, {super.key});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: context.text.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Approval state chip (drivers.status).
class DriverStatusTag extends StatelessWidget {
  const DriverStatusTag({super.key, required this.driver});
  final DriverProfile driver;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (driver.status) {
      DriverStatus.approved => Tag(l.verified, context.accent),
      DriverStatus.pending => Tag(l.underReview, AppColors.warning),
      DriverStatus.rejected => Tag(l.statusRejected, AppColors.danger),
      DriverStatus.suspended => Tag(l.statusSuspended, Colors.grey),
    };
  }
}

/// Why the distributor can't go online yet, with the way forward.
class DriverStatusBanner extends StatelessWidget {
  const DriverStatusBanner({super.key, required this.driver, required this.onRefresh});
  final DriverProfile driver;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reason = driver.statusReason ?? '-';
    final (icon, color, text) = switch (driver.status) {
      DriverStatus.rejected => (Icons.block_rounded, AppColors.danger, l.rejectedBody(reason)),
      DriverStatus.suspended => (Icons.pause_circle_rounded, Colors.grey, l.suspendedBody(reason)),
      _ => (Icons.hourglass_top_rounded, AppColors.warning, l.pendingApprovalBody),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: context.text.bodySmall),
                if (driver.status != DriverStatus.suspended)
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(l.uploadDocuments),
                  ),
              ],
            ),
          ),
          IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: context.accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.value, this.size = 16});
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

class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.onBrand,
        ),
      );
}
