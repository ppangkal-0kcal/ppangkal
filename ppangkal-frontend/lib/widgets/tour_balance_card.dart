import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Shows a 0-kcal tour balance (`burned − consumed`, exactly
/// `PATCH /tours/:id/complete`'s `balance_kcal` definition —
/// backend/src/routes/tours.routes.ts) with an action-nudge message.
///
/// This is a *different* concept from the home screen's use of
/// [CalorieStatusColors] on `GET /calories/balance`'s daily goal-relative
/// remaining calories — a single tour has no daily goal, so the
/// safe/warning/over cutoffs here are a separate, tour-specific judgment
/// call (±30kcal / ±150kcal), not derived from any backend threshold. The
/// three [CalorieStatusColors] shades are reused for visual consistency
/// with the rest of the app; the logic deciding which shade applies is
/// local to this widget only.
class TourBalanceCard extends StatelessWidget {
  final String title;
  final int balanceKcal;

  const TourBalanceCard({super.key, required this.title, required this.balanceKcal});

  // TODO(기획): 임의로 정한 임계값 — 기획 확정 시 조정 필요.
  static const int _safeThresholdKcal = 30;
  static const int _warningThresholdKcal = 150;

  Color _color(BuildContext context) {
    final colors = Theme.of(context).extension<CalorieStatusColors>() ?? CalorieStatusColors.grayscale;
    if (balanceKcal >= -_safeThresholdKcal) return colors.safe;
    if (balanceKcal >= -_warningThresholdKcal) return colors.warning;
    return colors.over;
  }

  String get _message {
    if (balanceKcal >= _safeThresholdKcal) {
      return '$balanceKcal kcal만큼 여유 있게 즐겼어요. 다음 빵도 편하게 골라도 좋아요!';
    }
    if (balanceKcal >= -_safeThresholdKcal) {
      return '0-kcal 밸런스에 거의 딱 맞췄어요!';
    }
    final deficit = -balanceKcal;
    if (balanceKcal >= -_warningThresholdKcal) {
      return '$deficit kcal만 더 소모하면 0-kcal 밸런스를 완성해요!';
    }
    return '$deficit kcal 초과했어요. 다음 이동에서 조금 더 걸어볼까요?';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: _color(context), shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${balanceKcal >= 0 ? '+' : ''}$balanceKcal kcal',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_message, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
