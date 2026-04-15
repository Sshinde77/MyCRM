class ProjectDetailModel {
  const ProjectDetailModel({
    required this.id,
    required this.title,
    required this.customerId,
    required this.client,
    required this.status,
    required this.priority,
    required this.startDate,
    required this.deadline,
    required this.billingType,
    required this.totalRate,
    required this.estimatedHours,
    required this.progress,
    required this.description,
    required this.taskTotal,
    required this.taskCompleted,
    required this.taskRemaining,
    required this.taskInProgress,
    required this.taskNotStarted,
    required this.taskOverdue,
    required this.tags,
    required this.technologies,
    required this.members,
    required this.memberIds,
    required this.employeeRecords,
    required this.taskRecords,
    required this.fileRecords,
    required this.clientEmail,
    required this.clientPhone,
    required this.clientAddress,
  });

  final String id;
  final String title;
  final String customerId;
  final String client;
  final String status;
  final String priority;
  final String startDate;
  final String deadline;
  final String billingType;
  final String totalRate;
  final String estimatedHours;
  final double progress;
  final String description;
  final String taskTotal;
  final String taskCompleted;
  final String taskRemaining;
  final String taskInProgress;
  final String taskNotStarted;
  final String taskOverdue;
  final List<String> tags;
  final List<String> technologies;
  final List<String> members;
  final List<String> memberIds;
  final List<ProjectAssignedEmployee> employeeRecords;
  final List<ProjectTaskRecord> taskRecords;
  final List<ProjectFileRecord> fileRecords;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;

  factory ProjectDetailModel.fromJson(Map<String, dynamic> json) {
    final source = _mergeNestedProject(json);
    final statsMap = _readMap(source, const ['stats']);
    final progressMap = _readMap(statsMap, const ['progress']).isNotEmpty
        ? _readMap(statsMap, const ['progress'])
        : _readMap(source, const ['progress']);
    final tasksMap = _readMap(statsMap, const ['tasks']).isNotEmpty
        ? _readMap(statsMap, const ['tasks'])
        : _readMap(source, const ['tasks']);
    final customerMap = _readMap(source, const ['customer', 'client']);
    final memberEntries = _readObjectList(source, const [
      'assigned_members',
      'members',
      'staff',
      'team',
      'employees',
    ]);
    final taskEntries = _readObjectList(source, const [
      'task_list',
      'project_tasks',
      'tasks',
      'task_items',
      'todos',
    ]);
    final fileEntries = _readObjectList(source, const [
      'files',
      'project_files',
      'projectFiles',
      'documents',
      'project_documents',
      'projectDocuments',
      'attachments',
    ]);

    final rawProgress =
        _readValue(progressMap, const ['overall'], fallback: '').isNotEmpty
        ? _readValue(progressMap, const ['overall'])
        : _readValue(source, const [
            'progress',
            'completion',
            'completion_rate',
            'completion_percentage',
            'progress_percentage',
            'percentage',
          ]);

    return ProjectDetailModel(
      id: _readValue(source, const ['id', '_id', 'project_id']),
      title: _readValue(source, const [
        'title',
        'name',
        'project_name',
        'subject',
      ], fallback: 'Untitled Project'),
      customerId: _readValue(
        customerMap,
        const ['id', '_id', 'customer_id', 'client_id'],
        fallback: _readValue(source, const [
          'customer',
          'customer_id',
          'client_id',
        ]),
      ),
      client: _readValue(
        customerMap,
        const ['name'],
        fallback: _readValue(source, const [
          'client_name',
          'customer_name',
          'company',
          'name',
        ], fallback: 'Unknown Client'),
      ),
      status: _readValue(source, const [
        'status',
        'project_status',
        'stage',
      ], fallback: 'Unknown'),
      priority: _readValue(source, const [
        'priority',
        'priority_level',
      ], fallback: 'Normal'),
      startDate: _readValue(source, const [
        'start_date',
        'startDate',
        'created_at',
        'createdAt',
      ], fallback: 'Not set'),
      deadline: _readValue(source, const [
        'deadline',
        'due_date',
        'end_date',
        'endDate',
      ], fallback: 'Not set'),
      billingType: _readValue(source, const ['billing_type', 'billingType']),
      totalRate: _readValue(source, const ['total_rate', 'totalRate']),
      estimatedHours: _readValue(source, const [
        'estimated_hours',
        'estimatedHours',
      ]),
      progress: _normalizeProgress(rawProgress),
      description: _readValue(source, const [
        'description',
        'details',
        'summary',
      ], fallback: 'No description available.'),
      taskTotal: _readValue(tasksMap, const ['total'], fallback: '0'),
      taskCompleted: _readValue(tasksMap, const ['completed'], fallback: '0'),
      taskRemaining: _readValue(tasksMap, const ['remaining'], fallback: '0'),
      taskInProgress: _readValue(tasksMap, const [
        'in_progress',
      ], fallback: '0'),
      taskNotStarted: _readValue(tasksMap, const [
        'not_started',
      ], fallback: '0'),
      taskOverdue: _readValue(tasksMap, const ['overdue'], fallback: '0'),
      tags: _readList(source, const ['tags']),
      technologies: _readList(source, const [
        'technologies',
        'technology',
        'tech_stack',
      ]),
      members: _readList(source, const [
        'members',
        'staff',
        'team',
        'assigned_members',
      ]),
      memberIds: _readIdList(source, const [
        'members',
        'staff',
        'team',
        'assigned_members',
      ]),
      employeeRecords: memberEntries
          .map(
            (entry) => ProjectAssignedEmployee.fromJson(
              entry,
              defaultStartDate: _readValue(source, const [
                'start_date',
                'startDate',
                'created_at',
                'createdAt',
              ]),
              defaultDeadline: _readValue(source, const [
                'deadline',
                'due_date',
                'end_date',
                'endDate',
              ]),
            ),
          )
          .where((entry) => entry.name.isNotEmpty)
          .toList(),
      taskRecords: taskEntries
          .map((entry) => ProjectTaskRecord.fromJson(entry))
          .where((entry) => entry.title.isNotEmpty || entry.id.isNotEmpty)
          .toList(),
      fileRecords: fileEntries
          .map((entry) => ProjectFileRecord.fromJson(entry))
          .where((entry) => entry.name.isNotEmpty || entry.url.isNotEmpty)
          .toList(),
      clientEmail: _readValue(customerMap, const [
        'email',
      ], fallback: 'Not available'),
      clientPhone: _readValue(source, const [
        'client_phone',
        'phone',
      ], fallback: 'Not available'),
      clientAddress: _readValue(source, const [
        'client_address',
        'address',
      ], fallback: 'Not available'),
    );
  }

  static Map<String, dynamic> _mergeNestedProject(Map<String, dynamic> json) {
    final projectMap = _readMap(json, const ['project']);
    if (projectMap.isEmpty) return json;

    return {
      ...json,
      ...projectMap,
      'project': projectMap,
      'stats': _readMap(json, const ['stats']),
      'progress': _readMap(json, const ['progress']).isNotEmpty
          ? _readMap(json, const ['progress'])
          : _readMap(projectMap, const ['progress']),
      'tasks': _readMap(json, const ['tasks']).isNotEmpty
          ? _readMap(json, const ['tasks'])
          : _readMap(projectMap, const ['tasks']),
      'customer': _readMap(json, const ['customer']).isNotEmpty
          ? _readMap(json, const ['customer'])
          : _readMap(projectMap, const ['customer', 'client']),
    };
  }

  static Map<String, dynamic> _readMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return const <String, dynamic>{};
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
          'email',
          'phone',
          'address',
        ]);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return fallback;
  }

  static List<String> _readList(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value
            .map((item) {
              if (item is String) return item.trim();
              if (item is Map<String, dynamic>) {
                return _readValue(item, const [
                  'name',
                  'title',
                  'label',
                  'value',
                ]);
              }
              return item.toString().trim();
            })
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  static List<Map<String, dynamic>> _readObjectList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value.map<Map<String, dynamic>>((item) {
          if (item is Map<String, dynamic>) return item;
          if (item is String) return {'name': item, 'title': item};
          return {'value': item.toString()};
        }).toList();
      }
    }
    return const [];
  }

  static List<String> _readIdList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is! List) {
        continue;
      }

      final ids = value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return _readValue(item, const [
                'id',
                '_id',
                'staff_id',
                'user_id',
                'member_id',
                'value',
              ]);
            }
            final normalized = item.toString().trim();
            return normalized;
          })
          .where((item) => item.isNotEmpty)
          .toList();

      if (ids.isNotEmpty) {
        return ids;
      }
    }

    return const [];
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
}

