/// One entry of `GET /bakeries/:id/nearby-spots` — a TourAPI spot within
/// 2km of the **bakery** (not the user; the phone's position is never sent).
/// Walk time/calories are derived on-device from [distanceM].
class NearbySpot {
  final String contentId;
  final String title;

  /// 관광지/문화시설/축제·공연/레포츠/쇼핑, or `null` if TourAPI had no type.
  final String? contentType;
  final String? address;
  final String? imageUrl;

  /// Straight-line distance from the bakery.
  final int distanceM;
  final double latitude;
  final double longitude;

  const NearbySpot({
    required this.contentId,
    required this.title,
    this.contentType,
    this.address,
    this.imageUrl,
    required this.distanceM,
    required this.latitude,
    required this.longitude,
  });

  factory NearbySpot.fromJson(Map<String, dynamic> json) => NearbySpot(
        contentId: json['content_id'] as String,
        title: json['title'] as String,
        contentType: json['content_type'] as String?,
        address: json['address'] as String?,
        imageUrl: json['image_url'] as String?,
        distanceM: json['distance_m'] as int,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}
