import 'dart:async';
import 'dart:math' as math;

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/admin_models.dart';
import '../l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
}

// ---------------------------------------------------------------- formatting

class Fmt {
  /// JOD has 3 decimals (1 JOD = 1000 fils).
  static final _money = NumberFormat('0.000', 'en');

  static String amount(double value) => _money.format(value);

  static String money(BuildContext context, double value) =>
      context.l10n.jod(_money.format(value));

  static String phone(String e164) => JordanPhone.display(e164);

  static String dateTime(BuildContext context, DateTime? value) =>
      value == null ? '-' : DateFormat.yMMMd(context.lang).add_jm().format(value);

  static String date(BuildContext context, DateTime? value) =>
      value == null ? '-' : DateFormat.yMMMd(context.lang).format(value);

  static String time(BuildContext context, DateTime? value) =>
      value == null ? '-' : DateFormat.jm(context.lang).format(value);

  static String shortDay(BuildContext context, DateTime value) =>
      DateFormat.Md(context.lang).format(value);

  /// "5 min ago", "3 h ago"...
  static String ago(BuildContext context, DateTime? value) {
    if (value == null) return context.l10n.never;
    final l = context.l10n;
    final d = DateTime.now().difference(value);
    if (d.inMinutes < 1) return l.justNow;
    if (d.inHours < 1) return l.minutesAgo(d.inMinutes);
    if (d.inDays < 1) return l.hoursAgo(d.inHours);
    return l.daysAgo(d.inDays);
  }

  /// "4 min", "1 h 5 min", "40 s".
  static String duration(BuildContext context, Duration d) {
    final l = context.l10n;
    if (d.inSeconds < 60) return l.seconds(math.max(d.inSeconds, 0));
    if (d.inHours < 1) return l.minutes(d.inMinutes);
    return l.hoursMinutes(d.inHours, d.inMinutes % 60);
  }
}

// ---------------------------------------------------------------- labels

String orderStatusLabel(AppLocalizations l, OrderStatus s) => switch (s) {
      OrderStatus.pending => l.statusPending,
      OrderStatus.accepted => l.statusAccepted,
      OrderStatus.onTheWay => l.statusOnTheWay,
      OrderStatus.delivered => l.statusDelivered,
      OrderStatus.cancelled => l.statusCancelled,
      OrderStatus.expired => l.statusExpired,
    };

Color orderStatusColor(OrderStatus s) => switch (s) {
      OrderStatus.pending => AppColors.warning,
      OrderStatus.accepted => AppColors.info,
      OrderStatus.onTheWay => AppColors.info,
      OrderStatus.delivered => AppColors.brandDeep,
      OrderStatus.cancelled => AppColors.danger,
      OrderStatus.expired => Colors.grey,
    };

String driverStatusLabel(AppLocalizations l, DriverStatus s) => switch (s) {
      DriverStatus.pending => l.driverPending,
      DriverStatus.approved => l.driverApproved,
      DriverStatus.rejected => l.driverRejected,
      DriverStatus.suspended => l.driverSuspended,
    };

Color driverStatusColor(DriverStatus s) => switch (s) {
      DriverStatus.pending => AppColors.warning,
      DriverStatus.approved => AppColors.brandDeep,
      DriverStatus.rejected => AppColors.danger,
      DriverStatus.suspended => Colors.grey,
    };

String documentKindLabel(AppLocalizations l, DocumentKind k) => switch (k) {
      DocumentKind.nationalId => l.docNationalId,
      DocumentKind.drivingLicence => l.docDrivingLicence,
      DocumentKind.vehicleRegistration => l.docVehicleRegistration,
      DocumentKind.agencyLetter => l.docAgencyLetter,
    };

String documentStatusLabel(AppLocalizations l, DocumentStatus s) => switch (s) {
      DocumentStatus.pending => l.docPending,
      DocumentStatus.approved => l.docApproved,
      DocumentStatus.rejected => l.docRejected,
    };

Color documentStatusColor(DocumentStatus s) => switch (s) {
      DocumentStatus.pending => AppColors.warning,
      DocumentStatus.approved => AppColors.brandDeep,
      DocumentStatus.rejected => AppColors.danger,
    };

String staffRoleLabel(AppLocalizations l, StaffRole r) => switch (r) {
      StaffRole.owner => l.roleOwner,
      StaffRole.operations => l.roleOperations,
      StaffRole.support => l.roleSupport,
    };