class ProjectFileRecord {
  const ProjectFileRecord({
    required this.id,
    required this.name,
    required this.url,
    required this.sizeBytes,
    required this.uploadedOn,
  });

  final String id;
  final String name;
  final String url;
  final int? sizeBytes;
  final String uploadedOn;

  String get extension {
    final value = name.trim().isNotEmpty ? name.trim() : url.trim();
    final withoutQuery = value.split('?').first;
    final last = withoutQuery.split('/').last;
    final dot = last.lastIndexOf('.');
    if (dot <= 0 || dot == last.length - 1) return '';
    return last.substring(dot + 1).toLowerCase();
  }

  factory ProjectFileRecord.fromJson(Map<String, dynamic> json) {
    final url = ProjectDetailModel._readValue(json, const [
      'url',
      'file_url',
      'file_path',
      'filePath',
      'download_url',
      'downloadUrl',
      'link',
      'href',
      'path',
      'file',
      'value',
    ]);

    final name = ProjectDetailModel._readValue(json, const [
      'name',
      'filename',
      'file_name',
      'fileName',
      'original_name',
      'originalName',
      'title',
      'label',
    ], fallback: _inferName(url));

    return ProjectFileRecord(
      id: ProjectDetailModel._readValue(json, const [
        'id',
        'file_id',
        'fileId',
      ]),
      name: name,
      url: url,
      sizeBytes: _readInt(json, const [
        'size',
        'file_size',
        'fileSize',
        'bytes',
      ]),
      uploadedOn: ProjectDetailModel._readValue(json, const [
        'uploaded_on',
        'uploadedOn',
        'uploaded_at',
        'uploadedAt',
        'created_at',
        'createdAt',
        'date',
      ]),
    );
  }

