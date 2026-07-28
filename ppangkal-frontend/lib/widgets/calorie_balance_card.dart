import 'package:flutter/material.dart';

import '../models/calorie_balance.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Renders a [CalorieBalance] snapshot — today's remaining calories plus
/// the safe/warning/over status. `balance.status` ('green'/'yellow'/'red')
/// is already decided server-side (calorieService.resolveBalanceStatus);
/// this widget only maps that string to a [CalorieStatusColors] shade, it
/// never re-derives the thresholds itself.
class CalorieBalanceCard extends StatelessWidget {
  final CalorieBalance balance;

  const CalorieBalanceCard({super.key, required this.balance});

  static const double _statusDotSize = 10;

  Color _statusColor(BuildContext context) {
    final colors = Theme.of(context).extension<CalorieStatusColors>() ?? CalorieStatusColors.grayscale;
    return switch (balance.status) {
      'green' => colors.safe,
      'yellow' => colors.warning,
      'red' => colors.over,
      _ => colors.warning,
    };
  }

  String get _statusLabel => switch (balance.status) {
        'green' => '안전',
        'yellow' => '주의',
        'red' => '초과',
        _ => balance.status,
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('오늘의 칼로리 잔액', style: textTheme.titleMedium),
              Row(
                children: [
                  Container(
                    width: _statusDotSize,
                    height: _statusDotSize,
                    decoration: BoxDecoration(color: _statusColor(context), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_statusLabel, style: textTheme.labelMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${balance.remainingCalories} kcal', style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatColumn(label: '목표', value: balance.dailyGoalCalories),
              _StatColumn(label: '섭취', value: balance.consumedCalories),
              _StatColumn(label: '소모', value: balance.burnedCalories),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('$value', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}
