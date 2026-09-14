import 'package:flutter/material.dart';

import '../models/weekly_stats.dart';
import '../theme/app_theme.dart';

/// 7-day calorie bar chart for the 통계 tab. Each bar's height is
/// `consumed_calories` scaled against the week's max; a bar is colored
/// `over` when that day's `consumed - burned` exceeded the daily goal —
/// the same day-level check the backend uses for `goal_achievement_rate`
/// (see `resolveBalanceStatus`'s sibling logic in `stats.routes.ts`), not a
/// separately invented threshold.
class WeeklyBarChart extends StatelessWidget {
  final WeeklyStats stats;
  final int dailyGoalCalories;

  const WeeklyBarChart({super.key, required this.stats, required this.dailyGoalCalories});

  static const double _maxBarHeight = 120;
  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CalorieStatusColors>() ?? CalorieStatusColors.brand;
    final textTheme = Theme.of(context).textTheme;

    final maxValue = stats.days
        .map((d) => d.consumedCalories)
        .fold<int>(dailyGoalCalories, (a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: stats.days.map((day) {
        final ratio = maxValue > 0 ? day.consumedCalories / maxValue : 0.0;
        final net = day.consumedCalories - day.burnedCalories;
        final overGoal = dailyGoalCalories > 0 && net > dailyGoalCalories;
        final weekday = DateTime.parse(day.date).weekday; // 1=Mon..7=Sun

        final barColor = overGoal ? colors.over : colors.safe;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: textTheme.labelSmall?.fontSize != null ? textTheme.labelSmall!.fontSize! * 1.6 : 18,
              child: day.consumedCalories > 0
                  ? Text('${day.consumedCalories}', style: textTheme.labelSmall)
                  : null,
            ),
            // Fixed-height track so the chart keeps its shape on light days
            // (bars are scaled against the goal, so most days are short).
            Container(
              width: 24,
              height: _maxBarHeight,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: barColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                height: (_maxBarHeight * ratio).clamp(day.consumedCalories > 0 ? 6 : 0, _maxBarHeight),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(_weekdayLabels[weekday - 1], style: textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}
