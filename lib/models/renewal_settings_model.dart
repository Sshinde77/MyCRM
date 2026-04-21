class RenewalSettingsModel {
  const RenewalSettingsModel({
    required this.renewalAdminEmail,
    required this.renewalNotificationTime,
    required this.renewalNoticeDays,
    required this.renewalNotificationsEnabled,
  });

  final String renewalAdminEmail;
  final String renewalNotificationTime;
  final int renewalNoticeDays;
  final bool renewalNotificationsEnabled;

  factory RenewalSettingsModel.fromJson(Map<String, dynamic> json) {
    return RenewalSettingsModel(
      renewalAdminEmail: _readString(
        json,
        const ['renewal_admin_email', 'renewalAdminEmail'],
      ),
      renewalNotificationTime: _normalizeTime(
        _readString(
          json,
          const ['renewal_notification_time', 'renewalNotificationTime'],
        ),
      ),
      renewalNoticeDays: _readInt(
        json,
        const ['renewal_notice_days', 'renewalNoticeDays'],
      ),
      renewalNotificationsEnabled: _readBool(
        json,
        const ['renewal_notifications_enabled', 'renewalNotificationsEnabled'],
      ),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'renewal_admin_email': renewalAdminEmail.trim(),
      'renewal_notification_time': _normalizeTime(renewalNotificationTime),
      'renewal_notice_days': renewalNoticeDays,
      'renewal_notifications_enabled': renewalNotificationsEnabled,
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

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
    }
    return false;
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
