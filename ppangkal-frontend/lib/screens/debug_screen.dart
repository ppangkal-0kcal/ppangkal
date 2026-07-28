import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'bakery_list_screen.dart';
import 'stats_screen.dart';
import 'tour_flow_screen.dart';

/// Debug-only entry points into the raw API-verification screens (bakery
/// list/detail, tour flow, stats/TourAPI). Only reachable via HomeScreen's
/// kDebugMode-gated button — `lib/router/app_router.dart`'s `/debug` route
/// also redirects away outside debug mode, so this is gated twice.
///
/// Intentionally uses plain [Navigator.push] instead of the go_router table:
/// these are throwaway verification screens, not part of the production
/// navigation graph.
class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('디버그')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BakeryListScreen()),
              ),
              child: const Text('bakeries API 확인'),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TourFlowScreen()),
              ),
              child: const Text('투어 플로우 확인'),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              ),
              child: const Text('통계 / TourAPI 확인'),
            ),
          ],
        ),
      ),
    );
  }
}
