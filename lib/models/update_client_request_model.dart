class UpdateClientRequestModel {
  const UpdateClientRequestModel({
    required this.clientName,
    required this.contactPerson,
    required this.email,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.clientType,
    required this.industry,
    required this.status,
    this.phone,
    this.website,
    this.addressLine2,
    this.priorityLevel,
    this.assignedManagerId,
    this.defaultDueDays,
    this.billingType,
    this.role,
    this.password,
    this.sendWelcomeEmail = true,
  });

  final String clientName;
  final String contactPerson;
  final String email;
  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String clientType;
  final String industry;
  final String status;
  final String? phone;
  final String? website;
  final String? addressLine2;
  final String? priorityLevel;
  final String? assignedManagerId;
  final int? defaultDueDays;
  final String? billingType;
  final String? role;
  final String? password;
  final bool sendWelcomeEmail;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'client_name': clientName,
      'contact_person': contactPerson,
      'email': email,
      'address_line1': addressLine1,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'client_type': clientType,
      'industry': industry,
      'status': status,
      'send_welcome_email': sendWelcomeEmail,
    };

    if (_hasValue(phone)) payload['phone'] = phone!.trim();
    if (_hasValue(website)) payload['website'] = website!.trim();
    if (_hasValue(addressLine2))
      payload['address_line2'] = addressLine2!.trim();
    if (_hasValue(priorityLevel))
      payload['priority_level'] = priorityLevel!.trim();
    if (_hasValue(assignedManagerId)) {
      payload['assigned_manager_id'] = assignedManagerId!.trim();
    }
    if (defaultDueDays != null) payload['default_due_days'] = defaultDueDays;
    if (_hasValue(billingType)) payload['billing_type'] = billingType!.trim();
    if (_hasValue(role)) payload['role'] = role!.trim();
    if (_hasValue(password)) payload['password'] = password!.trim();

    return payload;
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}
