import 'package:flutter/material.dart';

import '../models/bakery.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// One row in the bakery list (`GET /bakeries` — FRONTEND_API_GUIDE.md §2
/// steps 2~3). Only renders fields the list response actually has —
/// `distance_m`/`walk_recommended`/`suggested_walk` are all list-only and
/// nullable, see `lib/models/bakery.dart`.
class BakeryCard extends StatelessWidget {
  final Bakery bakery;
  final VoidCallback onTap;

  const BakeryCard({super.key, required this.bakery, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final walk = bakery.suggestedWalk;

    return InkWell(
      onTap: onTap,
      borderRadius: Theme.of(context).extension<GlassStyle>()?.borderRadius,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(bakery.name, style: textTheme.titleMedium)),
                if (bakery.walkRecommended == true) const _WalkRecommendedBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(bakery.address, style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (bakery.distanceM != null) ...[
                  const Icon(Icons.directions_walk, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text('${bakery.distanceM!.round()}m', style: textTheme.bodySmall),
                  const SizedBox(width: AppSpacing.md),
                ],
                if (bakery.rating != null) ...[
                  const Icon(Icons.star, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text(bakery.rating!.toStringAsFixed(1), style: textTheme.bodySmall),
                  if (bakery.reviewCount != null)
                    Text(' (${bakery.reviewCount})', style: textTheme.bodySmall),
                ],
              ],
            ),
            if (bakery.walkRecommended == false && walk != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '도보 대신 ${walk.title} 왕복 산책 추천 '
                '(${walk.roundTripDistanceM}m, 약 ${walk.estimatedCaloriesBurned}kcal)',
                style: textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WalkRecommendedBadge extends StatelessWidget {
  const _WalkRecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('걸어가기 좋아요', style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
