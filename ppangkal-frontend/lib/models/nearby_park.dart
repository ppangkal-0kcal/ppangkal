/// `nearby_park` in the location-free `GET /bakeries` response — the park
/// closest to a bakery (TourAPI), independent of who's asking. The app
/// turns it into a [SuggestedWalk] with the user's weight on-device.
class NearbyPark {
  final String contentId;
  final String title;
  final int roundTripDistanceM;

  const NearbyPark({required this.contentId, required this.title, required this.roundTripDistanceM});

  factory NearbyPark.fromJson(Map<String, dynamic> json) => NearbyPark(
        contentId: json['content_id'] as String,
        title: json['title'] as String,
        roundTripDistanceM: json['round_trip_distance_m'] as int,
      );
}
