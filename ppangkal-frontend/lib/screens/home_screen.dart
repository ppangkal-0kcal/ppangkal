import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'bakery_list_screen.dart';
import 'stats_screen.dart';
import 'tour_flow_screen.dart';

/// Placeholder post-login screen — proves the signup/login/tryAutoLogin
/// loop round-trips against the real backend. The 8-step tour flow
/// (bakery search onward) is scoped for a later pass.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('빵칼'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('안녕하세요, ${user.name}님', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('오늘의 목표 칼로리: ${user.dailyGoalCalories ?? '-'} kcal'),
                  const SizedBox(height: 24),
                  const Text('사용자 ID (로그인 시 필요, 복사해서 보관하세요)'),
                  SelectableText(
                    user.id,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BakeryListScreen()),
                    ),
                    child: const Text('bakeries API 확인'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TourFlowScreen()),
                    ),
                    child: const Text('투어 플로우 확인'),
                  ),
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
