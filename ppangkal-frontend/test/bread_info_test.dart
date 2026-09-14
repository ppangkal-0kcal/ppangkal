import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ppangkal/core/api_client.dart';
import 'package:ppangkal/core/formatters.dart';
import 'package:ppangkal/core/walk_calories.dart';
import 'package:ppangkal/models/bakery.dart';
import 'package:ppangkal/models/bread_item.dart';
import 'package:ppangkal/services/bakery_service.dart';

void main() {
  test('formatters', () {
    expect(formatThousands(5700), '5,700');
    expect(formatThousands(18392), '18,392');
    expect(formatThousands(900), '900');
    expect(formatDistance(405), '405m');
    expect(formatDistance(4690), '4.7km');
  });

  test('walk formulas match backend calorieService', () {
    // 400kcal / (3.5 × 60kg × 1.05) h = 1.814h ≈ 109분
    expect(WalkCalories.minutesToBurn(400, 60), 109);
    // estimateWalkMinutes(1000m) = round(1000 / 66.67) = 15 → 3.5 × 60 × 0.25 × 1.05 = 55.1 → 55
    expect(WalkCalories.estimateWalkMinutes(1000), 15);
    expect(WalkCalories.caloriesBurned(60, 15), 55);
  });

  group('on-device distance (location never sent)', () {
    final json = {
      'id': 'bak_far',
      'name': '먼 빵집',
      'latitude': 36.3504,
      'longitude': 127.4045, // ~1.8km east of the user below
      'address': '대전',
      'is_open_now': true,
      'bread_item_count': 3,
      'nearby_park': {'content_id': '123', 'title': '우리들공원', 'round_trip_distance_m': 1000},
    };

    test('far bakery: not walkable, park suggestion with user weight', () {
      final bakery =
          Bakery.fromJson(json).withUserPosition(latitude: 36.3504, longitude: 127.3845, userWeightKg: 60);
      expect(bakery.distanceM, closeTo(1790, 30));
      expect(bakery.walkRecommended, isFalse);
      expect(bakery.estimatedWalkCalories, isNotNull);
      expect(bakery.suggestedWalk?.title, '우리들공원');
      expect(bakery.suggestedWalk?.estimatedCaloriesBurned, 55);
    });

    test('near bakery: walkable, no park suggestion; no weight means no calories', () {
      final bakery = Bakery.fromJson(json).withUserPosition(latitude: 36.3504, longitude: 127.4000);
      expect(bakery.walkRecommended, isTrue);
      expect(bakery.suggestedWalk, isNull);
      expect(bakery.estimatedWalkCalories, isNull);
    });

    test('list request carries no coordinates or weight', () async {
      late Uri requested;
      final service = BakeryService(
        client: ApiClient(
          httpClient: MockClient((request) async {
            requested = request.url;
            return http.Response('{"bakeries":[]}', 200);
          }),
        ),
      );
      await service.fetchAll();
      expect(requested.path, endsWith('/bakeries'));
      expect(requested.queryParameters, isEmpty);
    });
  });

  test('curated list/item fields parse', () {
    final bakery = Bakery.fromJson({
      'id': 'bak_namusangja',
      'name': '나무상자',
      'latitude': 36.35,
      'longitude': 127.37,
      'address': '대전 서구',
      'is_open_now': false,
      'photo_url': 'https://example.com/curated/bak_namusangja/entrance.jpg',
      'bread_item_count': 3,
    });
    expect(bakery.breadItemCount, 3);
    expect(bakery.photoUrl, isNotNull);
    expect(bakery.nearbyPark, isNull);

    final item = BreadItem.fromJson({
      'id': 'itm_bak_mongsim_황치즈 휘낭시에',
      'bakery_id': 'bak_mongsim',
      'name': '황치즈 휘낭시에',
      'category': '디저트',
      'price': 4500,
      'calories': 270,
      'source_grade': 'C',
      'source_note': '매장 미공개 — 유사 제품 기준 추정치',
      'image_url': null,
      'is_available': true,
    });
    expect(item.isCalorieEstimated, isTrue);
  });
}
