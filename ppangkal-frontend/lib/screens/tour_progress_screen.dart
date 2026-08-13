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
import '../theme/app_theme.dart';
import '../widgets/arrival_result_card.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/live_progress_card.dart';
import '../widgets/loading_view.dart';

/// Active-tour screen for one bakery leg. Starts the tour if needed
/// (`POST /tours`), shows live steps/distance while walking, then records
/// arrival (`POST /tours/:tourId/stops`) and the resulting park-walk
/// suggestion. Map/real-time route display is out of scope (4단계) — see
/// the placeholder card below.
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
              const _RouteMapPlaceholder(),
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

class _RouteMapPlaceholder extends StatelessWidget {
  const _RouteMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: SizedBox(
        height: 120,
        child: Center(
          child: Text(
            '실시간 경로 지도는 4단계에서 제공됩니다.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