String staffRoleDescription(AppLocalizations l, StaffRole r) => switch (r) {
      StaffRole.owner => l.roleOwnerDesc,
      StaffRole.operations => l.roleOperationsDesc,
      StaffRole.support => l.roleSupportDesc,
    };

String chargeKindLabel(AppLocalizations l, ChargeKind k) => switch (k) {
      ChargeKind.fine => l.chargeKindFine,
      ChargeKind.itemFee => l.chargeKindItem,
      ChargeKind.other => l.chargeKindOther,
    };

String actorLabel(AppLocalizations l, UserRole? r) => switch (r) {
      null => l.actorSystem,
      UserRole.customer => l.actorCustomer,
      UserRole.driver => l.actorDriver,
      UserRole.admin => l.actorStaff,
    };

String vehicleTypeLabel(AppLocalizations l, String code) => switch (code) {
      'pickup' => l.vehiclePickup,
      'van' => l.vehicleVan,
      'small_truck' => l.vehicleSmallTruck,
      'truck' => l.vehicleTruck,
      'tricycle' => l.vehicleTricycle,
      '' => '-',
      _ => code,
    };

/// Audit trail action names (see admin_actions.action).
String actionLabel(AppLocalizations l, String action) => switch (action) {
      'driver.set_status' => l.actDriverStatus,
      'document.approve' => l.actDocumentApprove,
      'document.reject' => l.actDocumentReject,
      'account.block' => l.actAccountBlock,
      'account.unblock' => l.actAccountUnblock,
      'order.cancel' => l.actOrderCancel,
      'order.assign' => l.actOrderAssign,
      'order.return_to_queue' => l.actOrderReturn,
      'charge.create' => l.actChargeCreate,
      'charge.paid' => l.actChargePaid,
      'charge.waived' => l.actChargeWaived,
      'service.update' => l.actServiceUpdate,
      'service.create' => l.actServiceCreate,
      'fees.set' => l.actFeesSet,
      'config.update' => l.actConfigUpdate,
      'city.set_active' => l.actCitySetActive,
      'flag.set' => l.actFlagSet,
      'staff.save' => l.actStaffSave,
      'staff.remove' => l.actStaffRemove,
      'payment.resolve' => l.actPaymentResolve,
      'wallet.set_active' => l.actWalletActive,
      'wallet_provider.save' => l.actWalletProvider,
      _ => action,
    };

String targetTypeLabel(AppLocalizations l, String type) => switch (type) {
      'driver' => l.navDrivers,
      'user' => l.targetAccounts,
      'order' => l.navOrders,
      'service' => l.targetServices,
      'fees' => l.targetFees,
      'config' => l.navSettings,
      'city' => l.targetCities,
      'flag' => l.targetFlags,
      'staff' => l.navStaff,
      _ => type,
    };

// ---------------------------------------------------------------- errors

/// Translated message for any error (codes: docs/errors.md). Staff also see
/// the server detail when it explains what to fix.
String failureText(BuildContext context, Object error) {
  final l = context.l10n;
  final f = AppFailure.from(error);
  final detail = f.detail ?? '';
  return switch (f.code) {
    FailureCode.invalidCredentials => l.invalidCredentials,
    FailureCode.tooManyAttempts => l.tooManyAttempts,
    FailureCode.network => l.networkError,
    FailureCode.permissionDenied => l.permissionDenied,
    FailureCode.reasonRequired => l.reasonRequired,
    FailureCode.invalidAmount => l.invalidAmount,
    FailureCode.invalidSetting => l.invalidSetting(detail),
    FailureCode.invalidTarget => l.invalidTarget(detail),
    FailureCode.lastOwner => l.lastOwner,
    FailureCode.chargeNotOpen => l.chargeNotOpen,
    FailureCode.sessionExpired => l.sessionExpired,
    FailureCode.notFound => l.notFound,
    FailureCode.notVerifiedDriver => l.notVerifiedDriver,
    FailureCode.maxActiveOrders => l.maxActiveOrders,
    FailureCode.notEnoughCylinders => l.notEnoughCylinders,
    FailureCode.invalidTransition => l.orderChanged,
    FailureCode.orderNotCancellable => l.orderNotCancellable,
    FailureCode.noWalletAccount => l.noWalletAccount,
    FailureCode.paymentNotOpen => l.paymentNotOpen,
    FailureCode.paymentNotConfirmed => l.paymentNotConfirmed,
    _ => l.errorWithCode(f.code.value),
  };
}

