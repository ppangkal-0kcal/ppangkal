import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Bottom-tab shell for the 4 primary destinations (홈/빵집/통계/마이페이지).
/// Each tab is a [StatefulShellRoute] branch, so switching tabs preserves
/// that tab's own navigation stack instead of resetting it.
///
/// Also lays down the app-wide background gradient ([AppBackground]) behind
/// every tab: each tab screen is its own `Scaffold`, which paints an opaque
/// `scaffoldBackgroundColor` by default — without overriding that to
/// transparent for this subtree, the gradient would be fully hidden and
/// `GlassCard`'s `BackdropFilter` would have nothing to blur.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.extension<AppBackground>() ?? AppBackground.brand;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: background.gradient)),
          ),
          Theme(
            data: theme.copyWith(scaffoldBackgroundColor: Colors.transparent),
            child: navigationShell,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.bakery_dining_outlined),
            selectedIcon: Icon(Icons.bakery_dining),
            label: '빵집',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '통계',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}
