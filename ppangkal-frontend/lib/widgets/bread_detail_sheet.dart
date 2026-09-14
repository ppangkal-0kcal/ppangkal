import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/walk_calories.dart';
import '../models/bread_item.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'network_photo.dart';

/// Full info for one bread: large photo, price, calories (flagged when
/// estimated), macros when known, and the "0-kcal" hook — how long a walk
/// cancels it out.
Future<void> showBreadDetailSheet(BuildContext context, BreadItem item) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    // Opened from inside a tab branch — the root navigator puts the sheet
    // above the bottom tab bar instead of underneath it.
    useRootNavigator: true,
    builder: (_) => _BreadDetailSheet(item: item),
  );
}

class _BreadDetailSheet extends StatelessWidget {
  final BreadItem item;

  const _BreadDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final weight = context.read<AuthProvider>().user?.weight;
    final hasMacros = item.carbG != null || item.proteinG != null || item.fatG != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: NetworkPhoto(url: item.imageUrl, borderRadius: BorderRadius.circular(16)),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: Text(item.name, style: textTheme.titleLarge)),
                if (item.category != null) CategoryChip(label: item.category!),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${formatThousands(item.price)}원', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            CalorieLine(item: item, style: textTheme.bodyLarge),
            if (weight != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.directions_walk, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '걸어서 약 ${WalkCalories.minutesToBurn(item.calories, weight)}분이면 0kcal로 맞출 수 있어요',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            if (hasMacros) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                [
                  if (item.carbG != null) '탄수화물 ${item.carbG!.toStringAsFixed(0)}g',
                  if (item.proteinG != null) '단백질 ${item.proteinG!.toStringAsFixed(0)}g',
                  if (item.fatG != null) '지방 ${item.fatG!.toStringAsFixed(0)}g',
                ].join(' · '),
                style: textTheme.bodySmall,
              ),
            ],
            if (item.sourceNote != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(item.sourceNote!, style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// "320kcal" plus a small "추정" tag for grade-C values.
class CalorieLine extends StatelessWidget {
  final BreadItem item;
  final TextStyle? style;

  const CalorieLine({super.key, required this.item, this.style});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CalorieStatusColors>() ?? CalorieStatusColors.brand;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${item.calories}kcal', style: style),
        if (item.isCalorieEstimated) ...[
          const SizedBox(width: AppSpacing.xs),
          Tooltip(
            message: '매장 미공개 — 유사 제품 기준 추정치',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '추정',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.warning),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String label;

  const CategoryChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
