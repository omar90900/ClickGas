import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors.dart';
import '../models.dart';

class OrderCounts {
  const OrderCounts({this.total = 0, this.delivered = 0});
  final int total;
  final int delivered;
}

/// The signed-in user's `profiles` row. Throws only [AppFailure]; a phone
/// already used by another account surfaces as [FailureCode.phoneTaken].
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile?> fetch(String userId) => guard('profile.fetch', () async {
        final row = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        return row == null ? null : Profile.fromMap(row);
      });

  /// Orders placed (customer) or taken (distributor), for the profile header.
  /// RLS already limits the rows to the user's own orders.
  Future<OrderCounts> orderCounts(String userId, {bool asDriver = false}) =>
      guard('profile.order_counts', () async {
        final rows = await _client
            .from('orders')
            .select('status')
            .eq(asDriver ? 'driver_id' : 'customer_id', userId);
        return OrderCounts(
          total: rows.length,
          delivered: rows.where((r) => r['status'] == 'delivered').length,
        );
      });

  /// Only the columns the database lets users change (see column grants).
  Future<Profile> update(
    String userId, {
    required String fullName,
    required String phone,
    required int? cityId,
  }) =>
      guard('profile.update', () async {
        final row = await _client
            .from('profiles')
            .update({
              'full_name': fullName.trim(),
              'phone': phone,
              'city_id': cityId,
            })
            .eq('id', userId)
            .select()
            .single();
        return Profile.fromMap(row);
      });
}
