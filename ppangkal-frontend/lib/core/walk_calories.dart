/// On-device copies of the backend's walking formulas
/// (`backend/src/services/calorieService.ts`). The bakery list computes
/// distance/walkability/calorie previews locally so the user's position
/// never leaves the phone — keep these constants in sync with the server,
/// including [roadDistanceFactor] if that ever changes.
class WalkCalories {
  WalkCalories._();

  /// Fixed walking MET (도보 3.5).
  static const double walkMet = 3.5;

  /// Assumed walking speed for previews: 4km/h.
  static const double avgWalkSpeedMPerMin = 4000 / 60;

  /// Straight-line distance up to which walking is recommended (idea.md §3).
  static const double walkRecommendThresholdM = 1200;

  /// 직선거리 → 실제 도보 경로 보정 배율 (idea.md §3: 직선거리 1.2km ≈ 실제 도보거리 약
  /// 1.5km, 도로망 보정 1.2~1.4배 — 중간값 사용). [estimateWalkMinutes]에만 곱한다 —
  /// 화면에 보이는 거리(m)는 직선거리 그대로 두고, 그 거리로 계산하는 도보 시간·소모
  /// 칼로리만 보정한다. [walkRecommendThresholdM](1.2km)은 이미 이 보정을 감안해서
  /// 정한 값이라 다시 곱하지 않는다 — 곱하면 도보권 판정 기준이 달라진다.
  static const double roadDistanceFactor = 1.3;

  /// 관광지 소모 칼로리의 기준 시간. 거리 기반 도보 이동 시간(예: 450m ≈ 7분)만 반영하면
  /// 몇십 kcal로 체감상 너무 작아, "도착해서 1시간 정도 둘러본다"는 관광 특성을 반영해
  /// 고정값으로 잡는다 — `nearby_spots_section.dart`에서만 쓰고, 빵집까지의 도보 시간
  /// 표시(`estimateWalkMinutes`)와는 별개다.
  static const int sightseeingMinutes = 60;

  /// `estimateWalkMinutes` — minutes to walk [distanceM] at [avgWalkSpeedMPerMin],
  /// with [roadDistanceFactor] applied first (직선거리를 실제 도보거리로 보정).
  static int estimateWalkMinutes(double distanceM) =>
      (distanceM * roadDistanceFactor / avgWalkSpeedMPerMin).round();

  /// `calculateCaloriesBurned` — 3.5 MET × kg × h × 1.05.
  static int caloriesBurned(double weightKg, int durationMinutes) =>
      (walkMet * weightKg * (durationMinutes / 60) * 1.05).round();

  /// Minutes of walking that burn [kcal] — inverse of [caloriesBurned].
  static int minutesToBurn(int kcal, double weightKg) => (kcal / (walkMet * weightKg * 1.05) * 60).round();
}
