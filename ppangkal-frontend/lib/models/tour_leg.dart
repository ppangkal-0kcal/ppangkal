import 'bakery.dart';
import 'bread_selection.dart';
import 'tour_stop.dart';

/// The bakery + bread the user picked for the current leg of an active tour,
/// and how far that leg has progressed. Client-only state held by
/// `TourFlowController` — the server never stores a pre-arrival pick
/// (FRONTEND_API_GUIDE.md §2 step 4), so this is what lets 홈/통계 show
/// "what did I choose" before anything is confirmed.
class TourLeg {
  final Bakery bakery;
  final List<BreadSelection> selections;

  /// Set once `POST /tours/:id/stops` succeeds for [bakery].
  final TourStop? arrivedStop;

  /// Set once every selection was logged via `POST /food-logs`.
  final bool foodConfirmed;

  const TourLeg({
    required this.bakery,
    required this.selections,
    this.arrivedStop,
    this.foodConfirmed = false,
  });

  int get estimatedCalories => selections.fold(0, (sum, s) => sum + s.estimatedCalories);

  TourLeg copyWith({List<BreadSelection>? selections, TourStop? arrivedStop, bool? foodConfirmed}) => TourLeg(
        bakery: bakery,
        selections: selections ?? this.selections,
        arrivedStop: arrivedStop ?? this.arrivedStop,
        foodConfirmed: foodConfirmed ?? this.foodConfirmed,
      );
}
