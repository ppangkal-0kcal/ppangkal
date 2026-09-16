import 'bread_item.dart';

/// A chosen quantity of one bread, either from the bakery's menu
/// ([breadItemId] set) or typed in by the user when the bakery's menu
/// doesn't have it ([isCustom]). Calories here are a live client-side
/// estimate only; nothing is persisted until the real `POST /food-logs`
/// call happens (FRONTEND_API_GUIDE.md §2 step 4: "예상 섭취 칼로리는
/// 저장하지 않는다").
class BreadSelection {
  /// `null` for a user-entered bread — those are never written to
  /// `bread_items`, only to that user's own food log.
  final String? breadItemId;
  final String name;
  final int unitCalories;
  final String? imageUrl;
  final int quantity;

  const BreadSelection({
    this.breadItemId,
    required this.name,
    required this.unitCalories,
    this.imageUrl,
    required this.quantity,
  });

  BreadSelection.fromItem({required BreadItem item, required this.quantity})
      : breadItemId = item.id,
        name = item.name,
        unitCalories = item.calories,
        imageUrl = item.imageUrl;

  bool get isCustom => breadItemId == null;

  int get estimatedCalories => unitCalories * quantity;

  BreadSelection copyWith({int? quantity}) => BreadSelection(
        breadItemId: breadItemId,
        name: name,
        unitCalories: unitCalories,
        imageUrl: imageUrl,
        quantity: quantity ?? this.quantity,
      );
}
