class ProjectMilestoneModel {
  const ProjectMilestoneModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dueDate,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String dueDate;

  factory ProjectMilestoneModel.fromJson(Map<String, dynamic> json) {
    String readValue(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is num) return value.toString();
      }
      return fallback;
    }

    String formatDueDate(String raw) {
      final value = raw.trim();
      if (value.isEmpty) return '';
      final plainDateMatch = RegExp(
        r'^(\d{4})-(\d{2})-(\d{2})$',
      ).firstMatch(value);
      if (plainDateMatch != null) {
        return '${plainDateMatch.group(3)}-${plainDateMatch.group(2)}-${plainDateMatch.group(1)}';
      }
      final parsed = DateTime.tryParse(value);
      if (parsed == null) return value;
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      return '$day-$month-${parsed.year}';
    }

    return ProjectMilestoneModel(
      id: readValue(const ['id', '_id', 'milestone_id']),
      title: readValue(const [
        'title',
        'name',
        'milestone_title',
      ], fallback: 'Milestone'),
      description: readValue(const [
        'description',
        'details',
        'milestone_description',
      ]),
      status: readValue(const [
        'status',
        'milestone_status',
      ], fallback: 'Pending'),
      dueDate: formatDueDate(
        readValue(const ['due_date', 'dueDate', 'deadline', 'target_date']),
      ),
    );
  }
}
