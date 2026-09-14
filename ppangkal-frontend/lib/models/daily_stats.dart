/// Mirrors `GET /api/stats/daily` (FRONTEND_API_GUIDE.md §2; backend
/// `src/routes/stats.routes.ts`). All fields always present.
class DailyStats {
  final String date;
  final int consumedCalories;
  final int burnedCalories;
  final int goalCalories;
  final int bakeriesVisited;

  const DailyStats({
    required this.date,
    required this.consumedCalories,
    required this.burnedCalories,
    required this.goalCalories,
    required this.bakeriesVisited,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
        date: json['date'] as String,
        consumedCalories: json['consumed_calories'] as int,
        burnedCalories: json['burned_calories'] as int,
        goalCalories: json['goal_calories'] as int,
        bakeriesVisited: json['bakeries_visited'] as int,
      );
}
