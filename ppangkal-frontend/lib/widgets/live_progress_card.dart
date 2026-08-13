import 'package:flutter/material.dart';

import '../controllers/tour_flow_controller.dart';
import 'glass_card.dart';
import 'stat_column.dart';

/// Live in-progress stats for the current tour leg — steps/distance for
/// the leg still being walked (client-side, from [TourFlowController]'s
/// `StepCounter`), plus calories burned so far from legs already
/// confirmed by the server (`stop.calories_burned`, never recomputed
/// client-side).
class LiveProgressCard extends StatelessWidget {
  final TourFlowController controller;

  const LiveProgressCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatColumn(label: '이번 구간 걸음', value: '${controller.currentLegSteps}'),
          StatColumn(label: '이번 구간 거리', value: '${controller.currentLegDistanceM}m'),
          StatColumn(label: '지금까지 소모', value: '${controller.totalConfirmedCaloriesBurned}kcal'),
        ],
      ),
    );
  }
}
