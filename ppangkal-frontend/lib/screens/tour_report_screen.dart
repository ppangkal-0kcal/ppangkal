import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_column.dart';
import '../widgets/tour_balance_card.dart';

/// Tour-end report. `FoodConfirmScreen` calls `PATCH /tours/:id/complete`
/// then `GET /tours/:id` before navigating here — the PATCH response alone
/// omits `started_at`/`stops` (backend/src/routes/tours.routes.ts), so the
/// follow-up GET is what fills in the per-bakery breakdown below. All of
/// these are frozen snapshot numbers: later food-log edits never change
/// what a completed tour reports.
class TourReportScreen extends StatelessWidget {
  const TourReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tour = context.watch<TourFlowController>().tour;

    return Scaffold(
      appBar: AppBar(title: const Text('투어 리포트')),
      body: tour == null
          ? const EmptyView(message: '완료된 투어 정보가 없습니다.', icon: Icons.hiking_outlined)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                TourBalanceCard(title: '최종 0-kcal 밸런스', balanceKcal: tour.balanceKcal ?? 0),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StatColumn(label: '총 걸음', value: '${tour.totalSteps ?? 0}'),
                      StatColumn(label: '총 거리', value: '${tour.totalDistanceM ?? 0}m'),
                      StatColumn(label: '총 소모', value: '${tour.totalCaloriesBurned ?? 0}kcal'),
                      StatColumn(label: '총 섭취', value: '${tour.totalCaloriesConsumed ?? 0}kcal'),
                    ],
                  ),
                ),
                if (tour.stops != null && tour.stops!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('방문한 빵집', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        for (final stop in tour.stops!)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                            child: Text(
                              '${stop.bakeryName ?? stop.bakeryId} · ${stop.distanceM}m · '
                              '${stop.steps}걸음 · ${stop.caloriesBurned}kcal',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('홈으로 돌아가기'),
                ),
              ],
            ),
    );
  }
}
