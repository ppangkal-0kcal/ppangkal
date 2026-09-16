/// Mirrors `GET /api/stats/daily` (FRONTEND_API_GUIDE.md §2; backend
/// `src/routes/stats.routes.ts`). All fields always present; [visits] is
/// defaulted to empty for a backend that predates it.
class DailyStats {
  final String date;
  final int consumedCalories;
  final int burnedCalories;
  final int goalCalories;
  final int bakeriesVisited;

  /// That day's bakery arrivals (in-progress tours included), oldest first.
  final List<DailyVisit> visits;

  const DailyStats({
    required this.date,
    required this.consumedCalories,
    required this.burnedCalories,
    required this.goalCalories,
    required this.bakeriesVisited,
    this.visits = const [],
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
        date: json['date'] as String,
        consumedCalories: json['consumed_calories'] as int,
        burnedCalories: json['burned_calories'] as int,
        goalCalories: json['goal_calories'] as int,
        bakeriesVisited: json['bakeries_visited'] as int,
        visits: (json['visits'] as List<dynamic>? ?? const [])
            .map((e) => DailyVisit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DailyVisit {
  final String tourStopId;
  final String bakeryId;
  final String bakeryName;
  final DateTime visitedAt;
  final int caloriesBurned;
  final List<DailyVisitBread> breads;

  const DailyVisit({
    required this.tourStopId,
    required this.bakeryId,
    required this.bakeryName,
    required this.visitedAt,
    required this.caloriesBurned,
    required this.breads,
  });

  int get consumedCalories => breads.fold(0, (sum, b) => sum + b.calories);

  factory DailyVisit.fromJson(Map<String, dynamic> json) => DailyVisit(
        tourStopId: json['tour_stop_id'] as String,
        bakeryId: json['bakery_id'] as String,
        bakeryName: json['bakery_name'] as String,
        visitedAt: DateTime.parse(json['visited_at'] as String),
        caloriesBurned: json['calories_burned'] as int,
        breads: (json['breads'] as List<dynamic>)
            .map((e) => DailyVisitBread.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DailyVisitBread {
  final String breadItemId;
  final String name;
  final int quantity;

  /// Already multiplied by [quantity].
  final int calories;

  const DailyVisitBread({required this.breadItemId, required this.name, required this.quantity, required this.calories});

  factory DailyVisitBread.fromJson(Map<String, dynamic> json) => DailyVisitBread(
        breadItemId: json['bread_item_id'] as String,
        name: json['name'] as String,
        quantity: json['quantity'] as int,
        calories: json['calories'] as int,
      );
}
