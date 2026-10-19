/// API slugs and validation shared by lead screens.
class LeadFlow {
  static const statuses = <String>[
    'new',
    'attempted_contact',
    'contacted',
    'qualified',
    'demo_scheduled',
    'proposal_sent',
    'negotiation',
    'converted',
    'lost',
    'junk',
  ];
  static const sources = <String>[
    'lead',
    'digital_marketing',
    'webapp',
    'meta',
    'google',
    'contactform',
    'enquiryform',
    'indiamart',
    'justdial',
  ];
  static const types = <String>[
    'call',
    'whatsapp',
    'email',
    'meeting',
    'demo',
    'video_call',
    'site_visit',
    'proposal_sent',
    'quotation_sent',
  ];
  static const outcomes = <String>[
    'interested',
    'not_interested',
    'callback_later',
    'converted',
    'no_response',
    'meeting_scheduled',
    'proposal_requested',
    'negotiation',
    'lost',
  ];
  static const priorities = <String>[
    'low',
    'medium',
    'high',
  ];
  static bool isClosed(String? status) =>
      const ['converted', 'lost', 'junk'].contains(status);
  static String label(String value) => value
      .split('_')
      .where((s) => s.isNotEmpty)
      .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
      .join(' ');

  static Map<String, String> options(dynamic value) {
    final result = <String, String>{};
    if (value is Map) {
      for (final entry in value.entries) {
        final item = entry.value;
        final slug = item is Map
            ? item['value'] ?? item['slug'] ?? entry.key
            : entry.key;
        result[slug.toString()] = item is Map
            ? (item['label'] ?? item['name'] ?? label(slug.toString()))
                  .toString()
            : item.toString();
      }
    } else if (value is List) {
      for (final item in value) {
        final slug = item is Map
            ? item['value'] ?? item['slug'] ?? item['id']
            : item;
        if (slug == null) continue;
        result[slug.toString()] = item is Map
            ? (item['label'] ?? item['name'] ?? label(slug.toString()))
                  .toString()
            : label(slug.toString());
      }
    }
    return result;
  }

  static Map<String, String> validateConversation({
    required DateTime now,
    required DateTime date,
    required String type,
    required String outcome,
    required String notes,
    required String status,
    DateTime? nextDate,
    String lostReason = '',
    String wonValue = '',
    bool createReminder = false,
  }) {
    final errors = <String, String>{};
    if (date.isAfter(now))
      errors['followup_date'] = 'Conversation date cannot be in the future.';
    if (!types.contains(type))
      errors['followup_type'] = 'Select a conversation type.';
    if (!outcomes.contains(outcome)) errors['outcome'] = 'Select an outcome.';
    if (notes.trim().isEmpty || notes.trim().length > 5000) {
      errors['discussion_notes'] =
          'Enter discussion notes (maximum 5000 characters).';
    }
    if (!isClosed(status)) {
      if (nextDate != null && !nextDate.isAfter(now)) {
        errors['next_followup_date'] = 'Next follow-up must be in the future.';
      }
      if (nextDate == null &&
          const ['callback_later', 'meeting_scheduled'].contains(outcome)) {
        errors['next_followup_date'] =
            'Schedule the next follow-up for this outcome.';
      }
      if (createReminder && nextDate == null)
        errors['next_followup_date'] =
            'Choose a next date to create a reminder.';
    }
    if (const ['converted', 'lost'].contains(outcome) && status != outcome) {
      errors['lead_status_after_followup'] =
          'Select ${label(outcome)} status for this outcome.';
    }
    if (status == 'lost' && lostReason.trim().isEmpty)
      errors['lost_reason'] = 'Lost reason is required.';
    final amount = double.tryParse(wonValue.trim());
    if (wonValue.trim().isNotEmpty &&
        (amount == null || !amount.isFinite || amount < 0)) {
      errors['won_value'] = 'Enter a valid value of zero or more.';
    }
    return errors;
  }
}
