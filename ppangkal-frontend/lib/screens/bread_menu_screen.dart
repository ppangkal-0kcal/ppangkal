import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exception.dart';
import '../models/bread_item.dart';
import '../models/bread_selection.dart';
import '../services/bakery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/quantity_stepper.dart';

/// Bread-menu selection for one bakery (`GET /bakeries/:id/items` —
/// FRONTEND_API_GUIDE.md §2 step 4). Quantities and the resulting
/// estimated-calorie total are purely client-side — the backend never
/// stores a preview selection, only a confirmed `POST /food-logs` later
/// (out of scope here; see [BreadSelection] for the hand-off shape).
class BreadMenuScreen extends StatefulWidget {
  final String bakeryId;

  const BreadMenuScreen({super.key, required this.bakeryId});

  @override
  State<BreadMenuScreen> createState() => _BreadMenuScreenState();
}

class _BreadMenuScreenState extends State<BreadMenuScreen> {
  late Future<List<BreadItem>> _future;
  final Map<String, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = BakeryService().fetchItems(widget.bakeryId);
  }

  List<BreadSelection> _selections(List<BreadItem> items) {
    return items
        .where((item) => (_quantities[item.id] ?? 0) > 0)
        .map((item) => BreadSelection(item: item, quantity: _quantities[item.id]!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('빵 메뉴 선택')),
      body: FutureBuilder<List<BreadItem>>(
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
                  : const ApiException(
                      statusCode: 0,
                      code: 'UNKNOWN_ERROR',
                      message: '메뉴를 불러오지 못했습니다.',
                    ),
              onRetry: () => setState(_load),
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const EmptyView(message: '등록된 빵 메뉴가 없습니다.', icon: Icons.bakery_dining_outlined);
          }

          final selections = _selections(items);
          final totalCalories = selections.fold<int>(0, (sum, s) => sum + s.estimatedCalories);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _BreadItemRow(
                    item: items[i],
                    quantity: _quantities[items[i].id] ?? 0,
                    onChanged: (q) => setState(() => _quantities[items[i].id] = q),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    if (selections.isNotEmpty) ...[
                      GlassCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('예상 섭취 칼로리', style: Theme.of(context).textTheme.titleMedium),
                            Text('$totalCalories kcal', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    FilledButton(
                      onPressed: () => context.push(
                        '/tour/progress/${widget.bakeryId}',
                        extra: selections,
                      ),
                      child: const Text('투어 진행하기'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BreadItemRow extends StatelessWidget {
  final BreadItem item;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _BreadItemRow({required this.item, required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final estimatedCalories = item.calories * quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${item.price}원 · ${item.calories}kcal', style: textTheme.bodySmall),
                  if (quantity > 0)
                    Text('선택 시 ${estimatedCalories}kcal', style: textTheme.bodySmall),
                ],
              ),
            ),
            QuantityStepper(quantity: quantity, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
