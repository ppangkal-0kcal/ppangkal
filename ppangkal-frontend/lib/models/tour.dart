import 'tour_stop.dart';

/// Mirrors the Tour shape across the 3 endpoints that return one
/// (FRONTEND_API_GUIDE.md §2 steps 1/7/8; backend/src/routes/tours.routes.ts)
/// — the 3 don't return the same fields:
/// - `POST /tours` → only `{id, started_at}`
/// - `PATCH /tours/:id/complete` → `{id, completed_at, total_steps,
///   total_distance_m, total_calories_burned, total_calories_consumed,
///   balance_kcal}` (no `started_at`, no `stops`)
/// - `GET /tours/:id` → everything above plus `stops[]`
///
/// so every field beyond `id` is nullable — check which call produced the
/// value before assuming a field is populated.
class Tour {
  final String id;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? totalSteps;
  final int? totalDistanceM;
  final int? totalCaloriesBurned;
  final int? totalCaloriesConsumed;
  final int? balanceKcal;
  final List<TourStop>? stops;

  const Tour({
    required this.id,
    this.startedAt,
    this.completedAt,
    this.totalSteps,
    this.totalDistanceM,
    this.totalCaloriesBurned,
    this.totalCaloriesConsumed,
    this.balanceKcal,
    this.stops,
  });

  factory Tour.fromJson(Map<String, dynamic> json) => Tour(
        id: json['id'] as String,
        startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
        completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
        totalSteps: json['total_steps'] as int?,
        totalDistanceM: json['total_distance_m'] as int?,
        totalCaloriesBurned: json['total_calories_burned'] as int?,
        totalCaloriesConsumed: json['total_calories_consumed'] as int?,
        balanceKcal: json['balance_kcal'] as int?,
        stops: (json['stops'] as List<dynamic>?)
            ?.map((e) => TourStop.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
