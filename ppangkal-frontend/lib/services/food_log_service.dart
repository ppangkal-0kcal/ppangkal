import '../core/api_client.dart';

/// POST/GET /api/food-logs (FRONTEND_API_GUIDE.md §2 step 7). Auth required.
class FoodLogService {
  final ApiClient _client;

  FoodLogService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> create({
    required String token,
    required String breadItemId,
    String? tourStopId,
    int quantity = 1,
  }) {
    return _client.post(
      '/food-logs',
      token: token,
      body: {
        'bread_item_id': breadItemId,
        'tour_stop_id': ?tourStopId,
        'quantity': quantity,
      },
    );
  }

  Future<Map<String, dynamic>> list(String token, {String? from, String? to}) {
    return _client.get(
      '/food-logs',
      token: token,
      query: {
        'from': ?from,
        'to': ?to,
      },
    );
  }
}
