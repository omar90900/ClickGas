import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_service.dart';

/// Local notifications with sound (heads-up on Android), shown for order
/// events the apps receive through Supabase Realtime while they are running.
/// When the device also receives pushes ([PushService.registered]), these
/// are shown only while the app is on screen, so nothing arrives twice.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  /// Also used by pushes from the server (Edge Function send-push).
  static const channelId = 'order_updates';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _nextId = 1;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      'Order updates',
      channelDescription: 'Order status changes and new orders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
    ),
  );

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      // Create the channel up front so pushes that arrive while the app is
      // closed use it (sound, heads-up).
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            channelId,
            'Order updates',
            description: 'Order status changes and new orders',
            importance: Importance.high,
          ));
      _ready = true;
    } catch (e) {
      debugPrint('Notifications init failed: $e');
    }
  }

  /// Android 13+ / iOS permission prompt (no-op if already decided).
  Future<void> requestPermission() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// [force] shows it even in the background (used for pushes that arrive
  /// while the app is open).
  Future<void> show(String title, String body, {bool force = false}) async {
    if (!_ready) return;
    final onScreen = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!force && PushService.instance.registered && !onScreen) return;
    try {
      await _plugin.show(
        id: _nextId++,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }
}
