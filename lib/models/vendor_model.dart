class VendorModel {
  const VendorModel({
    required this.id,
    required this.vendorName,
    required this.email,
    required this.contactNo,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.services = const <VendorServiceModel>[],
  });

  final String id;
  final String vendorName;
  final String email;
  final String contactNo;
  final String address;
  final String status;
  final String createdAt;
  final String updatedAt;
  final List<VendorServiceModel> services;

  bool get isActive {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    if (normalized == '1' || normalized == 'true') {
      return true;
    }
    if (normalized == '0' || normalized == 'false') {
      return false;
    }
    if (normalized.contains('inactive') ||
        normalized.contains('disabled') ||
        normalized.contains('blocked')) {
      return false;
    }
    return normalized.contains('active');
  }

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    final source = _extractSource(json);
    return VendorModel(
      id: _readString(source, const ['id', '_id', 'vendorId', 'vendor_id']),
      vendorName: _readString(source, const [
        'vendor_name',
        'vendorName',
        'name',
        'title',
        'company_name',
        'companyName',
      ]),
      email: _readString(source, const [
        'email',
        'email_id',
        'emailId',
        'contact_email',
        'primary_email',
      ]),
      contactNo: _readString(source, const [
        'contact_no',
        'contactNo',
        'phone',
        'mobile',
        'phone_number',
      ]),
      address: _readString(source, const [
        'address',
        'address_line1',
        'addressLine1',
        'location',
      ]),
      status: _readStatus(source),
      createdAt: _formatDateTime(
        _readString(source, const ['created_at', 'createdAt']),
      ),
      updatedAt: _formatDateTime(
        _readString(source, const ['updated_at', 'updatedAt']),
      ),
      services: _readServices(source),
    );
  }

  static Map<String, dynamic> _extractSource(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    for (final key in ['vendor', 'data', 'item', 'result', 'attributes']) {
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

  static List<VendorServiceModel> _readServices(Map<String, dynamic> json) {
    final rawServices = json['services'];
    if (rawServices is! List) {
      return const <VendorServiceModel>[];
    }

    return rawServices
        .whereType<Object?>()
        .map((entry) {
          if (entry is Map<String, dynamic>) {
            return VendorServiceModel.fromJson(entry);
          }
          if (entry is Map) {
            return VendorServiceModel.fromJson(
              entry.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
          return null;
        })
        .whereType<VendorServiceModel>()
        .toList(growable: false);
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

  static String _readStatus(Map<String, dynamic> json) {
    for (final key in ['status', 'is_active', 'active', 'state']) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      if (value is bool) {
        return value ? 'Active' : 'Inactive';
      }
      if (value is num) {
        return value == 0 ? 'Inactive' : 'Active';
      }

      final normalized = value.toString().trim();
      if (normalized.isEmpty) {
        continue;
      }
      if (normalized == '1' || normalized.toLowerCase() == 'true') {
        return 'Active';
      }
      if (normalized == '0' || normalized.toLowerCase() == 'false') {
        return 'Inactive';
      }
      return normalized;
    }

    return 'Inactive';
  }

  static String _formatDateTime(String value) {
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
}

class VendorServiceModel {
  const VendorServiceModel({
    required this.id,
    required this.clientId,
    required this.vendorId,
    required this.clientName,
    required this.serviceName,
    required this.serviceDetails,
    required this.remarkText,
    required this.remarkColor,
    required this.startDate,
    required this.endDate,
    required this.billingDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final String vendorId;
  final String clientName;
  final String serviceName;
  final String serviceDetails;
  final String remarkText;
  final String remarkColor;
  final String startDate;
  final String endDate;
  final String billingDate;
  final String status;
  final String createdAt;
  final String updatedAt;

  factory VendorServiceModel.fromJson(Map<String, dynamic> json) {
    final client = _readNestedMap(json['client']);
    return VendorServiceModel(
      id: VendorModel._readString(json, const [
        'id',
        'service_id',
        'serviceId',
      ]),
      clientId: VendorModel._readString(json, const ['client_id', 'clientId']),
      vendorId: VendorModel._readString(json, const ['vendor_id', 'vendorId']),
      clientName: VendorModel._readString(client, const [
        'cname',
        'name',
        'client_name',
        'clientName',
        'coname',
      ]),
      serviceName: VendorModel._readString(json, const [
        'service_name',
        'serviceName',
      ]),
      serviceDetails: _stripHtml(
        VendorModel._readString(json, const [
          'service_details',
          'serviceDetails',
        ]),
      ),
      remarkText: VendorModel._readString(json, const [
        'remark_text',
        'remarkText',
      ]),
      remarkColor: VendorModel._readString(json, const [
        'remark_color',
        'remarkColor',
      ]),
      startDate: _formatShortDate(
        VendorModel._readString(json, const ['start_date', 'startDate']),
      ),
      endDate: _formatShortDate(
        VendorModel._readString(json, const ['end_date', 'endDate']),
      ),
      billingDate: _formatShortDate(
        VendorModel._readString(json, const ['billing_date', 'billingDate']),
      ),
      status: VendorModel._readStatus(json),
      createdAt: VendorModel._formatDateTime(
        VendorModel._readString(json, const ['created_at', 'createdAt']),
      ),
      updatedAt: VendorModel._formatDateTime(
        VendorModel._readString(json, const ['updated_at', 'updatedAt']),
      ),
    );
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

  static String _stripHtml(String value) {
    if (value.isEmpty) {
      return '';
    }
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
    return '${local.day.toString().padLeft(2, '0')} '
        '${months[local.month - 1]} ${local.year}';
  }
}
