import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'controllers/tour_flow_controller.dart';
import 'providers/auth_provider.dart';
import 'providers/permission_notice_provider.dart';
import 'router/app_router.dart';
import 'services/location_service.dart';
import 'services/naver_map_setup.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NaverMapSetup.init();
  runApp(const PpangkalApp());
}

class PpangkalApp extends StatefulWidget {
  const PpangkalApp({super.key});

  @override
  State<PpangkalApp> createState() => _PpangkalAppState();
}

class _PpangkalAppState extends State<PpangkalApp> {
  final _authProvider = AuthProvider()..tryAutoLogin();
  final _permissionNoticeProvider = PermissionNoticeProvider()..load();

  // Single app-wide instance — an active tour has to survive the user
  // bouncing between the bakery tab and the tour screens (see
  // lib/controllers/tour_flow_controller.dart's class doc).
  final PositionSource _positionSource = GeolocatorPositionSource();
  late final _tourFlowController = TourFlowController(positionSource: _positionSource);

  late final GoRouter _router = buildAppRouter(_authProvider, _permissionNoticeProvider);

  @override
  void dispose() {
    _authProvider.dispose();
    _permissionNoticeProvider.dispose();
    _tourFlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _permissionNoticeProvider),
        ChangeNotifierProvider.value(value: _tourFlowController),
        Provider<PositionSource>.value(value: _positionSource),
      ],
      child: MaterialApp.router(
        title: '빵칼',
        theme: buildAppTheme(),
        routerConfig: _router,
      ),
    );
  }
}
