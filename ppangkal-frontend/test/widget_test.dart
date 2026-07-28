import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ppangkal/main.dart';
import 'package:ppangkal/providers/auth_provider.dart';

void main() {
  testWidgets('AuthGate shows the login screen when unauthenticated', (tester) async {
    final auth = AuthProvider()..status = AuthStatus.unauthenticated;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    expect(find.text('빵칼 로그인'), findsOneWidget);
  });

  testWidgets('AuthGate shows a spinner while auth status is unknown', (tester) async {
    final auth = AuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
