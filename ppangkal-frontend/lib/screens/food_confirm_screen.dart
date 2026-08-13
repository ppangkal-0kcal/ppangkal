import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../core/api_exception.dart';
import '../models/bread_selection.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/tour_balance_card.dart';

/// Confirms the bread actually eaten at the just-arrived stop
/// (`POST /food-logs`, once per selected item — FRONTEND_API_GUIDE.md §2
/// step 7) and shows the running tour balance afterward. [selections] came
/// from the bread-menu screen's client-only preview; nothing here was
/// saved until this screen's confirm button is pressed. [tourStopId] isn't
/// used directly (the controller already knows the latest stop — see
/// `TourFlowController.logFood`); it's kept in the route for URL clarity
/// and asserted against the controller's own state as a sanity check.
class FoodConfirmScreen extends StatefulWidget {
  final String tourStopId;
  final List<BreadSelection> selections;

  const FoodConfirmScreen({super.key, required this.tourStopId, required this.selections});

  @override
  State<FoodConfirmScreen> createState() => _FoodConfirmScreenState();
}

class _FoodConfirmScreenState extends State<FoodConfirmScreen> {
  bool _confirmed = false;
  bool _busy = false;
  String? _errorMessage;

  Future<void> _confirm(TourFlowController controller, String token) async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      for (final selection in widget.selections) {
        await controller.logFood(
          token: token,
          breadItemId: selection.item.id,
          quantity: selection.quantity,
        );
      }
      setState(() => _confirmed = true);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _endTour(TourFlowController controller, String token) async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await controller.complete(token);
      await controller.fetchReport(token);
      if (!mounted) return;
      context.go('/tour/report');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      context.read<TourFlowController>().stops.isEmpty ||
          context.read<TourFlowController>().stops.last.id == widget.tourStopId,
      'FoodConfirmScreen은 방금 기록된 stop 바로 다음에만 진입해야 합니다.',
    );

    final controller = context.watch<TourFlowController>();
    final token = context.read<AuthProvider>().token!;
    final totalCalories = widget.selections.fold<int>(0, (sum, s) => sum + s.estimatedCalories);

    return Scaffold(
      appBar: AppBar(title: const Text('섭취 확정')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('먹은 빵', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                if (widget.selections.isEmpty) const Text('선택한 빵이 없습니다.'),
                for (final selection in widget.selections)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(
                      '${selection.item.name} × ${selection.quantity} · ${selection.estimatedCalories}kcal',
                    ),
                  ),
                const Divider(height: AppSpacing.lg),
                Text('총 예상 섭취 칼로리: $totalCalories kcal', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_errorMessage != null) ...[
            Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (!_confirmed)
            FilledButton(
              onPressed: _busy ? null : () => _confirm(controller, token),
              child: const Text('먹은 빵 확정하기'),
            )
          else ...[
            TourBalanceCard(title: '지금까지 0-kcal 밸런스', balanceKcal: controller.runningBalanceKcal),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => context.go('/bakeries'),
                    child: const Text('다음 빵집으로'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _endTour(controller, token),
                    child: const Text('투어 종료'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
