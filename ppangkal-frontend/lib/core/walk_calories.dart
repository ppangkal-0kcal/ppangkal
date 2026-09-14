/// On-device copies of the backend's walking formulas
/// (`backend/src/services/calorieService.ts`). The bakery list computes
/// distance/walkability/calorie previews locally so the user's position
/// never leaves the phone — keep these constants in sync with the server.
class WalkCalories {
  WalkCalories._();

  /// Fixed walking MET (도보 3.5).
  static const double walkMet = 3.5;

  /// Assumed walking speed for previews: 4km/h.
  static const double avgWalkSpeedMPerMin = 4000 / 60;

  /// Straight-line distance up to which walking is recommended (idea.md §3).
  static const double walkRecommendThresholdM = 1200;

  /// `estimateWalkMinutes` — minutes to walk [distanceM] at [avgWalkSpeedMPerMin].
  static int estimateWalkMinutes(double distanceM) => (distanceM / avgWalkSpeedMPerMin).round();

  /// `calculateCaloriesBurned` — 3.5 MET × kg × h × 1.05.
  static int caloriesBurned(double weightKg, int durationMinutes) =>
      (walkMet * weightKg * (durationMinutes / 60) * 1.05).round();

  /// Minutes of walking that burn [kcal] — inverse of [caloriesBurned].
  static int minutesToBurn(int kcal, double weightKg) => (kcal / (walkMet * weightKg * 1.05) * 60).round();
}
