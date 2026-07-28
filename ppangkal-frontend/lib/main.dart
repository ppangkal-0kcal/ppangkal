import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'controllers/tour_flow_controller.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PpangkalApp());
}

class PpangkalApp extends StatefulWidget {
  const PpangkalApp({super.key});

  @override
  State<PpangkalApp> createState() => _PpangkalAppState();
}

class _PpangkalAppState extends State<PpangkalApp> {
  final _authProvider = AuthProvider()..tryAutoLogin();

  // Single app-wide instance — an active tour has to survive the user
  // bouncing between the bakery tab and the tour screens (see
  // lib/controllers/tour_flow_controller.dart's class doc).
  final _tourFlowController = TourFlowController();

  late final GoRouter _router = buildAppRouter(_authProvider);

  @override
  void dispose() {
    _authProvider.dispose();
    _tourFlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _tourFlowController),
      ],
      child: MaterialApp.router(
        title: '빵칼',
        theme: buildAppTheme(),
        routerConfig: _router,
      ),
    );
  }
}
