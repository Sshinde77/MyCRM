class ClientIssueModel {
  const ClientIssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.clientName,
    required this.projectName,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.assignedTeam,
    required this.assignedTo,
    required this.assignedBy,
  });

  final String id;
  final String title;
  final String description;
  final String clientName;
  final String projectName;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final String assignedTeam;
  final String assignedTo;
  final String assignedBy;

  String get displayId => id.isEmpty ? '#ISS' : '#ISS-$id';

  String get displayTitle {
    final normalized = title.trim();
    if (normalized.isNotEmpty) return normalized;
    final desc = description.trim();
    return desc.isEmpty ? 'Client Issue' : desc;
  }

  String get displayDescription {
    final normalized = description.trim();
    return normalized.isEmpty ? 'No description available.' : normalized;
  }

  String get displayClient {
    final normalized = clientName.trim();
    return normalized.isEmpty ? 'Unknown client' : normalized;
  }

  String get displayProject {
    final normalized = projectName.trim();
    return normalized.isEmpty ? 'Project not available' : normalized;
  }

  String get displayPriority {
    final normalized = priority.trim();
    return normalized.isEmpty ? 'Medium' : _toTitleCase(normalized);
  }

  String get displayStatus {
    final normalized = status.trim();
    return normalized.isEmpty ? 'Open' : _toTitleCase(normalized);
  }

  String get displayDate {
    final date = createdAt;
    if (date == null) return 'N/A';
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    return [
      id,
      title,
      description,
      clientName,
      projectName,
      priority,
      status,
      assignedTeam,
      assignedTo,
      assignedBy,
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  factory ClientIssueModel.fromJson(Map<String, dynamic> json) {
    final source = _extractSource(json);
    final client = _readNestedMap(source, const ['client', 'customer']);
    final project = _readNestedMap(source, const ['project']);
    final latestAssignment = _readNestedMap(source, const [
      'latest_assignment',
      'latestAssignment',
      'assignment',
    ]);
    final assignedByMap = _readNestedMap(source, const [
      'assigned_by',
      'assignedBy',
      'created_by',
      'createdBy',
      'user',
      'assigned_by_user',
      'assignedByUser',
    ]);
    final latestAssignedBy = _readNestedMap(latestAssignment, const [
      'assigned_by_user',
      'assignedByUser',
      'assigned_by',
      'assignedBy',
      'user',
    ]);

    return ClientIssueModel(
      id: _readString(source, const ['id', '_id', 'issue_id', 'issueId']),
      title: _readString(source, const [
        'title',
        'subject',
        'issue_title',
        'issueTitle',
        'issue',
      ]),
      description: _readString(source, const [
        'issue_description',
        'issueDescription',
        'description',
        'details',
        'message',
        'remark',
      ]),
      clientName: _firstNonEmpty([
        _readString(source, const [
          'client_name',
          'clientName',
          'customer_name',
          'customerName',
        ]),
        _readString(client, const [
          'name',
          'cname',
          'client_name',
          'clientName',
          'company_name',
          'companyName',
        ]),
      ]),
      projectName: _firstNonEmpty([
        _readString(source, const [
          'project_name',
          'projectName',
          'project',
          'project_title',
          'projectTitle',
        ]),
        _readString(project, const ['name', 'title', 'project_name']),
      ]),
      priority: _readString(source, const [
        'priority',
        'priority_level',
        'priorityLevel',
      ]),
      status: _readString(source, const ['status', 'issue_status']),
      createdAt: _readDateTime(source, const [
        'created_at',
        'createdAt',
        'date',
        'issue_date',
        'issueDate',
      ]),
      assignedTeam: _firstNonEmpty([
        _readString(source, const [
          'team',
          'team_name',
          'teamName',
          'assigned_team',
          'assignedTeam',
          'department',
        ]),
        _readString(latestAssignment, const [
          'team',
          'team_name',
          'teamName',
          'assigned_team',
          'assignedTeam',
        ]),
      ]),
      assignedTo: _firstNonEmpty([
        _readAssignedTo(source),
        _readAssignedTo(latestAssignment),
        _readString(latestAssignment, const [
          'assigned_staff',
          'assignedStaff',
          'assigned_to',
          'assignedTo',
        ]),
      ]),
      assignedBy: _firstNonEmpty([
        _readString(source, const ['assigned_by_name', 'assignedByName']),
        _readString(latestAssignment, const [
          'assigned_by_name',
          'assignedByName',
        ]),
        _readString(latestAssignedBy, const [
          'name',
          'full_name',
          'first_name',
          'username',
        ]),
        _readString(assignedByMap, const [
          'name',
          'full_name',
          'first_name',
          'username',
        ]),
      ]),
    );
  }

  static Map<String, dynamic> _extractSource(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    for (final key in const [
      'client_issue',
      'clientIssue',
      'issue',
      'data',
      'item',
      'result',
      'attributes',
    ]) {
      final value = normalized[key];
      if (value is Map<String, dynamic>) {
        final merged = Map<String, dynamic>.from(normalized);
        merged.addAll(value);
        return merged;
      }
      if (value is Map) {
        final merged = Map<String, dynamic>.from(normalized);
        merged.addAll(value.map((key, value) => MapEntry(key.toString(), value)));
        return merged;
      }
    }
    return normalized;
  }

  static Map<String, dynamic> _readNestedMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    return const <String, dynamic>{};
  }

  static String _readAssignedTo(Map<String, dynamic> json) {
    final direct = _readString(json, const [
      'assigned_to_name',
      'assignedToName',
      'assigned_to',
      'assignedTo',
      'assignee',
    ]);
    if (direct.isNotEmpty) return direct;

    final assigned = json['assigned_to'] ?? json['assignedTo'] ?? json['assignees'];
    if (assigned is List) {
      final names = assigned
          .map((entry) {
            if (entry is Map<String, dynamic>) {
              return _readString(entry, const [
                'name',
                'full_name',
                'first_name',
                'username',
              ]);
            }
            if (entry is Map) {
              return _readString(
                entry.map((key, value) => MapEntry(key.toString(), value)),
                const ['name', 'full_name', 'first_name', 'username'],
              );
            }
            return entry.toString().trim();
          })
          .where((entry) => entry.isNotEmpty)
          .toList();
      return names.join(', ');
    }

    if (assigned is Map<String, dynamic>) {
      return _readString(assigned, const [
        'name',
        'full_name',
        'first_name',
        'username',
      ]);
    }

    return '';
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null || value is Map || value is List) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return '';
  }

  static DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is DateTime) return value;
      if (value == null) continue;
      final normalized = value.toString().trim();
      if (normalized.isEmpty) continue;
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) return parsed;

      final ddMmYyyy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(
        normalized,
      );
      if (ddMmYyyy != null) {
        return DateTime.tryParse(
          '${ddMmYyyy.group(3)}-${ddMmYyyy.group(2)}-${ddMmYyyy.group(1)}',
        );
      }
    }
    return null;
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  static String _toTitleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }
}

