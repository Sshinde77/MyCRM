class RoleModel {
  const RoleModel({
    required this.id,
    required this.name,
    this.description,
    this.status,
    this.permissionsCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final String? status;
  final int permissionsCount;

  bool get isActive {
    final value = status?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return true;
    }

    return value == 'active' ||
        value == 'enabled' ||
        value == '1' ||
        value == 'true';
  }

  String get displayName => name.trim().isEmpty ? 'Unnamed Role' : name.trim();

  String get displayDescription {
    final value = description?.trim();
    return value == null || value.isEmpty ? 'No description available.' : value;
  }

  String get displayStatus {
    final value = status?.trim();
    if (value == null || value.isEmpty) {
      return isActive ? 'Active' : 'Inactive';
    }
    return value[0].toUpperCase() + value.substring(1);
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return [id, name, description, status].whereType<String>().any(
      (value) => value.toLowerCase().contains(normalized),
    );
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final source = _extractSource(json);
    return RoleModel(
      id: _readString(source, const ['id', '_id', 'role_id', 'roleId']),
      name: _readString(source, const [
        'name',
        'role',
        'role_name',
        'roleName',
        'display_name',
        'displayName',
        'title',
      ]),
      description: _readNullableString(source, const [
        'description',
        'details',
        'summary',
        'note',
      ]),
      status: _readNullableString(source, const [
        'status',
        'state',
        'is_active',
        'isActive',
        'active',
      ]),
      permissionsCount: _readPermissionsCount(source),
    );
  }

  static Map<String, dynamic> _extractSource(Map<String, dynamic> json) {
    for (final key in const ['role', 'data', 'item', 'result', 'attributes']) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    return json;
  }

  static int _readPermissionsCount(Map<String, dynamic> json) {
    final direct = _readNullableInt(json, const [
      'permissions_count',
      'permissionsCount',
      'permission_count',
      'permissionCount',
      'total_permissions',
      'totalPermissions',
    ]);
    if (direct != null) {
      return direct;
    }

    for (final key in const ['permissions', 'permission', 'modules']) {
      final value = json[key];
      if (value is List) {
        return value.length;
      }
      if (value is Map) {
        return value.length;
      }
    }

    return 0;
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map || value is List || value == null) {
        continue;
      }

      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) {
        return normalized;
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

  static int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
