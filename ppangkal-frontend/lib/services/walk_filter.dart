import 'dart:math' as math;

/// One GPS fix, decoupled from any location package so [WalkFilter] stays
/// pure Dart and unit-testable.
class GeoSample {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  /// Horizontal accuracy radius in meters (smaller is better).
  final double accuracyM;

  const GeoSample({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyM = 0,
  });
}

/// GPS speed filter (FRONTEND_API_GUIDE.md §2 6단계, §4): only movement at
/// ≤20km/h counts as walking. Anything faster (bike/bus/car) is excluded
/// from both distance and duration, so `POST /tours/:tourId/stops` never
/// reports a bus ride as calories burned.
///
/// Speed is derived from consecutive fixes (distance ÷ elapsed time) rather
/// than the platform's `speed` field, which is often 0 or missing on
/// Android when the fused provider interpolates.
class WalkFilter {
  static const double maxWalkingSpeedKmh = 20;

  /// Below this the user is effectively standing still.
  static const double minWalkingSpeedKmh = 1;

  /// Fixes worse than this are too noisy to measure a leg with — dropping
  /// them avoids a single 80m GPS jump reading as a sprint.
  static const double maxAccuracyM = 50;

  /// Longer gaps (tunnel, app paused without the foreground service) can't
  /// tell a walk from a ride, so the interval is skipped rather than guessed.
  static const Duration maxGap = Duration(minutes: 5);

  GeoSample? _last;
  double _walkedDistanceM = 0;
  Duration _walkedDuration = Duration.zero;
  bool _lastIntervalWasVehicle = false;

  double get walkedDistanceM => _walkedDistanceM;
  Duration get walkedDuration => _walkedDuration;

  /// True when the most recent measured interval exceeded
  /// [maxWalkingSpeedKmh] — lets the step counter drop steps taken while
  /// riding (bus vibration is a well-known false-step source).
  bool get isInVehicle => _lastIntervalWasVehicle;

  bool get hasFix => _last != null;

  void add(GeoSample sample) {
    if (sample.accuracyM > maxAccuracyM) return;

    final previous = _last;
    _last = sample;
    if (previous == null) return;

    final elapsed = sample.timestamp.difference(previous.timestamp);
    if (elapsed <= Duration.zero || elapsed > maxGap) return;

    final distanceM = haversineM(previous.latitude, previous.longitude, sample.latitude, sample.longitude);
    final speedKmh = distanceM / elapsed.inMilliseconds * 3600000 / 1000;

    _lastIntervalWasVehicle = speedKmh > maxWalkingSpeedKmh;
    if (_lastIntervalWasVehicle) return;

    _walkedDistanceM += distanceM;
    // Standing in a queue then moving on yields one long, very slow
    // interval — that's waiting, not walking, so it adds no burn time.
    if (speedKmh >= minWalkingSpeedKmh) {
      _walkedDuration += elapsed;
    }
  }

  static double haversineM(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusM = 6371000.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusM * math.asin(math.sqrt(a));
  }
}
