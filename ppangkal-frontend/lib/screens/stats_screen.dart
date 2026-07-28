import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/sightseeing_service.dart';
import '../services/stats_service.dart';

/// Data-verification only — standalone calls that don't depend on the tour
/// flow chain: daily/weekly stats and the TourAPI(/tour/*) proxy.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final List<String> _log = [];
  bool _running = false;

  void _append(String line) => setState(() => _log.add(line));

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

    final statsService = StatsService();
    final sightseeingService = SightseeingService();

    try {
      _append('GET /stats/daily 호출...');
      _append('-> ${await statsService.daily(token)}');

      _append('\nGET /stats/weekly 호출...');
      _append('-> ${await statsService.weekly(token)}');

      _append('\nGET /tour/nearby 호출 (성심당 좌표 기준)...');
      final nearby = await sightseeingService.nearby(token: token, lat: 36.3283, lng: 127.4291);
      _append('-> $nearby');

      final spots = nearby['spots'] as List<dynamic>;
      if (spots.isNotEmpty) {
        final firstContentId = (spots.first as Map<String, dynamic>)['content_id'].toString();
        _append('\nGET /tour/spots/$firstContentId 호출...');
        _append('-> ${await sightseeingService.spotDetail(token, firstContentId)}');
      } else {
        _append('\n(spots 결과 없어서 /tour/spots 호출 생략)');
      }

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
      appBar: AppBar(title: const Text('통계 / TourAPI 확인 (디자인 없음)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: _running ? null : _run,
              child: Text(_running ? '실행 중...' : '통계/관광지 API 실행'),
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
