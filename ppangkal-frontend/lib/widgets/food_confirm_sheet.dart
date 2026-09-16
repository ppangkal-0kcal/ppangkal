import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/tour_flow_controller.dart';
import '../core/api_exception.dart';
import '../models/tour_leg.dart';
import '../providers/auth_provider.dart';
import '../services/food_photo_service.dart';
import '../theme/app_theme.dart';

/// 먹은 빵 확정 (`POST /food-logs` per selection — FRONTEND_API_GUIDE.md §2
/// step 7), opened from the 홈 tour card. It closes on success; the card
/// then shows the confirmed state, so this sheet never navigates anywhere.
Future<void> showFoodConfirmSheet(BuildContext context, {required TourLeg leg}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _FoodConfirmSheet(leg: leg),
  );
}

class _FoodConfirmSheet extends StatefulWidget {
  final TourLeg leg;

  const _FoodConfirmSheet({required this.leg});

  @override
  State<_FoodConfirmSheet> createState() => _FoodConfirmSheetState();
}

class _FoodConfirmSheetState extends State<_FoodConfirmSheet> {
  bool _busy = false;
  bool _photoSaved = false;
  String? _errorMessage;

  Future<void> _takePhoto() async {
    final result = await FoodPhotoService().captureAndSave();
    if (!mounted || result == FoodPhotoResult.cancelled) return;
    final saved = result == FoodPhotoResult.saved;
    if (saved) setState(() => _photoSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? '갤러리의 빵칼 앨범에 저장했어요.' : '사진을 저장하지 못했습니다.')),
    );
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final controller = context.read<TourFlowController>();
    final token = context.read<AuthProvider>().token!;
    try {
      await controller.confirmFood(token: token, selections: widget.leg.selections);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먹은 빵을 기록했어요.')),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selections = widget.leg.selections;
    final total = widget.leg.estimatedCalories;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${widget.leg.bakery.name}에서 먹은 빵', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (selections.isEmpty)
            Text('고른 빵이 없어요. 시트를 닫고 "빵 다시 고르기"로 골라 주세요.', style: textTheme.bodyMedium),
          for (final selection in selections)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${selection.name} × ${selection.quantity}${selection.isCustom ? ' (직접 입력)' : ''}',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  Text('${selection.estimatedCalories}kcal', style: textTheme.bodyMedium),
                ],
              ),
            ),
          const Divider(height: AppSpacing.lg),
          Text('총 예상 섭취 $total kcal', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (!kIsWeb) ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : _takePhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(_photoSaved ? '사진 한 장 더 찍기' : '빵 사진 남기기 (갤러리에만 저장)'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (_errorMessage != null) ...[
            Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: AppSpacing.sm),
          ],
          FilledButton(
            onPressed: _busy || selections.isEmpty ? null : _confirm,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('이대로 확정하기'),
          ),
        ],
      ),
    );
  }
}
