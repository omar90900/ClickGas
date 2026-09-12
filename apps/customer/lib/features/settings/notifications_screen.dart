import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../widgets/common.dart';

/// Everything the platform told this customer (last 60 days).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.notificationsTitle)),
      body: NotificationInbox(
        repository: context.read<NotificationsRepository>(),
        emptyTitle: l.notificationsEmpty,
        emptyBody: l.notificationsEmptyBody,
        timeAgo: (t) => _timeAgo(context, t),
        errorBuilder: (context, error, retry) =>
            ErrorView(message: failureText(context, error), onRetry: retry),
      ),
    );
  }
}

String _timeAgo(BuildContext context, DateTime time) {
  final l = context.l10n;
  final age = DateTime.now().difference(time);
  if (age.inMinutes < 1) return l.justNow;
  if (age.inMinutes < 60) return l.minutesAgo(age.inMinutes);
  if (age.inHours < 24) return l.hoursAgo(age.inHours);
  return DateFormat.MMMd(context.lang).add_jm().format(time);
}
