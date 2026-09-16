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
        Text(value, style: textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

/// A full-width row of [StatColumn]s. Each column gets an equal share and
/// centres inside it, so the first and last keep a gutter from the card edge
/// instead of sitting flush against it the way `spaceBetween` leaves them.
class StatRow extends StatelessWidget {
  final List<StatColumn> children;

  const StatRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [for (final child in children) Expanded(child: child)],
    );
  }
}
