import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../core/api_exception.dart';
import '../core/formatters.dart';
import '../models/bakery.dart';
import '../models/bread_item.dart';
import '../models/bread_selection.dart';
import '../providers/auth_provider.dart';
import '../services/bakery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bread_detail_sheet.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/network_photo.dart';
import '../widgets/quantity_stepper.dart';

/// Bread-menu selection for one bakery (`GET /bakeries/:id/items` —
/// FRONTEND_API_GUIDE.md §2 step 4). Quantities and the estimated-calorie
/// total are client-side only; the pick is handed to
/// [TourFlowController.startLeg] and the tour then runs on 홈.
///
/// Bread the bakery's menu doesn't list can be typed in by the user (name +
/// calories). Those never reach `bread_items` — they're written to that
/// user's own food log at 확정 time (`custom_name`/`custom_calories`).
class BreadMenuScreen extends StatefulWidget {
  final String bakeryId;

  const BreadMenuScreen({super.key, required this.bakeryId});

  @override
  State<BreadMenuScreen> createState() => _BreadMenuScreenState();
}

class _BreadMenuScreenState extends State<BreadMenuScreen> {
  late Future<(Bakery, List<BreadItem>)> _future;
  final Map<String, int> _quantities = {};
  final List<BreadSelection> _customSelections = [];
  String? _category; // null = 전체
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final service = BakeryService();
    _future = Future.wait([
      service.fetchDetail(widget.bakeryId),
      service.fetchItems(widget.bakeryId),
    ]).then((results) => (results[0] as Bakery, results[1] as List<BreadItem>));
  }

  List<BreadSelection> _selections(List<BreadItem> items) => [
        for (final item in items)
          if ((_quantities[item.id] ?? 0) > 0)
            BreadSelection.fromItem(item: item, quantity: _quantities[item.id]!),
        ..._customSelections,
      ];

  Future<void> _startTour(Bakery bakery, List<BreadSelection> selections) async {
    setState(() => _busy = true);
    final controller = context.read<TourFlowController>();
    final token = context.read<AuthProvider>().token!;
    try {
      await controller.startLeg(token: token, bakery: bakery, selections: selections);
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addCustomBread() async {
    final selection = await showDialog<BreadSelection>(
      context: context,
      builder: (dialogContext) => const _CustomBreadDialog(),
    );
    if (selection != null) setState(() => _customSelections.add(selection));
  }

  @override
  Widget build(BuildContext context) {
    final isTouring = context.select<TourFlowController, bool>((c) => c.isStarted);

    return Scaffold(
      appBar: AppBar(title: const Text('빵 메뉴 선택')),
      body: FutureBuilder<(Bakery, List<BreadItem>)>(
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
          final (bakery, items) = snapshot.data!;

          final selections = _selections(items);
          final totalCalories = selections.fold<int>(0, (sum, s) => sum + s.estimatedCalories);
          final categories = items.map((i) => i.category).whereType<String>().toSet().toList()..sort();
          final visible = _category == null ? items : items.where((i) => i.category == _category).toList();

          return Column(
            children: [
              if (categories.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      for (final category in [null, ...categories])
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(category == null
                                ? '전체 ${items.length}'
                                : '$category ${items.where((i) => i.category == category).length}'),
                            selected: _category == category,
                            onSelected: (_) => setState(() => _category = category),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: EmptyView(
                          message: '등록된 빵 메뉴가 없어요. 아래에서 직접 추가할 수 있어요.',
                          icon: Icons.bakery_dining_outlined,
                        ),
                      ),
                    for (final item in visible)
                      _BreadItemRow(
                        item: item,
                        quantity: _quantities[item.id] ?? 0,
                        onChanged: (q) => setState(() => _quantities[item.id] = q),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    _CustomBreadCard(
                      selections: _customSelections,
                      onAdd: _addCustomBread,
                      onRemove: (i) => setState(() => _customSelections.removeAt(i)),
                      onQuantityChanged: (i, q) => setState(() {
                        if (q <= 0) {
                          _customSelections.removeAt(i);
                        } else {
                          _customSelections[i] = _customSelections[i].copyWith(quantity: q);
                        }
                      }),
                    ),
                  ],
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
                      onPressed: _busy || selections.isEmpty ? null : () => _startTour(bakery, selections),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: Text(
                        selections.isEmpty
                            ? '빵을 골라 주세요'
                            : isTouring
                                ? '이 빵집으로 이어서 투어하기'
                                : '이 빵으로 투어 시작하기',
                      ),
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
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => showBreadDetailSheet(context, item),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    NetworkPhoto(url: item.imageUrl, width: 64, height: 64),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: textTheme.titleSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text('${formatThousands(item.price)}원', style: textTheme.bodySmall),
                          CalorieLine(item: item, style: textTheme.bodySmall),
                          if (quantity > 0)
                            Text('선택 시 ${estimatedCalories}kcal', style: textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            QuantityStepper(quantity: quantity, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// 메뉴에 없는 빵을 직접 입력해 담아두는 칸.
class _CustomBreadCard extends StatelessWidget {
  final List<BreadSelection> selections;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, int quantity) onQuantityChanged;

  const _CustomBreadCard({
    required this.selections,
    required this.onAdd,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('메뉴에 없는 빵', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('이름과 칼로리를 직접 입력하면 내 기록에만 저장돼요.', style: textTheme.bodySmall),
          for (final (index, selection) in selections.indexed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selection.name, style: textTheme.titleSmall),
                        Text('1개 ${selection.unitCalories}kcal · 합계 ${selection.estimatedCalories}kcal',
                            style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  QuantityStepper(
                    quantity: selection.quantity,
                    onChanged: (q) => onQuantityChanged(index, q),
                  ),
                  IconButton(
                    tooltip: '삭제',
                    icon: const Icon(Icons.close),
                    onPressed: () => onRemove(index),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('빵 직접 추가하기'),
          ),
        ],
      ),
    );
  }
}

class _CustomBreadDialog extends StatefulWidget {
  const _CustomBreadDialog();

  @override
  State<_CustomBreadDialog> createState() => _CustomBreadDialogState();
}

class _CustomBreadDialogState extends State<_CustomBreadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      BreadSelection(
        name: _nameController.text.trim(),
        unitCalories: int.parse(_caloriesController.text),
        quantity: _quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('빵 직접 추가'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              maxLength: 50,
              decoration: const InputDecoration(labelText: '빵 이름'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '빵 이름을 입력하세요' : null,
            ),
            TextFormField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '1개당 칼로리', suffixText: 'kcal'),
              validator: (v) {
                final kcal = int.tryParse(v ?? '');
                if (kcal == null) return '숫자를 입력하세요';
                if (kcal < 0 || kcal > 5000) return '0~5000 사이로 입력하세요';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('개수'),
                QuantityStepper(
                  quantity: _quantity,
                  onChanged: (q) => setState(() => _quantity = q < 1 ? 1 : q),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
        FilledButton(onPressed: _submit, child: const Text('추가')),
      ],
    );
  }
}
