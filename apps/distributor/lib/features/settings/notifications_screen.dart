import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../widgets/common.dart';

/// New orders, confirmations, charges and account messages (last 60 days).
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
        errorBuilder: (context, error, retry) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failureText(context, error), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                IconButton.filledTonal(
                  onPressed: retry,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        ),
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
