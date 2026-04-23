import 'package:get/get.dart';

import '../core/services/biometric_service.dart';
import '../core/services/permission_service.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

enum StartupDestination { login, biometricGate, dashboard }

class AuthController extends GetxController {
  AuthController({AuthService? authService, BiometricService? biometricService})
    : _authService = authService ?? AuthService(),
      _biometricService = biometricService ?? BiometricService();

  final AuthService _authService;
  final BiometricService _biometricService;

  final RxBool biometricEnabled = false.obs;

  Future<void> init() async {
    biometricEnabled.value = await _authService.isBiometricEnabled();
  }

  Future<StartupDestination> determineStartupDestination() async {
    await init();

    final hasToken = await _authService.hasAccessToken();
    if (!hasToken) {
      if (biometricEnabled.value) {
        await disableBiometricLogin();
      }
      return StartupDestination.login;
    }

    if (biometricEnabled.value) {
      return StartupDestination.biometricGate;
    }

    final ok = await validateSession();
    if (!ok) {
      await clearLocalSession(disableBiometric: false);
      return StartupDestination.login;
    }

    return StartupDestination.dashboard;
  }

  Future<bool> validateSession() async {
    return await _authService.validateSession();
  }

  Future<BiometricAvailability> getBiometricAvailability() async {
    return await _biometricService.checkAvailability();
  }

  Future<BiometricAuthResult> authenticateWithBiometrics() async {
    return await _biometricService.authenticate(
      reason: 'Authenticate to sign in to MyCRM',
    );
  }

  Future<bool> enableBiometricLogin() async {
    final availability = await getBiometricAvailability();
    if (!availability.isUsable) {
      _showSnack(
        title: 'Biometric not available',
        message: availability.status == BiometricAvailabilityStatus.notEnrolled
            ? 'Please enable fingerprint/face in device settings'
            : 'Biometric not available',
        isError: true,
      );
      return false;
    }

    final result = await authenticateWithBiometrics();
    if (!result.isSuccess) {
      _showSnack(
        title: 'Authentication failed',
        message: result.message ?? 'Authentication failed',
        isError: true,
      );
      return false;
    }

    await _authService.setBiometricEnabled(true);
    biometricEnabled.value = true;
    _showSnack(
      title: 'Biometric enabled',
      message: 'You can now sign in using fingerprint/face.',
    );
    return true;
  }

  Future<void> disableBiometricLogin() async {
    await _authService.setBiometricEnabled(false);
    biometricEnabled.value = false;
  }

  Future<void> clearLocalSession({bool disableBiometric = true}) async {
    await _authService.clearSession(clearBiometricFlag: disableBiometric);
    if (disableBiometric) {
      biometricEnabled.value = false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    biometricEnabled.value = false;
  }

  void goToLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> goToDashboard() async {
    Get.offAllNamed(await PermissionService.firstAllowedRoute());
  }

  void goToBiometricGate() {
    Get.offAllNamed(AppRoutes.biometricGate);
  }

  void _showSnack({
    required String title,
    required String message,
    bool isError = false,
  }) {
    AppSnackbar.show(title, message, isError: isError);
  }
}
