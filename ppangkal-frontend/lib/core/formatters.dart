/// 5700 → "5,700"
String formatThousands(int value) =>
    value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// 405 → "405m", 4690 → "4.7km"
String formatDistance(double meters) =>
    meters < 1000 ? '${meters.round()}m' : '${(meters / 1000).toStringAsFixed(1)}km';
