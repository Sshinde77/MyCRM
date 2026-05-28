// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

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

  testWidgets('Login screen renders with dummy credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(initialDarkModeEnabled: false));
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.textContaining('demo@mycrm.com / crm@123'), findsOneWidget);
  });
}
