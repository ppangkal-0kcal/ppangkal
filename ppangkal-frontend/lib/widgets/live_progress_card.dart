import 'package:flutter/material.dart';

import '../controllers/tour_flow_controller.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'stat_column.dart';

/// Live in-progress stats for the current tour leg — steps/distance for
/// the leg still being walked (client-side, from [TourFlowController]'s
/// pedometer + GPS speed filter), plus calories burned so far from legs
/// already confirmed by the server (`stop.calories_burned`, never
/// recomputed client-side).
class LiveProgressCard extends StatelessWidget {
  final TourFlowController controller;

  const LiveProgressCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CalorieStatusColors>() ?? CalorieStatusColors.brand;

    final (IconData icon, Color color, String label) = controller.isInVehicle
        ? (Icons.directions_bus_outlined, colors.warning, '빠르게 이동 중 — 걸음으로 계산하지 않아요')
        : controller.isGpsTracking
            ? (Icons.gps_fixed, colors.safe, 'GPS로 걸은 거리를 측정 중이에요')
            : (Icons.gps_not_fixed, colorScheme.onSurfaceVariant, '위치를 찾는 중 — 거리는 걸음 수로 추정해요');

    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatColumn(label: '이번 구간 걸음', value: '${controller.currentLegSteps}'),
              StatColumn(label: '이번 구간 거리', value: '${controller.currentLegDistanceM}m'),
              StatColumn(label: '지금까지 소모', value: '${controller.totalConfirmedCaloriesBurned}kcal'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(label, style: textTheme.bodySmall?.copyWith(color: color))),
            ],
          ),
        ],
      ),
    );
  }
}
