import '../core/api_client.dart';
import '../models/bread_selection.dart';
import '../models/food_log.dart';

/// POST/GET /api/food-logs (FRONTEND_API_GUIDE.md §2 step 7). Auth required.
class FoodLogService {
  final ApiClient _client;

  FoodLogService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Menu bread sends `bread_item_id`; a bread the user typed in sends
  /// `custom_name` + `custom_calories` instead (nothing is added to the
  /// bakery's menu).
  Future<FoodLog> create({
    required String token,
    required BreadSelection selection,
    String? tourStopId,
  }) async {
    final json = await _client.post(
      '/food-logs',
      token: token,
      body: {
        if (selection.breadItemId != null)
          'bread_item_id': selection.breadItemId
        else ...{
          'custom_name': selection.name,
          'custom_calories': selection.unitCalories,
        },
        'tour_stop_id': ?tourStopId,
        'quantity': selection.quantity,
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
