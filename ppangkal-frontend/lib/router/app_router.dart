import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/permission_notice_provider.dart';
import '../screens/bakery_detail_screen.dart';
import '../screens/bakery_list_screen.dart';
import '../screens/bread_menu_screen.dart';
import '../screens/debug_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/permission_notice_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/tour_report_screen.dart';
import '../widgets/brand_background.dart';
import '../widgets/main_shell.dart';

/// Central route table — replaces the screen-by-screen `Navigator.push` +
/// `MaterialPageRoute` calls that used to be scattered across screens.
///
/// Auth gating is done here via [redirect] + [refreshListenable] instead of
/// a separate `AuthGate` widget: [authProvider] calling `notifyListeners()`
/// (login/logout/tryAutoLogin) re-runs [redirect] automatically, so
/// login/signup screens no longer need to navigate to `/home` themselves —
/// they just flip [AuthProvider.status] and the router follows.
GoRouter buildAppRouter(AuthProvider authProvider, PermissionNoticeProvider noticeProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([authProvider, noticeProvider]),
    redirect: (context, state) {
      final location = state.matchedLocation;

      // 접근권한 고지 여부를 아직 못 읽었거나 자동 로그인이 끝나지 않았으면 스플래시.
      if (authProvider.status == AuthStatus.unknown || noticeProvider.acknowledged == null) {
        return location == '/splash' ? null : '/splash';
      }

      // 접근권한 고지는 OS 권한 팝업보다 먼저 떠야 하므로 로그인보다도 앞이다
      // (정보통신망법 제22조의2). 기존 계정으로 로그인만 하는 사용자도 반드시 거친다.
      if (noticeProvider.acknowledged == false) {
        return location == '/permissions' ? null : '/permissions';
      }

      final loggedIn = authProvider.isAuthenticated;
      final onAuthPage = location == '/login' || location == '/signup';
      // 고지를 이미 본 뒤에는 마이페이지에서 다시 열 수 있어야 해서 로그인 검사에서 뺀다.
      final onNotice = location == '/permissions';

      if (location == '/splash') return loggedIn ? '/home' : '/login';
      if (!loggedIn && !onAuthPage && !onNotice) return '/login';
      if (loggedIn && onAuthPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => _page(const SplashScreen())),
      GoRoute(path: '/permissions', builder: (context, state) => _page(const PermissionNoticeScreen())),
      GoRoute(path: '/login', builder: (context, state) => _page(const LoginScreen())),
      GoRoute(path: '/signup', builder: (context, state) => _page(const SignupScreen())),
      GoRoute(
        path: '/debug',
        // Belt-and-suspenders: HomeScreen only shows the entry button under
        // kDebugMode, and this redirect also blocks direct navigation
        // (e.g. a typed URL on web) outside debug builds.
        redirect: (context, state) => kDebugMode ? null : '/home',
        builder: (context, state) => _page(const DebugScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => _page(const HomeScreen())),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bakeries',
                builder: (context, state) => _page(const BakeryListScreen()),
                routes: [
                  GoRoute(
                    path: ':bakeryId',
                    builder: (context, state) => _page(BakeryDetailScreen(
                      bakeryId: state.pathParameters['bakeryId']!,
                    )),
                    routes: [
                      GoRoute(
                        path: 'menu',
                        builder: (context, state) => _page(BreadMenuScreen(
                          bakeryId: state.pathParameters['bakeryId']!,
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/stats', builder: (context, state) => _page(const StatsScreen())),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (context, state) => _page(const ProfileScreen())),
            ],
          ),
        ],
      ),
      // 투어 진행(이동 → 도착 → 섭취 확정 → 다음 빵집)은 별도 화면이 아니라 홈 탭의
      // `ActiveTourCard`에서 이뤄진다 — 남은 top-level 라우트는 종료 후 리포트뿐이다.
      // 종료 직후의 리포트는 컨트롤러가 들고 있는 투어를, `/:tourId`는 통계에서
      // 고른 지난 투어를 `GET /tours/:id`로 다시 받아 보여준다.
      GoRoute(path: '/tour/report', builder: (context, state) => _page(const TourReportScreen())),
      GoRoute(
        path: '/tour/report/:tourId',
        builder: (context, state) => _page(TourReportScreen(tourId: state.pathParameters['tourId'])),
      ),
    ],
  );
}

/// Every page paints its own opaque brand background — see [BrandBackground].
Widget _page(Widget screen) => BrandBackground(child: screen);
