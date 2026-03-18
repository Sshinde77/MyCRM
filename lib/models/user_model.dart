import 'dart:convert';

/// User model mapped from the authenticated user payload.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.profilePicture,
  });

  /// Creates a user object from API JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final source = _extractUserSource(json);

    return UserModel(
      id: _readString(source, ['id', '_id', 'user_id']),
      name: _readString(source, ['name', 'full_name', 'username']),
      email: _readString(source, ['email', 'email_address']),
      phone: _readNullableString(source, ['phone', 'mobile', 'phone_number']),
      role: _readNullableString(source, ['role', 'user_role']),
      profilePicture: _readNullableString(
        source,
        ['profile_picture', 'profilePicture', 'avatar', 'image'],
      ),
    );
  }

  /// Converts the model back into JSON for requests/storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profile_picture': profilePicture,
    };
  }

  /// Serializes the user for local persistence.
  String toRawJson() => jsonEncode(toJson());

  /// Restores a persisted user payload.
  factory UserModel.fromRawJson(String source) =>
      UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  static Map<String, dynamic> _extractUserSource(Map<String, dynamic> json) {
    final nestedData = json['data'];
    if (nestedData is Map<String, dynamic>) {
      final nestedUser = nestedData['user'];
      if (nestedUser is Map<String, dynamic>) {
        return nestedUser;
      }
      return nestedData;
    }

    final nestedUser = json['user'];
    if (nestedUser is Map<String, dynamic>) {
      return nestedUser;
    }

    return json;
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = _readString(json, keys);
    return value.isEmpty ? null : value;
  }
}
