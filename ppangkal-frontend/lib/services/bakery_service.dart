import '../core/api_client.dart';
import '../models/bakery.dart';
import '../models/bread_item.dart';

/// GET /api/bakeries (FRONTEND_API_GUIDE.md §2) — no auth required.
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

  /// Raw passthrough — `tour_info` is null unless the bakery is TourAPI-registered
  /// (FRONTEND_API_GUIDE.md §2 step 2~3), so this is left as a Map, not a model.
  Future<Map<String, dynamic>> fetchDetail(String bakeryId) {
    return _client.get('/bakeries/$bakeryId');
  }

  Future<List<BreadItem>> fetchItems(String bakeryId) async {
    final json = await _client.get('/bakeries/$bakeryId/items');
    final list = json['bread_items'] as List<dynamic>;
    return list.map((e) => BreadItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
