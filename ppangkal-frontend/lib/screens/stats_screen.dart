import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../models/daily_stats.dart';
import '../models/weekly_stats.dart';
import '../providers/auth_provider.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/stat_column.dart';
import '../widgets/weekly_bar_chart.dart';

/// 통계 tab — today's breakdown (`GET /stats/daily`) plus a 7-day bar chart
/// (`GET /stats/weekly`). See `API_INTEGRATION.md` §3 for the service
/// mapping this replaces the "디자인 없음" raw-dump verification screen.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<(DailyStats, WeeklyStats)> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final token = context.read<AuthProvider>().token!;
    _future = _fetch(token);
  }

  Future<(DailyStats, WeeklyStats)> _fetch(String token) async {
    final service = StatsService();
    return (service.daily(token), service.weekly(token)).wait;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _StatsSection(future: _future, onRetry: () => setState(_load)),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final Future<(DailyStats, WeeklyStats)> future;
  final VoidCallback onRetry;

  const _StatsSection({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(DailyStats, WeeklyStats)>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return ErrorView(
            error: error is ApiException
                ? error
                : const ApiException(statusCode: 0, code: 'UNKNOWN_ERROR', message: '통계를 불러오지 못했습니다.'),
            onRetry: onRetry,
          );
        }

        final (daily, weekly) = snapshot.data!;
        final textTheme = Theme.of(context).textTheme;

        return ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('최근 7일', style: textTheme.titleMedium),
                      _AchievementBadge(rate: weekly.goalAchievementRate),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  WeeklyBarChart(stats: weekly, dailyGoalCalories: daily.goalCalories),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatColumn(label: '목표', value: '${daily.goalCalories}'),
                      StatColumn(label: '섭취', value: '${daily.consumedCalories}'),
                      StatColumn(label: '소모', value: '${daily.burnedCalories}'),
                      StatColumn(label: '방문 빵집', value: '${daily.bakeriesVisited}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final int rate;

  const _AchievementBadge({required this.rate});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CalorieStatusColors>() ?? CalorieStatusColors.brand;
    final color = rate >= 70 ? colors.safe : (rate >= 40 ? colors.warning : colors.over);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(
        '달성률 $rate%',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
