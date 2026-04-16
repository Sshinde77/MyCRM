import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../core/services/biometric_service.dart';
import '../routes/app_routes.dart';

class BiometricGateScreen extends StatefulWidget {
  const BiometricGateScreen({super.key});

  @override
  State<BiometricGateScreen> createState() => _BiometricGateScreenState();
}

class _BiometricGateScreenState extends State<BiometricGateScreen> {
  final AuthController _authController = Get.find<AuthController>();

  bool _isAuthenticating = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAuth();
    });
  }

  Future<void> _startAuth() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = null;
    });

    final result = await _authController.authenticateWithBiometrics();

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _isAuthenticating = false;
        _statusMessage = _mapMessage(result);
      });
      return;
    }

    final ok = await _authController.validateSession();
    if (!mounted) return;

    if (!ok) {
      await _authController.clearLocalSession();
      setState(() {
        _isAuthenticating = false;
        _statusMessage = 'Session expired. Please login with password.';
      });
      return;
    }

    _authController.goToDashboard();
  }

  String _mapMessage(BiometricAuthResult result) {
    switch (result.status) {
      case BiometricAuthStatus.notAvailable:
      case BiometricAuthStatus.deviceNotSupported:
        return 'Biometric not available';
      case BiometricAuthStatus.notEnrolled:
        return 'Please enable fingerprint/face in device settings';
      case BiometricAuthStatus.lockedOut:
      case BiometricAuthStatus.permanentlyLockedOut:
        return result.message ?? 'Too many failed attempts. Try again later.';
      case BiometricAuthStatus.cancelled:
        return 'Authentication cancelled';
      case BiometricAuthStatus.failed:
      case BiometricAuthStatus.error:
      case BiometricAuthStatus.success:
        return result.message ?? 'Authentication failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18C6D3).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      color: const Color(0xFF18C6D3),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Unlock MyCRM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF153A63),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAuthenticating
                        ? 'Waiting for fingerprint/face authentication...'
                        : (_statusMessage ??
                              'Use biometrics to sign in, or login with password.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7C8F),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_isAuthenticating)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _startAuth,
                            child: const Text('Try Again'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Get.offAllNamed(AppRoutes.login);
                            },
                            child: const Text('Login with Password'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
