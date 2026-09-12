import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'logger.dart';

/// Keeps the Supabase access token fresh for as long as the app runs.
///
/// The SDK refreshes the token (valid 1 hour) only while the app is in the
/// foreground; it pauses when the app goes to the background. The
/// distributor app keeps writing its location from a foreground service, and
/// a dashboard tab keeps polling while hidden, so after an hour every call
/// failed with "JWT expired". This keeper:
///
/// * checks every minute and refreshes when under 5 minutes are left;
/// * lets [guard] refresh and retry once when a call still hits an expired
///   token ([isExpiredError]);
/// * signs out locally when the session can't be renewed (refresh token
///   revoked), so the app returns to its sign-in screen instead of failing.
///
/// Installed once in each app's `main()`; see docs/runbooks/session-expired.md.
class SessionKeeper {
  SessionKeeper._(this._auth) {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => ensureFresh());
  }

  static SessionKeeper? instance;

  static void install(GoTrueClient auth) {
    instance?._timer.cancel();
    instance = SessionKeeper._(auth);
  }

  final GoTrueClient _auth;
  late final Timer _timer;
  Future<bool>? _refreshing;

  /// Refreshes when the token expires within [margin]. Never throws.
  Future<void> ensureFresh({Duration margin = const Duration(minutes: 5)}) async {
    final expiresAt = _auth.currentSession?.expiresAt;
    if (expiresAt == null) return;
    final left = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000).difference(DateTime.now());
    if (left > margin) return;
    await refresh();
  }

  /// One refresh at a time; concurrent callers share it. True on success.
  Future<bool> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    if (_auth.currentSession == null) return false;
    try {
      await _auth.refreshSession();
      Log.i('session_refreshed');
      return true;
    } on AuthRetryableFetchException catch (e) {
      // Offline: keep the session and try again later.
      Log.w('session_refresh_offline', {'message': e.message});
      return false;
    } on AuthException catch (e) {
      Log.w('session_refresh_failed', {'code': e.code, 'message': e.message});
      await _auth.signOut(scope: SignOutScope.local);
      return false;
    } catch (e) {
      Log.w('session_refresh_failed', {'error': e.toString()});
      return false;
    }
  }

  /// Errors that mean "the access token expired" from PostgREST (PGRST301 /
  /// PGRST303), Storage ("jwt expired") or Realtime ("Token has expired").
  static bool isExpiredError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('jwt expired') ||
        text.contains('pgrst303') ||
        text.contains('pgrst301') ||
        text.contains('token has expired') ||
        text.contains('invalidjwttoken');
  }
}
