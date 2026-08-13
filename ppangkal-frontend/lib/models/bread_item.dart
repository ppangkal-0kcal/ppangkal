/// GET /api/bakeries/{bakeryId}/items response items (FRONTEND_API_GUIDE.md §2 step 4).
class BreadItem {
  final String id;
  final String name;
  final String? category;
  final num? price;
  final num? calories;
  final num? baseWeightG;
  final bool? isAvailable;
  final String? imageUrl;

  const BreadItem({
    required this.id,
    required this.name,
    this.category,
    this.price,
    this.calories,
    this.baseWeightG,
    this.isAvailable,
    this.imageUrl,
  });

  factory BreadItem.fromJson(Map<String, dynamic> json) => BreadItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String?,
        price: json['price'] as num?,
        calories: json['calories'] as num?,
        baseWeightG: json['base_weight_g'] as num?,
        isAvailable: json['is_available'] as bool?,
        imageUrl: json['image_url'] as String?,
      );
}
