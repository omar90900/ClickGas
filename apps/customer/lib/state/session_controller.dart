import 'dart:async';

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'my_orders_controller.dart';

enum SessionStatus { initializing, signedOut, loadingProfile, ready, profileError }

/// Single source of truth for "who is signed in": follows Supabase auth,
/// loads the matching `profiles` row, and binds the order stream to it.
/// Once signed in, this phone is registered for pushes, and the language of
/// pushes follows the app language.
class SessionController extends ChangeNotifier {
  SessionController(
    this._auth,
    this._profiles,
    this._orders,
    this._settings,
    this._notifications,
  ) {
    _sub = _auth.changes.listen((state) => _handleUser(state.session?.user));
    _settings.addListener(_syncLocale);
    // Start outside the build phase that created this controller.
    scheduleMicrotask(() => _handleUser(_auth.currentUser));
  }

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final MyOrdersController _orders;
  final AppSettings _settings;
  final NotificationsRepository _notifications;
  late final StreamSubscription<AuthState> _sub;

  SessionStatus _status = SessionStatus.initializing;
  Profile? _profile;
  String? _userId;

  SessionStatus get status => _status;
  Profile? get profile => _profile;

  Future<void> _handleUser(User? user) async {
    if (user?.id == _userId && _status != SessionStatus.initializing) return;
    _userId = user?.id;
    if (user == null) {
      _profile = null;
      _status = SessionStatus.signedOut;
      _orders.bind(null);
      notifyListeners();
      return;
    }
    await _loadProfile(user.id);
  }

  Future<void> _loadProfile(String userId) async {
    _status = SessionStatus.loadingProfile;
    notifyListeners();
    try {
      final profile = await _profiles.fetch(userId);
      if (userId != _userId) return; // signed out meanwhile
      _profile = profile;
      _status = profile == null ? SessionStatus.profileError : SessionStatus.ready;
    } catch (e) {
      debugPrint('Profile load failed: $e');
      if (userId != _userId) return;
      _status = SessionStatus.profileError;
    }
    _orders.bind(_status == SessionStatus.ready ? userId : null);
    notifyListeners();
    if (_status == SessionStatus.ready) {
      unawaited(PushService.instance.register());
      unawaited(_syncLocale());
    }
  }

  Future<void> retry() async {
    final id = _userId;
    if (id != null) await _loadProfile(id);
  }

  void updateProfile(Profile profile) {
    _profile = profile;
    notifyListeners();
  }

  /// Which notifications this user receives on their phone.
  Future<void> setNotifyOrderUpdates(bool value) async {
    final p = _profile;
    if (p == null) return;
    _profile = await _notifications.updatePreferences(p.id, orderUpdates: value);
    notifyListeners();
  }

  String get _appLanguage =>
      (_settings.locale ??
              AppSettings.resolve(PlatformDispatcher.instance.locale, AppSettings.supportedLocales))
          .languageCode;

  Future<void> _syncLocale() async {
    final p = _profile;
    final lang = _appLanguage;
    if (p == null || p.locale == lang) return;
    try {
      _profile = await _notifications.updatePreferences(p.id, locale: lang);
      notifyListeners();
    } catch (e) {
      Log.w('locale_sync_failed', {'error': e.toString()});
    }
  }

  Future<void> signOut() async {
    await PushService.instance.unregister();
    await _auth.signOut();
  }

  @override
  void dispose() {
    _settings.removeListener(_syncLocale);
    _sub.cancel();
    super.dispose();
  }
}
