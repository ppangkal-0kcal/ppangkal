import '../core/api_client.dart';
import '../models/bakery.dart';
import '../models/bread_item.dart';

/// GET /api/bakeries* (FRONTEND_API_GUIDE.md §2 steps 2~4) — none of these
/// three require auth.
class BakeryService {
  final ApiClient _client;

  BakeryService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Bakery>> fetchNearby({
    required double lat,
    required double lng,
    double radiusKm = 3,
    String sort = 'recommended',
    double? userWeight,
  }) async {
    final json = await _client.get('/bakeries', query: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius_km': radiusKm.toString(),
      'sort': sort,
      if (userWeight != null) 'user_weight': userWeight.toString(),
    });
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
