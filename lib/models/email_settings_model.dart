class EmailSettingsModel {
  const EmailSettingsModel({
    required this.mailEngine,
    required this.emailProtocol,
    required this.emailEncryption,
    required this.smtpHost,
    required this.smtpPort,
    required this.email,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.mailFromName,
    required this.emailCharset,
    required this.bccAll,
    required this.emailSignature,
    required this.predefinedHeader,
    required this.predefinedFooter,
  });

  final String mailEngine;
  final String emailProtocol;
  final String emailEncryption;
  final String smtpHost;
  final int smtpPort;
  final String email;
  final String smtpUsername;
  final String smtpPassword;
  final String mailFromName;
  final String emailCharset;
  final String bccAll;
  final String emailSignature;
  final String predefinedHeader;
  final String predefinedFooter;

  factory EmailSettingsModel.fromJson(Map<String, dynamic> json) {
    return EmailSettingsModel(
      mailEngine: _readString(json, const ['mail_engine', 'mailEngine']),
      emailProtocol: _readString(json, const [
        'email_protocol',
        'emailProtocol',
      ]),
      emailEncryption: _readString(json, const [
        'email_encryption',
        'emailEncryption',
      ]),
      smtpHost: _readString(json, const ['smtp_host', 'smtpHost']),
      smtpPort: _readInt(json, const ['smtp_port', 'smtpPort']),
      email: _readString(json, const ['email']),
      smtpUsername: _readString(json, const ['smtp_username', 'smtpUsername']),
      smtpPassword: _readString(json, const ['smtp_password', 'smtpPassword']),
      mailFromName: _readString(json, const [
        'mail_from_name',
        'mailFromName',
        'from_name',
        'fromName',
      ]),
      emailCharset: _readString(json, const ['email_charset', 'emailCharset']),
      bccAll: _readString(json, const ['bcc_all', 'bccAll']),
      emailSignature: _readString(json, const [
        'email_signature',
        'emailSignature',
      ]),
      predefinedHeader: _readString(json, const [
        'predefined_header',
        'predefinedHeader',
      ]),
      predefinedFooter: _readString(json, const [
        'predefined_footer',
        'predefinedFooter',
      ]),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'mail_engine': mailEngine.trim(),
      'email_protocol': emailProtocol.trim(),
      'email_encryption': emailEncryption.trim(),
      'smtp_host': smtpHost.trim(),
      'smtp_port': smtpPort,
      'email': email.trim(),
      'smtp_username': smtpUsername.trim(),
      'smtp_password': smtpPassword.trim(),
      'mail_from_name': mailFromName.trim(),
      'email_charset': emailCharset.trim(),
      'bcc_all': bccAll.trim(),
      'email_signature': emailSignature.trim(),
      'predefined_header': predefinedHeader.trim(),
      'predefined_footer': predefinedFooter.trim(),
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

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value != null) {
        final parsed = int.tryParse(value.toString().trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }
}
