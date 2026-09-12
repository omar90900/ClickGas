import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors.dart';
import '../models.dart';

/// The signed-in user's notification history (`notifications`, newest
/// first) and their notification preferences on `profiles`.
class NotificationsRepository {
  NotificationsRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> inbox({int limit = 50}) =>
      guard('notifications.inbox', () async {
        final uid = _client.auth.currentUser?.id;
        if (uid == null) return const <AppNotification>[];
        final rows = await _client
            .from('notifications')
            .select('id, kind, title_ar, body_ar, title_en, body_en, data, created_at, read_at')
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(limit);
        return rows.map(AppNotification.fromMap).toList();
      });

  /// For the badge (capped at 99).
  Future<int> unreadCount() => guard('notifications.unread', () async {
        final uid = _client.auth.currentUser?.id;
        if (uid == null) return 0;
        final rows = await _client
            .from('notifications')
            .select('id')
            .eq('user_id', uid)
            .isFilter('read_at', null)
            .limit(99);
        return rows.length;
      });

  /// Marks everything read; returns how many were unread.
  Future<int> markAllRead() => guard('notifications.mark_read', () async {
        final value = await _client.rpc('mark_notifications_read');
        return value is int ? value : 0;
      });

  /// Language for pushes and which kinds to receive (null = unchanged).
  Future<Profile> updatePreferences(
    String userId, {
    String? locale,
    bool? orderUpdates,
    bool? newOrders,
  }) =>
      guard('notifications.preferences', () async {
        final row = await _client
            .from('profiles')
            .update({
              'locale': ?locale,
              'notify_order_updates': ?orderUpdates,
              'notify_new_orders': ?newOrders,
            })
            .eq('id', userId)
            .select()
            .single();
        return Profile.fromMap(row);
      });
}
