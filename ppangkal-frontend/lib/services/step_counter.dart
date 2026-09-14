import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

/// Source of step-count data for the tour flow. Real pedometer packages
/// ([PedometerStepCounter]) emit a **cumulative**
/// count — since the listener attached, or since device boot, depending
/// on platform — not a delta. [stepStream] mirrors that contract on
/// purpose, so callers already write the "snapshot a baseline, subtract
/// later" logic they'll need for the real sensor.
///
/// That delta is what `POST /tours/:tourId/stops`'s `steps` field expects
/// (backend/src/routes/tours.routes.ts) — a single leg's step count, not a
/// running total: `PATCH /tours/:tourId/complete` sums every stop's own
/// `steps` into `total_steps`, it never re-reads a live counter itself.
///
/// Swapping [FakeStepCounter] for a real implementation should require no
/// screen or controller changes — only whatever constructs the
/// [StepCounter] instance.
abstract class StepCounter {
  Stream<int> get stepStream;

  /// Requests the motion/activity permission if the platform needs one.
  /// Returns false when step data won't be available.
  Future<bool> ensurePermission();

  void dispose();
}

/// Picks the real sensor on Android/iOS and the timer-driven fake
/// elsewhere (Chrome/desktop dev targets have no pedometer).
StepCounter createStepCounter() {
  final hasPedometer = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  return hasPedometer ? PedometerStepCounter() : FakeStepCounter();
}

/// Platform pedometer — Android `TYPE_STEP_COUNTER` (steps since boot) /
/// iOS `CMPedometer`. Because the Android value is counted by the sensor
/// hub itself, steps taken while the screen is off are still reflected the
/// next time an event arrives, even if the Dart side was throttled.
class PedometerStepCounter implements StepCounter {
  @override
  Stream<int> get stepStream => Pedometer.stepCountStream
      .map((event) => event.steps)
      // A device without a step sensor errors the stream; the controller
      // then keeps GPS-only distance instead of crashing the tour.
      .handleError((Object _) {});

  @override
  Future<bool> ensurePermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  @override
  void dispose() {}
}

/// Development stand-in — increments a cumulative counter on a timer so
/// anything wired against [StepCounter] has plausible values before the
/// real pedometer package is integrated.
class FakeStepCounter implements StepCounter {
  final Duration tickInterval;
  final int stepsPerTick;

  int _cumulative = 0;
  final _controller = StreamController<int>.broadcast();
  Timer? _timer;

  FakeStepCounter({
    this.tickInterval = const Duration(seconds: 1),
    this.stepsPerTick = 2,
  }) {
    _timer = Timer.periodic(tickInterval, (_) {
      _cumulative += stepsPerTick;
      _controller.add(_cumulative);
    });
  }

  @override
  Stream<int> get stepStream => _controller.stream;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
