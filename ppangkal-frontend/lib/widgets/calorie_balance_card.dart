import 'package:flutter/material.dart';

import '../models/calorie_balance.dart';
import '../theme/app_theme.dart';
import 'calorie_gauge.dart';
import 'glass_card.dart';
import 'stat_column.dart';

/// Renders a [CalorieBalance] snapshot as a circular gauge (remaining
/// calories centered, status pill below) plus the 목표/섭취/소모 breakdown.
/// `balance.status` ('green'/'yellow'/'red') is already decided
/// server-side (calorieService.resolveBalanceStatus) — see [CalorieGauge]
/// for the status→color mapping, never re-derived here.
class CalorieBalanceCard extends StatelessWidget {
  final CalorieBalance balance;

  const CalorieBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        children: [
          Text('오늘의 칼로리 잔액', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          CalorieGauge(balance: balance),
          const SizedBox(height: AppSpacing.xl),
          StatRow(
            children: [
              StatColumn(label: '목표', value: '${balance.dailyGoalCalories}kcal'),
              StatColumn(label: '섭취', value: '${balance.consumedCalories}kcal'),
              StatColumn(label: '소모', value: '${balance.burnedCalories}kcal'),
            ],
          ),
        ],
      ),
    );
  }
}
