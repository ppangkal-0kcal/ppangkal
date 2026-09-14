import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../core/api_config.dart';

/// Whether the in-app Naver map can be shown. The SDK is Android/iOS only
/// and needs an NCP Maps Client ID ([naverMapClientId]); it also reports
/// auth failures (wrong key, package name not registered in the NCP
/// console, quota) asynchronously, after init already returned — so this
/// is a listenable the map view watches, not a one-time bool.
class NaverMapSetup {
  NaverMapSetup._();

  static final ValueNotifier<bool> available = ValueNotifier(false);

  /// Last auth failure, surfaced on the fallback card to make a key/console
  /// misconfiguration diagnosable on a real device.
  static String? failureReason;

  static bool get _supportedPlatform =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> init() async {
    if (!_supportedPlatform) {
      failureReason = '이 기기에서는 앱 내 지도를 지원하지 않아요.';
      return;
    }
    if (naverMapClientId.isEmpty) {
      failureReason = '지도 키(NAVER_MAP_CLIENT_ID)가 설정되지 않았어요.';
      return;
    }
    try {
      await FlutterNaverMap().init(
        clientId: naverMapClientId,
        onAuthFailed: (ex) {
          failureReason = '네이버 지도 인증 실패: $ex';
          available.value = false;
        },
      );
      available.value = true;
    } catch (e) {
      failureReason = '네이버 지도 초기화 실패: $e';
    }
  }
}