// ---------------------------------------------------------------- feedback

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : null,
        width: 480,
      ),
    );
}

/// Runs a staff action and reports the result; returns true on success.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) showSnack(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, failureText(context, e), error: true);
    return false;
  }
}

Future<bool> confirmDialog(
  BuildContext context,
  String message, {
  String? title,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(message, style: ctx.text.bodyLarge),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? l.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Asks for a reason (3+ characters), which is saved in the audit trail.
Future<String?> askReason(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  bool destructive = false,
}) {
  final l = context.l10n;
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 440,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message != null) ...[
                Text(message, style: ctx.text.bodyMedium),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: controller,
                autofocus: true,
                maxLength: 200,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(labelText: l.reasonLabel, helperText: l.reasonHelper),
                validator: (v) => (v ?? '').trim().length < 3 ? l.reasonRequired : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx, controller.text.trim());
            }
          },
          child: Text(confirmLabel ?? l.confirm),
        ),
      ],
    ),
  );
}

/// Parses "12.5" or "12,500" style input to JOD with 3 decimals.
double? parseAmount(String input) {
  final cleaned = input.trim().replaceAll(',', '.');
  final value = double.tryParse(cleaned);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return (value * 1000).roundToDouble() / 1000;
}

final amountInputFormatter = FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'));

/// Amount + note dialog (payments and balance adjustments).
Future<({double amount, String note})?> askAmount(
  BuildContext context, {
  required String title,
  String? message,
  bool allowNegative = false,
  bool noteRequired = false,
  String? confirmLabel,
}) {
  final l = context.l10n;
  final amount = TextEditingController();
  final note = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<({double amount, String note})>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 440,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message != null) ...[
                Text(message, style: ctx.text.bodyMedium),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: amount,
                autofocus: true,
                inputFormatters: [amountInputFormatter],
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: l.amountLabel, suffixText: l.currency),
                validator: (v) {
                  final value = parseAmount(v ?? '');
                  if (value == null || value == 0) return l.invalidAmount;
                  if (!allowNegative && value < 0) return l.invalidAmount;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: note,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: noteRequired ? l.reasonLabel : l.noteLabel,
                  helperText: l.reasonHelper,
                ),
                validator: (v) =>
                    noteRequired && (v ?? '').trim().length < 3 ? l.reasonRequired : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx, (amount: parseAmount(amount.text)!, note: note.text.trim()));
            }
          },
          child: Text(confirmLabel ?? l.save),
        ),
      ],
    ),
  );
}

