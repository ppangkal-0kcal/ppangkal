import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/bakery.dart';
import '../providers/auth_provider.dart';
import '../services/bakery_service.dart';

/// Data-verification screen only — no design pass yet. Confirms
/// GET /api/bakeries round-trips through the DB by dumping raw fields.
/// Origin is hardcoded to central Daejeon (36.3504, 127.3845, same point
/// used in backend/verify testing) since GPS isn't wired up yet.
class BakeryListScreen extends StatefulWidget {
  const BakeryListScreen({super.key});

  @override
  State<BakeryListScreen> createState() => _BakeryListScreenState();
}

class _BakeryListScreenState extends State<BakeryListScreen> {
  late Future<List<Bakery>> _future;

  @override
  void initState() {
    super.initState();
    final weight = context.read<AuthProvider>().user?.weight;
    _future = BakeryService().fetchNearby(
      lat: 36.3504,
      lng: 127.3845,
      radiusKm: 5,
      userWeight: weight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('bakeries API 확인 (디자인 없음)')),
      body: FutureBuilder<List<Bakery>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }
          final bakeries = snapshot.data!;
          if (bakeries.isEmpty) {
            return const Center(child: Text('빵집 데이터가 없습니다 (DB 확인 필요)'));
          }
          return ListView.separated(
            itemCount: bakeries.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final b = bakeries[i];
              return InkWell(
                onTap: () => context.push('/bakeries/${b.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('id: ${b.id}'),
                      Text('name: ${b.name}'),
                      Text('address: ${b.address}'),
                      Text('lat/lng: ${b.latitude}, ${b.longitude}'),
                      Text('rating: ${b.rating}  review_count: ${b.reviewCount}'),
                      Text('opening_hours: ${b.openingHours}'),
                      Text('distance_m: ${b.distanceM}'),
                      Text('is_open_now: ${b.isOpenNow}'),
                      Text('walk_recommended: ${b.walkRecommended}'),
                      Text('estimated_walk_calories: ${b.estimatedWalkCalories}'),
                      Text('suggested_walk: ${b.suggestedWalk}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
