import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/calorie_balance.dart';
import '../models/food_log.dart';
import '../models/tour.dart';
import '../models/tour_stop.dart';
import '../services/calories_service.dart';
import '../services/food_log_service.dart';
import '../services/step_counter.dart';
import '../services/tour_service.dart';

/// Owns the tour session lifecycle end to end — start → (arrive at a
/// bakery → log food eaten there)×N → complete → fetch report — so a
/// screen never has to know the API call order or thread IDs between
/// calls itself (`tour_id` from [startTour] into every later call,
/// `tour_stop_id` from the latest [arriveAtBakery] into [logFood]).
///
/// The sequence and its constraints come straight from
/// `backend/src/routes/tours.routes.ts`: a tour can have multiple stops,
/// a stop can't be added once the tour is `completedAt` (the backend
/// 400s), and `PATCH .../complete` sums each stop's own `steps`/
/// `distance_m`/`calories_burned` into the tour's `total_*` snapshot — it
/// doesn't re-read anything client-supplied at complete time.
///
/// **Why this exists as a plain [ChangeNotifier] instead of living inside
/// a screen:** the intent is that a teammate can throw out and rebuild the
/// entire tour UI — any widget tree, any layout — without touching this
/// class, and the API call sequence keeps working unchanged underneath.
///
/// This is meant to be a single app-wide instance (provided once at the
/// app root, alongside `AuthProvider` — see `lib/main.dart`), not one per
/// screen: the same active tour has to survive the user bouncing between
/// the bakery tab and the tour screens to visit several bakeries in one
/// trip, which only works if every screen shares one instance.
///
/// **Step/distance sourcing** (2단계 최종 결정): [StepCounter] emits a
/// *cumulative* count (matching how a real pedometer package would), but
/// `POST /tours/:tourId/stops`'s `steps` is a *per-leg* value — so the
/// baseline-snapshot-then-delta logic has to live somewhere that persists
/// across the whole leg and knows when a leg starts/ends. That's this
/// controller, not [StepCounter] itself (a sensor shouldn't know about
/// "legs", that's a domain concept) and not the screen (steps directly
/// feeds the API call this class already owns — splitting that across a
/// screen would undo the "screen doesn't know the API shape" goal this
/// class exists for). `distance_m` has no real source yet either (GPS is
/// 4단계) — estimated from the same step delta via a fixed stride length,
/// clearly marked for replacement.
class TourFlowController extends ChangeNotifier {
  final TourService _tourService;
  final FoodLogService _foodLogService;
  final CaloriesService _caloriesService;
  final StepCounter _stepCounter;
  final bool _ownsStepCounter;

  TourFlowController({
    TourService? tourService,
    FoodLogService? foodLogService,
    CaloriesService? caloriesService,
    StepCounter? stepCounter,
  })  : _tourService = tourService ?? TourService(),
        _foodLogService = foodLogService ?? FoodLogService(),
        _caloriesService = caloriesService ?? CaloriesService(),
        _stepCounter = stepCounter ?? FakeStepCounter(),
        _ownsStepCounter = stepCounter == null;

  Tour? _tour;
  final List<TourStop> _stops = [];
  final List<FoodLog> _foodLogs = [];

  StreamSubscription<int>? _stepSubscription;
  int _latestCumulativeSteps = 0;
  int _legStepBaseline = 0;
  DateTime? _legStartedAt;

  // TODO(4단계): 실제 GPS 거리로 교체 — 지금은 걸음수 × 평균 보폭으로만 추정.
  static const double _fakeStrideLengthM = 0.7;

  Tour? get tour => _tour;
  List<TourStop> get stops => List.unmodifiable(_stops);
  List<FoodLog> get foodLogs => List.unmodifiable(_foodLogs);

  /// True only while a tour is actively in progress. [_tour] itself stays
  /// non-null after [complete]/[fetchReport] too (the report screen reads
  /// it to show the finished tour) — so this must also check
  /// [isCompleted], otherwise a screen for a brand-new bakery visit would
  /// see a leftover *completed* tour and think it's still active, then try
  /// to record a stop against it. tours.routes.ts 400s that
  /// ("이미 종료된 투어입니다"), which is exactly the bug this fixes: the
  /// "투어 시작" button never reappeared for the next tour, so "도착 기록"
  /// silently failed against the old, already-completed tour every time.
  bool get isStarted => _tour != null && !isCompleted;
  bool get isCompleted => _tour?.completedAt != null;

