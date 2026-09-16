import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/bakery.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'network_photo.dart';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NetworkPhoto(url: bakery.photoUrl, width: 72, height: 72, placeholderIcon: Icons.storefront_outlined),
                const SizedBox(width: AppSpacing.md),
                Expanded(
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
                      Text(bakery.address, style: textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (bakery.distanceM != null)
                            _Meta(icon: Icons.directions_walk, text: formatDistance(bakery.distanceM!)),
                          if (bakery.rating != null)
                            _Meta(
                              icon: Icons.star,
                              text: bakery.rating!.toStringAsFixed(1) +
                                  (bakery.reviewCount != null ? ' (${formatThousands(bakery.reviewCount!)})' : ''),
                            ),
                          if (bakery.breadItemCount != null)
                            _Meta(
                              icon: Icons.bakery_dining_outlined,
                              text: bakery.breadItemCount! > 0 ? '메뉴 ${bakery.breadItemCount}종' : '메뉴 준비 중',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
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

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// 걸어갈 만한 거리라는 건 이 앱에서 "칼로리를 채울 수 있다"는 뜻이라,
/// [CalorieStatusColors]의 안전(초록)을 그대로 쓴다 — 회색 배지일 때는
/// 다른 메타 정보와 구분이 안 됐다.
class _WalkRecommendedBadge extends StatelessWidget {
  const _WalkRecommendedBadge();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<CalorieStatusColors>()?.safe ?? CalorieStatusColors.brand.safe;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_walk, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '걸어가기 좋아요',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
