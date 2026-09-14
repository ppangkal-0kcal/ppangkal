import 'package:flutter_test/flutter_test.dart';

import 'package:ppangkal/services/walk_filter.dart';

/// ~0.0009° latitude ≈ 100m.
const _degPer100m = 100 / 111195;

GeoSample _at(double metersNorth, int seconds, {double accuracyM = 5}) => GeoSample(
      latitude: 36.35 + metersNorth / 100 * _degPer100m,
      longitude: 127.38,
      timestamp: DateTime(2026, 9, 14, 12).add(Duration(seconds: seconds)),
      accuracyM: accuracyM,
    );

void main() {
  test('walking pace counts distance and duration', () {
    final filter = WalkFilter()
      ..add(_at(0, 0))
      ..add(_at(100, 72)); // 100m / 72s = 5km/h

    expect(filter.walkedDistanceM, closeTo(100, 1));
    expect(filter.walkedDuration, const Duration(seconds: 72));
    expect(filter.isInVehicle, isFalse);
  });

  test('faster than 20km/h is excluded as a vehicle', () {
    final filter = WalkFilter()
      ..add(_at(0, 0))
      ..add(_at(100, 72))
      ..add(_at(600, 102)); // 500m / 30s = 60km/h

    expect(filter.walkedDistanceM, closeTo(100, 1));
    expect(filter.isInVehicle, isTrue);
  });

  test('inaccurate fixes are ignored', () {
    final filter = WalkFilter()
      ..add(_at(0, 0))
      ..add(_at(80, 5, accuracyM: 120))
      ..add(_at(50, 36));

    expect(filter.walkedDistanceM, closeTo(50, 1));
  });

  test('standing still adds no walking time', () {
    final filter = WalkFilter()
      ..add(_at(0, 0))
      ..add(_at(6, 60)); // 6m in a minute = 0.36km/h

    expect(filter.walkedDuration, Duration.zero);
  });

  test('gaps longer than 5 minutes are skipped', () {
    final filter = WalkFilter()
      ..add(_at(0, 0))
      ..add(_at(400, 600));

    expect(filter.walkedDistanceM, 0);
  });
}
