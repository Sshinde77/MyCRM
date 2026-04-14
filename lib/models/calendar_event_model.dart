class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    this.endAt,
    this.emailRecipients,
    this.whatsappRecipients,
    this.location,
  });

  final String id;
  final String title;
  final String description;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? emailRecipients;
  final String? whatsappRecipients;
  final String? location;

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    final source = _extractSource(json);

    final dateCandidate = _readNullableString(source, const [
      'date',
      'event_date',
      'start_date',
      'startDate',
      'meeting_date',
      'meetingDate',
      'scheduled_date',
      'scheduledDate',
    ]);
    final timeCandidate = _readNullableString(source, const [
      'time',
      'start_time',
      'startTime',
      'meeting_time',
      'meetingTime',
      'scheduled_time',
      'scheduledTime',
    ]);

    final startAt =
        _readNullableDateTime(source, const [
          'start',
          'start_at',
          'startAt',
          'starts_at',
          'startsAt',
          'from',
          'start_datetime',
          'startDateTime',
          'datetime',
          'created_at',
          'createdAt',
        ]) ??
        _combineDateAndTime(dateCandidate, timeCandidate);

    final endAt = _readNullableDateTime(source, const [
      'end',
      'end_at',
      'endAt',
      'ends_at',
      'endsAt',
      'to',
      'end_datetime',
      'endDateTime',
    ]);

    return CalendarEventModel(
      id: _readString(source, const ['id', '_id', 'event_id', 'eventId']),
      title: _readString(source, const [
        'title',
        'name',
        'subject',
        'event_title',
        'eventTitle',
      ], fallback: 'Calendar Event'),
      description: _readString(source, const [
        'description',
        'details',
        'note',
        'notes',
        'agenda',
      ], fallback: ''),
      startAt: startAt,
      endAt: endAt,
      emailRecipients: _readNullableString(source, const [
        'email_recipients',
        'emailRecipients',
        'emails',
        'email',
      ]),
      whatsappRecipients: _readNullableString(source, const [
        'whatsapp_recipients',
        'whatsappRecipients',
        'whatsapp',
        'whatsapp_numbers',
        'whatsappNumbers',
        'phone_numbers',
        'phoneNumbers',
      ]),
      location: _readNullableString(source, const [
        'location',
        'venue',
        'address',
      ]),
    );
  }

  static Map<String, dynamic> _extractSource(Map<String, dynamic> json) {
    for (final key in const [
      'data',
      'event',
      'calendar',
      'calendar_event',
      'calendarEvent',
    ]) {
      final value = json[key];
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
    }
    return json;
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }

      if (value is num) {
        return value.toString();
      }
    }

    return fallback;
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = _readString(json, keys);
    return value.trim().isEmpty ? null : value.trim();
  }

  static DateTime? _readNullableDateTime(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      final parsed = _tryParseDateTime(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  static DateTime? _tryParseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is num) {
      final v = value.toInt();
      // Heuristic: treat large values as milliseconds since epoch.
      if (v > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(v);
      }
      if (v > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      }
      return null;
    }

    if (value is String) {
      final raw = value.trim();
      if (raw.isEmpty) return null;

      final iso = DateTime.tryParse(raw);
      if (iso != null) {
        return iso;
      }

      // Try common "yyyy-MM-dd HH:mm:ss" format by swapping space with 'T'.
      final maybeIso = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
      if (maybeIso != null) {
        return maybeIso;
      }

      return null;
    }

    return null;
  }

  static DateTime? _combineDateAndTime(String? date, String? time) {
    if (date == null || date.trim().isEmpty) {
      return null;
    }
    final parsedDate =
        DateTime.tryParse(date.trim()) ??
        DateTime.tryParse(date.trim().replaceFirst(' ', 'T'));
    if (parsedDate == null) {
      return null;
    }

    if (time == null || time.trim().isEmpty) {
      return parsedDate;
    }

    final parsedTime = _tryParseTimeOfDay(time.trim());
    if (parsedTime == null) {
      return parsedDate;
    }

    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      parsedTime.$1,
      parsedTime.$2,
    );
  }

  static (int, int)? _tryParseTimeOfDay(String raw) {
    // HH:mm or HH:mm:ss
    final twentyFourHour = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?$',
    ).firstMatch(raw);
    if (twentyFourHour != null) {
      final hour = int.tryParse(twentyFourHour.group(1)!);
      final minute = int.tryParse(twentyFourHour.group(2)!);
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23) return null;
      if (minute < 0 || minute > 59) return null;
      return (hour, minute);
    }

    // h:mm AM/PM
    final ampm = RegExp(r'^(\d{1,2}):(\d{2})\s*([aApP][mM])$').firstMatch(raw);
    if (ampm != null) {
      final hourRaw = int.tryParse(ampm.group(1)!);
      final minute = int.tryParse(ampm.group(2)!);
      final suffix = ampm.group(3)!.toLowerCase();
      if (hourRaw == null || minute == null) return null;
      if (hourRaw < 1 || hourRaw > 12) return null;
      if (minute < 0 || minute > 59) return null;
      var hour = hourRaw % 12;
      if (suffix == 'pm') {
        hour += 12;
      }
      return (hour, minute);
    }

    return null;
  }
}
