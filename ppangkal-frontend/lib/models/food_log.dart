/// Mirrors `POST`/`GET /api/food-logs` (FRONTEND_API_GUIDE.md §2 step 7;
/// backend/src/routes/foodLogs.routes.ts) — both return the same shape.
/// `tourStopId` is nullable: it's optional on creation (a food log doesn't
/// have to be tied to a tour) and the backend passes that through as-is.
class FoodLog {
  final String id;
  final String breadItemId;
  final String? tourStopId;
  final int calories;
  final int quantity;
  final DateTime loggedAt;

  const FoodLog({
    required this.id,
    required this.breadItemId,
    this.tourStopId,
    required this.calories,
    required this.quantity,
    required this.loggedAt,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) => FoodLog(
        id: json['id'] as String,
        breadItemId: json['bread_item_id'] as String,
        tourStopId: json['tour_stop_id'] as String?,
        calories: json['calories'] as int,
        quantity: json['quantity'] as int,
        loggedAt: DateTime.parse(json['logged_at'] as String),
      );
}
