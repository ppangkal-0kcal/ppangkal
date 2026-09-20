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
      // 모서리는 각지게 둔다 — 둥글리면 그 바깥으로 이 Scaffold의 배경이 흰
      // 삼각형으로 드러난다(페이지 그라데이션은 각 페이지가 칠하므로 셸까지
      // 닿지 않는다).
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // 탭을 누르면 그 탭의 첫 화면으로 되돌린다. 빵을 고른 뒤 홈으로 넘어간
        // 상태에서 빵집 탭을 누르면 빵 메뉴 화면이 그대로 남아 있어, 목록을 다시
        // 보려면 뒤로가기를 눌러야 했다.
        onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: true),
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
