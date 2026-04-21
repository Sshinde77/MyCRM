class CompanyInformationModel {
  const CompanyInformationModel({
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    required this.website,
    required this.gstNumber,
    required this.officeStartTime,
    required this.lunchStartTime,
    required this.lunchEndTime,
    required this.officeEndTime,
  });

  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String website;
  final String gstNumber;
  final String officeStartTime;
  final String lunchStartTime;
  final String lunchEndTime;
  final String officeEndTime;

  factory CompanyInformationModel.fromJson(Map<String, dynamic> json) {
    return CompanyInformationModel(
      companyName: _readString(json, const ['company_name', 'companyName']),
      companyEmail: _readString(json, const ['company_email', 'companyEmail']),
      companyPhone: _readString(json, const ['company_phone', 'companyPhone']),
      address: _readString(json, const ['address']),
      city: _readString(json, const ['city']),
      state: _readString(json, const ['state']),
      zip: _readString(json, const ['zip', 'zip_code', 'zipCode']),
      country: _readString(json, const ['country']),
      website: _readString(json, const ['website']),
      gstNumber: _readString(json, const ['gst_number', 'gstNumber']),
      officeStartTime: _normalizeTime(
        _readString(json, const ['office_start_time', 'officeStartTime']),
      ),
      lunchStartTime: _normalizeTime(
        _readString(json, const ['lunch_start_time', 'lunchStartTime']),
      ),
      lunchEndTime: _normalizeTime(
        _readString(json, const ['lunch_end_time', 'lunchEndTime']),
      ),
      officeEndTime: _normalizeTime(
        _readString(json, const ['office_end_time', 'officeEndTime']),
      ),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'company_name': companyName.trim(),
      'company_email': companyEmail.trim(),
      'company_phone': companyPhone.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'zip': zip.trim(),
      'country': country.trim(),
      'website': website.trim(),
      'gst_number': gstNumber.trim(),
      'office_start_time': _normalizeTime(officeStartTime),
      'lunch_start_time': _normalizeTime(lunchStartTime),
      'lunch_end_time': _normalizeTime(lunchEndTime),
      'office_end_time': _normalizeTime(officeEndTime),
    };
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static String _normalizeTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(trimmed);
    if (match == null) {
      return trimmed;
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return trimmed;
    }

    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
