import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'logger.dart';
import 'notification_service.dart';

/// Notifications that reach the phone when the app is closed.
///
/// The database decides who is told what (triggers write `notifications`
/// rows); a Supabase Edge Function sends them through Firebase Cloud
/// Messaging to the device tokens registered here
/// (docs/decisions/0014-push-notifications.md).
///
/// Safe without Firebase: if `google-services.json` is missing, [init] logs
/// once and everything else is a no-op, so the apps keep their in-app
/// notifications.
class PushService {
  PushService._();
  static final instance = PushService._();

  bool _available = false;
  String? _app;
  String? _token;
  StreamSubscription<String>? _refresh;

  /// Firebase is configured on this build.
  bool get available => _available;

  /// This device receives pushes. The apps' own local notifications are then
  /// shown only while the app is on screen, so nothing arrives twice.
  bool get registered => _token != null;

  /// Kinds the apps already announce themselves while open (from Realtime).
  static const localKinds = {
    'order_accepted',
    'order_on_the_way',
    'order_delivered',
    'order_released',
    'order_expired',
    'new_order',
    'order_confirmed',
  };

  Future<void>? _starting;

  /// Once at start-up, after Supabase. [app] is customer / distributor. The
  /// apps don't wait for it; [register] does.
  Future<void> init({required String app}) => _starting ??= _init(app);

  Future<void> _init(String app) async {
    if (kIsWeb || _available) return;
    _app = app;
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      Log.i('push_unavailable', {'reason': 'Firebase not configured on this build'});
      return;
    }
    // Foreground messages are not shown by Android; show the kinds the app
    // doesn't already announce itself.
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null || localKinds.contains(message.data['kind'])) return;
      NotificationService.instance.show(n.title ?? '', n.body ?? '', force: true);
    });
  }

  /// After sign-in: ask permission, then register this device's token.
  Future<void> register() async {
    await _starting;
    if (!_available) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return;
      await _save(token);
      _refresh ??= messaging.onTokenRefresh.listen((t) => _save(t).catchError((Object _) {}));
    } catch (e) {
      Log.w('push_register_failed', {'error': e.toString()});
    }
  }

  Future<void> _save(String token) async {
    await Supabase.instance.client.rpc('register_device', params: {
      'p_token': token,
      'p_app': _app,
      'p_platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    });
    _token = token;
    Log.i('push_registered', {'app': _app});
  }

  /// Before sign-out, so the next person on this phone doesn't get pushes.
  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    _token = null;
    try {
      await Supabase.instance.client.rpc('unregister_device', params: {'p_token': token});
    } catch (_) {
      // The server also drops tokens Firebase reports as invalid.
    }
  }
}
