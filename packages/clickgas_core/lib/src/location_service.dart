import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationIssue { serviceDisabled, denied, deniedForever }

class LocationException implements Exception {
  const LocationException(this.issue);
  final LocationIssue issue;
}

class LocationService {
  Future<void> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationIssue.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationIssue.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationIssue.denied);
    }
  }

  Future<Position> current() async {
    await ensurePermission();
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      final last = kIsWeb ? null : await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  Future<void> openSettingsFor(LocationIssue issue) async {
    if (issue == LocationIssue.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}
