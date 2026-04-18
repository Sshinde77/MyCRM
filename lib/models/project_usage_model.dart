class ProjectUsageModel {
  const ProjectUsageModel({required this.statuses});

  final List<ProjectUsageStat> statuses;

  int get totalTasks =>
      statuses.fold<int>(0, (sum, item) => sum + item.taskCount);

  factory ProjectUsageModel.fromJson(Map<String, dynamic> json) {
    final source = _extractUsageSource(json);
    final statuses = <ProjectUsageStat>[
      ProjectUsageStat.fromSource(
        key: 'not_started',
        label: 'Not Started',
        source: source,
        aliases: const ['not_started', 'notStarted', 'pending', 'todo'],
      ),
      ProjectUsageStat.fromSource(
        key: 'in_progress',
        label: 'In Progress',
        source: source,
        aliases: const ['in_progress', 'inProgress', 'progress', 'running'],
      ),
      ProjectUsageStat.fromSource(
        key: 'on_hold',
        label: 'On Hold',
        source: source,
        aliases: const ['on_hold', 'onHold', 'hold', 'paused'],
      ),
      ProjectUsageStat.fromSource(
        key: 'completed',
        label: 'Completed',
        source: source,
        aliases: const ['completed', 'complete', 'done', 'closed'],
      ),
      ProjectUsageStat.fromSource(
        key: 'cancelled',
        label: 'Cancelled',
        source: source,
        aliases: const ['cancelled', 'canceled', 'rejected'],
      ),
    ];

    final total = statuses.fold<int>(0, (sum, item) => sum + item.taskCount);
    if (total == 0) {
      return ProjectUsageModel(statuses: statuses);
    }

    return ProjectUsageModel(
      statuses: statuses
          .map(
            (item) => item.percentage > 0
                ? item
                : item.copyWith(percentage: (item.taskCount / total) * 100),
          )
          .toList(),
    );
  }

  static Map<String, dynamic> _extractUsageSource(Map<String, dynamic> json) {
    for (final key in const [
      'data',
      'usage',
      'statistics',
      'task_status_distribution',
      'taskStatusDistribution',
      'status_distribution',
      'statusDistribution',
    ]) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map((nestedKey, nestedValue) {
          return MapEntry(nestedKey.toString(), nestedValue);
        });
      }
    }
    return json;
  }
}

class ProjectUsageStat {
  const ProjectUsageStat({
    required this.key,
    required this.label,
    required this.taskCount,
    required this.percentage,
  });

  final String key;
  final String label;
  final int taskCount;
  final double percentage;

  ProjectUsageStat copyWith({
    String? key,
    String? label,
    int? taskCount,
    double? percentage,
  }) {
    return ProjectUsageStat(
      key: key ?? this.key,
      label: label ?? this.label,
      taskCount: taskCount ?? this.taskCount,
      percentage: percentage ?? this.percentage,
    );
  }

  factory ProjectUsageStat.fromSource({
    required String key,
    required String label,
    required Map<String, dynamic> source,
    required List<String> aliases,
  }) {
    final entry = _findEntry(source, aliases);
    if (entry.isEmpty) {
      return ProjectUsageStat(
        key: key,
        label: label,
        taskCount: 0,
        percentage: 0,
      );
    }

    final count = _readCount(entry);
    final percentage = _readPercentage(entry);
    return ProjectUsageStat(
      key: key,
      label: label,
      taskCount: count,
      percentage: percentage,
    );
  }

  static Map<String, dynamic> _findEntry(
    Map<String, dynamic> source,
    List<String> aliases,
  ) {
    for (final alias in aliases) {
      final direct = source[alias];
      if (direct is Map<String, dynamic>) {
        return direct;
      }
      if (direct is Map) {
        return direct.map((key, value) => MapEntry(key.toString(), value));
      }
      if (direct is num || direct is String) {
        return <String, dynamic>{'count': direct};
      }
    }

    for (final entry in source.entries) {
      final normalizedKey = entry.key.toLowerCase().trim();
      if (!aliases.any((alias) => alias.toLowerCase() == normalizedKey)) {
        continue;
      }

      final value = entry.value;
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map((key, item) => MapEntry(key.toString(), item));
      }
      if (value is num || value is String) {
        return <String, dynamic>{'count': value};
      }
    }

    return const <String, dynamic>{};
  }

  static int _readCount(Map<String, dynamic> source) {
    for (final key in const [
      'count',
      'task_count',
      'tasks',
      'value',
      'total',
    ]) {
      final value = source[key];
      final count = _toInt(value);
      if (count != null) {
        return count;
      }
    }
    return 0;
  }

  static double _readPercentage(Map<String, dynamic> source) {
    for (final key in const [
      'percentage',
      'percent',
      'ratio',
      'value_percentage',
    ]) {
      final value = source[key];
      final percentage = _toDouble(value);
      if (percentage != null) {
        return percentage;
      }
    }
    return 0;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value == null) return null;
    return int.tryParse(value.toString().trim());
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString().replaceAll('%', '').trim());
  }
}
