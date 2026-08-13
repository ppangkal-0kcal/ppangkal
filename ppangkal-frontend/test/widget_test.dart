import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ppangkal/providers/auth_provider.dart';
import 'package:ppangkal/router/app_router.dart';

void main() {
  testWidgets('Router shows the login screen when unauthenticated', (tester) async {
    final auth = AuthProvider()..status = AuthStatus.unauthenticated;
    final router = buildAppRouter(auth);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('빵칼 로그인'), findsOneWidget);
  });

  testWidgets('Router shows a spinner while auth status is unknown', (tester) async {
    final auth = AuthProvider();
    final router = buildAppRouter(auth);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
