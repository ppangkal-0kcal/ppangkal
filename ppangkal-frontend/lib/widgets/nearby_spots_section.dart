import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../core/walk_calories.dart';
import '../models/bakery.dart';
import '../models/nearby_spot.dart';
import '../models/spot_detail.dart';
import '../providers/auth_provider.dart';
import '../services/bakery_service.dart';
import '../services/naver_map_launcher.dart';
import '../services/sightseeing_service.dart';
import '../theme/app_theme.dart';
import 'empty_view.dart';
import 'error_view.dart';
import 'glass_card.dart';
import 'loading_view.dart';
import 'network_photo.dart';

/// 홈 — "고른 빵집 주변 갈만한 곳" (한국관광공사 TourAPI via
/// `GET /bakeries/:id/nearby-spots`). Only built once a bakery is picked;
/// refetches when the picked bakery changes. Tapping a spot opens its TourAPI
/// detail (`GET /tour/spots/:id`) with a Naver Map walking handoff.
///
/// The 소모 칼로리 badge reads "1시간 관광"이지만 실제로는 빵집→관광지 이동(거리 기반)
/// + [WalkCalories.sightseeingMinutes](1시간 관광) 합산이다 — 이동만으로는 체감상 너무
/// 작고, 1시간만 쓰면 실제로 거기까지 걸어가는 몫이 빠진다. 라벨에 "이동+"을 넣지 않기로
/// 했으므로(가독성 우선) 빵집마다 거리가 달라 같은 "1시간 관광" 라벨 아래 숫자가 조금씩
/// 다르다 — 의도된 것이지 버그가 아니다. 도보 이동 캡션(`걸어서 약 X분`)과는 표시가
/// 분리돼 있지만 칼로리 자체는 그 이동 시간을 포함한다 — 각 위젯의 계산부 주석 참고.
class NearbySpotsSection extends StatefulWidget {
  final Bakery bakery;

  const NearbySpotsSection({super.key, required this.bakery});

  @override
  State<NearbySpotsSection> createState() => _NearbySpotsSectionState();
}

