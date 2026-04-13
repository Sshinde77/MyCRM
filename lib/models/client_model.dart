class ClientModel {
  const ClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.industry,
    required this.website,
    required this.contactName,
    required this.contactRole,
    required this.isActive,
  });

  final String id;
  final String name;
  final String email;
  final String industry;
  final String website;
  final String contactName;
  final String contactRole;
  final bool isActive;

  String get contactLine {
    final role = contactRole.trim();
    final person = contactName.trim();
    if (role.isNotEmpty && person.isNotEmpty) {
      return '$role - $person';
    }
    if (role.isNotEmpty) return role;
    if (person.isNotEmpty) return person;
    return 'Primary contact';
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    final source = _extractSource(json);
    return ClientModel(
      id: _readString(source, [
        'id',
        '_id',
        'clientId',
        'client_id',
        'clientID',
      ]),
      name: _readString(source, [
        'name',
        'client_name',
        'company',
        'companyName',
        'company_name',
        'title',
      ]),
      email: _readString(source, [
        'email',
        'email_address',
        'contact_email',
        'primary_email',
      ]),
      industry: _readString(source, [
        'industry',
        'industry_name',
        'sector',
        'category',
      ]),
      website: _readString(source, ['website', 'website_url', 'site', 'url']),
      contactName: _readString(source, [
        'contact_name',
        'contactName',
        'primary_contact',
        'contact_person',
        'owner',
        'contactPerson',
        'contact',
      ]),
      contactRole: _readString(source, [
        'contact_role',
        'designation',
        'role',
        'title',
        'position',
      ]),
      isActive: _readActive(source),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static Map<String, dynamic> _extractSource(Map<String, dynamic> json) {
    for (final key in ['client', 'data', 'item', 'result', 'attributes']) {
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

  static bool _readActive(Map<String, dynamic> json) {
    for (final key in ['is_active', 'active', 'status', 'state']) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized.isEmpty) continue;
        if (normalized == '0' || normalized == 'false') return false;
        if (normalized == '1' || normalized == 'true') return true;
        if (normalized.contains('inactive')) return false;
        if (normalized.contains('active')) return true;
        if (normalized.contains('disabled') || normalized.contains('blocked')) {
          return false;
        }
      }
    }
    return false;
  }
}
