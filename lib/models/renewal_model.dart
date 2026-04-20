class RenewalModel {
  const RenewalModel({
    required this.id,
    required this.clientId,
    required this.vendorId,
    required this.title,
    required this.client,
    required this.clientEmail,
    required this.vendor,
    required this.vendorEmail,
    required this.serviceDetails,
    required this.remarkText,
    required this.remarkColor,
    required this.planType,
    required this.remark,
    required this.startDate,
    required this.endDate,
    required this.startDateValue,
    required this.endDateValue,
    required this.billing,
    required this.billingDateValue,
    required this.status,
    required this.expiryNote,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final String vendorId;
  final String title;
  final String client;
  final String clientEmail;
  final String vendor;
  final String vendorEmail;
  final String serviceDetails;
  final String remarkText;
  final String remarkColor;
  final String planType;
  final String remark;
  final String startDate;
  final String endDate;
  final DateTime? startDateValue;
  final DateTime? endDateValue;
  final String billing;
  final DateTime? billingDateValue;
  final String status;
  final String expiryNote;
  final String createdAt;
  final String updatedAt;

  String get durationText {
    final start = startDateValue;
    final end = endDateValue;
    if (start == null || end == null) return '';
    final diff = end.difference(start).inDays + 1;
    if (diff <= 0) return '';
    return '$diff days';
  }

  bool get showExpiryAlert {
    if (expiryNote.trim().isNotEmpty) {
      return true;
    }

    final normalizedStatus = status.trim().toLowerCase();
    return normalizedStatus.contains('overdue') ||
        normalizedStatus.contains('expire') ||
        normalizedStatus.contains('due');
  }

  factory RenewalModel.fromJson(Map<String, dynamic> json) {
    final source = _extractSource(json);
    final clientMap = _readNestedMap(source['client']);
    final vendorMap = _readNestedMap(source['vendor']);

    final rawStartDate = _readString(source, const [
      'start_date',
      'startDate',
      'renewal_start_date',
      'from_date',
      'fromDate',
    ]);
    final rawEndDate = _readString(source, const [
      'end_date',
      'endDate',
      'renewal_date',
      'renewalDate',
      'expiry_date',
      'expiryDate',
      'to_date',
      'toDate',
    ]);
    final rawBillingDate = _readString(source, const [
      'billing_date',
      'billingDate',
      'billing',
      'due_date',
      'dueDate',
    ]);

    final title = _readString(source, const [
      'service_name',
      'serviceName',
      'service',
      'title',
      'name',
      'plan_name',
      'planName',
      'renewal_name',
      'renewalName',
    ]);

    final client = _firstNonEmpty([
      _readString(source, const [
        'client_name',
        'clientName',
        'client',
        'customer_name',
        'customerName',
      ]),
      _readString(clientMap, const [
        'name',
        'client_name',
        'clientName',
        'cname',
        'company_name',
        'companyName',
      ]),
    ]);

    final vendor = _firstNonEmpty([
      _readString(source, const [
        'vendor_name',
        'vendorName',
        'vendor',
        'provider_name',
        'providerName',
      ]),
      _readString(vendorMap, const [
        'name',
        'vendor_name',
        'vendorName',
        'company_name',
        'companyName',
      ]),
    ]);

    return RenewalModel(
      id: _readString(source, const [
        'id',
        '_id',
        'renewal_id',
        'renewalId',
        'service_id',
        'serviceId',
      ]),
      clientId: _firstNonEmpty([
        _readString(source, const ['client_id', 'clientId']),
        _readString(clientMap, const ['id', 'client_id', 'clientId']),
      ]),
      vendorId: _firstNonEmpty([
        _readString(source, const ['vendor_id', 'vendorId']),
        _readString(vendorMap, const ['id', 'vendor_id', 'vendorId']),
      ]),
      title: title.isEmpty ? 'Service' : title,
      client: client.isEmpty ? 'Unknown client' : client,
      clientEmail: _readString(source, const [
        'client_email',
        'clientEmail',
        'customer_email',
        'customerEmail',
      ]),
      vendor: vendor.isEmpty ? 'Unknown vendor' : vendor,
      vendorEmail: _firstNonEmpty([
        _readString(source, const [
          'email_id',
          'emailId',
          'email',
          'vendor_email',
          'vendorEmail',
          'provider_email',
          'providerEmail',
        ]),
        _readString(vendorMap, const [
          'email_id',
          'emailId',
          'email',
          'vendor_email',
          'vendorEmail',
        ]),
      ]),
      serviceDetails: _readString(source, const [
        'service_details',
        'serviceDetails',
        'details',
        'description',
      ]),
      remarkText: _readString(source, const ['remark_text', 'remarkText']),
      remarkColor: _readString(source, const ['remark_color', 'remarkColor']),
      planType: _readString(source, const [
        'plan_type',
        'planType',
        'billing_cycle',
        'billingCycle',
        'billing_type',
        'billingType',
      ]),
      remark: _readString(source, const [
        'remark',
        'remark_text',
        'remarkText',
      ]),
      startDate: _formatShortDate(rawStartDate),
      endDate: _formatShortDate(rawEndDate),
      startDateValue: _tryParseDate(rawStartDate),
      endDateValue: _tryParseDate(rawEndDate),
      billing: _formatShortDate(rawBillingDate),
      billingDateValue: _tryParseDate(rawBillingDate),
      status: _normalizeStatus(source),
      expiryNote: _readString(source, const [
        'expiry_note',
        'expiryNote',
        'remark_text',
        'remarkText',
        'note',
      ]),
      createdAt: _formatDateTime(
        _readString(source, const ['created_at', 'createdAt']),
      ),
      updatedAt: _formatDateTime(
        _readString(source, const [
          'updated_at',
          'updatedAt',
          'last_updated',
          'lastUpdated',
          'modified_at',
          'modifiedAt',
        ]),
      ),
    );
  }

  static Map<String, dynamic> _extractSource(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    for (final key in const [
      'renewal',
      'data',
      'item',
      'result',
      'attributes',
    ]) {
      final value = normalized[key];
      if (value is Map<String, dynamic>) {
        final merged = Map<String, dynamic>.from(normalized);
        merged.addAll(value);
        return merged;
      }
      if (value is Map) {
        final merged = Map<String, dynamic>.from(normalized);
        merged.addAll(value.map((k, v) => MapEntry(k.toString(), v)));
        return merged;
      }
    }
    return normalized;
  }

  static Map<String, dynamic> _readNestedMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const <String, dynamic>{};
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return '';
  }

  static String _firstNonEmpty(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return '';
  }

  static String _normalizeStatus(Map<String, dynamic> json) {
    final raw = _readString(json, const [
      'status',
      'renewal_status',
      'renewalStatus',
      'state',
      'is_active',
      'active',
    ]);
    if (raw.isEmpty) {
      return 'Unknown';
    }

    final normalized = raw.toLowerCase();
    if (normalized == '1' || normalized == 'true' || normalized == 'active') {
      return 'Active';
    }
    if (normalized == '0' ||
        normalized == 'false' ||
        normalized == 'inactive') {
      return 'Inactive';
    }

    return raw;
  }

  static String _formatShortDate(String value) {
    if (value.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
  }

  static String _formatDateTime(String value) {
    if (value.isEmpty) {
      return '';
    }

    final parsed = _tryParseDate(value);
    if (parsed == null) {
      return value;
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final local = parsed.toLocal();
    final hour24 = local.hour;
    final hour12 = hour24 == 0
        ? 12
        : hour24 > 12
        ? hour24 - 12
        : hour24;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'PM' : 'AM';

    return '${local.day.toString().padLeft(2, '0')} '
        '${months[local.month - 1]} ${local.year}, '
        '${hour12.toString().padLeft(2, '0')}:$minute $suffix';
  }

  static DateTime? _tryParseDate(String value) {
    if (value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;

    final ddMmYyyy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(value);
    if (ddMmYyyy != null) {
      return DateTime.tryParse(
        '${ddMmYyyy.group(3)}-${ddMmYyyy.group(2)}-${ddMmYyyy.group(1)}',
      );
    }

    return null;
  }
}
