import '../core/api_client.dart';
import '../models/calorie_balance.dart';

/// GET/POST /api/calories/* (FRONTEND_API_GUIDE.md §2 step 7, §3).
class CaloriesService {
  final ApiClient _client;

  CaloriesService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Auth required.
  Future<CalorieBalance> getBalance(String token) async {
    final json = await _client.get('/calories/balance', token: token);
    return CalorieBalance.fromJson(json);
  }

  /// No auth — preview-only calculator. Response shape (`met_value`,
  /// `calories_burned`, `message`) isn't one of the requested models and
  /// has no current caller, so it's left as a raw map for now.
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
