import 'package:flutter/foundation.dart';

import '../models/calorie_balance.dart';
import '../models/food_log.dart';
import '../models/tour.dart';
import '../models/tour_stop.dart';
import '../services/calories_service.dart';
import '../services/food_log_service.dart';
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
/// Sourcing `distanceM`/`durationMinutes`/`steps` for [arriveAtBakery] is
/// deliberately left to the caller — GPS tracking and the step-count
/// source (`lib/services/step_counter.dart`) are separate concerns from
/// call sequencing.
class TourFlowController extends ChangeNotifier {
  final TourService _tourService;
  final FoodLogService _foodLogService;
  final CaloriesService _caloriesService;

  TourFlowController({
    TourService? tourService,
    FoodLogService? foodLogService,
    CaloriesService? caloriesService,
  })  : _tourService = tourService ?? TourService(),
        _foodLogService = foodLogService ?? FoodLogService(),
        _caloriesService = caloriesService ?? CaloriesService();

  Tour? _tour;
  final List<TourStop> _stops = [];

  Tour? get tour => _tour;
  List<TourStop> get stops => List.unmodifiable(_stops);
  bool get isStarted => _tour != null;
  bool get isCompleted => _tour?.completedAt != null;

  Future<Tour> startTour(String token) async {
    final tour = await _tourService.startTour(token);
    _tour = tour;
    _stops.clear();
    notifyListeners();
    return tour;
  }

  /// Records arrival at [bakeryId]. [distanceM]/[durationMinutes]/[steps]
  /// are this leg's measured values — tours.routes.ts requires all three
  /// and uses them as-is, so the caller must supply real (or, for now,
  /// test) numbers.
  Future<TourStop> arriveAtBakery({
    required String token,
    required String bakeryId,
    required int distanceM,
    required int durationMinutes,
    required int steps,
  }) async {
    final tour = _requireTour();
    final stop = await _tourService.addStop(
      token: token,
      tourId: tour.id,
      bakeryId: bakeryId,
      distanceM: distanceM,
      durationMinutes: durationMinutes,
      steps: steps,
    );
    _stops.add(stop);
    notifyListeners();
    return stop;
  }

  /// Logs food eaten at the most recently recorded stop.
  Future<FoodLog> logFood({
    required String token,
    required String breadItemId,
    int quantity = 1,
  }) {
    if (_stops.isEmpty) {
      throw StateError('arriveAtBakery()를 먼저 호출해야 합니다.');
    }
    return _foodLogService.create(
      token: token,
      breadItemId: breadItemId,
      tourStopId: _stops.last.id,
      quantity: quantity,
    );
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

  Tour _requireTour() {
    final tour = _tour;
    if (tour == null) {
      throw StateError('startTour()를 먼저 호출해야 합니다.');
    }
    return tour;
  }
}
