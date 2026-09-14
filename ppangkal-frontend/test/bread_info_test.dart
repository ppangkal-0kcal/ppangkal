import 'package:flutter_test/flutter_test.dart';

import 'package:ppangkal/core/formatters.dart';
import 'package:ppangkal/models/bakery.dart';
import 'package:ppangkal/models/bread_item.dart';
import 'package:ppangkal/widgets/bread_detail_sheet.dart';

void main() {
  test('formatters', () {
    expect(formatThousands(5700), '5,700');
    expect(formatThousands(18392), '18,392');
    expect(formatThousands(900), '900');
    expect(formatDistance(405), '405m');
    expect(formatDistance(4690), '4.7km');
  });

  test('walk minutes use the backend MET formula (3.5 × kg × h × 1.05)', () {
    // 400kcal / (3.5 × 60kg × 1.05) h = 1.814h ≈ 109분
    expect(walkMinutesToBurn(400, 60), 109);
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
