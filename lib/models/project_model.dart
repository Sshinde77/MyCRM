class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.title,
    required this.client,
    required this.status,
    required this.startDate,
    required this.deadline,
    required this.progress,
    this.members = const [],
  });

  final String id;
  final String title;
  final String client;
  final String status;
  final String startDate;
  final String deadline;
  final double progress;
  final List<ProjectMemberModel> members;

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final progressMap = _readMap(json, const ['progress']);
    final rawProgress = _readValue(progressMap, const ['overall']).isNotEmpty
        ? _readValue(progressMap, const ['overall'])
        : _readValue(json, const [
            'progress',
            'completion',
            'completion_rate',
            'completion_percentage',
            'progress_percentage',
            'percentage',
          ]);

    return ProjectModel(
      id: _readValue(json, const ['id', '_id', 'project_id']),
      title: _readValue(json, const [
        'title',
        'name',
        'project_name',
        'subject',
      ], fallback: 'Untitled Project'),
      client: _readValue(json, const [
        'client_name',
        'client',
        'customer_name',
        'customer',
        'company',
      ], fallback: 'Unknown Client'),
      status: _readValue(json, const [
        'status',
        'project_status',
        'stage',
      ], fallback: 'Unknown'),
      startDate: _readValue(json, const [
        'start_date',
        'startDate',
        'created_at',
        'createdAt',
      ], fallback: 'Not set'),
      deadline: _readValue(json, const [
        'deadline',
        'due_date',
        'end_date',
        'endDate',
      ], fallback: 'Not set'),
      progress: _normalizeProgress(rawProgress),
      members: _readMembers(json),
    );
  }

  static Map<String, dynamic> _readMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map) {
        return value.map(
          (nestedKey, nestedValue) =>
              MapEntry(nestedKey.toString(), nestedValue),
        );
      }
    }

    return const {};
  }

  static String _readValue(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      if (value is num) {
        return value.toString();
      }

      if (value is Map<String, dynamic>) {
        final nested = _readValue(value, const [
          'name',
          'title',
          'label',
          'value',
        ]);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return fallback;
  }

  static double _normalizeProgress(String raw) {
    final normalized = raw.replaceAll('%', '').trim();
    final value = double.tryParse(normalized);
    if (value == null) return 0;
    if (value > 1) {
      return (value / 100).clamp(0, 1);
    }
    return value.clamp(0, 1);
  }

  static List<ProjectMemberModel> _readMembers(Map<String, dynamic> json) {
    for (final key in const [
      'assigned_members',
      'members',
      'staff',
      'team',
      'employees',
    ]) {
      final value = json[key];
      if (value is! List) {
        continue;
      }

      return value
          .map(ProjectMemberModel.fromDynamic)
          .where((member) => member.name.isNotEmpty)
          .toList();
    }

    return const [];
  }
}

class ProjectMemberModel {
  const ProjectMemberModel({
    required this.id,
    required this.name,
    this.profileImage,
    this.status,
  });

  final String id;
  final String name;
  final String? profileImage;
  final String? status;

  bool get isActive => (status ?? '').trim().toLowerCase() == 'active';

  factory ProjectMemberModel.fromDynamic(dynamic source) {
    if (source is String) {
      final name = source.trim();
      return ProjectMemberModel(id: name, name: name);
    }

    if (source is Map) {
      final json = source.map((key, value) => MapEntry(key.toString(), value));
      final firstName = ProjectModel._readValue(json, const [
        'first_name',
        'firstName',
      ]);
      final lastName = ProjectModel._readValue(json, const [
        'last_name',
        'lastName',
      ]);
      final combinedName = [
        firstName,
        lastName,
      ].where((value) => value.trim().isNotEmpty).join(' ').trim();
      final name = combinedName.isNotEmpty
          ? combinedName
          : ProjectModel._readValue(json, const [
              'name',
              'full_name',
              'employee_name',
              'staff_name',
              'title',
            ]);

      return ProjectMemberModel(
        id: ProjectModel._readValue(json, const [
          'id',
          '_id',
          'staff_id',
          'user_id',
          'member_id',
        ], fallback: name),
        name: name,
        profileImage: _readNullableValue(json, const [
          'profile_image',
          'profileImage',
          'avatar',
          'avatar_url',
          'image',
          'photo',
        ]),
        status: _readNullableValue(json, const ['status', 'account_status']),
      );
    }

    final name = source.toString().trim();
    return ProjectMemberModel(id: name, name: name);
  }

  static String? _readNullableValue(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = ProjectModel._readValue(json, keys);
    return value.isEmpty ? null : value;
  }
}