class _NearbySpotsSectionState extends State<NearbySpotsSection> {
  late Future<List<NearbySpot>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(NearbySpotsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bakery.id != widget.bakery.id) _load();
  }

  void _load() {
    _future = BakeryService().fetchNearbySpots(widget.bakery.id);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final weightKg = context.select<AuthProvider, double?>((a) => a.user?.weight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.bakery.name} 주변 갈만한 곳', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('빵 먹고 걸어서 들러 보세요 · 한국관광공사 제공', style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        FutureBuilder<List<NearbySpot>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 160, child: LoadingView());
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return ErrorView(
                error: error is ApiException
                    ? error
                    : const ApiException(
                        statusCode: 0,
                        code: 'UNKNOWN_ERROR',
                        message: '주변 관광지 정보를 불러오지 못했습니다.',
                      ),
                onRetry: () => setState(_load),
              );
            }
            final spots = snapshot.data!;
            if (spots.isEmpty) {
              return const SizedBox(
                height: 160,
                child: EmptyView(message: '2km 안에 등록된 관광지가 없어요.', icon: Icons.travel_explore),
              );
            }
            return Column(
              children: [
                for (final spot in spots)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SpotRow(spot: spot, weightKg: weightKg),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SpotRow extends StatelessWidget {
  final NearbySpot spot;
  final double? weightKg;

  const _SpotRow({required this.spot, required this.weightKg});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final walkMinutes = WalkCalories.estimateWalkMinutes(spot.distanceM.toDouble());
    // 빵집에서 여기까지 걷는 몫 + 도착해서 1시간 둘러보는 몫을 합친다.
    final sightseeingKcal = weightKg == null
        ? null
        : WalkCalories.caloriesBurned(weightKg!, walkMinutes + WalkCalories.sightseeingMinutes);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: InkWell(
        onTap: () => _showSpotDetailSheet(context, spot),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            NetworkPhoto(url: spot.imageUrl, width: 64, height: 64, placeholderIcon: Icons.landscape_outlined),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.title, style: textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xs),
                  Text('빵집에서 ${_formatDistance(spot.distanceM)} · 걸어서 약 $walkMinutes분', style: textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (spot.contentType != null) SpotTag(label: spot.contentType!),
                      if (sightseeingKcal != null)
                        SpotTag(label: '1시간 관광 $sightseeingKcal kcal', tone: TagTone.calorie, icon: Icons.local_fire_department),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// 목록·상세에서 같은 모양으로 쓰는 작은 태그. [TagTone.calorie]만 색을 달리해서
/// "얼마나 타는지"가 다른 정보에 묻히지 않게 한다.
enum TagTone { category, neutral, calorie }

class SpotTag extends StatelessWidget {
  final String label;
  final TagTone tone;
  final IconData? icon;

  const SpotTag({super.key, required this.label, this.tone = TagTone.category, this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColors = Theme.of(context).extension<CalorieStatusColors>() ?? CalorieStatusColors.brand;
    final color = switch (tone) {
      TagTone.category => scheme.primary,
      TagTone.neutral => scheme.onSurfaceVariant,
      TagTone.calorie => statusColors.safe,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

String _formatDistance(int meters) =>
    meters < 1000 ? '${meters}m' : '${(meters / 1000).toStringAsFixed(1)}km';

void _showSpotDetailSheet(BuildContext context, NearbySpot spot) {
  final token = context.read<AuthProvider>().token!;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) => _SpotDetailSheet(
        spot: spot,
        future: SightseeingService().spotDetail(token, spot.contentId),
        scrollController: scrollController,
      ),
    ),
  );
}

class _SpotDetailSheet extends StatelessWidget {
  final NearbySpot spot;
  final Future<SpotDetail> future;
  final ScrollController scrollController;

  const _SpotDetailSheet({required this.spot, required this.future, required this.scrollController});

  Future<void> _openMap(BuildContext context) async {
    final opened = await NaverMapLauncher.walkTo(
      latitude: spot.latitude,
      longitude: spot.longitude,
      name: spot.title,
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
    final walkMinutes = WalkCalories.estimateWalkMinutes(spot.distanceM.toDouble());
    final weightKg = context.select<AuthProvider, double?>((a) => a.user?.weight);
    // 위 _SpotRow와 같은 계산 — 이동 + 1시간 관광.
    final sightseeingKcal = weightKg == null
        ? null
        : WalkCalories.caloriesBurned(weightKg, walkMinutes + WalkCalories.sightseeingMinutes);

    return FutureBuilder<SpotDetail>(
      future: future,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        final imageUrl = (detail != null && detail.images.isNotEmpty) ? detail.images.first : spot.imageUrl;

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (imageUrl != null) ...[
              AspectRatio(
                aspectRatio: 16 / 10,
                child: NetworkPhoto(url: imageUrl, placeholderIcon: Icons.landscape_outlined),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(spot.title, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (spot.contentType != null) SpotTag(label: spot.contentType!),
                SpotTag(
                  label: '빵집에서 ${_formatDistance(spot.distanceM)}',
                  tone: TagTone.neutral,
                  icon: Icons.place_outlined,
                ),
                SpotTag(
                  label: '걸어서 약 $walkMinutes분',
                  tone: TagTone.neutral,
                  icon: Icons.directions_walk,
                ),
                if (sightseeingKcal != null)
                  SpotTag(
                    label: '1시간 관광 시 약 $sightseeingKcal kcal',
                    tone: TagTone.calorie,
                    icon: Icons.local_fire_department,
                  ),
              ],
            ),
            if (spot.address != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(spot.address!, style: textTheme.bodySmall),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => _openMap(context),
              icon: const Icon(Icons.directions_walk),
              label: const Text('네이버 지도로 걸어가기'),
            ),
            const SizedBox(height: AppSpacing.md),
            if (snapshot.connectionState != ConnectionState.done)
              const SizedBox(height: 120, child: LoadingView())
            else if (snapshot.hasError)
              Text('상세 정보를 불러오지 못했습니다.', style: textTheme.bodyMedium)
            else ...[
              if (detail!.openingHours != null) ...[
                Text('이용 시간', style: textTheme.labelMedium),
                Text(detail.openingHours!, style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
              ],
              if (detail.overview.isNotEmpty) Text(detail.overview, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('정보 제공: 한국관광공사', style: textTheme.labelSmall),
          ],
        );
      },
    );
  }
}
