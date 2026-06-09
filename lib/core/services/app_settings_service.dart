import 'voice_notification_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app-level UI/security flags used by settings screens.
class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const String _darkModeEnabledKey = 'dark_mode_enabled';
  static const String _faceLockEnabledKey = 'face_lock_enabled';
  // ==================== Dark Mode ====================

  Future<bool> isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeEnabledKey) ?? false;
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeEnabledKey, enabled);
  }

  // ==================== Face Lock ====================

  Future<bool> isFaceLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_faceLockEnabledKey) ?? false;
  }

  Future<void> setFaceLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_faceLockEnabledKey, enabled);
  }

  // ==================== Voice Notifications ====================

  /// Check if voice notifications are enabled
  /// Default: false (disabled)
  Future<bool> isVoiceNotificationsEnabled() async {
    return VoiceNotificationSettings.instance.isEnabled();
  }

  /// Enable or disable voice notifications
  Future<void> setVoiceNotificationsEnabled(bool enabled) async {
    await VoiceNotificationSettings.instance.setEnabled(enabled);
  }
}
