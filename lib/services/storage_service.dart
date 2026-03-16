import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper around SharedPreferences for local key/value storage.
class StorageService {
  late SharedPreferences _prefs;

  /// Must be called before using any getter/setter methods.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Saves a string value under the provided key.
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// Reads a string value if it exists.
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Deletes a stored value for the given key.
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
}
