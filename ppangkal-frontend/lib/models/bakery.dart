import 'suggested_walk.dart';
import 'tour_info.dart';

/// Mirrors both `GET /bakeries` list items and `GET /bakeries/:id` detail
/// (FRONTEND_API_GUIDE.md §2 steps 2~3; backend/src/routes/bakeries.routes.ts)
/// — the two responses aren't the same shape:
/// - list items include `distance_m`/`walk_recommended`/
///   `estimated_walk_calories`/`suggested_walk` (computed from the query's
///   `lat`/`lng`/`user_weight`), but never `tour_info`
/// - the detail response adds `tour_info` but omits all 4 of those
///   distance-derived fields entirely
///
/// so those 5 fields are all nullable, and which ones are populated
/// depends on which endpoint produced this instance. `isOpenNow` is the
/// one extra field guaranteed non-null from both — `geo.isBakeryOpenNow`
/// always returns a plain `boolean`, never `null`.
class Bakery {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final double? rating;
  final int? reviewCount;
  final String? openingHours;
  final String? photoUrl;
  final bool isOpenNow;
  final double? distanceM;
  final bool? walkRecommended;
  final num? estimatedWalkCalories;
  final SuggestedWalk? suggestedWalk;
  final TourInfo? tourInfo;

  const Bakery({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.rating,
    this.reviewCount,
    this.openingHours,
    this.photoUrl,
    required this.isOpenNow,
    this.distanceM,
    this.walkRecommended,
    this.estimatedWalkCalories,
    this.suggestedWalk,
    this.tourInfo,
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
        photoUrl: json['photo_url'] as String?,
        isOpenNow: json['is_open_now'] as bool,
        distanceM: (json['distance_m'] as num?)?.toDouble(),
        walkRecommended: json['walk_recommended'] as bool?,
        estimatedWalkCalories: json['estimated_walk_calories'] as num?,
        suggestedWalk: json['suggested_walk'] != null
            ? SuggestedWalk.fromJson(json['suggested_walk'] as Map<String, dynamic>)
            : null,
        tourInfo:
            json['tour_info'] != null ? TourInfo.fromJson(json['tour_info'] as Map<String, dynamic>) : null,
      );
}
