class CreateClientRequestModel {
  const CreateClientRequestModel({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.password,
    this.sendMail = false,
    this.website,
    this.status,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.clientType,
    this.companyName,
    this.industry,
    this.businessInformation = const [],
    this.profileImagePath,
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? password;
  final bool sendMail;
  final String? website;
  final String? status;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? clientType;
  final String? companyName;
  final String? industry;
  final List<Map<String, String>> businessInformation;
  final String? profileImagePath;

  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{};

    if (_hasValue(firstName)) payload['first_name'] = firstName!.trim();
    if (_hasValue(lastName)) payload['last_name'] = lastName!.trim();
    if (_hasValue(email)) payload['email'] = email!.trim();
    if (_hasValue(phone)) payload['phone'] = phone!.trim();
    if (_hasValue(password)) payload['password'] = password!.trim();
    payload['send_invite_mail'] = sendMail;
    if (_hasValue(status)) payload['status'] = status!.trim().toLowerCase();
    if (_hasValue(website)) payload['website'] = website!.trim();
    if (_hasValue(addressLine1))
      payload['address_line_1'] = addressLine1!.trim();
    if (_hasValue(addressLine2))
      payload['address_line_2'] = addressLine2!.trim();
    if (_hasValue(city)) payload['city'] = city!.trim();
    if (_hasValue(state)) payload['state'] = state!.trim();
    if (_hasValue(country)) payload['country'] = country!.trim();
    if (_hasValue(postalCode)) payload['pincode'] = postalCode!.trim();
    final primaryBusiness = businessInformation.isNotEmpty
        ? businessInformation.first
        : const <String, String>{};
    final resolvedClientType = _firstNonEmpty([
      primaryBusiness['client_type'],
      clientType,
    ]);
    final resolvedCompanyName = _firstNonEmpty([
      primaryBusiness['company_name'],
      companyName,
    ]);
    final resolvedIndustry = _firstNonEmpty([
      primaryBusiness['industry'],
      industry,
    ]);
    final resolvedWebsite = _firstNonEmpty([
      primaryBusiness['website'],
      website,
    ]);

    if (_hasValue(resolvedWebsite)) payload['website'] = resolvedWebsite!.trim();
    if (businessInformation.isNotEmpty) {
      payload['companies'] = businessInformation;
    } else {
      final company = <String, String>{};
      _addIfNotEmpty(company, 'client_type', resolvedClientType);
      _addIfNotEmpty(company, 'company_name', resolvedCompanyName);
      _addIfNotEmpty(company, 'industry', resolvedIndustry);
      _addIfNotEmpty(company, 'website', resolvedWebsite);
      if (company.isNotEmpty) {
        payload['companies'] = [company];
      }
    }

    return payload;
  }

  bool get hasProfileImage =>
      profileImagePath != null && profileImagePath!.trim().isNotEmpty;

  String? get normalizedProfileImagePath =>
      hasProfileImage ? profileImagePath!.trim() : null;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  void _addIfNotEmpty(Map<String, String> map, String key, String? value) {
    if (_hasValue(value)) {
      map[key] = value!.trim();
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (_hasValue(value)) {
        return value!.trim();
      }
    }
    return null;
  }
}
