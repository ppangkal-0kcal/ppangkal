import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../core/api_exception.dart';
import '../models/tour.dart';
import '../providers/auth_provider.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/stat_column.dart';
import '../widgets/tour_balance_card.dart';

/// Tour report. Two ways in:
/// - right after 종료 (`/tour/report`) — the tour is already in
///   [TourFlowController] (`PATCH /tours/:id/complete` + `GET /tours/:id`),
///   so no refetch;
/// - from 통계's 지난 투어 list (`/tour/report/:tourId`) — fetched here with
///   `GET /tours/:id`.
///
/// All of these are frozen snapshot numbers: later food-log edits never
/// change what a completed tour reports.
class TourReportScreen extends StatefulWidget {
  /// Null means "the tour that just finished", read from the controller.
  final String? tourId;

  const TourReportScreen({super.key, this.tourId});

  @override
  State<TourReportScreen> createState() => _TourReportScreenState();
}

class _TourReportScreenState extends State<TourReportScreen> {
  Future<Tour>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.tourId != null) _load();
  }

  void _load() {
    final token = context.read<AuthProvider>().token!;
    _future = TourService().getTour(token, widget.tourId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('투어 리포트')),
      body: widget.tourId == null ? _buildLiveTour(context) : _buildFetchedTour(),
    );
  }

  Widget _buildLiveTour(BuildContext context) {
    final tour = context.watch<TourFlowController>().tour;
    return tour == null
        ? const EmptyView(message: '완료된 투어 정보가 없습니다.', icon: Icons.hiking_outlined)
        : _TourReportBody(tour: tour, showHomeButton: true);
  }

  Widget _buildFetchedTour() {
    return FutureBuilder<Tour>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return ErrorView(
            error: error is ApiException
                ? error
                : const ApiException(statusCode: 0, code: 'UNKNOWN_ERROR', message: '투어 리포트를 불러오지 못했습니다.'),
            onRetry: () => setState(_load),
          );
        }
        return _TourReportBody(tour: snapshot.data!, showHomeButton: false);
      },
    );
  }
}

class _TourReportBody extends StatelessWidget {
  final Tour tour;

  /// 종료 직후에만 보여준다 — 통계에서 들어온 지난 리포트는 뒤로가기로 돌아간다.
  final bool showHomeButton;

  const _TourReportBody({required this.tour, required this.showHomeButton});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stops = tour.stops ?? const [];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (tour.completedAt != null) ...[
          Text(_formatDate(tour.completedAt!), style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
        ],
        TourBalanceCard(title: '최종 0-kcal 밸런스', balanceKcal: tour.balanceKcal ?? 0),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          child: StatRow(
            children: [
              StatColumn(label: '총 걸음', value: '${tour.totalSteps ?? 0}'),
              StatColumn(label: '총 거리', value: '${tour.totalDistanceM ?? 0}m'),
              StatColumn(label: '총 소모', value: '${tour.totalCaloriesBurned ?? 0}kcal'),
              StatColumn(label: '총 섭취', value: '${tour.totalCaloriesConsumed ?? 0}kcal'),
            ],
          ),
        ),
        if (stops.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('방문한 빵집 ${stops.length}곳', style: textTheme.titleMedium),
                for (final stop in stops)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stop.bakeryName ?? stop.bakeryId, style: textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${stop.distanceM}m · ${stop.steps}걸음 · ${stop.caloriesBurned}kcal 소모',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (showHomeButton) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('홈으로 돌아가기'),
          ),
        ],
      ],
    );
  }

  static String _formatDate(DateTime utc) {
    final t = utc.toLocal();
    return '${t.year}년 ${t.month}월 ${t.day}일 '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} 종료';
  }
}
