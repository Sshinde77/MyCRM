class ProjectFormOptionsModel {
  const ProjectFormOptionsModel({
    this.customers = const [],
    this.statuses = const [],
    this.priorities = const [],
    this.staff = const [],
    this.billingTypes = const [],
  });

  final List<ProjectSelectOption> customers;
  final List<String> statuses;
  final List<String> priorities;
  final List<ProjectSelectOption> staff;
  final List<String> billingTypes;

  factory ProjectFormOptionsModel.fromJson(Map<String, dynamic> json) {
    final source = _extractSource(json);
    return ProjectFormOptionsModel(
      customers: _readSelectOptions(source, const [
        'customers',
        'customer',
        'clients',
      ]),
      statuses: _readStringOptions(source, const [
        'statuses',
        'status',
        'project_statuses',
      ]),
      priorities: _readStringOptions(source, const [
        'priorities',
        'priority',
        'project_priorities',
      ]),
      staff: _readSelectOptions(source, const [
        'staff',
        'members',
        'assigned_staff',
        'users',
      ]),
      billingTypes: _readStringOptions(source, const [
        'billing_types',
        'billing_type',
        'billingTypes',
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
      final options = _normalizeStringList(json[key]);
      if (options.isNotEmpty) {
        return options;
      }
    }

    for (final value in json.values) {
      final nested = _normalizeNestedMap(value);
      if (nested == null) {
        continue;
      }

      final options = _readStringOptions(nested, keys);
      if (options.isNotEmpty) {
        return options;
      }
    }

    return const [];
  }

  static List<ProjectSelectOption> _readSelectOptions(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is! List) {
        continue;
      }

      final options = value
          .map((entry) => ProjectSelectOption.fromDynamic(entry))
          .whereType<ProjectSelectOption>()
          .toList();

      if (options.isNotEmpty) {
        return options;
      }
    }

    for (final value in json.values) {
      final nested = _normalizeNestedMap(value);
      if (nested == null) {
        continue;
      }

      final options = _readSelectOptions(nested, keys);
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

    return value
        .map((entry) {
          if (entry is String) {
            return entry.trim();
          }
          if (entry is Map<String, dynamic>) {
            return _readString(entry, const ['name', 'title', 'label', 'value']);
          }
          if (entry is Map) {
            return _readString(
              entry.map((key, value) => MapEntry(key.toString(), value)),
              const ['name', 'title', 'label', 'value'],
            );
          }
          return entry.toString().trim();
        })
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList();
  }

  static Map<String, dynamic>? _normalizeNestedMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
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

class ProjectSelectOption {
  const ProjectSelectOption({required this.id, required this.name});

  final String id;
  final String name;

  factory ProjectSelectOption.fromJson(Map<String, dynamic> json) {
    final firstName = ProjectFormOptionsModel._readString(json, const [
      'first_name',
      'firstName',
    ]);
    final lastName = ProjectFormOptionsModel._readString(json, const [
      'last_name',
      'lastName',
    ]);
    final fullName = [firstName, lastName]
        .where((value) => value.isNotEmpty)
        .join(' ')
        .trim();

    final name = fullName.isNotEmpty
        ? fullName
        : ProjectFormOptionsModel._readString(json, const [
            'name',
            'company',
            'company_name',
            'full_name',
            'fullName',
            'title',
            'label',
            'value',
            'email',
          ]);

    final id = ProjectFormOptionsModel._readString(json, const [
      'id',
      '_id',
      'client_id',
      'customer_id',
      'staff_id',
      'user_id',
      'value',
    ]);

    return ProjectSelectOption(
      id: id.isNotEmpty ? id : name,
      name: name,
    );
  }

  static ProjectSelectOption? fromDynamic(dynamic value) {
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return null;
      }
      return ProjectSelectOption(id: normalized, name: normalized);
    }

    if (value is Map<String, dynamic>) {
      final option = ProjectSelectOption.fromJson(value);
      if (option.id.isEmpty || option.name.isEmpty) {
        return null;
      }
      return option;
    }

    if (value is Map) {
      final normalized = value.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final option = ProjectSelectOption.fromJson(normalized);
      if (option.id.isEmpty || option.name.isEmpty) {
        return null;
      }
      return option;
    }

    return null;
  }
}
