import 'dart:async';

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/driver_repository.dart';
import 'active_orders_controller.dart';

enum SessionStatus { initializing, signedOut, loading, ready, error }

/// Who is signed in: Supabase auth -> `profiles` row -> `drivers` row.
/// Once signed in, this phone is registered for pushes, and the language of
/// pushes follows the app language.
class DriverSession extends ChangeNotifier {
  DriverSession(
    this._auth,
    this._profiles,
    this._drivers,
    this._orders,
    this._settings,
    this._notifications,
  ) {
    _sub = _auth.changes.listen((s) => _handleUser(s.session?.user));
    _settings.addListener(_syncLocale);
    scheduleMicrotask(() => _handleUser(_auth.currentUser));
  }

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final DriverRepository _drivers;
  final ActiveOrdersController _orders;
  final AppSettings _settings;
  final NotificationsRepository _notifications;
  late final StreamSubscription<AuthState> _sub;

  SessionStatus _status = SessionStatus.initializing;
  Profile? _profile;
  DriverProfile? _driver;
  String? _userId;

  SessionStatus get status => _status;
  Profile? get profile => _profile;
  DriverProfile? get driver => _driver;

  Future<void> _handleUser(User? user) async {
    if (user?.id == _userId && _status != SessionStatus.initializing) return;
    _userId = user?.id;
    if (user == null) {
      _profile = null;
      _driver = null;
      _status = SessionStatus.signedOut;
      _orders.bind(null);
      notifyListeners();
      return;
    }
    await _load(user.id);
  }

  Future<void> _load(String userId) async {
    _status = SessionStatus.loading;
    notifyListeners();
    try {
      final profile = await _profiles.fetch(userId);
      final driver = profile?.role == UserRole.driver
          ? await _drivers.fetchMe(userId)
          : null;
      if (userId != _userId) return;
      _profile = profile;
      _driver = driver;
      _status = profile == null ? SessionStatus.error : SessionStatus.ready;
    } catch (e) {
      debugPrint('Session load failed: $e');
      if (userId != _userId) return;
      _status = SessionStatus.error;
    }
    _orders.bind(_driver?.isVerified == true ? _driver!.id : null);
    notifyListeners();
    if (_status == SessionStatus.ready) {
      unawaited(PushService.instance.register());
      unawaited(_syncLocale());
    }
  }

  Future<void> retry() async {
    final id = _userId;
    if (id != null) await _load(id);
  }

  /// Re-read the drivers row (e.g. after the admin verifies the account or
  /// a delivery lowers the cylinder count).
  Future<void> refreshDriver() async {
    final id = _userId;
    if (id == null) return;
    try {
      final d = await _drivers.fetchMe(id);
      if (d == null) return;
      final becameVerified = d.isVerified && _driver?.isVerified != true;
      _driver = d;
      if (becameVerified) _orders.bind(d.id);
      notifyListeners();
    } catch (_) {}
  }

  void setProfile(Profile p) {
    _profile = p;
    notifyListeners();
  }

  void setDriver(DriverProfile d) {
    _driver = d;
    notifyListeners();
  }

  /// Which notifications this distributor receives on their phone.
  Future<void> setNotificationPrefs({bool? orderUpdates, bool? newOrders}) async {
    final p = _profile;
    if (p == null) return;
    _profile = await _notifications.updatePreferences(
      p.id,
      orderUpdates: orderUpdates,
      newOrders: newOrders,
    );
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
