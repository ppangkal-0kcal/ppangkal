import 'package:flutter/material.dart';

import '../widgets/loading_view.dart';

/// Shown while [AuthProvider.tryAutoLogin] resolves whether a stored token
/// is still valid — see `lib/router/app_router.dart`'s redirect logic.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingView());
  }
}
