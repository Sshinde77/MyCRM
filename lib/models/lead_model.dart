class LeadModel {
  const LeadModel({
    required this.id,
    required this.name,
    this.leadCode,
    this.company,
    this.amount,
    this.status,
    this.email,
    this.phone,
    this.createdAt,
    this.assignedTo,
    this.source,
    this.website,
    this.avatarUrl,
    this.position,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.description,
    this.tags = const [],
    this.assignedStaffIds = const [],
  });

  final String id;
  final String name;
  final String? leadCode;
  final String? company;
  final double? amount;
  final String? status;
  final String? email;
  final String? phone;
  final DateTime? createdAt;
  final String? assignedTo;
  final String? source;
  final String? website;
  final String? avatarUrl;
  final String? position;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? description;
  final List<String> tags;
  final List<String> assignedStaffIds;

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    final source = _extractSource(json);
    final assignedSource = _extractNestedMap(source, [
      'assigned_staff',
      'assigned_to',
      'assignedTo',
      'owner',
      'user',
      'staff',
    ]);
    final assignedStaff = _extractNestedList(source, ['assigned_staff']);

    final firstName = _readNullableString(source, ['first_name', 'firstName']);
    final lastName = _readNullableString(source, ['last_name', 'lastName']);
    final combinedName = [firstName, lastName]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ');

    return LeadModel(
      id: _readString(source, ['id', '_id', 'lead_id', 'leadId']),
      name: combinedName.isNotEmpty
          ? combinedName
          : _readString(source, [
              'name',
              'full_name',
              'lead_name',
              'contact_name',
              'title',
            ]),
      leadCode: _readNullableString(source, [
        'lead_code',
        'lead_no',
        'lead_number',
        'reference_no',
        'reference',
      ]),
      company: _readNullableString(source, [
        'company',
        'company_name',
        'organization',
        'client_name',
        'business_name',
      ]),
      amount: _readNullableDouble(source, [
        'amount',
        'lead_value',
        'value',
        'budget',
        'expected_value',
      ]),
      status: _readNullableString(source, [
        'status',
        'lead_status',
        'stage',
        'lead_stage',
      ]),
      email: _readNullableString(source, [
        'email',
        'email_address',
        'contact_email',
      ]),
      phone: _readNullableString(source, [
        'phone',
        'mobile',
        'phone_number',
        'contact_number',
      ]),
      createdAt: _readNullableDateTime(source, [
        'created_at',
        'createdAt',
        'date',
        'lead_date',
      ]),
      assignedTo:
          _readAssignedStaffNames(assignedStaff) ??
          _readNullableString(assignedSource, ['first_name']) ??
          _readNullableString(source, [
            'assigned_to_name',
            'assigned_name',
            'owner_name',
          ]) ??
          _readNullableString(assignedSource, [
            'name',
            'full_name',
            'username',
          ]),
      source: _readNullableString(source, ['source', 'lead_source']),
      website: _readNullableString(source, ['website', 'website_url', 'url']),
      position: _readNullableString(source, [
        'position',
        'designation',
        'role',
      ]),
      address: _readNullableString(source, ['address', 'street_address']),
      city: _readNullableString(source, ['city']),
      state: _readNullableString(source, ['state']),
      country: _readNullableString(source, ['country']),
      zipCode: _readNullableString(source, [
        'zipCode',
        'zip_code',
        'postal_code',
      ]),
      description: _readNullableString(source, [
        'description',
        'notes',
        'remark',
      ]),
      tags: _readStringList(source['tags']),
      assignedStaffIds: _readAssignedStaffIds(
        assignedStaff,
        assignedSource,
        source,
      ),
      avatarUrl: _readNullableString(source, [
        'avatar',
        'image',
        'profile_picture',
      ]),
    );
  }

  String get displayId {
    final value = leadCode?.trim();
    if (value != null && value.isNotEmpty) {
      return value.startsWith('#') ? value : '#$value';
    }
    return id.isEmpty ? '#LEAD' : '#$id';
  }

  String get displayName {
    final value = name.trim();
    return value.isEmpty ? 'Unnamed Lead' : value;
  }

  String get displayCompany {
    final value = company?.trim();
    return value == null || value.isEmpty ? 'Company not available' : value;
  }

  String get displayAmount {
    final value = amount;
    if (value == null) {
      return '';
    }

    final hasFraction = value % 1 != 0;
    return hasFraction ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
  }

  String get displayStatus {
    final value = status?.trim();
    return value == null || value.isEmpty ? 'Unknown' : value;
  }

  String get displayEmail {
    final value = email?.trim();
    return value == null || value.isEmpty ? 'Email not available' : value;
  }

  String get displayPhone {
    final value = phone?.trim();
    return value == null || value.isEmpty ? 'Phone not available' : value;
  }

  String get displayAssignedTo {
    final value = assignedTo?.trim();
    return value == null || value.isEmpty ? 'Unassigned' : value;
  }

  String get displayWebsite {
    final value = website?.trim();
    return value == null || value.isEmpty ? 'Not available' : value;
  }

  String get displayPosition {
    final value = position?.trim();
    return value == null || value.isEmpty ? 'Not available' : value;
  }

  String get displaySource {
    final value = source?.trim();
    return value == null || value.isEmpty ? 'Not available' : value;
  }

  String get displayAddress {
    final value = address?.trim();
    return value == null || value.isEmpty ? 'Not available' : value;
  }

  String get displayLocation {
    final parts = [
      city?.trim(),
      state?.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Not available';
    }
    return parts.join(', ');
  }

  String get displayCountry {
    final value = country?.trim();
    return value == null || value.isEmpty ? 'Not available' : value;
  }

  String get displayZipCode {
    final value = zipCode?.trim();
    return value == null || value.isEmpty ? 'Not available' : value;
  }

  String get displayDescription {
    final value = description?.trim();
    return value == null || value.isEmpty ? 'No description available.' : value;
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return [id, leadCode, name, company, email, phone, assignedTo]
        .whereType<String>()
        .any((value) => value.toLowerCase().contains(normalized));
  }

  static Map<String, dynamic> _extractSource(Map<String, dynamic> json) {
    for (final key in ['lead', 'data', 'item', 'result', 'attributes']) {
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

  static Map<String, dynamic> _extractNestedMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    return const {};
  }

  static List<Map<String, dynamic>> _extractNestedList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value
            .map((item) {
              if (item is Map<String, dynamic>) {
                return item;
              }
              if (item is Map) {
                return item.map(
                  (key, value) => MapEntry(key.toString(), value),
                );
              }
              return <String, dynamic>{};
            })
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  static String? _readAssignedStaffNames(List<Map<String, dynamic>> staffList) {
    if (staffList.isEmpty) {
      return null;
    }

    final firstNames = staffList
        .map((staff) => _readNullableString(staff, ['first_name']))
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (firstNames.isEmpty) {
      return null;
    }

    return firstNames.join(', ');
  }

  static List<String> _readAssignedStaffIds(
    List<Map<String, dynamic>> staffList,
    Map<String, dynamic> assignedSource,
    Map<String, dynamic> source,
  ) {
    final ids = <String>{};

    for (final staff in staffList) {
      final id = _readString(staff, ['id', '_id', 'staff_id', 'user_id']);
      if (id.isNotEmpty) {
        ids.add(id);
      }
    }

    final directAssigned = _readString(assignedSource, [
      'id',
      '_id',
      'staff_id',
      'user_id',
    ]);
    if (directAssigned.isNotEmpty) {
      ids.add(directAssigned);
    }

    final sourceAssigned = source['assigned'];
    if (sourceAssigned is List) {
      for (final value in sourceAssigned) {
        final normalized = value?.toString().trim() ?? '';
        if (normalized.isNotEmpty) {
          ids.add(normalized);
        }
      }
    } else {
      final singleAssigned = sourceAssigned?.toString().trim() ?? '';
      if (singleAssigned.isNotEmpty) {
        ids.add(singleAssigned);
      }
    }

    return ids.toList(growable: false);
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) {
            if (item is String) {
              return item.trim();
            }
            if (item is Map<String, dynamic>) {
              return _readString(item, ['name', 'title', 'label']);
            }
            if (item is Map) {
              final normalized = item.map(
                (key, value) => MapEntry(key.toString(), value),
              );
              return _readString(normalized, ['name', 'title', 'label']);
            }
            return item.toString().trim();
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
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

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = _readString(json, keys);
    return value.isEmpty ? null : value;
  }

  static double? _readNullableDouble(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }
      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
        if (cleaned.isEmpty) {
          continue;
        }
        final parsed = double.tryParse(cleaned);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static DateTime? _readNullableDateTime(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
