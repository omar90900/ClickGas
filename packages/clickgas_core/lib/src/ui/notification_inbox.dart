import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models.dart';
import '../repositories/notifications_repository.dart';
import 'settings_kit.dart';

/// The user's notification history, newest first. Opening it marks
/// everything read; unread items stay highlighted until the screen closes.
/// Texts come from the app.
class NotificationInbox extends StatefulWidget {
  const NotificationInbox({
    super.key,
    required this.repository,
    required this.emptyTitle,
    required this.emptyBody,
    required this.timeAgo,
    required this.errorBuilder,
  });

  final NotificationsRepository repository;
  final String emptyTitle;
  final String emptyBody;
  final String Function(DateTime time) timeAgo;
  final Widget Function(BuildContext context, Object error, VoidCallback retry) errorBuilder;

  @override
  State<NotificationInbox> createState() => _NotificationInboxState();
}

class _NotificationInboxState extends State<NotificationInbox> {
  late Future<List<AppNotification>> _items = _load();

  Future<List<AppNotification>> _load() async {
    final items = await widget.repository.inbox();
    if (items.any((n) => !n.isRead)) {
      widget.repository.markAllRead().ignore();
    }
    return items;
  }

  void _reload() => setState(() => _items = _load());

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return FutureBuilder<List<AppNotification>>(
      future: _items,
      builder: (context, snap) {
        if (snap.hasError) return widget.errorBuilder(context, snap.error!, _reload);
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _items.catchError((Object _) => <AppNotification>[]);
          },
          child: items.isEmpty
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
                  children: [_Empty(title: widget.emptyTitle, body: widget.emptyBody)],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return _NotificationCard(
                      notification: n,
                      lang: lang,
                      time: n.createdAt == null ? '' : widget.timeAgo(n.createdAt!.toLocal()),
                    );
                  },
                ),
        );
      },
    );
  }
}

/// Icon and colour for each kind written by the database triggers.
(IconData, Color?) _style(String kind) => switch (kind) {
      'order_accepted' => (Icons.check_circle_outline_rounded, null),
      'order_on_the_way' => (Icons.local_shipping_outlined, null),
      'order_delivered' || 'order_confirmed' => (Icons.done_all_rounded, null),
      'order_released' => (Icons.sync_rounded, AppColors.warning),
      'order_expired' => (Icons.timer_off_outlined, AppColors.warning),
      'order_cancelled' || 'order_unassigned' => (Icons.cancel_outlined, AppColors.danger),
      'new_order' => (Icons.notifications_active_outlined, null),
      'order_assigned' => (Icons.assignment_ind_outlined, AppColors.info),
      'account_approved' => (Icons.verified_user_outlined, null),
      'account_rejected' || 'account_suspended' => (Icons.gpp_bad_outlined, AppColors.danger),
      'charge_created' => (Icons.receipt_long_outlined, AppColors.danger),
      'charge_paid' || 'charge_waived' => (Icons.receipt_long_outlined, null),
      'document_approved' => (Icons.task_outlined, null),
      'document_rejected' => (Icons.description_outlined, AppColors.danger),
      'order_pay_on_arrival' || 'wallet_saved' => (Icons.account_balance_wallet_outlined, AppColors.info),
      'order_payment_claimed' => (Icons.account_balance_wallet_outlined, AppColors.warning),
      'order_payment_confirmed' => (Icons.verified_outlined, null),
      'order_payment_disputed' => (Icons.report_gmailerrorred_outlined, AppColors.danger),
      _ => (Icons.notifications_none_rounded, null),
    };

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.lang, required this.time});

  final AppNotification notification;
  final String lang;
  final String time;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final (icon, color) = _style(n.kind);
    final unread = !n.isRead;
    final body = n.body(lang);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unread
            ? Color.alphaBlend(AppColors.brand.withValues(alpha: context.isDark ? 0.08 : 0.07), context.card)
            : context.card,
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        border: Border.all(
          color: unread ? AppColors.brand.withValues(alpha: 0.4) : context.colors.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsIcon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        n.title(lang),
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: context.text.labelSmall?.copyWith(color: context.muted)),
                    if (unread) ...[
                      const SizedBox(width: 6),
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body, style: context.text.bodyMedium?.copyWith(color: context.muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: context.isDark ? 0.14 : 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications_none_rounded, size: 42, color: context.accent),
        ),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.muted)),
      ],
    );
  }
}
