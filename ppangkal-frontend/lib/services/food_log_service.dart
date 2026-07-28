import '../core/api_client.dart';
import '../models/food_log.dart';

/// POST/GET /api/food-logs (FRONTEND_API_GUIDE.md §2 step 7). Auth required.
class FoodLogService {
  final ApiClient _client;

  FoodLogService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<FoodLog> create({
    required String token,
    required String breadItemId,
    String? tourStopId,
    int quantity = 1,
  }) async {
    final json = await _client.post(
      '/food-logs',
      token: token,
      body: {
        'bread_item_id': breadItemId,
        'tour_stop_id': ?tourStopId,
        'quantity': quantity,
      },
    );
    return FoodLog.fromJson(json);
  }

  Future<List<FoodLog>> list(String token, {String? from, String? to}) async {
    final json = await _client.get(
      '/food-logs',
      token: token,
      query: {
        'from': ?from,
        'to': ?to,
      },
    );
    final list = json['food_logs'] as List<dynamic>;
    return list.map((e) => FoodLog.fromJson(e as Map<String, dynamic>)).toList();
  }
}
