import '../core/api_client.dart';
import '../models/daily_stats.dart';
import '../models/weekly_stats.dart';

/// GET /api/stats/* (FRONTEND_API_GUIDE.md §2 "그 외 — 통계 화면"). Auth required.
class StatsService {
  final ApiClient _client;

  StatsService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<DailyStats> daily(String token, {String? date}) async {
    final json = await _client.get('/stats/daily', token: token, query: {'date': ?date});
    return DailyStats.fromJson(json);
  }

  Future<WeeklyStats> weekly(String token, {String? to}) async {
    final json = await _client.get('/stats/weekly', token: token, query: {'to': ?to});
    return WeeklyStats.fromJson(json);
  }
}
