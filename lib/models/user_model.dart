import 'dart:convert';

/// User model mapped from the authenticated user payload.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? roleId;
  final String? profilePicture;
  final List<String> permissions;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.roleId,
    this.profilePicture,
    this.permissions = const [],
  });

  /// Creates a user object from API JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final source = _extractUserSource(json);
    final roleSource = _extractRoleSource(source);

    return UserModel(
      id: _readString(source, ['id', '_id', 'user_id']),
      name: _readDisplayName(source),
      email: _readString(source, ['email', 'email_address']),
      phone: _readNullableString(source, ['phone', 'mobile', 'phone_number']),
      role:
          _readNullableString(source, ['role', 'user_role']) ??
          _readNullableString(roleSource, ['name', 'title', 'role']),
      roleId:
          _readNullableString(source, ['role_id', 'roleId']) ??
          _readNullableString(roleSource, ['id', 'role_id', 'roleId']),
      profilePicture: _readNullableString(source, [
        'profile_picture',
        'profilePicture',
        'profile_image',
        'avatar',
        'image',
      ]),
      permissions: _extractPermissionNames(json),
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
      'role_id': roleId,
      'profile_picture': profilePicture,
      'permissions': permissions,
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

  static Map<String, dynamic> _extractRoleSource(Map<String, dynamic> json) {
    for (final key in ['role', 'role_data', 'role_details']) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    return const {};
  }

  static String _readDisplayName(Map<String, dynamic> json) {
    final directName = _readString(json, ['name', 'full_name', 'username']);
    if (directName.isNotEmpty) {
      return directName;
    }

    final firstName = _readString(json, ['first_name', 'firstName']);
    final lastName = _readString(json, ['last_name', 'lastName']);
    final combined = [
      firstName,
      lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (combined.isNotEmpty) {
      return combined;
    }

    return _readString(json, ['email', 'email_address']);
  }

  static List<String> _extractPermissionNames(Map<String, dynamic> json) {
    final permissions = <String>{};

    void addPermission(dynamic value) {
      if (value is String) {
        final normalized = value.trim();
        if (normalized.isNotEmpty) {
          permissions.add(normalized);
        }
        return;
      }

      if (value is Map<String, dynamic>) {
        final name = _readString(value, ['name', 'permission', 'key']);
        if (name.isNotEmpty) {
          permissions.add(name);
        }
        return;
      }

      if (value is Map) {
        addPermission(value.map((key, item) => MapEntry(key.toString(), item)));
      }
    }

    void addPermissionList(dynamic value) {
      if (value is! List) {
        return;
      }
      for (final entry in value) {
        addPermission(entry);
      }
    }

    void addRolePermissions(dynamic roles) {
      if (roles is! List) {
        return;
      }

      for (final role in roles) {
        final roleMap = role is Map<String, dynamic>
            ? role
            : role is Map
            ? role.map((key, item) => MapEntry(key.toString(), item))
            : const <String, dynamic>{};
        addPermissionList(roleMap['permissions']);
      }
    }

    addPermissionList(json['permissions']);
    addRolePermissions(json['roles']);

    final nestedData = json['data'];
    if (nestedData is Map<String, dynamic>) {
      addPermissionList(nestedData['permissions']);
      addRolePermissions(nestedData['roles']);
      final nestedUser = nestedData['user'];
      if (nestedUser is Map<String, dynamic>) {
        addPermissionList(nestedUser['permissions']);
        addRolePermissions(nestedUser['roles']);
      }
    } else if (nestedData is Map) {
      final normalized = nestedData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      addPermissionList(normalized['permissions']);
      addRolePermissions(normalized['roles']);
      final nestedUser = normalized['user'];
      if (nestedUser is Map<String, dynamic>) {
        addPermissionList(nestedUser['permissions']);
        addRolePermissions(nestedUser['roles']);
      } else if (nestedUser is Map) {
        final normalizedUser = nestedUser.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        addPermissionList(normalizedUser['permissions']);
        addRolePermissions(normalizedUser['roles']);
      }
    }

    return permissions.toList(growable: false)..sort();
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map || value is List || value == null) {
        continue;
      }
      if (value.toString().trim().isNotEmpty) {
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
