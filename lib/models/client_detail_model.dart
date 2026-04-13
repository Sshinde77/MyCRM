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
    return ClientDetailModel(
      id: _readString(json, ['id', '_id', 'clientId', 'client_id']),
      name: _readString(json, ['name', 'full_name', 'fullName']),
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
      contactPerson: _readString(json, [
        'contact_person',
        'contactPerson',
        'contact_name',
        'primary_contact',
      ]),
      clientType: _readString(json, ['client_type', 'type']),
      industry: _readString(json, ['industry', 'industry_name', 'sector']),
      priorityLevel: _readString(json, ['priority', 'priority_level']),
      addressLine1: _readString(json, [
        'address_line1',
        'address_line_1',
        'address1',
        'address',
      ]),
      addressLine2: _readString(json, [
        'address_line2',
        'address_line_2',
        'address2',
      ]),
      city: _readString(json, ['city', 'town']),
      state: _readString(json, ['state', 'province']),
      postalCode: _readString(json, ['postal_code', 'zip', 'zipcode']),
      country: _readString(json, ['country', 'nation']),
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
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }
}
