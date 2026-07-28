import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Data-verification only — drives [TourFlowController] through the full
/// step 1/7/8 tour sequence (start → arrive at a stop → log food → check
/// balance → complete → fetch report) against fixed test ids and dumps
/// each step's key fields in order. bak_sungsimdang / its 소보로빵 item are
/// the known-seeded ids from earlier verification passes.
///
/// Doubles as a live check that [TourFlowController] itself sequences
/// calls correctly, since this screen no longer threads `tour_id`/
/// `tour_stop_id` by hand — the controller does.
class TourFlowScreen extends StatefulWidget {
  const TourFlowScreen({super.key});

  @override
  State<TourFlowScreen> createState() => _TourFlowScreenState();
}

class _TourFlowScreenState extends State<TourFlowScreen> {
  final List<String> _log = [];
  bool _running = false;

  void _append(String line) {
    setState(() => _log.add(line));
  }

  Future<void> _run() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      _append('에러: 로그인 토큰이 없습니다.');
      return;
    }

    setState(() {
      _running = true;
      _log.clear();
    });

    final controller = TourFlowController();

    try {
      _append('POST /tours 호출...');
      final tour = await controller.startTour(token);
      _append('-> id=${tour.id} started_at=${tour.startedAt}');

      _append('\nPOST /tours/${tour.id}/stops 호출...');
      final stop = await controller.arriveAtBakery(
        token: token,
        bakeryId: 'bak_sungsimdang',
        distanceM: 1500,
        durationMinutes: 20,
        steps: 2000,
      );
      final walk = stop.suggestedWalk;
      _append(
        '-> id=${stop.id} calories_burned=${stop.caloriesBurned} '
        'suggested_walk=${walk == null ? null : '${walk.title} ${walk.roundTripDistanceM}m ${walk.estimatedCaloriesBurned}kcal'}',
      );

      _append('\nPOST /food-logs 호출...');
      final foodLog = await controller.logFood(
        token: token,
        breadItemId: 'itm_bak_sungsimdang_소보로빵',
        quantity: 1,
      );
      _append('-> id=${foodLog.id} calories=${foodLog.calories} quantity=${foodLog.quantity}');

      _append('\nGET /calories/balance 호출...');
      final balance = await controller.checkBalance(token);
      _append('-> remaining_calories=${balance.remainingCalories} status=${balance.status}');

      _append('\nPATCH /tours/${tour.id}/complete 호출...');
      final completed = await controller.complete(token);
      _append(
        '-> total_steps=${completed.totalSteps} '
        'total_calories_burned=${completed.totalCaloriesBurned} '
        'balance_kcal=${completed.balanceKcal}',
      );

      _append('\nGET /tours/${tour.id} 호출...');
      final report = await controller.fetchReport(token);
      _append('-> stops=${report.stops?.length} balance_kcal=${report.balanceKcal}');

      _append('\n=== 완료 ===');
    } catch (e) {
      _append('\n에러: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('투어 플로우 확인 (디자인 없음)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: ElevatedButton(
              onPressed: _running ? null : _run,
              child: Text(_running ? '실행 중...' : '투어 플로우 실행'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: SelectableText(_log.join('\n')),
            ),
          ),
        ],
      ),
    );
  }
}
