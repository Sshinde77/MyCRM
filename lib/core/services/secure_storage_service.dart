import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure key/value storage using platform-backed encryption (Keychain/Keystore).
class SecureStorageService {
  SecureStorageService._internal()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  static final SecureStorageService instance = SecureStorageService._internal();

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String currentUserKey = 'current_user';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String biometricPromptShownKey = 'biometric_prompt_shown';
  static const String fcmTokenKey = 'fcm_token';
  static const String fcmTokenSyncedUserIdKey = 'fcm_token_synced_user_id';

  static const String _legacyAuthTokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  Future<void> migrateLegacyPrefsIfNeeded() async {
    final existingAccess = await read(accessTokenKey);
    if (existingAccess != null && existingAccess.isNotEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_legacyAuthTokenKey);
    if (legacyToken != null && legacyToken.trim().isNotEmpty) {
      await write(accessTokenKey, legacyToken.trim());
      await prefs.remove(_legacyAuthTokenKey);
    }

    final legacyUser = prefs.getString(currentUserKey);
    if (legacyUser != null && legacyUser.trim().isNotEmpty) {
      await write(currentUserKey, legacyUser.trim());
      await prefs.remove(currentUserKey);
    }
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await write(biometricEnabledKey, enabled ? 'true' : 'false');
  }

  Future<bool> isBiometricEnabled() async {
    final raw = await read(biometricEnabledKey);
    return raw == 'true';
  }

  Future<void> setBiometricPromptShown(bool shown) async {
    await write(biometricPromptShownKey, shown ? 'true' : 'false');
  }

  Future<bool> isBiometricPromptShown() async {
    final raw = await read(biometricPromptShownKey);
    return raw == 'true';
  }

  Future<bool> hasAccessToken() async {
    final token = await read(accessTokenKey);
    return token != null && token.trim().isNotEmpty;
  }
}
