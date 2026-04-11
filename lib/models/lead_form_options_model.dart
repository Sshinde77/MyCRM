class LeadFormOptionsModel {
  const LeadFormOptionsModel({
    this.statuses = const [],
    this.sources = const [],
    this.tags = const [],
    this.staff = const [],
  });

  final List<String> statuses;
  final List<String> sources;
  final List<String> tags;
  final List<LeadStaffOption> staff;

  factory LeadFormOptionsModel.fromJson(Map<String, dynamic> json) {
    final source = _extractSource(json);
    return LeadFormOptionsModel(
      statuses: _readStringOptions(source, [
        'statuses',
        'status',
        'lead_statuses',
        'leadStatuses',
      ]),
      sources: _readStringOptions(source, [
        'sources',
        'source',
        'lead_sources',
        'leadSources',
      ]),
      tags: _readStringOptions(source, ['tags', 'tag', 'lead_tags', 'leadTags']),
      staff: _readStaffOptions(source, [
        'staff',
        'assigned_staff',
        'assignedStaff',
        'staff_members',
        'users',
        'members',
      ]),
    );
  }

  static Map<String, dynamic> _extractSource(Map<String, dynamic> json) {
    for (final key in ['data', 'result', 'item']) {
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

  static List<String> _readStringOptions(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      final options = _normalizeStringList(value);
      if (options.isNotEmpty) {
        return options;
      }
    }

    for (final value in json.values) {
      final normalized = value is Map<String, dynamic>
          ? value
          : value is Map
              ? value.map((key, value) => MapEntry(key.toString(), value))
              : null;
      if (normalized == null) {
        continue;
      }

      final options = _readStringOptions(normalized, keys);
      if (options.isNotEmpty) {
        return options;
      }
    }

    return const [];
  }

  static List<LeadStaffOption> _readStaffOptions(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is! List) {
        continue;
      }

      final options = value
          .map((entry) => LeadStaffOption.fromDynamic(entry))
          .where((entry) => entry != null)
          .cast<LeadStaffOption>()
          .toList();

      if (options.isNotEmpty) {
        return options;
      }
    }

    for (final value in json.values) {
      final normalized = value is Map<String, dynamic>
          ? value
          : value is Map
              ? value.map((key, value) => MapEntry(key.toString(), value))
              : null;
      if (normalized == null) {
        continue;
      }

      final options = _readStaffOptions(normalized, keys);
      if (options.isNotEmpty) {
        return options;
      }
    }

    return const [];
  }

  static List<String> _normalizeStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final items = value
        .map((entry) {
          if (entry is String) {
            return entry.trim();
          }
          if (entry is Map<String, dynamic>) {
            return _readString(entry, ['name', 'title', 'label', 'value']);
          }
          if (entry is Map) {
            final normalized = entry.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            return _readString(normalized, ['name', 'title', 'label', 'value']);
          }
          return entry.toString().trim();
        })
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList();

    return items;
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
}

class LeadStaffOption {
  const LeadStaffOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory LeadStaffOption.fromJson(Map<String, dynamic> json) {
    final firstName = _readString(json, ['first_name', 'firstName']);
    final lastName = _readString(json, ['last_name', 'lastName']);
    final fullName = [firstName, lastName]
        .where((value) => value.isNotEmpty)
        .join(' ')
        .trim();

    return LeadStaffOption(
      id: _readString(json, ['id', '_id', 'staff_id', 'user_id']),
      name: fullName.isNotEmpty
          ? fullName
          : _readString(json, ['name', 'full_name', 'fullName', 'email']),
    );
  }

  static LeadStaffOption? fromDynamic(dynamic value) {
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return null;
      }
      return LeadStaffOption(id: normalized, name: normalized);
    }
    if (value is Map<String, dynamic>) {
      final option = LeadStaffOption.fromJson(value);
      if (option.name.isEmpty && option.id.isEmpty) {
        return null;
      }
      return option.id.isEmpty
          ? LeadStaffOption(id: option.name, name: option.name)
          : option;
    }
    if (value is Map) {
      final normalized = value.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final option = LeadStaffOption.fromJson(normalized);
      if (option.name.isEmpty && option.id.isEmpty) {
        return null;
      }
      return option.id.isEmpty
          ? LeadStaffOption(id: option.name, name: option.name)
          : option;
    }
    return null;
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
}
