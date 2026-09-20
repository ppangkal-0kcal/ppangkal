import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../core/formatters.dart';
import '../models/bakery.dart';
import '../services/naver_map_launcher.dart';
import '../services/naver_map_setup.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'network_photo.dart';

/// Naver 지도 앱 마커와 같은 계열의 짙은 브랜드 그린 — 테마의 primary(seed:
/// 빵 베이지)를 그대로 쓰면 핀이 형광색으로 튀어서 지도 위에서 따로 고정했다.
const _pinColor = Color(0xFF03A54A);

/// Bakery pins on a Naver map (list screen's 지도 mode). Tapping a pin shows
/// a preview card; tapping the card opens the bakery detail.
///
/// Without a working map SDK (web/desktop, no Client ID, or NCP auth
/// failure) it degrades to a card that hands the area off to the Naver Map
/// app — the list mode keeps working either way.
class BakeryMapView extends StatelessWidget {
  final List<Bakery> bakeries;
  final double centerLatitude;
  final double centerLongitude;
  final ValueChanged<Bakery> onOpenBakery;

  const BakeryMapView({
    super.key,
    required this.bakeries,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.onOpenBakery,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NaverMapSetup.available,
      builder: (context, available, _) => available
          ? _NaverBakeryMap(
              bakeries: bakeries,
              center: NLatLng(centerLatitude, centerLongitude),
              onOpenBakery: onOpenBakery,
            )
          : _MapUnavailable(bakeries: bakeries, onOpenBakery: onOpenBakery),
    );
  }
}

class _NaverBakeryMap extends StatefulWidget {
  final List<Bakery> bakeries;
  final NLatLng center;
  final ValueChanged<Bakery> onOpenBakery;

  const _NaverBakeryMap({required this.bakeries, required this.center, required this.onOpenBakery});

  @override
  State<_NaverBakeryMap> createState() => _NaverBakeryMapState();
}

class _NaverBakeryMapState extends State<_NaverBakeryMap> {
  NaverMapController? _controller;
  Bakery? _selected;

  @override
  void didUpdateWidget(covariant _NaverBakeryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bakeries != widget.bakeries) _syncMarkers();
  }

  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.clearOverlays(type: NOverlayType.marker);

    final markers = widget.bakeries.map((bakery) {
      final marker = NMarker(
        id: bakery.id,
        position: NLatLng(bakery.latitude, bakery.longitude),
        iconTintColor: _pinColor,
        caption: NOverlayCaption(text: bakery.name, textSize: 12),
        isHideCollidedCaptions: true,
      );
      marker.setOnTapListener((_) => setState(() => _selected = bakery));
      return marker;
    }).toSet();
    await controller.addOverlayAll(markers);

    if (widget.bakeries.length > 1) {
      final bounds = NLatLngBounds.from(widget.bakeries.map((b) => NLatLng(b.latitude, b.longitude)));
      await controller.updateCamera(NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(48)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(target: widget.center, zoom: 12),
              locationButtonEnable: true,
              consumeSymbolTapEvents: false,
            ),
            onMapReady: (controller) {
              _controller = controller;
              _syncMarkers();
            },
            onMapTapped: (_, _) => setState(() => _selected = null),
          ),
          if (selected != null)
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: _BakeryPreview(bakery: selected, onTap: () => widget.onOpenBakery(selected)),
            ),
        ],
      ),
    );
  }
}

class _BakeryPreview extends StatelessWidget {
  final Bakery bakery;
  final VoidCallback onTap;

  const _BakeryPreview({required this.bakery, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              NetworkPhoto(url: bakery.photoUrl, width: 64, height: 64, placeholderIcon: Icons.storefront_outlined),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bakery.name, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        if (bakery.distanceM != null) formatDistance(bakery.distanceM!),
                        if (bakery.rating != null) '★ ${bakery.rating!.toStringAsFixed(1)}',
                        if ((bakery.breadItemCount ?? 0) > 0) '메뉴 ${bakery.breadItemCount}종',
                      ].join(' · '),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapUnavailable extends StatelessWidget {
  final List<Bakery> bakeries;
  final ValueChanged<Bakery> onOpenBakery;

  const _MapUnavailable({required this.bakeries, required this.onOpenBakery});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.map_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Text('지도는 네이버 지도 앱에서 볼 수 있어요', style: textTheme.titleSmall),
                ],
              ),
              if (NaverMapSetup.failureReason != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(NaverMapSetup.failureReason!, style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final bakery in bakeries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: Text(bakery.name),
            subtitle: Text(bakery.address, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => onOpenBakery(bakery),
            trailing: IconButton(
              tooltip: '네이버 지도로 보기',
              icon: const Icon(Icons.open_in_new),
              onPressed: () => NaverMapLauncher.walkTo(
                latitude: bakery.latitude,
                longitude: bakery.longitude,
                name: bakery.name,
              ),
            ),
          ),
      ],
    );
  }
}
