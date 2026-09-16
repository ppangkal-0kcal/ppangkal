import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bakery.dart';
import '../models/bread_selection.dart';
import '../models/calorie_balance.dart';
import '../models/food_log.dart';
import '../models/tour.dart';
import '../models/tour_leg.dart';
import '../models/tour_stop.dart';
import '../services/calories_service.dart';
import '../services/food_log_service.dart';
import '../services/location_service.dart';
import '../services/step_counter.dart';
import '../services/tour_service.dart';
import '../services/walk_filter.dart';

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
/// class exists for).
///
/// **GPS speed filter** (4단계): while a tour is active, [PositionSource]
/// fixes run through [WalkFilter] — only ≤20km/h movement adds to
/// `distance_m`/`duration_minutes`, and steps that arrive while the filter
/// says the user is in a vehicle are dropped. When GPS is unavailable
/// (permission denied, Chrome dev target without a fix yet) distance falls
/// back to steps × stride and duration to wall-clock time, so a tour never
/// fails just because a sensor is missing.
class TourFlowController extends ChangeNotifier {
  final TourService _tourService;
  final FoodLogService _foodLogService;
  final CaloriesService _caloriesService;
  final StepCounter _stepCounter;
  final bool _ownsStepCounter;
  final PositionSource? _positionSource;

  TourFlowController({
    TourService? tourService,
    FoodLogService? foodLogService,
    CaloriesService? caloriesService,
    StepCounter? stepCounter,
    this._positionSource,
  })  : _tourService = tourService ?? TourService(),
        _foodLogService = foodLogService ?? FoodLogService(),
        _caloriesService = caloriesService ?? CaloriesService(),
        _stepCounter = stepCounter ?? createStepCounter(),
        _ownsStepCounter = stepCounter == null;

  Tour? _tour;
  final List<TourStop> _stops = [];
  final List<FoodLog> _foodLogs = [];
  TourLeg? _currentLeg;

  StreamSubscription<int>? _stepSubscription;
  StreamSubscription<GeoSample>? _positionSubscription;
  WalkFilter _walkFilter = WalkFilter();
  bool _gpsPermitted = false;

  /// Raw cumulative value from the sensor (steps since boot on Android) —
  /// only used to compute deltas, never shown.
  int? _lastRawSteps;

  /// Steps this app counted as walking since the tour started.
  int _countedSteps = 0;
  int _legStepBaseline = 0;
  double _legDistanceBaselineM = 0;
  Duration _legWalkDurationBaseline = Duration.zero;
  DateTime? _legStartedAt;

  /// Fallback only, when there's no GPS fix to measure distance with.
  static const double _fallbackStrideLengthM = 0.7;

  int _dataRevision = 0;

  /// Bumps whenever something the server aggregates changes (a stop, a
  /// food log, a completed tour). Screens that show server-side totals —
  /// 홈 balance, 통계 — `select` this and refetch when it moves, since the
  /// tab shell keeps them alive instead of rebuilding them.
  int get dataRevision => _dataRevision;

  Tour? get tour => _tour;
  List<TourStop> get stops => List.unmodifiable(_stops);
  List<FoodLog> get foodLogs => List.unmodifiable(_foodLogs);

  /// Bakery + bread picked for the leg in progress — `null` until a tour
  /// starts with a pick, and cleared again when the tour completes. 홈 uses
  /// it for the tour summary and to decide whether to show nearby spots.
  TourLeg? get currentLeg => _currentLeg;

  /// Records the bakery/bread pick for the active tour's current leg. Picking
  /// the same bakery again before its food is confirmed (e.g. resuming from
  /// 홈) keeps the leg's arrival state; anything else starts a fresh leg.
  /// Starts a tour if none is running, then records the pick — the single
  /// entry point used by 빵 메뉴 선택's "투어 시작" button.
  Future<void> startLeg({
    required String token,
    required Bakery bakery,
    required List<BreadSelection> selections,
  }) async {
    if (!isStarted) await startTour(token);
    planLeg(bakery, selections);
  }

  void planLeg(Bakery bakery, List<BreadSelection> selections) {
    if (!isStarted) return;
    final leg = _currentLeg;
    _currentLeg = leg != null && leg.bakery.id == bakery.id && !leg.foodConfirmed
        ? leg.copyWith(selections: selections)
        : TourLeg(bakery: bakery, selections: selections);
    notifyListeners();
  }

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
  int get currentLegSteps => _countedSteps - _legStepBaseline;

  /// Whether distance is GPS-measured (true) or estimated from steps.
  bool get isGpsTracking => _gpsPermitted && _walkFilter.hasFix;

