/// TourAPI enrichment for a bakery detail — `tour_info` in
/// `GET /bakeries/:id` (FRONTEND_API_GUIDE.md §2 steps 2~3). Only present
/// when the bakery has a `tour_content_id` AND the TourAPI call succeeds;
/// `null` otherwise (unregistered bakery, or a transient TourAPI failure —
/// both normal, not error cases; see
/// backend/src/routes/bakeries.routes.ts's `fetchTourInfoSafely`).
///
/// Even when non-null, individual fields can still be null/empty — TourAPI
/// itself may simply not have that data for a given spot. [isEmpty] lets a
/// screen decide whether the whole enrichment section is worth showing at
/// all, instead of rendering a header over nothing.
class TourInfo {
  final String? overview;
  final String? tel;
  final List<String> homepageUrls;
  final List<String> images;
  final String? signatureMenu;
  final String? recommendedMenu;
  final String? openTime;
  final String? restDate;
  final String? parking;
  final String? packaging;

  const TourInfo({
    this.overview,
    this.tel,
    this.homepageUrls = const [],
    this.images = const [],
    this.signatureMenu,
    this.recommendedMenu,
    this.openTime,
    this.restDate,
    this.parking,
    this.packaging,
  });

  bool get isEmpty =>
      overview == null &&
      tel == null &&
      homepageUrls.isEmpty &&
      images.isEmpty &&
      signatureMenu == null &&
      recommendedMenu == null &&
      openTime == null &&
      restDate == null &&
      parking == null &&
      packaging == null;

  factory TourInfo.fromJson(Map<String, dynamic> json) => TourInfo(
        overview: json['overview'] as String?,
        tel: json['tel'] as String?,
        homepageUrls: (json['homepage_urls'] as List<dynamic>?)?.cast<String>() ?? const [],
        images: (json['images'] as List<dynamic>?)?.cast<String>() ?? const [],
        signatureMenu: json['signature_menu'] as String?,
        recommendedMenu: json['recommended_menu'] as String?,
        openTime: json['open_time'] as String?,
        restDate: json['rest_date'] as String?,
        parking: json['parking'] as String?,
        packaging: json['packaging'] as String?,
      );
}
