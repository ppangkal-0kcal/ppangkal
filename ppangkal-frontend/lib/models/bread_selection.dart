import 'bread_item.dart';

/// A chosen quantity for one [BreadItem] — the shape the tour flow will
/// eventually hand off to food-log confirmation (a later pass). Calories
/// here are a live client-side estimate only; nothing is persisted until
/// the real `POST /food-logs` call happens
/// (FRONTEND_API_GUIDE.md §2 step 4: "예상 섭취 칼로리는 저장하지 않는다").
class BreadSelection {
  final BreadItem item;
  final int quantity;

  const BreadSelection({required this.item, required this.quantity});

  int get estimatedCalories => item.calories * quantity;

  BreadSelection copyWith({int? quantity}) => BreadSelection(item: item, quantity: quantity ?? this.quantity);
}
