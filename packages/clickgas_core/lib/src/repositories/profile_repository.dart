import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors.dart';
import '../models.dart';

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
