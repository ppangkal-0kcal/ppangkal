import '../core/api_client.dart';

/// POST/GET/PATCH /api/tours* (FRONTEND_API_GUIDE.md §2 steps 1, 7~8) — all
/// auth required. Raw-map passthrough for now (data-verification pass, no
/// design/models yet).
class TourService {
  final ApiClient _client;

  TourService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> startTour(String token) {
    return _client.post('/tours', token: token);
  }

  Future<Map<String, dynamic>> addStop({
    required String token,
    required String tourId,
    required String bakeryId,
    required int distanceM,
    required int durationMinutes,
    required int steps,
  }) {
    return _client.post(
      '/tours/$tourId/stops',
      token: token,
      body: {
        'bakery_id': bakeryId,
        'distance_m': distanceM,
        'duration_minutes': durationMinutes,
        'steps': steps,
      },
    );
  }

  Future<Map<String, dynamic>> completeTour(String token, String tourId) {
    return _client.patch('/tours/$tourId/complete', token: token);
  }

  Future<Map<String, dynamic>> getTour(String token, String tourId) {
    return _client.get('/tours/$tourId', token: token);
  }
}