  static String _inferName(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final withoutQuery = trimmed.split('?').first;
    final last = withoutQuery.split('/').last.trim();
    return last;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}

class ProjectAssignedEmployee {
  const ProjectAssignedEmployee({
    required this.name,
    required this.avatarUrl,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.team,
    required this.departments,
    required this.startDate,
    required this.deadline,
    required this.totalTimeHours,
  });

  final String name;
  final String avatarUrl;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String team;
  final List<String> departments;
  final String startDate;
  final String deadline;
  final String totalTimeHours;

  String get departmentLabel =>
      departments.isEmpty ? 'Not assigned' : departments.join(', ');

  factory ProjectAssignedEmployee.fromJson(
    Map<String, dynamic> json, {
    String defaultStartDate = 'Not set',
    String defaultDeadline = 'Not set',
  }) {
    final firstName = ProjectDetailModel._readValue(json, const [
      'first_name',
      'firstName',
    ]);
    final lastName = ProjectDetailModel._readValue(json, const [
      'last_name',
      'lastName',
    ]);
    final fullName = [
      firstName,
      lastName,
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();

    return ProjectAssignedEmployee(
      name: fullName.isNotEmpty
          ? fullName
          : ProjectDetailModel._readValue(json, const [
              'name',
              'full_name',
              'employee_name',
              'staff_name',
              'title',
            ]),
      avatarUrl: ProjectDetailModel._readValue(json, const [
        'avatar',
        'avatar_url',
        'image',
        'profile_image',
        'photo',
      ]),
      firstName: firstName,
      lastName: lastName,
      email: ProjectDetailModel._readValue(json, const [
        'email',
        'email_address',
      ], fallback: 'Not available'),
      phone: ProjectDetailModel._readValue(json, const [
        'phone',
        'mobile',
        'phone_number',
      ], fallback: 'Not available'),
      role: ProjectDetailModel._readValue(json, const [
        'role',
        'designation',
      ], fallback: 'Staff'),
      status: ProjectDetailModel._readValue(json, const [
        'status',
        'account_status',
      ], fallback: 'Unknown'),
      team: ProjectDetailModel._readValue(json, const [
        'team',
        'department',
        'department_name',
      ], fallback: 'Not assigned'),
      departments: ProjectDetailModel._readList(json, const ['departments']),
      startDate: ProjectDetailModel._readValue(json, const [
        'start_date',
        'startDate',
        'assigned_at',
      ], fallback: defaultStartDate.isEmpty ? 'Not set' : defaultStartDate),
      deadline: ProjectDetailModel._readValue(json, const [
        'deadline',
        'due_date',
        'end_date',
        'endDate',
      ], fallback: defaultDeadline.isEmpty ? 'Not set' : defaultDeadline),
      totalTimeHours: ProjectDetailModel._readValue(json, const [
        'total_time',
        'total_time_hours',
        'hours',
        'worked_hours',
      ], fallback: '0.0h'),
    );
  }
}

class ProjectTaskRecord {
  const ProjectTaskRecord({
    required this.id,
    required this.title,
    required this.createdOn,
    required this.priority,
    required this.status,
    required this.assigneeName,
    required this.assigneeAvatarUrl,
  });

  final String id;
  final String title;
  final String createdOn;
  final String priority;
  final String status;
  final String assigneeName;
  final String assigneeAvatarUrl;

  factory ProjectTaskRecord.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'];
    final assigneeMap = assignee is Map<String, dynamic>
        ? assignee
        : const <String, dynamic>{};

    return ProjectTaskRecord(
      id: ProjectDetailModel._readValue(json, const [
        'id',
        'task_id',
        'todo_id',
      ]),
      title: ProjectDetailModel._readValue(json, const [
        'title',
        'name',
        'task_title',
        'subject',
      ]),
      createdOn: ProjectDetailModel._readValue(json, const [
        'created_at',
        'created_on',
        'task_date',
        'date',
      ], fallback: 'Not set'),
      priority: ProjectDetailModel._readValue(json, const [
        'priority',
        'priority_level',
      ], fallback: 'Normal'),
      status: ProjectDetailModel._readValue(json, const [
        'status',
        'task_status',
      ], fallback: 'Unknown'),
      assigneeName: ProjectDetailModel._readValue(
        assigneeMap.isNotEmpty ? assigneeMap : json,
        const ['name', 'assignee_name', 'full_name', 'employee_name'],
        fallback: 'Unassigned',
      ),
      assigneeAvatarUrl: ProjectDetailModel._readValue(
        assigneeMap.isNotEmpty ? assigneeMap : json,
        const ['avatar', 'avatar_url', 'image', 'profile_image', 'photo'],
      ),
    );
  }
}
