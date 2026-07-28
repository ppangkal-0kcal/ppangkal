import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/loading_view.dart';

/// Home tab placeholder. Proves the auth/router/shell wiring works end to
/// end — the calorie-balance bar (FRONTEND_API_GUIDE.md §2 step 7) is a
/// separate, later task and intentionally not built here.
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
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              tooltip: '디버그',
              onPressed: () => context.push('/debug'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: user == null
          ? const LoadingView()
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('안녕하세요, ${user.name}님', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text('오늘의 목표 칼로리: ${user.dailyGoalCalories ?? '-'} kcal'),
                  const SizedBox(height: AppSpacing.lg),
                  const Expanded(
                    child: EmptyView(
                      message: '칼로리 잔액 바는 준비 중입니다.',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
