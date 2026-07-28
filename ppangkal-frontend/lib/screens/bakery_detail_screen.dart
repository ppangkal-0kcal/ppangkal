import 'package:flutter/material.dart';

import '../models/bread_item.dart';
import '../services/bakery_service.dart';

/// Data-verification only — dumps GET /api/bakeries/:id (raw map, since
/// `tour_info` shape varies) and GET /api/bakeries/:id/items side by side.
class BakeryDetailScreen extends StatefulWidget {
  final String bakeryId;

  const BakeryDetailScreen({super.key, required this.bakeryId});

  @override
  State<BakeryDetailScreen> createState() => _BakeryDetailScreenState();
}

class _BakeryDetailScreenState extends State<BakeryDetailScreen> {
  late Future<(Map<String, dynamic>, List<BreadItem>)> _future;

  @override
  void initState() {
    super.initState();
    final service = BakeryService();
    _future = Future.wait([
      service.fetchDetail(widget.bakeryId),
      service.fetchItems(widget.bakeryId),
    ]).then((results) => (results[0] as Map<String, dynamic>, results[1] as List<BreadItem>));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.bakeryId} 상세 (디자인 없음)')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }
          final (detail, items) = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              const Text('=== GET /bakeries/:id ===', style: TextStyle(fontWeight: FontWeight.bold)),
              ...detail.entries.map((e) => Text('${e.key}: ${e.value}')),
              const Divider(height: 32),
              Text(
                '=== GET /bakeries/:id/items (${items.length}개) ===',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final item in items) ...[
                Text(
                  'id:${item.id} name:${item.name} category:${item.category} '
                  'price:${item.price} calories:${item.calories} '
                  'base_weight_g:${item.baseWeightG} is_available:${item.isAvailable} '
                  'image_url:${item.imageUrl}',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
