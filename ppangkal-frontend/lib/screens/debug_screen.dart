import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'stats_screen.dart';
import 'tour_flow_screen.dart';

/// Debug-only entry points into the raw API-verification screens (tour
/// flow, stats/TourAPI). Only reachable via HomeScreen's kDebugMode-gated
/// button — `lib/router/app_router.dart`'s `/debug` route also redirects
/// away outside debug mode, so this is gated twice.
///
/// The bakery list/detail screens used to live here too, but they're now
/// real production UI (the 빵집 tab) rather than raw-dump verification
/// screens, so they were removed from this list — reach them through the
/// tab shell instead.
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
