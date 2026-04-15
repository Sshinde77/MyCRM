class ProjectIssueModel {
  const ProjectIssueModel({
    required this.id,
    required this.issueDescription,
    required this.priority,
    required this.status,
  });

  final String id;
  final String issueDescription;
  final String priority;
  final String status;

  factory ProjectIssueModel.fromJson(Map<String, dynamic> json) {
    String readValue(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is num) return value.toString();
      }
      return fallback;
    }

    return ProjectIssueModel(
      id: readValue(const ['id', '_id', 'issue_id']),
      issueDescription: readValue(const [
        'issue_description',
        'description',
        'details',
        'issue',
      ], fallback: 'Issue'),
      priority: readValue(const [
        'priority',
        'priority_level',
      ], fallback: 'medium'),
      status: readValue(const ['status', 'issue_status'], fallback: 'open'),
    );
  }
}
