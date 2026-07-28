/// Mirrors `GET /api/bakeries/{bakeryId}/items` response items
/// (FRONTEND_API_GUIDE.md §2 step 4; backend/src/routes/bakeries.routes.ts,
/// cross-checked against `prisma/schema.prisma`'s `BreadItem` model for
/// nullability). `sourceGrade`/`sourceNote` record data-trust provenance —
/// grade C entries are required by the backend to carry a `sourceNote`
/// explaining the estimate, so treat a C-grade item with no note as
/// unexpected rather than filtering it out silently.
class BreadItem {
  final String id;
  final String bakeryId;
  final String name;
  final String? category;
  final int price;
  final int calories;
  final int? baseWeightG;
  final double? carbG;
  final double? proteinG;
  final double? fatG;
  final String? sourceGrade;
  final String? sourceNote;
  final String? imageUrl;
  final bool isAvailable;

  const BreadItem({
    required this.id,
    required this.bakeryId,
    required this.name,
    this.category,
    required this.price,
    required this.calories,
    this.baseWeightG,
    this.carbG,
    this.proteinG,
    this.fatG,
    this.sourceGrade,
    this.sourceNote,
    this.imageUrl,
    required this.isAvailable,
  });

  factory BreadItem.fromJson(Map<String, dynamic> json) => BreadItem(
        id: json['id'] as String,
        bakeryId: json['bakery_id'] as String,
        name: json['name'] as String,
        category: json['category'] as String?,
        price: json['price'] as int,
        calories: json['calories'] as int,
        baseWeightG: json['base_weight_g'] as int?,
        carbG: (json['carb_g'] as num?)?.toDouble(),
        proteinG: (json['protein_g'] as num?)?.toDouble(),
        fatG: (json['fat_g'] as num?)?.toDouble(),
        sourceGrade: json['source_grade'] as String?,
        sourceNote: json['source_note'] as String?,
        imageUrl: json['image_url'] as String?,
        isAvailable: json['is_available'] as bool,
      );
}
