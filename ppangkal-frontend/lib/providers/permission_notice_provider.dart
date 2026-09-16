import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 접근권한 고지를 한 번이라도 봤는지만 기억한다 (기기 로컬, 서버로 보내지 않음).
///
/// 고지는 OS 권한 팝업보다 **먼저** 떠야 하므로 로그인/회원가입보다 앞에 둔다 —
/// 라우터의 redirect가 이 값을 보고 `/permissions`로 보낸다
/// (`lib/router/app_router.dart`). 기존 계정으로 로그인만 하는 사용자도 반드시
/// 거치게 하려는 것이 회원가입 화면이 아닌 여기에 둔 이유다.
class PermissionNoticeProvider extends ChangeNotifier {
  static const _key = 'permission_notice_ack_v1';

  final FlutterSecureStorage _storage;

  PermissionNoticeProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// null이면 아직 읽는 중 — 라우터는 이 동안 스플래시에 머문다.
  /// [AuthProvider.status]와 같이 테스트에서 바로 세팅할 수 있게 공개 필드로 둔다.
  bool? acknowledged;

  Future<void> load() async {
    try {
      acknowledged = await _storage.read(key: _key) == 'true';
    } catch (_) {
      // 저장소를 못 읽으면 "아직 안 봤다"로 두고 고지를 한 번 더 띄운다 —
      // 고지를 건너뛰는 것보다 두 번 보는 편이 낫다.
      acknowledged = false;
    }
    notifyListeners();
  }

  Future<void> acknowledge() async {
    acknowledged = true;
    notifyListeners();
    try {
      await _storage.write(key: _key, value: 'true');
    } catch (_) {
      // 기록에 실패해도 이번 실행에서는 통과시킨다. 다음 실행에 다시 뜬다.
    }
  }
}
