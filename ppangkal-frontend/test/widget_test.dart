import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ppangkal/providers/auth_provider.dart';
import 'package:ppangkal/providers/permission_notice_provider.dart';
import 'package:ppangkal/router/app_router.dart';

/// 고지를 이미 본 상태 — 접근권한 화면이 아닌 원래 화면을 확인하는 테스트용.
PermissionNoticeProvider _acknowledgedNotice() => PermissionNoticeProvider()..acknowledged = true;

Widget _app(AuthProvider auth, PermissionNoticeProvider notice) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: notice),
      ],
      child: MaterialApp.router(routerConfig: buildAppRouter(auth, notice)),
    );

void main() {
  testWidgets('Router shows the login screen when unauthenticated', (tester) async {
    final auth = AuthProvider()..status = AuthStatus.unauthenticated;

    await tester.pumpWidget(_app(auth, _acknowledgedNotice()));
    await tester.pump();

    expect(find.text('이메일'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
  });

  testWidgets('Router shows a spinner while auth status is unknown', (tester) async {
    final auth = AuthProvider();

    await tester.pumpWidget(_app(auth, _acknowledgedNotice()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('접근권한 사전 고지 (정보통신망법 제22조의2)', () {
    testWidgets('고지를 보기 전에는 로그인보다 먼저 접근권한 화면이 뜬다', (tester) async {
      final auth = AuthProvider()..status = AuthStatus.unauthenticated;
      final notice = PermissionNoticeProvider()..acknowledged = false;

      await tester.pumpWidget(_app(auth, notice));
      await tester.pump();

      expect(find.text('앱 접근권한 안내'), findsOneWidget);
      // 로그인 화면으로 새어나가지 않아야 한다.
      expect(find.text('로그인'), findsNothing);
    });

    testWidgets('이미 로그인된 사용자도 고지를 안 봤으면 홈 대신 고지 화면을 본다', (tester) async {
      final auth = AuthProvider()..status = AuthStatus.authenticated;
      final notice = PermissionNoticeProvider()..acknowledged = false;

      await tester.pumpWidget(_app(auth, notice));
      await tester.pump();

      expect(find.text('앱 접근권한 안내'), findsOneWidget);
    });

    testWidgets('확인을 누르면 고지가 끝나고 로그인으로 넘어간다', (tester) async {
      final auth = AuthProvider()..status = AuthStatus.unauthenticated;
      final notice = PermissionNoticeProvider()..acknowledged = false;

      await tester.pumpWidget(_app(auth, notice));
      await tester.pump();

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(notice.acknowledged, isTrue);
      expect(find.text('이메일'), findsOneWidget);
    });

    testWidgets('필수 권한이 없다는 점과 거부해도 쓸 수 있다는 점을 고지한다', (tester) async {
      final auth = AuthProvider()..status = AuthStatus.unauthenticated;
      final notice = PermissionNoticeProvider()..acknowledged = false;

      await tester.pumpWidget(_app(auth, notice));
      await tester.pump();

      expect(find.text('선택적 접근권한'), findsOneWidget);
      expect(find.text('필수적 접근권한'), findsNothing);
      expect(find.textContaining('허용하지 않아도'), findsWidgets);
      // 요청하는 세 권한이 모두 고지돼야 한다.
      expect(find.text('위치'), findsOneWidget);
      expect(find.text('신체 활동'), findsOneWidget);
      expect(find.text('알림'), findsOneWidget);
    });
  });
}
