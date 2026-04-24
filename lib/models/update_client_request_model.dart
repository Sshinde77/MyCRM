class UpdateClientRequestModel {
  const UpdateClientRequestModel({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
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
    this.password,
    this.profileImagePath,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
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
  final String? password;
  final String? profileImagePath;

  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'phone': phone.trim(),
    };

    if (_hasValue(email)) payload['email'] = email!.trim();
    if (_hasValue(website)) payload['website'] = website!.trim();
    if (_hasValue(status)) payload['status'] = status!.trim().toLowerCase();
    if (_hasValue(addressLine1))
      payload['address_line_1'] = addressLine1!.trim();
    if (_hasValue(addressLine2))
      payload['address_line_2'] = addressLine2!.trim();
    if (_hasValue(city)) payload['city'] = city!.trim();
    if (_hasValue(state)) payload['state'] = state!.trim();
    if (_hasValue(country)) payload['country'] = country!.trim();
    if (_hasValue(postalCode)) payload['pincode'] = postalCode!.trim();
    if (_hasValue(clientType)) {
      payload['client_type'] = clientType!.trim().toLowerCase();
    }
    if (_hasValue(companyName)) payload['company_name'] = companyName!.trim();
    if (_hasValue(industry)) payload['industry'] = industry!.trim();
    if (_hasValue(password)) payload['password'] = password!.trim();

    return payload;
  }

  bool get hasProfileImage =>
      profileImagePath != null && profileImagePath!.trim().isNotEmpty;

  String? get normalizedProfileImagePath =>
      hasProfileImage ? profileImagePath!.trim() : null;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}
