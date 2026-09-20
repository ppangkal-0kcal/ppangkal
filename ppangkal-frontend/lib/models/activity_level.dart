/// The backend accepts exactly these three strings for `activity_level`
/// (FRONTEND_API_GUIDE.md §1) — anything else is a 400.
class ActivityLevel {
  static const travelRest = '여행 휴식';
  static const sightseeing = '관광';
  static const walkingTour = '도보여행';

  static const values = [travelRest, sightseeing, walkingTour];

  /// What the user sees. The API value stays as-is — the backend matches these
  /// exact strings, so only the label is reworded.
  static String label(String value) => switch (value) {
        travelRest => '휴식 위주',
        _ => value,
      };
}
