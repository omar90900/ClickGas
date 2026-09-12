import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors.dart';
import '../logger.dart';

/// Email/phone + password authentication on Supabase Auth, shared by both
/// apps. Throws only [AppFailure] (see docs/errors.md).
///
/// Phone login: `login_email_for_phone` checks the password in the database
/// (rate limited) and returns the account email, then Supabase Auth signs in
/// with it. See docs/decisions/0005-phone-login.md.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;
  User? get currentUser => _auth.currentUser;
  Stream<AuthState> get changes => _auth.onAuthStateChange;

  /// Returns `true` when the user is signed in right away, `false` when the
  /// project still requires email confirmation.
  ///
  /// [extra] is added to the sign-up metadata read by the `handle_new_user`
  /// trigger - the distributor app sends `account_type: 'driver'` plus
  /// vehicle details there.
  Future<bool> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required int cityId,
    Map<String, dynamic> extra = const {},
  }) =>
      guard('auth.sign_up', () async {
        final taken = await _client.rpc(
          'is_phone_registered',
          params: {'p_phone': phone},
        );
        if (taken == true) throw const AppFailure(FailureCode.phoneTaken);

        final res = await _auth.signUp(
          email: email.trim().toLowerCase(),
          password: password,
          data: {
            'full_name': fullName.trim(),
            'phone': phone,
            'city_id': cityId,
            ...extra,
          },
        );
        Log.i('signed_up', {
          'account_type': extra['account_type'] ?? 'customer',
          'session': res.session != null,
        });
        return res.session != null;
      });

  Future<void> signInWithEmail(String email, String password) =>
      guard('auth.sign_in_email', () async {
        await _auth.signInWithPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );
        Log.i('signed_in', {'method': 'email'});
      });

  Future<void> signInWithPhone(String phone, String password) =>
      guard('auth.sign_in_phone', () async {
        final email = await _client.rpc(
          'login_email_for_phone',
          params: {'p_phone': phone, 'p_password': password},
        );
        if (email is! String || email.isEmpty) {
          throw const AppFailure(FailureCode.invalidCredentials);
        }
        await _auth.signInWithPassword(email: email, password: password);
        Log.i('signed_in', {'method': 'phone'});
      });

  Future<void> signOut() async {
    Log.i('signed_out');
    await _auth.signOut();
  }
}
