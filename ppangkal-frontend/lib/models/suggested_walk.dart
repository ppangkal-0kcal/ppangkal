/// A "walk to the nearest park" suggestion. Appears as `suggested_walk` in
/// `GET /bakeries` (a walk-not-recommended bakery, only when `user_weight`
/// was given) and in `POST /tours/:tourId/stops` (a leg that walked
/// ≤1.2km). Always fully populated when present —
/// `tourApiService.buildParkWalkSuggestion` returns either every field or
/// `null`, never a partial object.
class SuggestedWalk {
  final String contentId;
  final String title;
  final int roundTripDistanceM;
  final int estimatedCaloriesBurned;

  const SuggestedWalk({
    required this.contentId,
    required this.title,
    required this.roundTripDistanceM,
    required this.estimatedCaloriesBurned,
  });

  factory SuggestedWalk.fromJson(Map<String, dynamic> json) => SuggestedWalk(
        contentId: json['content_id'] as String,
        title: json['title'] as String,
        roundTripDistanceM: json['round_trip_distance_m'] as int,
        estimatedCaloriesBurned: json['estimated_calories_burned'] as int,
      );
}