  /// Steps walked since the current leg started (tour start, or the
  /// previous [arriveAtBakery] — whichever was most recent).
  int get currentLegSteps {
    final delta = _latestCumulativeSteps - _legStepBaseline;
    return delta < 0 ? 0 : delta;
  }

  int get currentLegDistanceM => (currentLegSteps * _fakeStrideLengthM).round();

  int get totalConfirmedSteps => _stops.fold(0, (sum, s) => sum + s.steps);
  int get totalConfirmedDistanceM => _stops.fold(0, (sum, s) => sum + s.distanceM);
  int get totalConfirmedCaloriesBurned => _stops.fold(0, (sum, s) => sum + s.caloriesBurned);
  int get totalConfirmedCaloriesConsumed =>
      _foodLogs.fold(0, (sum, log) => sum + log.calories * log.quantity);

  /// Running 0-kcal balance for the *active* tour so far (burned so far
  /// minus consumed so far) — the same `소모 − 섭취` definition
  /// `PATCH /tours/:id/complete` uses for `balance_kcal`
  /// (backend/src/routes/tours.routes.ts), just computed incrementally
  /// from values the server already returned rather than waiting for the
  /// tour to finish. **Not** the same concept as `GET /calories/balance`'s
  /// daily `remaining_calories` — that's goal-relative and spans the whole
  /// day, this is tour-relative and has no goal.
  int get runningBalanceKcal => totalConfirmedCaloriesBurned - totalConfirmedCaloriesConsumed;

  Future<Tour> startTour(String token) async {
    final tour = await _tourService.startTour(token);
    _tour = tour;
    _stops.clear();
    _foodLogs.clear();
    _beginLeg();
    notifyListeners();
    return tour;
  }

  /// Records arrival at [bakeryId]. `steps`/`distance_m`/`duration_minutes`
  /// are derived from this leg's elapsed [StepCounter] delta and wall-clock
  /// time — see the class doc for why sourcing lives here.
  Future<TourStop> arriveAtBakery({
    required String token,
    required String bakeryId,
  }) async {
    final tour = _requireTour();
    final startedAt = _legStartedAt ?? DateTime.now();
    final steps = currentLegSteps;
    final distanceM = currentLegDistanceM;
    final durationMinutes = DateTime.now().difference(startedAt).inMinutes;

    final stop = await _tourService.addStop(
      token: token,
      tourId: tour.id,
      bakeryId: bakeryId,
      distanceM: distanceM,
      durationMinutes: durationMinutes,
      steps: steps,
    );
    _stops.add(stop);
    _beginLeg();
    notifyListeners();
    return stop;
  }

  /// Logs food eaten at the most recently recorded stop.
  Future<FoodLog> logFood({
    required String token,
    required String breadItemId,
    int quantity = 1,
  }) async {
    if (_stops.isEmpty) {
      throw StateError('arriveAtBakery()를 먼저 호출해야 합니다.');
    }
    final log = await _foodLogService.create(
      token: token,
      breadItemId: breadItemId,
      tourStopId: _stops.last.id,
      quantity: quantity,
    );
    _foodLogs.add(log);
    notifyListeners();
    return log;
  }

  /// Today's running balance — independent of which tour is active (the
  /// backend aggregates across all of today's tours/food logs), but kept
  /// here so a tour screen can show it without importing [CaloriesService]
  /// itself.
  Future<CalorieBalance> checkBalance(String token) {
    return _caloriesService.getBalance(token);
  }

  Future<Tour> complete(String token) async {
    final tour = _requireTour();
    final completed = await _tourService.completeTour(token, tour.id);
    _tour = completed;
    notifyListeners();
    return completed;
  }

  Future<Tour> fetchReport(String token) async {
    final tour = _requireTour();
    final report = await _tourService.getTour(token, tour.id);
    _tour = report;
    notifyListeners();
    return report;
  }

  void _beginLeg() {
    _legStepBaseline = _latestCumulativeSteps;
    _legStartedAt = DateTime.now();
    _stepSubscription ??= _stepCounter.stepStream.listen((cumulative) {
      _latestCumulativeSteps = cumulative;
      notifyListeners();
    });
  }

  Tour _requireTour() {
    final tour = _tour;
    if (tour == null) {
      throw StateError('startTour()를 먼저 호출해야 합니다.');
    }
    return tour;
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    if (_ownsStepCounter) {
      _stepCounter.dispose();
    }
    super.dispose();
  }
}
