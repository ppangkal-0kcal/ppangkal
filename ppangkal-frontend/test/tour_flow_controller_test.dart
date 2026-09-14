import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ppangkal/controllers/tour_flow_controller.dart';
import 'package:ppangkal/models/tour.dart';
import 'package:ppangkal/models/tour_stop.dart';
import 'package:ppangkal/services/location_service.dart';
import 'package:ppangkal/services/step_counter.dart';
import 'package:ppangkal/services/tour_service.dart';
import 'package:ppangkal/services/walk_filter.dart';

class _FakeTourService extends TourService {
  final List<Map<String, int>> recordedStops = [];

  @override
  Future<Tour> startTour(String token) async => Tour.fromJson({'id': 'tour_1', 'started_at': '2026-09-14T12:00:00Z'});

  @override
  Future<TourStop> addStop({
    required String token,
    required String tourId,
    required String bakeryId,
    required int distanceM,
    required int durationMinutes,
    required int steps,
  }) async {
    recordedStops.add({'distance_m': distanceM, 'duration_minutes': durationMinutes, 'steps': steps});
    return TourStop.fromJson({
      'id': 'stop_${recordedStops.length}',
      'bakery_id': bakeryId,
      'distance_m': distanceM,
      'duration_minutes': durationMinutes,
      'steps': steps,
      'calories_burned': 10,
      'visited_at': '2026-09-14T12:30:00Z',
    });
  }
}

class _ManualStepCounter implements StepCounter {
  final _controller = StreamController<int>.broadcast();

  void emit(int cumulative) => _controller.add(cumulative);

  @override
  Stream<int> get stepStream => _controller.stream;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  void dispose() => _controller.close();
}

class _ManualPositionSource implements PositionSource {
  final _controller = StreamController<GeoSample>.broadcast();

  void emit(double metersNorth, int seconds) => _controller.add(GeoSample(
        latitude: 36.35 + metersNorth / 111195,
        longitude: 127.38,
        timestamp: DateTime(2026, 9, 14, 12).add(Duration(seconds: seconds)),
        accuracyM: 5,
      ));

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Stream<GeoSample> watch() => _controller.stream;

  @override
  Future<GeoSample?> current() async => null;
}

void main() {
  late _FakeTourService tours;
  late _ManualStepCounter steps;
  late _ManualPositionSource gps;
  late TourFlowController controller;

  setUp(() {
    tours = _FakeTourService();
    steps = _ManualStepCounter();
    gps = _ManualPositionSource();
    controller = TourFlowController(tourService: tours, stepCounter: steps, positionSource: gps);
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('first pedometer value is a baseline, not steps walked', () async {
    await controller.startTour('t');
    steps.emit(52000); // steps since boot
    await flush();
    expect(controller.currentLegSteps, 0);

    steps.emit(52150);
    await flush();
    expect(controller.currentLegSteps, 150);
  });

  test('GPS distance is used and vehicle segments are excluded from steps and distance', () async {
    await controller.startTour('t');
    steps.emit(1000);
    gps.emit(0, 0);
    gps.emit(200, 144); // 5km/h walk
    steps.emit(1250);
    await flush();

    gps.emit(1200, 204); // 60km/h bus
    await flush();
    steps.emit(1300); // bus vibration
    await flush();

    expect(controller.isGpsTracking, isTrue);
    expect(controller.isInVehicle, isTrue);
    expect(controller.currentLegSteps, 250);
    expect(controller.currentLegDistanceM, closeTo(200, 2));

    await controller.arriveAtBakery(token: 't', bakeryId: 'bak_1');
    expect(tours.recordedStops.single['steps'], 250);
    expect(tours.recordedStops.single['distance_m'], closeTo(200, 2));
    expect(tours.recordedStops.single['duration_minutes'], 2);

    // Next leg starts from zero.
    expect(controller.currentLegSteps, 0);
    expect(controller.currentLegDistanceM, 0);
  });
}
