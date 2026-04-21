import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app-level UI/security flags used by settings screens.
class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const String _darkModeEnabledKey = 'dark_mode_enabled';
  static const String _faceLockEnabledKey = 'face_lock_enabled';

  Future<bool> isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeEnabledKey) ?? false;
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeEnabledKey, enabled);
  }

  Future<bool> isFaceLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_faceLockEnabledKey) ?? false;
  }

  Future<void> setFaceLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_faceLockEnabledKey, enabled);
  }
}
