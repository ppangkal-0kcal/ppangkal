import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../models/calorie_balance.dart';
import '../providers/auth_provider.dart';
import '../services/calories_service.dart';
import '../theme/app_theme.dart';
import '../widgets/calorie_balance_card.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

/// Home tab. Shows today's calorie balance from `GET /calories/balance`
/// (FRONTEND_API_GUIDE.md §2 step 7) — only fields that endpoint actually
/// returns; see `lib/widgets/calorie_balance_card.dart` for the status
/// mapping.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<CalorieBalance> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final token = context.read<AuthProvider>().token!;
    _future = CaloriesService().getBalance(token);
  }

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
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(child: _BalanceSection(future: _future, onRetry: () => setState(_load))),
                ],
              ),
            ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  final Future<CalorieBalance> future;
  final VoidCallback onRetry;

  const _BalanceSection({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CalorieBalance>(
      future: future,
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
                    message: '칼로리 정보를 불러오지 못했습니다.',
                  ),
            onRetry: onRetry,
          );
        }
        return CalorieBalanceCard(balance: snapshot.data!);
      },
    );
  }
}
