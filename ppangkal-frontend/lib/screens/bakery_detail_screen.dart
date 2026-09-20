import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exception.dart';
import '../core/formatters.dart';
import '../models/bakery.dart';
import '../models/bread_item.dart';
import '../services/bakery_service.dart';
import '../services/naver_map_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/bread_detail_sheet.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/network_photo.dart';
import '../widgets/page_title.dart';
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
      appBar: PageAppBar('빵집 상세'),
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
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
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bakery.photoUrl != null)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: NetworkPhoto(
                url: bakery.photoUrl,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                placeholderIcon: Icons.storefront_outlined,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _basicInfo(context, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _basicInfo(BuildContext context, TextTheme textTheme) {
    return Column(
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
              Text(
                bakery.rating!.toStringAsFixed(1) +
                    (bakery.reviewCount != null
                        ? ' · 리뷰 ${formatThousands(bakery.reviewCount!)}'
                        : ''),
                style: textTheme.bodySmall,
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Icon(
              bakery.isOpenNow
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              bakery.isOpenNow ? '영업 중' : '영업 종료',
              style: textTheme.bodySmall,
            ),
          ],
        ),
        if (bakery.openingHours != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('영업시간 ${bakery.openingHours}', style: textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () async {
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
          },
          icon: const Icon(Icons.directions_walk),
          label: const Text('네이버 지도로 길찾기'),
        ),
      ],
    );
  }
}

class _MenuThumb extends StatelessWidget {
  final BreadItem item;

  const _MenuThumb({required this.item});

  static const double _width = 120;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => showBreadDetailSheet(context, item),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: _width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkPhoto(url: item.imageUrl, width: _width, height: 100),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.name,
              style: textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text('${formatThousands(item.price)}원', style: textTheme.bodySmall),
            CalorieLine(item: item, style: textTheme.bodySmall),
          ],
        ),
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
          if (items.isEmpty)
            Text('아직 등록된 메뉴 정보가 없어요.', style: textTheme.bodySmall)
          else
            SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) => _MenuThumb(item: items[i]),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: items.isEmpty
                  ? null
                  : () => context.push('/bakeries/$bakeryId/menu'),
              child: const Text('빵 고르고 투어 시작하기'),
            ),
          ),
        ],
      ),
    );
  }
}
