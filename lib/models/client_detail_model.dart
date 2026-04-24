class ClientDetailModel {
  const ClientDetailModel({
    required this.id,
    required this.name,
    required this.companyName,
    required this.email,
    required this.phone,
    required this.website,
    required this.managerName,
    required this.status,
    required this.role,
    required this.contactPerson,
    required this.clientType,
    required this.industry,
    required this.priorityLevel,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.billingType,
    required this.dueDays,
  });

  final String id;
  final String name;
  final String companyName;
  final String email;
  final String phone;
  final String website;
  final String managerName;
  final String status;
  final String role;
  final String contactPerson;
  final String clientType;
  final String industry;
  final String priorityLevel;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String billingType;
  final String dueDays;

  bool get isActive => status.toLowerCase().contains('active');

  String get addressSummary {
    final lines = [
      addressLine1,
      addressLine2,
      [city, state].where((value) => value.trim().isNotEmpty).join(', '),
      [
        country,
        postalCode,
      ].where((value) => value.trim().isNotEmpty).join(' - '),
    ].where((value) => value.trim().isNotEmpty).toList();

    return lines.isEmpty ? 'No address provided' : lines.join('\n');
  }

  factory ClientDetailModel.fromJson(Map<String, dynamic> json) {
    final addressObject = _readMap(json, const [
      'address',
      'client_address',
      'address_detail',
      'address_line_1',
    ]);
    final fallbackPersonName = _readFullName(json);
    final resolvedName = _readString(json, [
      'name',
      'full_name',
      'fullName',
      'company',
      'company_name',
      'companyName',
      'title',
    ]);
    final resolvedContactPerson = _readString(json, [
      'contact_person',
      'contactPerson',
      'contact_name',
      'primary_contact',
    ]);
    final resolvedAddressLine1 = _firstNonEmpty([
      _readString(json, const [
        'address_line1',
        'address_line_1',
        'address1',
        'address',
      ]),
      _readString(addressObject, const [
        'address_line_1',
        'address_line1',
        'address1',
        'address',
      ]),
    ]);
    final resolvedAddressLine2 = _firstNonEmpty([
      _readString(json, const ['address_line2', 'address_line_2', 'address2']),
      _readString(addressObject, const [
        'address_line_2',
        'address_line2',
        'address2',
      ]),
    ]);
    final resolvedCity = _firstNonEmpty([
      _readString(json, const ['city', 'town']),
      _readString(addressObject, const ['city']),
    ]);
    final resolvedState = _firstNonEmpty([
      _readString(json, const ['state', 'province']),
      _readString(addressObject, const ['state', 'province']),
    ]);
    final resolvedPostalCode = _firstNonEmpty([
      _readString(json, const ['postal_code', 'zip', 'zipcode', 'pincode']),
      _readString(addressObject, const [
        'postal_code',
        'zip',
        'zipcode',
        'pincode',
      ]),
    ]);
    final resolvedCountry = _firstNonEmpty([
      _readString(json, const ['country', 'nation']),
      _readString(addressObject, const ['country', 'nation']),
    ]);

    return ClientDetailModel(
      id: _readString(json, [
        'customer_id',
        'customerId',
        'id',
        '_id',
        'clientId',
        'client_id',
      ]),
      name: resolvedName.isNotEmpty ? resolvedName : fallbackPersonName,
      companyName: _readString(json, [
        'company',
        'companyName',
        'company_name',
        'client_name',
        'title',
      ]),
      email: _readString(json, [
        'email',
        'email_address',
        'contact_email',
        'primary_email',
      ]),
      phone: _readString(json, ['phone', 'mobile', 'phone_number']),
      website: _readString(json, ['website', 'website_url', 'site', 'url']),
      managerName: _readString(json, [
        'manager',
        'manager_name',
        'account_manager',
        'owner',
      ]),
      status: _readString(json, ['status', 'state', 'account_status']),
      role: _readString(json, ['role', 'user_role']),
      contactPerson: resolvedContactPerson.isNotEmpty
          ? resolvedContactPerson
          : fallbackPersonName,
      clientType: _readString(json, ['client_type', 'type']),
      industry: _readString(json, ['industry', 'industry_name', 'sector']),
      priorityLevel: _readString(json, ['priority', 'priority_level']),
      addressLine1: resolvedAddressLine1,
      addressLine2: resolvedAddressLine2,
      city: resolvedCity,
      state: resolvedState,
      postalCode: resolvedPostalCode,
      country: resolvedCountry,
      billingType: _readString(json, ['billing_type', 'billingType']),
      dueDays: _readString(json, [
        'default_due_days',
        'due_days',
        'dueDays',
        'payment_terms',
      ]),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if ((value is num || value is bool) &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
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
      if (value is Map) {
        return value.map((entryKey, entryValue) {
          return MapEntry(entryKey.toString(), entryValue);
        });
      }
    }
    return const {};
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static String _readFullName(Map<String, dynamic> json) {
    final firstName = _readString(json, const ['first_name', 'firstName']);
    final lastName = _readString(json, const ['last_name', 'lastName']);
    return [
      firstName,
      lastName,
    ].where((entry) => entry.trim().isNotEmpty).join(' ').trim();
  }
}
