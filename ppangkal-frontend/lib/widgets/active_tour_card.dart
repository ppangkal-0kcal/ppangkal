import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../core/api_exception.dart';
import '../models/tour_leg.dart';
import '../providers/auth_provider.dart';
import '../services/naver_map_launcher.dart';
import '../theme/app_theme.dart';
import 'arrival_result_card.dart';
import 'food_confirm_sheet.dart';
import 'glass_card.dart';
import 'live_progress_card.dart';
import 'stat_column.dart';

/// 홈 — the whole active tour lives here (there is no separate 투어 진행
/// screen): 빵집으로 이동 → 도착 기록 → 먹은 빵 확정 → 다음 빵집/종료.
/// Every step is one card state driven by [TourFlowController.currentLeg],
/// so leaving 홈 and coming back always resumes where the user left off.
class ActiveTourCard extends StatefulWidget {
  const ActiveTourCard({super.key});

  @override
  State<ActiveTourCard> createState() => _ActiveTourCardState();
}

class _ActiveTourCardState extends State<ActiveTourCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String fallbackMessage = '요청에 실패했습니다.'}) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fallbackMessage)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recordArrival(TourFlowController controller, String token, TourLeg leg) {
    return _run(
      () => controller.arriveAtBakery(token: token, bakeryId: leg.bakery.id),
      fallbackMessage: '도착을 기록하지 못했습니다.',
    );
  }

  Future<void> _endTour(TourFlowController controller, String token) async {
    await _run(() async {
      await controller.complete(token);
      await controller.fetchReport(token);
      if (mounted) context.push('/tour/report');
    }, fallbackMessage: '투어를 종료하지 못했습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TourFlowController>();
    final token = context.read<AuthProvider>().token!;
    final leg = controller.isStarted ? controller.currentLeg : null;

    if (leg == null) return const _IdleCard();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LegHeader(leg: leg, controller: controller),
          const Divider(height: AppSpacing.lg),
          if (leg.arrivedStop == null)
            ..._walkingSteps(controller, token, leg)
          else if (!leg.foodConfirmed)
            ..._arrivedSteps(controller, token, leg)
          else
            ..._doneSteps(controller, token, leg),
        ],
      ),
    );
  }

  /// 빵집으로 이동 중 — live sensor numbers + 도착 기록.
  List<Widget> _walkingSteps(TourFlowController controller, String token, TourLeg leg) => [
        LiveProgressCard(controller: controller),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _openMap(leg),
                icon: const Icon(Icons.directions_walk),
                label: const Text('길찾기'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _recordArrival(controller, token, leg),
                child: const Text('빵집 도착!'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _SecondaryActions(leg: leg, busy: _busy, onEnd: () => _endTour(controller, token)),
      ];

  /// 도착했고 아직 먹은 빵을 확정하지 않은 상태.
  List<Widget> _arrivedSteps(TourFlowController controller, String token, TourLeg leg) => [
        ArrivalResultCard(stop: leg.arrivedStop!),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: _busy ? null : () => showFoodConfirmSheet(context, leg: leg),
          child: const Text('먹은 빵 확정하기'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SecondaryActions(leg: leg, busy: _busy, onEnd: () => _endTour(controller, token)),
      ];

  /// 먹은 빵까지 확정 — 다음 빵집으로 가거나 투어를 끝낸다.
  List<Widget> _doneSteps(TourFlowController controller, String token, TourLeg leg) => [
        StatRow(
          children: [
            StatColumn(label: '이번 빵집 소모', value: '${leg.arrivedStop!.caloriesBurned}'),
            StatColumn(label: '이번 빵집 섭취', value: '${leg.estimatedCalories}'),
            StatColumn(label: '투어 밸런스', value: '${controller.runningBalanceKcal}'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${controller.stops.length}번째 빵집까지 마쳤어요. 더 걷고 싶다면 다음 빵집으로!',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => context.go('/bakeries'),
                child: const Text('다음 빵집 고르기'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _endTour(controller, token),
                child: const Text('투어 종료'),
              ),
            ),
          ],
        ),
      ];

  Future<void> _openMap(TourLeg leg) async {
    final opened = await NaverMapLauncher.walkTo(
      latitude: leg.bakery.latitude,
      longitude: leg.bakery.longitude,
      name: leg.bakery.name,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네이버 지도를 열 수 없습니다.')),
      );
    }
  }
}

/// Bakery, picked bread and the tour totals — shown in every active state.
class _LegHeader extends StatelessWidget {
  final TourLeg leg;
  final TourFlowController controller;

  const _LegHeader({required this.leg, required this.controller});

  String get _status {
    if (leg.foodConfirmed) return '먹은 빵 확정 완료';
    if (leg.arrivedStop != null) return '도착 · 먹은 빵 확정 전';
    return '빵집으로 이동 중';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.directions_walk, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(leg.bakery.name, style: textTheme.titleMedium),
                  Text('$_status · ${controller.stops.length}번째 빵집', style: textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('고른 빵 · 예상 ${leg.estimatedCalories}kcal', style: textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        if (leg.selections.isEmpty)
          Text('아직 고른 빵이 없어요. "빵 다시 고르기"로 골라 보세요.', style: textTheme.bodySmall),
        for (final selection in leg.selections)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${selection.name} × ${selection.quantity}${selection.isCustom ? ' (직접 입력)' : ''}',
                  style: textTheme.bodyMedium,
                ),
              ),
              Text('${selection.estimatedCalories}kcal', style: textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}

class _SecondaryActions extends StatelessWidget {
  final TourLeg leg;
  final bool busy;
  final VoidCallback onEnd;

  const _SecondaryActions({required this.leg, required this.busy, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: busy ? null : () => context.go('/bakeries/${leg.bakery.id}/menu'),
            child: const Text('빵 다시 고르기'),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: busy ? null : onEnd,
            child: const Text('투어 종료'),
          ),
        ),
      ],
    );
  }
}

class _IdleCard extends StatelessWidget {
  const _IdleCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.bakery_dining_outlined, size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('빵투어 떠나기', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text('빵집과 빵을 고르면 여기서 투어를 진행해요.', style: textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: () => context.go('/bakeries'),
            child: const Text('시작'),
          ),
        ],
      ),
    );
  }
}
