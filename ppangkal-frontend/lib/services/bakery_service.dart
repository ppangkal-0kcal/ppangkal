import '../core/api_client.dart';
import '../models/bakery.dart';
import '../models/bread_item.dart';

/// GET /api/bakeries* (FRONTEND_API_GUIDE.md §2 steps 2~4) — none of these
/// three require auth.
class BakeryService {
  final ApiClient _client;

  BakeryService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Every bakery, requested **without** the user's position or weight —
  /// callers compute distance, walkability, calories and sort order on-device
  /// via [Bakery.withUserPosition], so location never leaves the phone.
  Future<List<Bakery>> fetchAll() async {
    final json = await _client.get('/bakeries');
    final list = json['bakeries'] as List<dynamic>;
    return list.map((e) => Bakery.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bakery> fetchDetail(String bakeryId) async {
    final json = await _client.get('/bakeries/$bakeryId');
    return Bakery.fromJson(json);
  }

  Future<List<BreadItem>> fetchItems(String bakeryId) async {
    final json = await _client.get('/bakeries/$bakeryId/items');
    final list = json['bread_items'] as List<dynamic>;
    return list.map((e) => BreadItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
