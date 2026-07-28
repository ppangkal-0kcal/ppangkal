import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PpangkalApp());
}

class PpangkalApp extends StatelessWidget {
  const PpangkalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..tryAutoLogin(),
      child: MaterialApp(
        title: '빵칼',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
        home: const AuthGate(),
      ),
    );
  }
}

/// Routes to Login or Home based on [AuthProvider.status], showing a
/// splash spinner while `tryAutoLogin` resolves a stored token.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.unknown => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.authenticated => const HomeScreen(),
      AuthStatus.authenticating || AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}