class ClientIssueIndexData {
  const ClientIssueIndexData({
    required this.issues,
    required this.projects,
    required this.customers,
  });

  final List<ClientIssueModel> issues;
  final List<ClientIssueSelectOption> projects;
  final List<ClientIssueSelectOption> customers;
}

class ClientIssueSelectOption {
  const ClientIssueSelectOption({required this.id, required this.name});

  final String id;
  final String name;

  String get displayName {
    final normalized = name.trim();
    return normalized.isEmpty ? 'Option #$id' : normalized;
  }

  factory ClientIssueSelectOption.projectFromJson(Map<String, dynamic> json) {
    return ClientIssueSelectOption(
      id: _readString(json, const ['id', '_id', 'project_id', 'projectId']),
      name: _readString(json, const [
        'project_name',
        'projectName',
        'name',
        'title',
      ]),
    );
  }

  factory ClientIssueSelectOption.customerFromJson(Map<String, dynamic> json) {
    return ClientIssueSelectOption(
      id: _readString(json, const [
        'id',
        '_id',
        'customer_id',
        'customerId',
        'client_id',
        'clientId',
      ]),
      name: _readString(json, const [
        'client_name',
        'clientName',
        'customer_name',
        'customerName',
        'contact_person',
        'name',
      ]),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null || value is Map || value is List) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return '';
  }
}
