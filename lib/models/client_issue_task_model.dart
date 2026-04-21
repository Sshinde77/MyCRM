class CreateClientIssueTaskRequest {
  const CreateClientIssueTaskRequest({
    required this.title,
    this.description,
    this.status,
    this.priority,
    this.assignedTo,
    this.startDate,
    this.dueDate,
    this.attachmentPaths = const [],
  });

  final String title;
  final String? description;
  final String? status;
  final String? priority;
  final String? assignedTo;
  final DateTime? startDate;
  final DateTime? dueDate;
  final List<String> attachmentPaths;
}

class ClientIssueTaskModel {
  const ClientIssueTaskModel({
    required this.id,
    required this.clientIssueId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assignedTo,
    required this.startDate,
    required this.dueDate,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientIssueId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String assignedTo;
  final String startDate;
  final String dueDate;
  final List<ClientIssueTaskAttachment> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClientIssueTaskModel.fromJson(Map<String, dynamic> json) {
    final attachmentValues = _readList(json, const [
      'attachments',
      'files',
      'documents',
    ]);

    return ClientIssueTaskModel(
      id: _readString(json, const ['id', 'task_id']),
      clientIssueId: _readString(json, const [
        'client_issue_id',
        'clientIssueId',
      ]),
      title: _readString(json, const ['title', 'task_title']),
      description: _readString(json, const ['description', 'task_description']),
      status: _readString(json, const ['status']),
      priority: _readString(json, const ['priority']),
      assignedTo: _readString(json, const ['assigned_to', 'assignee', 'staff']),
      startDate: _readString(json, const ['start_date']),
      dueDate: _readString(json, const ['due_date', 'deadline']),
      attachments: attachmentValues
          .map((entry) {
            if (entry is String) {
              final value = entry.trim();
              if (value.isEmpty) return null;
              return ClientIssueTaskAttachment(path: value, name: value);
            }
            if (entry is Map<String, dynamic>) {
              return ClientIssueTaskAttachment.fromJson(entry);
            }
            if (entry is Map) {
              return ClientIssueTaskAttachment.fromJson(
                entry.map((key, value) => MapEntry(key.toString(), value)),
              );
            }
            final value = entry.toString().trim();
            if (value.isEmpty) return null;
            return ClientIssueTaskAttachment(path: value, name: value);
          })
          .whereType<ClientIssueTaskAttachment>()
          .toList(growable: false),
      createdAt: _readDate(json, const ['created_at', 'createdAt']),
      updatedAt: _readDate(json, const ['updated_at', 'updatedAt']),
    );
  }

  static String _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null) {
        final normalized = value.toString().trim();
        if (normalized.isNotEmpty) return normalized;
      }
    }
    return '';
  }

  static List<dynamic> _readList(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is List) {
        return value;
      }
    }
    return const <dynamic>[];
  }

  static DateTime? _readDate(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is DateTime) return value;
      final normalized = value.toString().trim();
      if (normalized.isEmpty) continue;
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) return parsed;
    }
    return null;
  }
}

class ClientIssueTaskAttachment {
  const ClientIssueTaskAttachment({required this.path, required this.name});

  final String path;
  final String name;

  String get displayName {
    final normalizedName = name.trim();
    if (normalizedName.isNotEmpty) return normalizedName;
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) return 'Attachment';
    final segments = normalizedPath.split(RegExp(r'[\\/]'));
    return segments.isEmpty ? normalizedPath : segments.last;
  }

  factory ClientIssueTaskAttachment.fromJson(Map<String, dynamic> json) {
    final path = _readString(json, const [
      'path',
      'url',
      'file_path',
      'filePath',
    ]);
    final name = _readString(json, const ['name', 'file_name', 'fileName']);
    return ClientIssueTaskAttachment(path: path, name: name);
  }

  static String _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }
}
