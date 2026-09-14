import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../core/api_exception.dart';
import '../models/calorie_balance.dart';
import '../providers/auth_provider.dart';
import '../services/calories_service.dart';
import '../theme/app_theme.dart';
import '../widgets/calorie_balance_card.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_view.dart';

/// Home tab. Shows today's calorie balance from `GET /calories/balance`
/// (FRONTEND_API_GUIDE.md §2 step 7) — only fields that endpoint actually
/// returns; see `lib/widgets/calorie_balance_card.dart` for the status
/// mapping — plus the entry point into (or back into) a bakery tour.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<CalorieBalance> _future;
  int? _loadedRevision;

  void _load() {
    final token = context.read<AuthProvider>().token!;
    _future = CaloriesService().getBalance(token);
  }

  /// Same stale-tab refetch as the 통계 tab — see `StatsScreen`.
  void _reloadIfStale(BuildContext context) {
    final revision = context.select<TourFlowController, int>((c) => c.dataRevision);
    if (revision != _loadedRevision) {
      _loadedRevision = revision;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    _reloadIfStale(context);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('빵칼'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              tooltip: '디버그',
              onPressed: () => context.push('/debug'),
            ),
        ],
      ),
      body: user == null
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: () async {
                setState(_load);
                try {
                  await _future;
                } catch (_) {
                  // ErrorView below already renders the failure.
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text('안녕하세요, ${user.name}님', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '오늘도 걷고, 맛있게 먹고, 0kcal 맞춰봐요.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _BalanceSection(future: _future, onRetry: () => setState(_load)),
                  const SizedBox(height: AppSpacing.md),
                  const _TourEntryCard(),
                ],
              ),
            ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  final Future<CalorieBalance> future;
  final VoidCallback onRetry;

  const _BalanceSection({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CalorieBalance>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(height: 320, child: LoadingView());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return ErrorView(
            error: error is ApiException
                ? error
                : const ApiException(
                    statusCode: 0,
                    code: 'UNKNOWN_ERROR',
                    message: '칼로리 정보를 불러오지 못했습니다.',
                  ),
            onRetry: onRetry,
          );
        }
        return CalorieBalanceCard(balance: snapshot.data!);
      },
    );
  }
}

/// Starts a new tour, or resumes the one in progress — tours begin from a
/// bakery pick (list → detail → menu → 투어 진행), so both lead to the
/// 빵집 tab.
class _TourEntryCard extends StatelessWidget {
  const _TourEntryCard();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TourFlowController>();
    final textTheme = Theme.of(context).textTheme;
    final active = controller.isStarted;

    return GlassCard(
      child: Row(
        children: [
          Icon(
            active ? Icons.directions_walk : Icons.bakery_dining_outlined,
            size: 36,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(active ? '빵투어 진행 중' : '빵투어 떠나기', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  active
                      ? '${controller.stops.length}곳 방문 · 밸런스 ${controller.runningBalanceKcal}kcal'
                      : '주변 빵집을 고르고 걸어서 칼로리를 채워요.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: () => context.go('/bakeries'),
            child: Text(active ? '이어가기' : '시작'),
          ),
        ],
      ),
    );
  }
}
