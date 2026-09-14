import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


/// Bottom-tab shell for the 4 primary destinations (홈/빵집/통계/마이페이지).
/// Each tab is a [StatefulShellRoute] branch, so switching tabs preserves
/// that tab's own navigation stack instead of resetting it.
///
/// The brand gradient is painted per page (`BrandBackground`, applied in
/// the router), not here — see that widget for why.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      // 상단 콘텐츠와 시각적으로 분리되도록 위쪽 모서리만 둥글게 처리
      // (2026-09 디자인 가이드: rounded top corners).
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: NavigationBar(
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
      ),
    );
  }
}
