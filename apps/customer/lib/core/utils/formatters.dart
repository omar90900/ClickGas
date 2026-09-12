import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';

// JordanPhone and Validators now live in the shared package.
export 'package:clickgas_core/clickgas_core.dart' show JordanPhone, Validators;

class Fmt {
  /// JOD has 3 decimals (1 JOD = 1000 fils).
  static final _money = NumberFormat('0.000', 'en');

  static String money(BuildContext context, double amount) =>
      AppLocalizations.of(context).price(_money.format(amount));

  static String distance(BuildContext context, double meters) {
    final l = AppLocalizations.of(context);
    return meters < 1000
        ? l.distanceM(meters.round().toString())
        : l.distanceKm((meters / 1000).toStringAsFixed(1));
  }

  static String dateTime(BuildContext context, DateTime? value) {
    if (value == null) return '';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).add_jm().format(value);
  }

  static String time(BuildContext context, DateTime? value) {
    if (value == null) return '';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.jm(locale).format(value);
  }
}
