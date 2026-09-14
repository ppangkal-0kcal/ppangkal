import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../core/api_exception.dart';
import '../models/bakery.dart';
import '../models/bread_selection.dart';
import '../models/tour_stop.dart';
import '../providers/auth_provider.dart';
import '../services/bakery_service.dart';
import '../services/naver_map_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/arrival_result_card.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/live_progress_card.dart';
import '../widgets/loading_view.dart';

/// Active-tour screen for one bakery leg. Starts the tour if needed
/// (`POST /tours`), shows live steps/distance while walking, then records
/// arrival (`POST /tours/:tourId/stops`) and the resulting park-walk
/// suggestion. Directions are handed off to the Naver Map app
/// ([_NavigationCard]); there is no in-app map.
class TourProgressScreen extends StatefulWidget {
  final String bakeryId;
  final List<BreadSelection> selections;

  const TourProgressScreen({super.key, required this.bakeryId, required this.selections});

  @override
  State<TourProgressScreen> createState() => _TourProgressScreenState();
}

class _TourProgressScreenState extends State<TourProgressScreen> {
  late Future<Bakery> _bakeryFuture;
  TourStop? _arrivedStop;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bakeryFuture = BakeryService().fetchDetail(widget.bakeryId);
  }

  Future<void> _startTour(TourFlowController controller, String token) async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await controller.startTour(token);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _recordArrival(TourFlowController controller, String token) async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final stop = await controller.arriveAtBakery(token: token, bakeryId: widget.bakeryId);
      setState(() => _arrivedStop = stop);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TourFlowController>();
    final token = context.read<AuthProvider>().token!;

    return Scaffold(
      appBar: AppBar(title: const Text('투어 진행')),
      body: FutureBuilder<Bakery>(
        future: _bakeryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              error: const ApiException(
                statusCode: 0,
                code: 'UNKNOWN_ERROR',
                message: '빵집 정보를 불러오지 못했습니다.',
              ),
              onRetry: () => setState(() {
                _bakeryFuture = BakeryService().fetchDetail(widget.bakeryId);
              }),
            );
          }
          final bakery = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bakery.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(bakery.address, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _NavigationCard(bakery: bakery),
              const SizedBox(height: AppSpacing.md),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (!controller.isStarted)
                FilledButton(
                  onPressed: _busy ? null : () => _startTour(controller, token),
                  child: const Text('투어 시작'),
                )
              else if (_arrivedStop == null) ...[
                LiveProgressCard(controller: controller),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _busy ? null : () => _recordArrival(controller, token),
                  child: const Text('도착 기록'),
                ),
              ] else ...[
                ArrivalResultCard(stop: _arrivedStop!),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => context.push(
                    '/tour/confirm/${_arrivedStop!.id}',
                    extra: widget.selections,
                  ),
                  child: const Text('먹은 빵 확정하기'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Step 5 handoff — directions live in the Naver Map app, not in-app
/// (no map SDK by design, see `NaverMapLauncher`).
class _NavigationCard extends StatelessWidget {
  final Bakery bakery;

  const _NavigationCard({required this.bakery});

  Future<void> _open(BuildContext context) async {
    final opened = await NaverMapLauncher.walkTo(
      latitude: bakery.latitude,
      longitude: bakery.longitude,
      name: bakery.name,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네이버 지도를 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.directions_walk, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('걸어서 가는 길은 네이버 지도에서 안내해 드려요.', style: textTheme.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: () => _open(context),
            child: const Text('길찾기'),
          ),
        ],
      ),
    );
  }
}