  /// The latest GPS interval was faster than walking — shown so the user
  /// understands why the numbers stopped moving on a bus.
  bool get isInVehicle => isGpsTracking && _walkFilter.isInVehicle;

  int get currentLegDistanceM => isGpsTracking
      ? (_walkFilter.walkedDistanceM - _legDistanceBaselineM).round()
      : (currentLegSteps * _fallbackStrideLengthM).round();

  int get currentLegDurationMinutes {
    if (isGpsTracking) {
      return (_walkFilter.walkedDuration - _legWalkDurationBaseline).inMinutes;
    }
    final startedAt = _legStartedAt;
    return startedAt == null ? 0 : DateTime.now().difference(startedAt).inMinutes;
  }

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
    _currentLeg = null;
    _countedSteps = 0;
    _walkFilter = WalkFilter();
    await _startSensors();
    _beginLeg();
    notifyListeners();
    return tour;
  }

  Future<void> _startSensors() async {
    // Unanswered permission prompts must not block the tour from starting —
    // it just runs without that sensor (see the class doc's fallbacks).
    const promptTimeout = Duration(seconds: 15);
    await _stepCounter.ensurePermission().timeout(promptTimeout, onTimeout: () => false);
    _stepSubscription ??= _stepCounter.stepStream.listen(_onRawSteps);

    final source = _positionSource;
    if (source == null) return;
    _gpsPermitted = await source.ensurePermission().timeout(promptTimeout, onTimeout: () => false);
    if (_gpsPermitted) {
      await _positionSubscription?.cancel();
      _positionSubscription = source.watch().listen(
        (sample) {
          _walkFilter.add(sample);
          notifyListeners();
        },
        // Losing GPS mid-tour degrades to the step estimate, not an error.
        onError: (Object _) {},
      );
    }
  }

  void _onRawSteps(int raw) {
    final last = _lastRawSteps;
    _lastRawSteps = raw;
    // First event only establishes the baseline (Android reports steps
    // since boot); a negative delta means the device rebooted.
    if (last == null || raw < last || !isStarted) return;
    if (isInVehicle) return;
    _countedSteps += raw - last;
    notifyListeners();
  }

  Future<void> _stopPositionTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Records arrival at [bakeryId]. `steps`/`distance_m`/`duration_minutes`
  /// are derived from this leg's elapsed [StepCounter] delta and wall-clock
  /// time — see the class doc for why sourcing lives here.
  Future<TourStop> arriveAtBakery({
    required String token,
    required String bakeryId,
  }) async {
    final tour = _requireTour();
    final steps = currentLegSteps;
    final distanceM = currentLegDistanceM;
    final durationMinutes = currentLegDurationMinutes;

    final stop = await _tourService.addStop(
      token: token,
      tourId: tour.id,
      bakeryId: bakeryId,
      distanceM: distanceM,
      durationMinutes: durationMinutes,
      steps: steps,
    );
    _stops.add(stop);
    final leg = _currentLeg;
    if (leg != null && leg.bakery.id == bakeryId) {
      _currentLeg = leg.copyWith(arrivedStop: stop);
    }
    _beginLeg();
    _dataRevision++;
    notifyListeners();
    return stop;
  }

  /// Logs food eaten at the most recently recorded stop. [selection] may be
  /// a menu item or a bread the user typed in — see [BreadSelection].
  Future<FoodLog> logFood({required String token, required BreadSelection selection}) async {
    if (_stops.isEmpty) {
      throw StateError('arriveAtBakery()를 먼저 호출해야 합니다.');
    }
    final log = await _foodLogService.create(
      token: token,
      selection: selection,
      tourStopId: _stops.last.id,
    );
    _foodLogs.add(log);
    _dataRevision++;
    notifyListeners();
    return log;
  }

  /// Logs every selection at the latest stop, then marks the current leg's
  /// food as confirmed so re-entering the screen can't log it twice.
  Future<void> confirmFood({required String token, required List<BreadSelection> selections}) async {
    for (final selection in selections) {
      await logFood(token: token, selection: selection);
    }
    final leg = _currentLeg;
    if (leg != null) {
      _currentLeg = leg.copyWith(foodConfirmed: true);
      notifyListeners();
    }
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
    _currentLeg = null;
    await _stopPositionTracking();
    _dataRevision++;
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
    _legStepBaseline = _countedSteps;
    _legDistanceBaselineM = _walkFilter.walkedDistanceM;
    _legWalkDurationBaseline = _walkFilter.walkedDuration;
    _legStartedAt = DateTime.now();
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
    _positionSubscription?.cancel();
    if (_ownsStepCounter) {
      _stepCounter.dispose();
    }
    super.dispose();
  }
}
