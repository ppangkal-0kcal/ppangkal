import '../core/api_client.dart';
import '../models/spot_detail.dart';

/// GET /api/tour/* — TourAPI(한국관광공사) proxy, NOT the /tours (빵투어) resource.
/// Auth required (FRONTEND_API_GUIDE.md §3 endpoint table note).
///
/// Nearby spots come from `BakeryService.fetchNearbySpots` (bakery
/// coordinates). The old `/tour/nearby` call sent the user's coordinates and
/// was removed so location never leaves the phone.
class SightseeingService {
  final ApiClient _client;

  SightseeingService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<SpotDetail> spotDetail(String token, String contentId) async {
    final json = await _client.get('/tour/spots/$contentId', token: token);
    return SpotDetail.fromJson(json);
  }
}
