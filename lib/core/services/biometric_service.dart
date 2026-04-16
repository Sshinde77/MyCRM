import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricAvailabilityStatus {
  supportedAndEnrolled,
  deviceNotSupported,
  notAvailable,
  notEnrolled,
}

class BiometricAvailability {
  const BiometricAvailability({
    required this.status,
    required this.availableBiometrics,
    this.message,
  });

  final BiometricAvailabilityStatus status;
  final List<BiometricType> availableBiometrics;
  final String? message;

  bool get isUsable =>
      status == BiometricAvailabilityStatus.supportedAndEnrolled;

  bool get hasFace => availableBiometrics.contains(BiometricType.face);
  bool get hasFingerprint =>
      availableBiometrics.contains(BiometricType.fingerprint);
}

enum BiometricAuthStatus {
  success,
  failed,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  deviceNotSupported,
  error,
}

class BiometricAuthResult {
  const BiometricAuthResult({required this.status, this.message});

  final BiometricAuthStatus status;
  final String? message;

  bool get isSuccess => status == BiometricAuthStatus.success;
}

/// Handles biometric capability checks + auth prompts via `local_auth`.
class BiometricService {
  BiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<BiometricAvailability> checkAvailability() async {
    final isDeviceSupported = await _safeBool(() => _auth.isDeviceSupported());
    if (isDeviceSupported != true) {
      return const BiometricAvailability(
        status: BiometricAvailabilityStatus.deviceNotSupported,
        availableBiometrics: [],
        message: 'Device not supported',
      );
    }

    final canCheck = await _safeBool(() => _auth.canCheckBiometrics) ?? false;
    final available = await _safeList(() => _auth.getAvailableBiometrics());

    if (!canCheck && available.isEmpty) {
      return const BiometricAvailability(
        status: BiometricAvailabilityStatus.notAvailable,
        availableBiometrics: [],
        message: 'Biometric not available',
      );
    }

    if (available.isEmpty) {
      return const BiometricAvailability(
        status: BiometricAvailabilityStatus.notEnrolled,
        availableBiometrics: [],
        message: 'No biometrics enrolled',
      );
    }

    return BiometricAvailability(
      status: BiometricAvailabilityStatus.supportedAndEnrolled,
      availableBiometrics: available,
    );
  }

  Future<BiometricAuthResult> authenticate({
    String reason = 'Authenticate to continue',
  }) async {
    final availability = await checkAvailability();
    if (!availability.isUsable) {
      return BiometricAuthResult(
        status: _mapAvailabilityToAuthStatus(availability.status),
        message: availability.message,
      );
    }

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: false,
        ),
      );

      if (authenticated) {
        return const BiometricAuthResult(status: BiometricAuthStatus.success);
      }

      return const BiometricAuthResult(
        status: BiometricAuthStatus.failed,
        message: 'Authentication failed',
      );
    } on PlatformException catch (error) {
      final mapped = _mapPlatformException(error);
      return BiometricAuthResult(status: mapped.$1, message: mapped.$2);
    } catch (_) {
      return const BiometricAuthResult(
        status: BiometricAuthStatus.error,
        message: 'Authentication failed',
      );
    }
  }

  BiometricAuthStatus _mapAvailabilityToAuthStatus(
    BiometricAvailabilityStatus status,
  ) {
    switch (status) {
      case BiometricAvailabilityStatus.supportedAndEnrolled:
        return BiometricAuthStatus.success;
      case BiometricAvailabilityStatus.deviceNotSupported:
        return BiometricAuthStatus.deviceNotSupported;
      case BiometricAvailabilityStatus.notAvailable:
        return BiometricAuthStatus.notAvailable;
      case BiometricAvailabilityStatus.notEnrolled:
        return BiometricAuthStatus.notEnrolled;
    }
  }

  (BiometricAuthStatus, String) _mapPlatformException(PlatformException error) {
    final code = error.code.toLowerCase();

    if (code.contains('notavailable') || code.contains('not_available')) {
      return (BiometricAuthStatus.notAvailable, 'Biometric not available');
    }

    if (code.contains('notenrolled') || code.contains('not_enrolled')) {
      return (
        BiometricAuthStatus.notEnrolled,
        'Please enable fingerprint/face in device settings',
      );
    }

    if (code.contains('lockedout') || code.contains('lockout')) {
      return (
        BiometricAuthStatus.lockedOut,
        'Too many failed attempts. Try again later.',
      );
    }

    if (code.contains('permanentlylockedout') ||
        code.contains('permanently_locked_out')) {
      return (
        BiometricAuthStatus.permanentlyLockedOut,
        'Biometric locked. Please unlock in device settings.',
      );
    }

    if (code.contains('passcodenotset') || code.contains('passcode_not_set')) {
      return (
        BiometricAuthStatus.notAvailable,
        'Please set a device passcode to enable biometrics.',
      );
    }

    if (code.contains('usercancel') ||
        code.contains('user_cancel') ||
        code.contains('userCanceled'.toLowerCase()) ||
        code.contains('systemcancel') ||
        code.contains('system_cancel')) {
      return (BiometricAuthStatus.cancelled, 'Authentication cancelled');
    }

    return (
      BiometricAuthStatus.error,
      error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'Authentication failed',
    );
  }

  Future<bool?> _safeBool(Future<bool> Function() run) async {
    try {
      return await run();
    } catch (_) {
      return null;
    }
  }

  Future<List<BiometricType>> _safeList(
    Future<List<BiometricType>> Function() run,
  ) async {
    try {
      return await run();
    } catch (_) {
      return const [];
    }
  }
}
