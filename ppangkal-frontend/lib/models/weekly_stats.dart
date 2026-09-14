/// One day's entry inside `GET /api/stats/weekly`'s `days[]`.
class DayStat {
  final String date;
  final int consumedCalories;
  final int burnedCalories;

  const DayStat({
    required this.date,
    required this.consumedCalories,
    required this.burnedCalories,
  });

  factory DayStat.fromJson(Map<String, dynamic> json) => DayStat(
        date: json['date'] as String,
        consumedCalories: json['consumed_calories'] as int,
        burnedCalories: json['burned_calories'] as int,
      );
}

/// Mirrors `GET /api/stats/weekly` (FRONTEND_API_GUIDE.md §2; backend
/// `src/routes/stats.routes.ts`) — most recent 7 days, oldest first.
/// `goalAchievementRate` is the % of those days where
/// `consumed - burned <= daily_goal_calories`, computed server-side.
class WeeklyStats {
  final List<DayStat> days;
  final int goalAchievementRate;

  const WeeklyStats({required this.days, required this.goalAchievementRate});

  factory WeeklyStats.fromJson(Map<String, dynamic> json) => WeeklyStats(
        days: (json['days'] as List<dynamic>)
            .map((e) => DayStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        goalAchievementRate: json['goal_achievement_rate'] as int,
      );
}
