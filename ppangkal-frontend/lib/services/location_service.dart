import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'walk_filter.dart';

/// Source of GPS fixes for the tour flow. Abstract so the controller can be
/// driven by a fake in tests and on platforms without GPS.
abstract class PositionSource {
  /// Asks for location permission if needed. Returns false when the user
  /// denied it or location services are off — callers fall back to
  /// step-based estimates rather than failing the tour.
  Future<bool> ensurePermission();

  /// Continuous fixes while a tour is active. On Android this runs as a
  /// foreground service with an ongoing notification, so tracking survives
  /// screen-off and isn't killed by the OS (FRONTEND_API_GUIDE.md §4).
  Stream<GeoSample> watch();

  /// A single current fix for the bakery search, or null if unavailable.
  Future<GeoSample?> current();
}

class GeolocatorPositionSource implements PositionSource {
  @override
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  @override
  Stream<GeoSample> watch() async* {
    // Android 13+ hides the foreground-service notification without this;
    // tracking still works if denied, the user just can't see it.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    }
    yield* _watch();
  }

  Stream<GeoSample> _watch() {
    return Geolocator.getPositionStream(locationSettings: _trackingSettings()).map(_toSample);
  }

  @override
  Future<GeoSample?> current() async {
    try {
      if (!await ensurePermission()) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return _toSample(position);
    } catch (_) {
      // Timeout or platform error — the bakery list falls back to the
      // city-center coordinate instead of blocking on GPS.
      return null;
    }
  }

  static LocationSettings _trackingSettings() {
    const distanceFilterM = 5;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterM,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: '빵투어 진행 중',
          notificationText: '이동 거리와 걸음 수를 측정하고 있어요.',
          notificationChannelName: '빵투어 추적',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterM,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: distanceFilterM);
  }

  static GeoSample _toSample(Position p) => GeoSample(
        latitude: p.latitude,
        longitude: p.longitude,
        timestamp: p.timestamp,
        accuracyM: p.accuracy,
      );
}
