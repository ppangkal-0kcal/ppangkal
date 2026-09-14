/// Mirrors `GET /api/calories/balance` (FRONTEND_API_GUIDE.md §2 step 7;
/// backend/src/routes/calories.routes.ts). All fields are always present
/// (computed server-side from the user's profile + today's logs, never
/// optional). `status` is `'green' | 'yellow' | 'red'`, decided by
/// `calorieService.resolveBalanceStatus` — green if remaining ≥30% of the
/// daily goal, yellow ≥10%, red otherwise (or if the goal is ≤0). The
/// client only maps this string to a display color; it never re-derives
/// those thresholds itself.
class CalorieBalance {
  final int dailyGoalCalories;
  final int consumedCalories;
  final int burnedCalories;
  final int remainingCalories;
  final String status;

  const CalorieBalance({
    required this.dailyGoalCalories,
    required this.consumedCalories,
    required this.burnedCalories,
    required this.remainingCalories,
    required this.status,
  });

  factory CalorieBalance.fromJson(Map<String, dynamic> json) => CalorieBalance(
        dailyGoalCalories: json['daily_goal_calories'] as int,
        consumedCalories: json['consumed_calories'] as int,
        burnedCalories: json['burned_calories'] as int,
        remainingCalories: json['remaining_calories'] as int,
        status: json['status'] as String,
      );
}
