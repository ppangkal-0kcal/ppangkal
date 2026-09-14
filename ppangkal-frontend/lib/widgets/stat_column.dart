import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single labeled number in a row of stats (calorie balance card, tour
/// progress card, tour report). Takes the value pre-formatted as a string
/// so callers can add their own unit suffix (`'kcal'`, `'m'`, ...).
class StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const StatColumn({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}
