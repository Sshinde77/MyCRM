class ContactEnquiryModel {
  const ContactEnquiryModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.contact,
    required this.email,
    required this.message,
    required this.sourcePage,
    required this.createdAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String contact;
  final String email;
  final String message;
  final String sourcePage;
  final String createdAt;

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  factory ContactEnquiryModel.fromJson(Map<String, dynamic> json) {
    return ContactEnquiryModel(
      id: _firstString(json, const ['id']),
      firstName: _firstString(json, const ['fname', 'first_name', 'firstname']),
      lastName: _firstString(json, const ['lname', 'last_name', 'lastname']),
      contact: _firstString(json, const ['contact', 'phone']),
      email: _firstString(json, const ['email']),
      message: _firstString(json, const ['message']),
      sourcePage: _firstString(json, const ['source_page', 'sourcePage']),
      createdAt: _firstString(json, const ['created_at', 'createdAt']),
    );
  }
}
