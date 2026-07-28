import '../core/api_client.dart';

/// GET/POST /api/calories/* (FRONTEND_API_GUIDE.md §2 step 7, §3).
class CaloriesService {
  final ApiClient _client;

  CaloriesService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Auth required.
  Future<Map<String, dynamic>> getBalance(String token) {
    return _client.get('/calories/balance', token: token);
  }

  /// No auth — preview-only calculator.
  Future<Map<String, dynamic>> calculatePreview({
    required double userWeight,
    required int durationMinutes,
  }) {
    return _client.post('/calories/calculate', body: {
      'user_weight': userWeight,
      'duration_minutes': durationMinutes,
    });
  }
}
