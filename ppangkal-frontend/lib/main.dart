import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  late final GoRouter _router = buildAppRouter(_authProvider);

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authProvider,
      child: MaterialApp.router(
        title: '빵칼',
        theme: buildAppTheme(),
        routerConfig: _router,
      ),
    );
  }
}
