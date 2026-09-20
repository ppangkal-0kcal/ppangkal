import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../core/api_exception.dart';
import '../models/daily_stats.dart';
import '../models/tour_leg.dart';
import '../models/tour_summary.dart';
import '../models/weekly_stats.dart';
import '../providers/auth_provider.dart';
import '../services/stats_service.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/expandable_tile.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/page_title.dart';
import '../widgets/stat_column.dart';
import '../widgets/tour_history_card.dart';
import '../widgets/weekly_bar_chart.dart';

/// 통계 tab — today's breakdown (`GET /stats/daily`), a 7-day bar chart
/// (`GET /stats/weekly`), and the finished-tour reports (`GET /tours`).
/// See `API_INTEGRATION.md` §3 for the service mapping.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<(DailyStats, WeeklyStats, List<TourSummary>)> _future;
  int? _loadedRevision;

  /// Refetch after a stop/food log/tour completion — this tab stays alive
  /// in the shell's IndexedStack, so loading once in initState would show
  /// stale data. `select` is build-only in provider, hence checked here.
  void _reloadIfStale(BuildContext context) {
    final revision = context.select<TourFlowController, int>((c) => c.dataRevision);
    if (revision != _loadedRevision) {
      _loadedRevision = revision;
      _load();
    }
  }

  void _load() {
    final token = context.read<AuthProvider>().token!;
    _future = _fetch(token);
  }

  Future<(DailyStats, WeeklyStats, List<TourSummary>)> _fetch(String token) async {
    final service = StatsService();
    return (service.daily(token), service.weekly(token), TourService().fetchHistory(token)).wait;
  }

  @override
  Widget build(BuildContext context) {
    _reloadIfStale(context);
    return Scaffold(
      appBar: PageAppBar('통계'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
        child: _StatsSection(future: _future, onRetry: () => setState(_load)),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final Future<(DailyStats, WeeklyStats, List<TourSummary>)> future;
  final VoidCallback onRetry;

  const _StatsSection({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(DailyStats, WeeklyStats, List<TourSummary>)>(
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

        final (daily, weekly, tours) = snapshot.data!;
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
                      Text(
                        '최근 7일',
                        style: textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
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
                  Text('오늘', style: textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),),
                  const SizedBox(height: AppSpacing.lg),
                  StatRow(
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
            const SizedBox(height: AppSpacing.md),
            _TodayBreadCard(visits: daily.visits),
            const SizedBox(height: AppSpacing.md),
            TourHistoryCard(tours: tours),
          ],
        );
      },
    );
  }
}

/// 오늘 고른 빵집과 빵 — confirmed visits from `/stats/daily` plus the current
/// leg's pick if its bread isn't confirmed yet (client-only until then).
class _TodayBreadCard extends StatelessWidget {
  final List<DailyVisit> visits;

  const _TodayBreadCard({required this.visits});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final leg = context.select<TourFlowController, TourLeg?>((c) => c.isStarted ? c.currentLeg : null);
    final pendingLeg = leg != null && !leg.foodConfirmed ? leg : null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('오늘 고른 빵집과 빵', style: textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),),
          const SizedBox(height: AppSpacing.md),
          if (visits.isEmpty && pendingLeg == null)
            Text('아직 기록이 없어요. 빵투어를 떠나 보세요!', style: textTheme.bodySmall),
          for (final visit in visits)
            _VisitBlock(
              bakeryName: visit.bakeryName,
              caption: '${_hhmm(visit.visitedAt)} 도착 · ${visit.caloriesBurned}kcal 소모',
              lines: [for (final b in visit.breads) (name: b.name, quantity: b.quantity, kcal: b.calories)],
              emptyText: '먹은 빵 기록 없음',
            ),
          if (pendingLeg != null)
            _VisitBlock(
              bakeryName: pendingLeg.bakery.name,
              caption: pendingLeg.arrivedStop == null ? '이동 중 · 아직 먹기 전' : '도착 · 먹은 빵 확정 전',
              lines: [
                for (final s in pendingLeg.selections)
                  (name: s.name, quantity: s.quantity, kcal: s.estimatedCalories),
              ],
              emptyText: '고른 빵 없음',
              initiallyExpanded: true,
            ),
        ],
      ),
    );
  }

  static String _hhmm(DateTime utc) {
    final t = utc.toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

/// 빵집 한 곳의 방문 기록. 접으면 "어디서 몇 kcal"만, 펼치면 먹은 빵 목록까지 —
/// 하루에 여러 곳을 돌면 카드가 계속 길어져서 기본은 접힌 상태로 둔다.
class _VisitBlock extends StatelessWidget {
  final String bakeryName;
  final String caption;
  final List<({String name, int quantity, int kcal})> lines;
  final String emptyText;

  /// 아직 확정 전인 현재 구간은 지금 뭘 골랐는지가 바로 보여야 해서 펼쳐서 시작한다.
  final bool initiallyExpanded;

  const _VisitBlock({
    required this.bakeryName,
    required this.caption,
    required this.lines,
    required this.emptyText,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = lines.fold<int>(0, (sum, l) => sum + l.kcal);

    return ExpandableTile(
      title: bakeryName,
      subtitle: lines.isEmpty ? caption : '$caption · 빵 ${lines.length}종',
      initiallyExpanded: initiallyExpanded,
      trailing: lines.isEmpty ? null : Text('${total}kcal', style: textTheme.titleSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lines.isEmpty) Text(emptyText, style: textTheme.bodySmall),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(child: Text('${line.name} × ${line.quantity}', style: textTheme.bodyMedium)),
                  Text('${line.kcal}kcal', style: textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
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
