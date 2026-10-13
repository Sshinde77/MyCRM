// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mycrm/controllers/auth_controller.dart';
import 'package:mycrm/services/auth_service.dart';

import 'package:mycrm/main.dart';

class _TestAuthService extends AuthService {
  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(AuthController(authService: _TestAuthService()), permanent: true);
  });

  tearDown(Get.reset);

  testWidgets('Signed-out startup shows login and requires credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(initialDarkModeEnabled: false));
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.controller!.text, isEmpty);
    }

    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
