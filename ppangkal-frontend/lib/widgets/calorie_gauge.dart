import 'package:flutter/material.dart';

import '../models/calorie_balance.dart';
import '../theme/app_theme.dart';

/// Circular calorie gauge — thick-stroke ring with the remaining-calorie
/// count centered, plus a pill-shaped status message below. Replaces the
/// earlier horizontal [CalorieProgressBar] per the 2026-09 design guide
/// (원형 게이지 + 하단 알약 뱃지). Same status→color mapping as
/// [CalorieBalanceCard] — `safe`/`warning`/`over` from [CalorieStatusColors].
class CalorieGauge extends StatelessWidget {
  final CalorieBalance balance;
  final double size;

  const CalorieGauge({super.key, required this.balance, this.size = 176});

  static const double _strokeWidth = 14;

  Color _statusColor(BuildContext context) {
    final colors = Theme.of(context).extension<CalorieStatusColors>() ?? CalorieStatusColors.brand;
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

  String get _statusMessage => switch (balance.status) {
        'green' => '오늘 페이스가 좋아요',
        'yellow' => '칼로리 잔액이 얼마 안 남았어요',
        'red' => '오늘 목표를 넘었어요',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final goal = balance.dailyGoalCalories;
    final ratio = goal > 0 ? (balance.consumedCalories / goal).clamp(0.0, 1.0) : 1.0;
    final trackColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    final fillColor = _statusColor(context);
    final textTheme = Theme.of(context).textTheme;

    final remaining = balance.remainingCalories;
    final isOver = remaining < 0;

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: _strokeWidth,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation(trackColor),
                ),
              ),
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: _strokeWidth,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation(fillColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${isOver ? -remaining : remaining}',
                    style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(isOver ? 'kcal 초과' : 'kcal 남음', style: textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: fillColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$_statusLabel · $_statusMessage',
            style: textTheme.labelLarge?.copyWith(color: fillColor, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