/// Settings › Send diagnostics equivalent for the dashboard.
Future<void> sendDiagnostics(BuildContext context) async {
  final l = context.l10n;
  if (!await confirmDialog(context, l.sendDiagnosticsBody, confirmLabel: l.sendDiagnostics)) {
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

Future<void> openExternal(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

Future<void> openInMaps(double lat, double lng) =>
    openExternal('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

// ---------------------------------------------------------------- loading

/// Loads [load] once (and every [refreshEvery]), shows a spinner first, an
/// error with retry when nothing loaded, and keeps showing the last data with
/// a warning when a refresh fails. [builder] gets a reload callback for use
/// after actions.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.refreshEvery,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload)
      builder;
  final Duration? refreshEvery;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late T _data;
  bool _hasData = false;
  bool _loading = true;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reload();
    final every = widget.refreshEvery;
    if (every != null) {
      _timer = Timer.periodic(every, (_) => _reload(silent: true));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _reload({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _hasData = true;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasData) {
      if (_error != null) return ErrorView(error: _error!, onRetry: _reload);
      return const LoadingView();
    }
    return Stack(
      children: [
        widget.builder(context, _data, _reload),
        if (_loading)
          const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
        if (_error != null)
          PositionedDirectional(
            top: 8,
            end: 8,
            child: Material(
              color: AppColors.warning.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(99),
              child: InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: _reload,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sync_problem_rounded, size: 16, color: Colors.black87),
                      const SizedBox(width: 6),
                      Text(context.l10n.staleData,
                          style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      color: AppColors.danger,
      title: failureText(context, error),
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

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.accent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: c.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: c),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- building blocks

class Tag extends StatelessWidget {
  const Tag(this.text, this.color, {super.key, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(
            text,
            style: context.text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class OrderStatusTag extends StatelessWidget {
  const OrderStatusTag(this.status, {super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) =>
      Tag(orderStatusLabel(context.l10n, status), orderStatusColor(status));
}

class DriverStatusTag extends StatelessWidget {
  const DriverStatusTag(this.status, {super.key});
  final DriverStatus status;

  @override
  Widget build(BuildContext context) =>
      Tag(driverStatusLabel(context.l10n, status), driverStatusColor(status));
}

/// A card with a title row (and optional actions) above its content.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 16),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: context.text.bodySmall
                                ?.copyWith(color: context.colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.emphasize = false, this.ltr = false});

  final String label;
  final String value;
  final bool emphasize;

  /// Phone numbers and codes read left to right in Arabic too.
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)
        : context.text.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: style?.copyWith(color: emphasize ? null : context.colors.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: style,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A headline number on the Overview page.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.color,
    this.alert = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;
  final Color? color;
  final bool alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = alert ? AppColors.danger : (color ?? context.accent);
    return Card(
      shape: alert
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.danger, width: 1.5),
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: c),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(value,
                          style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    ),
                    if (caption != null)
                      Text(caption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: alert ? AppColors.danger : context.colors.onSurfaceVariant,
                            fontWeight: alert ? FontWeight.w700 : null,
                          )),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right_rounded, color: context.colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays out children in equal columns that wrap on narrow screens.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minTileWidth = 250, this.spacing = 12});

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = math.max(1, (constraints.maxWidth + spacing) ~/ (minTileWidth + spacing));
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: width, child: c)],
      );
    });
  }
}

/// A DataTable in a card that scrolls sideways on narrow screens.
class TableCard extends StatelessWidget {
  const TableCard({super.key, required this.columns, required this.rows, this.header, this.footer});

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?header,
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingTextStyle: context.text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurfaceVariant,
                  ),
                  columnSpacing: 24,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 64,
                  columns: columns,
                  rows: rows,
                ),
              ),
            ),
          ),
          ?footer,
        ],
      ),
    );
  }
}

/// Two-line cell: name above a smaller line (phone, plate...).
class TwoLine extends StatelessWidget {
  const TwoLine(this.title, this.subtitle, {super.key, this.ltrSubtitle = false});

  final String title;
  final String? subtitle;
  final bool ltrSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(
            subtitle!,
            textDirection: ltrSubtitle ? TextDirection.ltr : null,
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.hint, required this.onSubmitted, this.initial = ''});

  final String hint;
  final String initial;
  final ValueChanged<String> onSubmitted;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _controller = TextEditingController(text: widget.initial);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => widget.onSubmitted(value.trim()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _changed,
      onSubmitted: (v) {
        _debounce?.cancel();
        widget.onSubmitted(v.trim());
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.clear,
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _controller.clear();
                  _changed('');
                },
              ),
      ),
    );
  }
}

/// A page body: padded, scrollable column with a max width.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 1400});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- side panel

/// Slides a panel in from the end side (right in English, left in Arabic).
Future<T?> showSidePanel<T>(BuildContext context, {required WidgetBuilder builder, double width = 680}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Material(
        elevation: 12,
        color: ctx.colors.surface,
        child: SizedBox(
          width: math.min(width, MediaQuery.sizeOf(ctx).width),
          height: double.infinity,
          child: SafeArea(child: builder(ctx)),
        ),
      ),
    ),
    transitionBuilder: (ctx, animation, _, child) {
      final rtl = Directionality.of(ctx) == TextDirection.rtl;
      return SlideTransition(
        position: Tween(begin: Offset(rtl ? -1 : 1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

/// Header + scrolling body for [showSidePanel].
class PanelScaffold extends StatelessWidget {
  const PanelScaffold({super.key, required this.title, required this.body, this.subtitle, this.actions = const []});

  final String title;
  final Widget? subtitle;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    ?subtitle,
                  ],
                ),
              ),
              ...actions,
              IconButton(
                tooltip: context.l10n.close,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// Small coloured dot with a tooltip (online / offline / stale).
class Dot extends StatelessWidget {
  const Dot(this.color, {super.key, this.tooltip, this.size = 10});
  final Color color;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    return tooltip == null ? dot : Tooltip(message: tooltip!, child: dot);
  }
}
