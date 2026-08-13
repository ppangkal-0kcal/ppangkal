import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../models/bread_selection.dart';
import '../providers/auth_provider.dart';
import '../screens/bakery_detail_screen.dart';
import '../screens/bakery_list_screen.dart';
import '../screens/bread_menu_screen.dart';
import '../screens/coming_soon_screen.dart';
import '../screens/debug_screen.dart';
import '../screens/food_confirm_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tour_progress_screen.dart';
import '../screens/tour_report_screen.dart';
import '../widgets/main_shell.dart';

/// Central route table — replaces the screen-by-screen `Navigator.push` +
/// `MaterialPageRoute` calls that used to be scattered across screens.
///
/// Auth gating is done here via [redirect] + [refreshListenable] instead of
/// a separate `AuthGate` widget: [authProvider] calling `notifyListeners()`
/// (login/logout/tryAutoLogin) re-runs [redirect] automatically, so
/// login/signup screens no longer need to navigate to `/home` themselves —
/// they just flip [AuthProvider.status] and the router follows.
GoRouter buildAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (authProvider.status == AuthStatus.unknown) {
        return location == '/splash' ? null : '/splash';
      }

      final loggedIn = authProvider.isAuthenticated;
      final onAuthPage = location == '/login' || location == '/signup';

      if (location == '/splash') return loggedIn ? '/home' : '/login';
      if (!loggedIn && !onAuthPage) return '/login';
      if (loggedIn && onAuthPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: '/debug',
        // Belt-and-suspenders: HomeScreen only shows the entry button under
        // kDebugMode, and this redirect also blocks direct navigation
        // (e.g. a typed URL on web) outside debug builds.
        redirect: (context, state) => kDebugMode ? null : '/home',
        builder: (context, state) => const DebugScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bakeries',
                builder: (context, state) => const BakeryListScreen(),
                routes: [
                  GoRoute(
                    path: ':bakeryId',
                    builder: (context, state) => BakeryDetailScreen(
                      bakeryId: state.pathParameters['bakeryId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'menu',
                        builder: (context, state) => BreadMenuScreen(
                          bakeryId: state.pathParameters['bakeryId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/stats', builder: (context, state) => const ComingSoonScreen(title: '통계')),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (context, state) => const ComingSoonScreen(title: '마이페이지')),
            ],
          ),
        ],
      ),
      // Active-tour flow — deliberately plain top-level routes, not nested
      // under the tab shell: a tour spans multiple round trips through the
      // 빵집 tab, and TourFlowController is a single app-root instance (see
      // lib/main.dart), not scoped to any one branch of the shell.
      GoRoute(
        path: '/tour/progress/:bakeryId',
        builder: (context, state) => TourProgressScreen(
          bakeryId: state.pathParameters['bakeryId']!,
          selections: state.extra as List<BreadSelection>? ?? const [],
        ),
      ),
      GoRoute(
        path: '/tour/confirm/:tourStopId',
        builder: (context, state) => FoodConfirmScreen(
          tourStopId: state.pathParameters['tourStopId']!,
          selections: state.extra as List<BreadSelection>? ?? const [],
        ),
      ),
      GoRoute(path: '/tour/report', builder: (context, state) => const TourReportScreen()),
    ],
  );
}
