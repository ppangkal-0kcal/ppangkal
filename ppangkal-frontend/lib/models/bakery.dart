import '../core/geo.dart';
import '../core/walk_calories.dart';
import 'nearby_park.dart';
import 'suggested_walk.dart';
import 'tour_info.dart';

/// Mirrors both `GET /bakeries` list items and `GET /bakeries/:id` detail
/// (FRONTEND_API_GUIDE.md §2 steps 2~3; backend/src/routes/bakeries.routes.ts).
///
/// The list is fetched **without the user's position** (location-free mode),
/// so `distanceM`/`walkRecommended`/`estimatedWalkCalories`/`suggestedWalk`
/// arrive null and are filled on-device by [withUserPosition] — the phone's
/// coordinates never reach the server. The detail response adds `tour_info`
/// and never has any distance-derived field. `isOpenNow` is always present.
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

  /// On-sale menu count — list response only (`bread_item_count`).
  final int? breadItemCount;

  /// Closest park to this bakery, weight-independent — location-free list only.
  final NearbyPark? nearbyPark;

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
    this.breadItemCount,
    this.nearbyPark,
  });

  /// Fills the distance-derived fields from the user's position, on-device,
  /// with the same rules the server used to apply: 1.2km straight-line
  /// walk cutoff, 4km/h preview speed, and a park-walk suggestion only for
  /// bakeries too far to walk to (and only when [userWeightKg] is known).
  Bakery withUserPosition({required double latitude, required double longitude, double? userWeightKg}) {
    final distance = haversineM(latitude, longitude, this.latitude, this.longitude);
    final walkable = distance <= WalkCalories.walkRecommendThresholdM;
    final park = nearbyPark;

    return Bakery(
      id: id,
      name: name,
      latitude: this.latitude,
      longitude: this.longitude,
      address: address,
      rating: rating,
      reviewCount: reviewCount,
      openingHours: openingHours,
      photoUrl: photoUrl,
      isOpenNow: isOpenNow,
      tourInfo: tourInfo,
      breadItemCount: breadItemCount,
      nearbyPark: park,
      distanceM: distance,
      walkRecommended: walkable,
      estimatedWalkCalories: userWeightKg == null
          ? null
          : WalkCalories.caloriesBurned(userWeightKg, WalkCalories.estimateWalkMinutes(distance)),
      suggestedWalk: walkable || userWeightKg == null || park == null
          ? null
          : SuggestedWalk(
              contentId: park.contentId,
              title: park.title,
              roundTripDistanceM: park.roundTripDistanceM,
              estimatedCaloriesBurned: WalkCalories.caloriesBurned(
                userWeightKg,
                WalkCalories.estimateWalkMinutes(park.roundTripDistanceM.toDouble()),
              ),
            ),
    );
  }

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
        breadItemCount: json['bread_item_count'] as int?,
        nearbyPark:
            json['nearby_park'] != null ? NearbyPark.fromJson(json['nearby_park'] as Map<String, dynamic>) : null,
      );
}
