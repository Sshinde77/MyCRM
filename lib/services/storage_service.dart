import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper around SharedPreferences for local key/value storage.
class StorageService {
  static const String authTokenKey = 'auth_token';
  static const String currentUserKey = 'current_user';

  static final StorageService instance = StorageService._internal();

  StorageService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// Must be called before using any getter/setter methods.
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  Future<void> ensureInitialized() async {
    if (_isInitialized) {
      return;
    }
    await init();
  }

  /// Saves a string value under the provided key.
  Future<bool> setString(String key, String value) async {
    await ensureInitialized();
    return await _prefs.setString(key, value);
  }

  /// Reads a string value if it exists.
  String? getString(String key) {
    if (!_isInitialized) {
      return null;
    }
    return _prefs.getString(key);
  }

  /// Deletes a stored value for the given key.
  Future<bool> remove(String key) async {
    await ensureInitialized();
    return await _prefs.remove(key);
  }
}
