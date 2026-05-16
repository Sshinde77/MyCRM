class UpdateClientRequestModel {
  const UpdateClientRequestModel({
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.sendMail,
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
    this.clearBusinessInformation = false,
    this.password,
    this.profileImagePath,
  });

  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final bool? sendMail;
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
  final bool clearBusinessInformation;
  final String? password;
  final String? profileImagePath;

  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{};

    if (_hasValue(firstName)) payload['first_name'] = firstName!.trim();
    if (_hasValue(lastName)) payload['last_name'] = lastName!.trim();
    if (_hasValue(phone)) payload['phone'] = phone!.trim();
    if (_hasValue(email)) payload['email'] = email!.trim();
    if (sendMail != null) {
      payload['send_mail'] = sendMail;
      payload['sendMail'] = sendMail;
    }
    if (_hasValue(status)) payload['status'] = status!.trim().toLowerCase();
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

    if (clearBusinessInformation) {
      payload['website'] = '';
      payload['client_type'] = '';
      payload['company_name'] = '';
      payload['industry'] = '';
      payload['business_information'] = const <Map<String, String>>[];
    } else if (_hasValue(resolvedWebsite)) {
      payload['website'] = resolvedWebsite!.trim();
    }
    if (_hasValue(resolvedClientType)) {
      payload['client_type'] = resolvedClientType!.trim().toLowerCase();
    }
    if (_hasValue(resolvedCompanyName)) {
      payload['company_name'] = resolvedCompanyName!.trim();
    }
    if (_hasValue(resolvedIndustry)) {
      payload['industry'] = resolvedIndustry!.trim();
    }
    if (businessInformation.isNotEmpty) {
      payload['business_information'] = businessInformation;
    }
    if (_hasValue(password)) payload['password'] = password!.trim();

    return payload;
  }

  bool get hasProfileImage =>
      profileImagePath != null && profileImagePath!.trim().isNotEmpty;

  String? get normalizedProfileImagePath =>
      hasProfileImage ? profileImagePath!.trim() : null;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (_hasValue(value)) {
        return value!.trim();
      }
    }
    return null;
  }
}
