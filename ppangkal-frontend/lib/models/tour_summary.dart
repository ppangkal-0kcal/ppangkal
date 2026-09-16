/// One finished tour as the 통계 탭 lists it (`GET /tours` —
/// backend/src/routes/tours.routes.ts). Stop-level numbers (걸음/거리 per
/// bakery) aren't in this response; tapping a row fetches `GET /tours/:id`
/// and builds a [Tour] from that instead.
class TourSummary {
  final String id;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int totalSteps;
  final int totalDistanceM;
  final int totalCaloriesBurned;
  final int totalCaloriesConsumed;
  final int balanceKcal;
  final int bakeryCount;
  final List<String> bakeryNames;

  const TourSummary({
    required this.id,
    this.startedAt,
    this.completedAt,
    required this.totalSteps,
    required this.totalDistanceM,
    required this.totalCaloriesBurned,
    required this.totalCaloriesConsumed,
    required this.balanceKcal,
    required this.bakeryCount,
    required this.bakeryNames,
  });

  factory TourSummary.fromJson(Map<String, dynamic> json) => TourSummary(
        id: json['id'] as String,
        startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
        completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
        totalSteps: json['total_steps'] as int? ?? 0,
        totalDistanceM: json['total_distance_m'] as int? ?? 0,
        totalCaloriesBurned: json['total_calories_burned'] as int? ?? 0,
        totalCaloriesConsumed: json['total_calories_consumed'] as int? ?? 0,
        balanceKcal: json['balance_kcal'] as int? ?? 0,
        bakeryCount: json['bakery_count'] as int? ?? 0,
        bakeryNames: (json['bakery_names'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}
