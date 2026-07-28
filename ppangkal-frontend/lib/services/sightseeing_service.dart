import '../core/api_client.dart';

/// GET /api/tour/* — TourAPI(한국관광공사) proxy, NOT the /tours (빵투어) resource.
/// Auth required (FRONTEND_API_GUIDE.md §3 endpoint table note).
class SightseeingService {
  final ApiClient _client;

  SightseeingService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> nearby({
    required String token,
    required double lat,
    required double lng,
    double radiusKm = 2,
  }) {
    return _client.get('/tour/nearby', token: token, query: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius_km': radiusKm.toString(),
    });
  }

  Future<Map<String, dynamic>> spotDetail(String token, String contentId) {
    return _client.get('/tour/spots/$contentId', token: token);
  }
}
