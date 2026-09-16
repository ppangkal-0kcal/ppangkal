import '../core/api_client.dart';
import '../models/tour.dart';
import '../models/tour_stop.dart';
import '../models/tour_summary.dart';

/// POST/GET/PATCH /api/tours* (FRONTEND_API_GUIDE.md §2 steps 1, 7~8) — all
/// auth required.
class TourService {
  final ApiClient _client;

  TourService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Tour> startTour(String token) async {
    final json = await _client.post('/tours', token: token);
    return Tour.fromJson(json);
  }

  Future<TourStop> addStop({
    required String token,
    required String tourId,
    required String bakeryId,
    required int distanceM,
    required int durationMinutes,
    required int steps,
  }) async {
    final json = await _client.post(
      '/tours/$tourId/stops',
      token: token,
      body: {
        'bakery_id': bakeryId,
        'distance_m': distanceM,
        'duration_minutes': durationMinutes,
        'steps': steps,
      },
    );
    return TourStop.fromJson(json);
  }

  Future<Tour> completeTour(String token, String tourId) async {
    final json = await _client.patch('/tours/$tourId/complete', token: token);
    return Tour.fromJson(json);
  }

  Future<Tour> getTour(String token, String tourId) async {
    final json = await _client.get('/tours/$tourId', token: token);
    return Tour.fromJson(json);
  }

  /// 완료된 투어만, 최신순 (통계 탭의 지난 리포트 목록).
  Future<List<TourSummary>> fetchHistory(String token, {int limit = 20}) async {
    final json = await _client.get('/tours', token: token, query: {'limit': '$limit'});
    final list = json['tours'] as List<dynamic>;
    return list.map((e) => TourSummary.fromJson(e as Map<String, dynamic>)).toList();
  }
}
