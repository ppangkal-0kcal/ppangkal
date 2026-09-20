import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/tour_summary.dart';
import '../theme/app_theme.dart';
import 'expandable_tile.dart';
import 'glass_card.dart';

/// 통계 — 지난 투어 리포트 (`GET /tours`, 완료된 것만 최신순). Each row opens
/// to its totals; "리포트 자세히 보기" pushes `/tour/report/:tourId`, the same
/// screen shown right after a tour ends.
class TourHistoryCard extends StatelessWidget {
  final List<TourSummary> tours;

  const TourHistoryCard({super.key, required this.tours});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('지난 투어 리포트', style: textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),),
          const SizedBox(height: AppSpacing.md),
          if (tours.isEmpty) ...[
            Text('아직 끝낸 투어가 없어요. 투어를 마치면 여기에 리포트가 쌓여요.', style: textTheme.bodySmall),
          ],
          for (final tour in tours)
            ExpandableTile(
              title: _formatDate(tour.completedAt),
              subtitle: _bakerySummary(tour),
              trailing: _BalanceChip(balanceKcal: tour.balanceKcal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line(label: '총 걸음', value: '${tour.totalSteps}걸음'),
                  _Line(label: '총 거리', value: '${tour.totalDistanceM}m'),
                  _Line(label: '총 소모', value: '${tour.totalCaloriesBurned}kcal'),
                  _Line(label: '총 섭취', value: '${tour.totalCaloriesConsumed}kcal'),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/tour/report/${tour.id}'),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('리포트 자세히 보기'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _bakerySummary(TourSummary tour) {
    if (tour.bakeryNames.isEmpty) return '방문한 빵집 없음';
    if (tour.bakeryNames.length == 1) return tour.bakeryNames.first;
    return '${tour.bakeryNames.first} 외 ${tour.bakeryNames.length - 1}곳';
  }

  static String _formatDate(DateTime? utc) {
    if (utc == null) return '날짜 미상';
    final t = utc.toLocal();
    return '${t.year}.${t.month.toString().padLeft(2, '0')}.${t.day.toString().padLeft(2, '0')}';
  }
}

/// 밸런스는 부호가 핵심이라 색으로 먼저 읽히게 한다 — 0 이하면 안전(초록),
/// 초과면 빨강. [CalorieStatusColors]의 신호등 3색과 같은 규칙.
class _BalanceChip extends StatelessWidget {
  final int balanceKcal;

  const _BalanceChip({required this.balanceKcal});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CalorieStatusColors>() ?? CalorieStatusColors.brand;
    final color = balanceKcal <= 0 ? colors.safe : colors.over;
    final sign = balanceKcal > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$sign${balanceKcal}kcal',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodySmall)),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
