import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/food_log_service.dart';
import '../services/calories_service.dart';
import '../services/tour_service.dart';

/// Data-verification only — runs the full step 1/7/8 tour sequence
/// (start tour → arrive at a stop → log food → check balance → complete →
/// fetch report) against fixed test ids and dumps each raw response in
/// order. bak_sungsimdang / its 소보로빵 item are the known-seeded ids from
/// earlier verification passes.
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

    final tourService = TourService();
    final foodLogService = FoodLogService();
    final caloriesService = CaloriesService();

    try {
      _append('POST /tours 호출...');
      final tour = await tourService.startTour(token);
      _append('-> $tour');
      final tourId = tour['id'] as String;

      _append('\nPOST /tours/$tourId/stops 호출...');
      final stop = await tourService.addStop(
        token: token,
        tourId: tourId,
        bakeryId: 'bak_sungsimdang',
        distanceM: 1500,
        durationMinutes: 20,
        steps: 2000,
      );
      _append('-> $stop');
      final tourStopId = stop['id'] as String;

      _append('\nPOST /food-logs 호출...');
      final foodLog = await foodLogService.create(
        token: token,
        breadItemId: 'itm_bak_sungsimdang_소보로빵',
        tourStopId: tourStopId,
        quantity: 1,
      );
      _append('-> $foodLog');

      _append('\nGET /calories/balance 호출...');
      final balance = await caloriesService.getBalance(token);
      _append('-> $balance');

      _append('\nPATCH /tours/$tourId/complete 호출...');
      final completed = await tourService.completeTour(token, tourId);
      _append('-> $completed');

      _append('\nGET /tours/$tourId 호출...');
      final report = await tourService.getTour(token, tourId);
      _append('-> $report');

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
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: _running ? null : _run,
              child: Text(_running ? '실행 중...' : '투어 플로우 실행'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: SelectableText(_log.join('\n')),
            ),
          ),
        ],
      ),
    );
  }
}
