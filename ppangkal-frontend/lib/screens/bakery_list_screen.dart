import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../models/bakery.dart';
import '../providers/auth_provider.dart';
import '../services/bakery_service.dart';
import '../services/location_service.dart';
import '../services/walk_filter.dart';
import '../theme/app_theme.dart';
import '../widgets/bakery_card.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

// 위치 권한이 없거나 GPS를 못 잡을 때 쓰는 대전 시내 중심 좌표.
const double _fallbackLat = 36.3504;
const double _fallbackLng = 127.3845;

/// Bakery list (`GET /bakeries` — FRONTEND_API_GUIDE.md §2 steps 2~3).
/// Sorting is server-side only (`sort=distance|rating|recommended`) —
/// switching [_sort] re-fetches, it never reorders the list locally.
class BakeryListScreen extends StatefulWidget {
  const BakeryListScreen({super.key});

  @override
  State<BakeryListScreen> createState() => _BakeryListScreenState();
}

class _BakeryListScreenState extends State<BakeryListScreen> {
  static const _sortOptions = {
    'distance': '거리순',
    'rating': '평점순',
    'recommended': '추천순',
  };

  String _sort = 'distance';
  late Future<List<Bakery>> _future;

  /// Resolved once per screen — re-sorting reuses it instead of waiting on
  /// GPS again. Null result means "use the fallback coordinate".
  late final Future<GeoSample?> _location = context.read<PositionSource>().current();
  bool _usingFallbackLocation = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final weight = context.read<AuthProvider>().user?.weight;
    _future = _location.then((sample) {
      final usingFallback = sample == null;
      if (usingFallback != _usingFallbackLocation && mounted) {
        setState(() => _usingFallbackLocation = usingFallback);
      }
      return BakeryService().fetchNearby(
        lat: sample?.latitude ?? _fallbackLat,
        lng: sample?.longitude ?? _fallbackLng,
        radiusKm: 5,
        sort: _sort,
        userWeight: weight,
      );
    });
  }

  void _changeSort(String sort) {
    if (sort == _sort) return;
    setState(() {
      _sort = sort;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('빵집')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: _sortOptions.entries
                  .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                  .toList(),
              selected: {_sort},
              onSelectionChanged: (selection) => _changeSort(selection.first),
            ),
            if (_usingFallbackLocation) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.location_off_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '현재 위치를 확인할 수 없어 대전 시내 기준으로 보여드려요.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: FutureBuilder<List<Bakery>>(
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
                              message: '빵집 목록을 불러오지 못했습니다.',
                            ),
                      onRetry: () => setState(_load),
                    );
                  }
                  final bakeries = snapshot.data!;
                  if (bakeries.isEmpty) {
                    return const EmptyView(
                      message: '주변에 등록된 빵집이 없습니다.',
                      icon: Icons.bakery_dining_outlined,
                    );
                  }
                  return ListView.separated(
                    itemCount: bakeries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => BakeryCard(
                      bakery: bakeries[i],
                      onTap: () => context.push('/bakeries/${bakeries[i].id}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
