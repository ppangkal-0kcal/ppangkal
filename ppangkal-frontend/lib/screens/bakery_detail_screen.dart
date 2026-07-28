import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exception.dart';
import '../models/bakery.dart';
import '../models/bread_item.dart';
import '../services/bakery_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/tour_info_section.dart';

/// Bakery detail (`GET /bakeries/:id` + `GET /bakeries/:id/items` —
/// FRONTEND_API_GUIDE.md §2 steps 2~4). The TourAPI-enrichment section
/// only renders when `tour_info` is non-null AND has at least one
/// populated field — most seed bakeries have no `tour_content_id`, so
/// this branch is easy to miss while testing against only the 2 seeded
/// rows (see `Bakery.tourInfo` / `TourInfo.isEmpty`).
class BakeryDetailScreen extends StatefulWidget {
  final String bakeryId;

  const BakeryDetailScreen({super.key, required this.bakeryId});

  @override
  State<BakeryDetailScreen> createState() => _BakeryDetailScreenState();
}

class _BakeryDetailScreenState extends State<BakeryDetailScreen> {
  late Future<(Bakery, List<BreadItem>)> _future;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('빵집 상세')),
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
                      message: '빵집 정보를 불러오지 못했습니다.',
                    ),
              onRetry: () => setState(_load),
            );
          }
          final (bakery, items) = snapshot.data!;
          final tourInfo = bakery.tourInfo;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _BasicInfoCard(bakery: bakery),
              if (tourInfo != null && !tourInfo.isEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                TourInfoSection(info: tourInfo),
              ],
              const SizedBox(height: AppSpacing.md),
              _MenuPreviewCard(bakeryId: bakery.id, items: items),
            ],
          );
        },
      ),
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  final Bakery bakery;

  const _BasicInfoCard({required this.bakery});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bakery.name, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(bakery.address, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (bakery.rating != null) ...[
                const Icon(Icons.star, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(bakery.rating!.toStringAsFixed(1), style: textTheme.bodySmall),
                const SizedBox(width: AppSpacing.md),
              ],
              Icon(bakery.isOpenNow ? Icons.check_circle_outline : Icons.cancel_outlined, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(bakery.isOpenNow ? '영업 중' : '영업 종료', style: textTheme.bodySmall),
            ],
          ),
          if (bakery.openingHours != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('영업시간 ${bakery.openingHours}', style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _MenuPreviewCard extends StatelessWidget {
  final String bakeryId;
  final List<BreadItem> items;

  const _MenuPreviewCard({required this.bakeryId, required this.items});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('빵 메뉴 (${items.length}종)', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text('${item.name} · ${item.price}원 · ${item.calories}kcal'),
            ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: items.isEmpty ? null : () => context.push('/bakeries/$bakeryId/menu'),
            child: const Text('빵 메뉴 선택하기'),
          ),
        ],
      ),
    );
  }
}
