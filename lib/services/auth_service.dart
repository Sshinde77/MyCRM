import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/services/permission_service.dart';
import '../core/services/push_notification_service.dart';
import '../core/services/secure_storage_service.dart';
import '../models/login_response_model.dart';
import 'api_service.dart';

/// Handles token/biometric-flag state and session checks.
class AuthService {
  AuthService({ApiService? apiService, SecureStorageService? storage})
    : _apiService = apiService ?? ApiService.instance,
      _storage = storage ?? SecureStorageService.instance;

  final ApiService _apiService;
  final SecureStorageService _storage;

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(email: email, password: password);
    _emitAuthDebugLog(
      'Login API response: message=${response.message ?? 'null'}, '
      'user_id=${response.user.id}, user_name=${response.user.name}',
    );
    _emitAuthDebugLog(
      'Access token (login): ${response.accessToken ?? 'null'}',
    );
    unawaited(PushNotificationService.onUserLogin(userId: response.user.id));
    return response;
  }

  Future<bool> hasAccessToken() async {
    await _storage.migrateLegacyPrefsIfNeeded();
    return await _storage.hasAccessToken();
  }

  Future<bool> isBiometricEnabled() async {
    await _storage.migrateLegacyPrefsIfNeeded();
    return await _storage.isBiometricEnabled();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.setBiometricEnabled(enabled);
  }

  Future<bool> validateSession() async {
    try {
      await _apiService.getCurrentUser();
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> shouldShowBiometricLoginButton() async {
    final hasToken = await hasAccessToken();
    if (!hasToken) {
      await setBiometricEnabled(false);
      return false;
    }

    final enabled = await isBiometricEnabled();
    if (!enabled) {
      return false;
    }

    final valid = await validateSession();
    if (!valid) {
      return false;
    }

    return true;
  }

  Future<void> clearSession({bool clearBiometricFlag = true}) async {
    await _apiService.clearStoredAuth();
    PermissionService.clearCachedUser();
    if (clearBiometricFlag) {
      await setBiometricEnabled(false);
    }
  }

  Future<void> logout() async {
    try {
      await PushNotificationService.onUserLogout();
      await _apiService.logout();
      PermissionService.clearCachedUser();
    } finally {
      await setBiometricEnabled(false);
    }
  }

  void _emitAuthDebugLog(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }
}
