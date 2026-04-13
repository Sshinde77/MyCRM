class StaffMemberModel {
  const StaffMemberModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.team,
    this.status,
    this.lastLogin,
    this.profileImage,
    this.departments = const [],
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? team;
  final String? status;
  final String? lastLogin;
  final String? profileImage;
  final List<String> departments;

  bool get isActive => (status ?? '').toLowerCase() == 'active';

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) {
    final firstName = _readNullableString(json, ['firstName', 'first_name']);
    final lastName = _readNullableString(json, ['lastName', 'last_name']);

    final combinedName = [firstName, lastName]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ');

    return StaffMemberModel(
      id: _readString(json, ['id', '_id', 'staffId', 'staff_id']),
      name: combinedName.isNotEmpty
          ? combinedName
          : _readString(json, ['name', 'fullName', 'full_name']),
      email: _readString(json, ['email', 'emailAddress', 'email_address']),
      phone: _readNullableString(json, ['phone', 'mobile', 'phone_number']),
      role: _readNullableString(json, ['role', 'designation']),
      team: _readNullableString(json, ['team', 'department', 'departmentName']),
      status: _readNullableString(json, ['status', 'accountStatus']),
      lastLogin: _readNullableString(json, [
        'lastLogin',
        'last_login',
        'lastSeen',
        'updatedAt',
        'updated_at',
      ]),
      profileImage: _readNullableString(json, [
        'profileImage',
        'profile_image',
        'avatar',
        'image',
      ]),
      departments: _readDepartments(json['departments']),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
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

  static List<String> _readDepartments(dynamic rawDepartments) {
    if (rawDepartments is List) {
      return rawDepartments
          .map((item) {
            if (item is String) return item.trim();
            if (item is Map<String, dynamic>) {
              return _readString(item, ['name', 'title', 'department']);
            }
            if (item is Map) {
              final normalized = item.map(
                (key, value) => MapEntry(key.toString(), value),
              );
              return _readString(normalized, ['name', 'title', 'department']);
            }
            return item.toString().trim();
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }
}
