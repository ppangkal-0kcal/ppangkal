/// Mirrors the TourStop shape, which also differs by endpoint
/// (FRONTEND_API_GUIDE.md §2 step 7; backend/src/routes/tours.routes.ts):
/// - `POST /tours/:tourId/stops` → `{id, tour_id, bakery_id, distance_m,
///   duration_minutes, steps, calories_burned, visited_at, suggested_walk}`
/// - the `stops[]` nested inside `GET /tours/:id` instead include
///   `bakery_name` but drop `tour_id` and `suggested_walk`
///
/// so `tourId`/`bakeryName`/`suggestedWalk` are all nullable depending on
/// which call produced the value. `suggested_walk` is additionally `null`
/// whenever this leg's `distance_m` already exceeded the walk-recommend
/// threshold (tourApiService.buildParkWalkSuggestion) — that's a normal
/// case, not a missing-field bug.
class TourStop {
  final String id;
  final String? tourId;
  final String bakeryId;
  final String? bakeryName;
  final int distanceM;
  final int durationMinutes;
  final int steps;
  final int caloriesBurned;
  final DateTime visitedAt;
  final Map<String, dynamic>? suggestedWalk;

  const TourStop({
    required this.id,
    this.tourId,
    required this.bakeryId,
    this.bakeryName,
    required this.distanceM,
    required this.durationMinutes,
    required this.steps,
    required this.caloriesBurned,
    required this.visitedAt,
    this.suggestedWalk,
  });

  factory TourStop.fromJson(Map<String, dynamic> json) => TourStop(
        id: json['id'] as String,
        tourId: json['tour_id'] as String?,
        bakeryId: json['bakery_id'] as String,
        bakeryName: json['bakery_name'] as String?,
        distanceM: json['distance_m'] as int,
        durationMinutes: json['duration_minutes'] as int,
        steps: json['steps'] as int,
        caloriesBurned: json['calories_burned'] as int,
        visitedAt: DateTime.parse(json['visited_at'] as String),
        suggestedWalk: json['suggested_walk'] as Map<String, dynamic>?,
      );
}
