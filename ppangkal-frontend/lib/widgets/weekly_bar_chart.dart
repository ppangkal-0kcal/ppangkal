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

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: (_maxBarHeight * ratio).clamp(4, _maxBarHeight),
              decoration: BoxDecoration(
                color: overGoal ? colors.over : colors.safe,
                borderRadius: BorderRadius.circular(8),
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
