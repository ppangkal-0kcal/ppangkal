import 'package:flutter/material.dart';

import '../models/tour_stop.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Shows a just-recorded [TourStop] — the server-computed
/// `calories_burned` for that leg, plus a park-walk suggestion
/// (`suggested_walk`) when the backend included one (only when this leg's
/// `distance_m` was ≤1.2km — see `tourApiService.buildParkWalkSuggestion`).
class ArrivalResultCard extends StatelessWidget {
  final TourStop stop;

  const ArrivalResultCard({super.key, required this.stop});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final walk = stop.suggestedWalk;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('도착했어요!', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${stop.steps}걸음 · ${stop.distanceM}m · ${stop.caloriesBurned}kcal 소모',
            style: textTheme.bodyMedium,
          ),
          if (walk != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '도착 후 산책 제안: ${walk.title} 왕복 ${walk.roundTripDistanceM}m '
              '(약 ${walk.estimatedCaloriesBurned}kcal 추가 소모)',
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
