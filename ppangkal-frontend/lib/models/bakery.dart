/// Mirrors GET /api/bakeries list items (FRONTEND_API_GUIDE.md §2). Kept
/// close to the raw response shape since this is a data-verification pass,
/// not a UI pass — `suggestedWalk`/`estimatedWalkCalories` stay as raw
/// dynamic values rather than sub-models for now.
class Bakery {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final double? rating;
  final int? reviewCount;
  final String? openingHours;
  final double? distanceM;
  final bool? isOpenNow;
  final bool? walkRecommended;
  final num? estimatedWalkCalories;
  final Map<String, dynamic>? suggestedWalk;

  const Bakery({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.rating,
    this.reviewCount,
    this.openingHours,
    this.distanceM,
    this.isOpenNow,
    this.walkRecommended,
    this.estimatedWalkCalories,
    this.suggestedWalk,
  });

  factory Bakery.fromJson(Map<String, dynamic> json) => Bakery(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String,
        rating: (json['rating'] as num?)?.toDouble(),
        reviewCount: json['review_count'] as int?,
        openingHours: json['opening_hours'] as String?,
        distanceM: (json['distance_m'] as num?)?.toDouble(),
        isOpenNow: json['is_open_now'] as bool?,
        walkRecommended: json['walk_recommended'] as bool?,
        estimatedWalkCalories: json['estimated_walk_calories'] as num?,
        suggestedWalk: json['suggested_walk'] as Map<String, dynamic>?,
      );
}
