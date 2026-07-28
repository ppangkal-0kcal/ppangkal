import '../core/api_client.dart';

/// GET /api/stats/* (FRONTEND_API_GUIDE.md §2 "그 외 — 통계 화면"). Auth required.
class StatsService {
  final ApiClient _client;

  StatsService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> daily(String token, {String? date}) {
    return _client.get('/stats/daily', token: token, query: {'date': ?date});
  }

  Future<Map<String, dynamic>> weekly(String token, {String? to}) {
    return _client.get('/stats/weekly', token: token, query: {'to': ?to});
  }
}
