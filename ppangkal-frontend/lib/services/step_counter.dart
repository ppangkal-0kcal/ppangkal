import 'dart:async';

/// Source of step-count data for the tour flow. Real pedometer packages
/// (the actual implementation is planned next week) emit a **cumulative**
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

  void dispose();
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
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
