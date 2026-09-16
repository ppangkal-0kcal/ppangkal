import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../core/api_exception.dart';
import '../models/bakery.dart';
import '../models/calorie_balance.dart';
import '../providers/auth_provider.dart';
import '../services/calories_service.dart';
import '../theme/app_theme.dart';
import '../widgets/active_tour_card.dart';
import '../widgets/calorie_balance_card.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/nearby_spots_section.dart';

/// Home tab. Today's calorie balance from `GET /calories/balance`
/// (FRONTEND_API_GUIDE.md §2 step 7), the active tour itself
/// ([ActiveTourCard] — 이동/도착/섭취 확정/다음 빵집이 전부 여기서 끝난다),
/// and the picked bakery's nearby TourAPI spots.
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
    final pickedBakery = context.select<TourFlowController, Bakery?>((c) => c.currentLeg?.bakery);

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
                  const ActiveTourCard(),
                  // 빵집을 고르기 전에는 주변 관광지를 보여주지 않는다.
                  if (pickedBakery != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    NearbySpotsSection(bakery: pickedBakery),
                  ],
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
