import 'package:flutter/material.dart';

/// 앱이 요구하는 OS 접근권한 하나에 대한 고지 내용.
///
/// 방송미디어통신위원회 「앱 접근권한 동의 가이드라인」(정보통신망법 제22조의2)은
/// 권한을 **필수적/선택적로 구분**해 목적과 함께 고지하고, 선택적 권한은 동의하지
/// 않아도 서비스를 쓸 수 있다는 점을 알리도록 요구한다. 빵칼은 셋 다 없어도
/// 동작하므로 전부 선택적이다 — 거부 시 어떻게 되는지를 [fallback]에 적는다.
@immutable
class AppPermission {
  final IconData icon;

  /// 사용자에게 보이는 권한 이름. OS 설정 화면의 표기와 같은 말을 쓴다.
  final String name;

  /// 왜 필요한지 — 기능 이름이 아니라 사용자가 얻는 것으로 쓴다.
  final String purpose;

  /// 허용하지 않으면 어떻게 되는지. 가이드라인이 요구하는 "동의하지 않아도
  /// 이용 가능" 고지를 권한별로 구체화한 것.
  final String fallback;

  /// 필수적 접근권한 여부. 지금은 전부 false다 — true인 권한이 생기면 안내
  /// 화면이 자동으로 "필수" 묶음을 따로 그린다.
  final bool required;

  const AppPermission({
    required this.icon,
    required this.name,
    required this.purpose,
    required this.fallback,
    this.required = false,
  });
}

/// `android/app/src/main/AndroidManifest.xml`이 선언하고 앱이 실제로 요청하는
/// 권한과 1:1로 맞춰야 한다. 권한을 추가·삭제하면 이 목록도 같이 고쳐야
/// 고지 내용이 실제 동작과 어긋나지 않는다.
///
/// INTERNET·WAKE_LOCK·FOREGROUND_SERVICE는 사용자 동의 대상(런타임 권한)이
/// 아니라서 빠져 있다.
const List<AppPermission> appPermissions = [
  AppPermission(
    icon: Icons.place_outlined,
    name: '위치',
    purpose: '지금 위치에서 가까운 빵집을 찾고, 걸어서 몇 분 걸리는지 계산해요.',
    fallback: '허용하지 않으면 대전 시내 중심을 기준으로 빵집을 보여드려요.',
  ),
  AppPermission(
    icon: Icons.directions_walk,
    name: '신체 활동',
    purpose: '빵투어 중 걸음 수를 세어 소모 칼로리를 계산해요.',
    fallback: '허용하지 않아도 투어는 진행되고, 걸음 수 없이 GPS 이동 거리로만 계산해요.',
  ),
  AppPermission(
    icon: Icons.notifications_none,
    name: '알림',
    purpose: '빵투어가 진행 중이라는 것을 알림으로 보여줘요.',
    fallback: '허용하지 않아도 투어는 진행돼요.',
  ),
];
