import 'dart:async';

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'driver_repository.dart';

/// Online/offline + live location. While online, GPS fixes are written to
/// `drivers` at most every 5 seconds; on Android it runs as a foreground
/// service so tracking continues with the screen off.
class TrackingService extends ChangeNotifier {
  TrackingService(this._location, this._drivers);

  static const writeInterval = Duration(seconds: 5);

  final LocationService _location;
  final DriverRepository _drivers;
  StreamSubscription<Position>? _sub;
  Position? _position;
  DateTime? _lastWrite;
  String? _driverId;

  bool get isOnline => _sub != null;
  Position? get position => _position;

  Future<void> goOnline(
    String driverId, {
    required String notificationTitle,
    required String notificationText,
  }) async {
    _driverId = driverId;
    final first = await _location.current();
    _position = first;
    await _drivers.updateLocation(driverId, first.latitude, first.longitude, first.heading);
    await _drivers.setOnline(driverId, true);
    _lastWrite = DateTime.now();
    await _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: _settings(notificationTitle, notificationText),
    ).listen(_onPosition, onError: (Object e) => debugPrint('GPS error: $e'));
    notifyListeners();
  }

  Future<void> goOffline() async {
    await _sub?.cancel();
    _sub = null;
    notifyListeners();
    final id = _driverId;
    if (id != null) {
      try {
        await _drivers.setOnline(id, false);
      } catch (e) {
        debugPrint('Going offline failed: $e');
      }
    }
  }

  /// Location for screens that need it while offline (e.g. the map).
  Future<Position?> locateOnce() async {
    try {
      _position = await _location.current();
      notifyListeners();
    } catch (_) {}
    return _position;
  }

  void _onPosition(Position p) {
    _position = p;
    notifyListeners();
    final now = DateTime.now();
    final last = _lastWrite;
    if (last != null && now.difference(last) < writeInterval) return;
    _lastWrite = now;
    final id = _driverId;
    if (id == null) return;
    _drivers
        .updateLocation(id, p.latitude, p.longitude, p.heading)
        .catchError((Object e) => debugPrint('Location write failed: $e'));
  }

  LocationSettings _settings(String title, String text) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: writeInterval,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: title,
          notificationText: text,
          notificationChannelName: 'Live location',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
