/// `GET /tour/spots/:contentId` — TourAPI detailCommon2 + detailImage2
/// (backend caches it for 7 days).
class SpotDetail {
  final String contentId;
  final String title;

  /// TourAPI overview with its inline HTML (`<br>` etc.) stripped.
  final String overview;
  final String? openingHours;
  final List<String> images;

  const SpotDetail({
    required this.contentId,
    required this.title,
    required this.overview,
    this.openingHours,
    required this.images,
  });

  factory SpotDetail.fromJson(Map<String, dynamic> json) => SpotDetail(
        contentId: json['content_id'] as String,
        title: json['title'] as String,
        overview: _stripHtml(json['overview'] as String? ?? ''),
        openingHours: _nullIfBlank(_stripHtml(json['opening_hours'] as String? ?? '')),
        images: (json['images'] as List<dynamic>? ?? const []).cast<String>(),
      );

  static String _stripHtml(String value) => value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();

  static String? _nullIfBlank(String value) => value.isEmpty ? null : value;
}
