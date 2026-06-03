class CareerEnquiryModel {
  const CareerEnquiryModel({
    required this.id,
    required this.name,
    required this.email,
    required this.contact,
    required this.role,
    required this.experience,
    required this.applicantType,
    required this.currentCtc,
    required this.expectedCtc,
    required this.location,
    required this.reference,
    required this.noticePeriod,
    required this.referenceName,
    required this.createdAt,
    required this.sourceLabel,
    required this.resumeFile,
    required this.resumeUrl,
    required this.portfolioLink,
    required this.skillsText,
    required this.aiToolsText,
  });

  final String id;
  final String name;
  final String email;
  final String contact;
  final String role;
  final String experience;
  final String applicantType;
  final String currentCtc;
  final String expectedCtc;
  final String location;
  final String reference;
  final String noticePeriod;
  final String referenceName;
  final String createdAt;
  final String sourceLabel;
  final String resumeFile;
  final String resumeUrl;
  final String portfolioLink;
  final String skillsText;
  final String aiToolsText;

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  factory CareerEnquiryModel.fromJson(Map<String, dynamic> json) {
    return CareerEnquiryModel(
      id: _firstString(json, const ['id']),
      name: _firstString(json, const ['fname', 'name']),
      email: _firstString(json, const ['email']),
      contact: _firstString(json, const ['contact', 'phone']),
      role: _firstString(json, const ['role']),
      experience: _firstString(json, const ['experience']),
      applicantType: _firstString(json, const [
        'applicant_type',
        'applicantType',
        'type',
      ]),
      currentCtc: _firstString(json, const ['ctc', 'current_ctc']),
      expectedCtc: _firstString(json, const ['ectc', 'expected_ctc']),
      location: _firstString(json, const ['location']),
      reference: _firstString(json, const ['refrence', 'reference']),
      noticePeriod: _firstString(json, const ['notice', 'notice_period']),
      referenceName: _firstString(json, const [
        'rn',
        'refrence_name',
        'reference_name',
      ]),
      createdAt: _firstString(json, const ['created_at', 'createdAt']),
      sourceLabel: _firstString(json, const [
        'source_page',
        'source',
        'source_label',
      ]),
      resumeFile: _firstString(json, const ['resume', 'resume_file']),
      resumeUrl: _firstString(json, const ['resume_url']),
      portfolioLink: _firstString(json, const ['portfolio_link', 'portfolio']),
      skillsText: _firstString(json, const ['skills', 'skills_text']),
      aiToolsText: _firstString(json, const ['ai_tools', 'ai_tools_text']),
    );
  }
}
