import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_text_styles.dart';
import '../models/renewal_model.dart';
import '../models/vendor_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class VendorRenewalFormScreen extends StatelessWidget {
  const VendorRenewalFormScreen({super.key, this.initialRenewal});

  final RenewalModel? initialRenewal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: CommonScreenAppBar(
        title: (initialRenewal?.id.trim().isNotEmpty ?? false)
            ? 'Edit Vendor Service'
            : 'Add Vendor Service',
      ),
      body: VendorRenewalFormSheet(initialRenewal: initialRenewal),
    );
  }
}

class VendorRenewalFormSheet extends StatefulWidget {
  const VendorRenewalFormSheet({super.key, this.initialRenewal});

  final RenewalModel? initialRenewal;

  @override
  State<VendorRenewalFormSheet> createState() => _VendorRenewalFormSheetState();
}

class _VendorRenewalFormSheetState extends State<VendorRenewalFormSheet> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _serviceDetailsController =
      TextEditingController();

  List<VendorModel> _vendors = const <VendorModel>[];

  String? _renewalId;
  String? _selectedVendorId;
  String _seedVendorName = '';
  String _selectedPlanType = 'monthly';
  String _selectedStatus = 'active';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _billingDate;

  bool _isLoadingOptions = false;
  bool _isLoadingDetail = false;
  bool _isSubmitting = false;

  bool get _isEditMode => (_renewalId ?? '').isNotEmpty;

  static const List<String> _defaultPlanTypes = <String>[
    'monthly',
    'quarterly',
    'half-yearly',
    'yearly',
    'one-time',
  ];

  static const List<String> _statusValues = <String>[
    'active',
    'inactive',
    'pending',
    'expired',
  ];

  @override
  void initState() {
    super.initState();
    _applyRenewalSeed(widget.initialRenewal);
    _loadFormData();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _serviceDetailsController.dispose();
    super.dispose();
  }

  void _applyRenewalSeed(RenewalModel? renewal) {
    if (renewal == null) {
      return;
    }

    _renewalId = renewal.id.trim().isEmpty ? null : renewal.id.trim();
    _selectedVendorId = renewal.vendorId.trim().isEmpty
        ? null
        : renewal.vendorId.trim();
    _seedVendorName = renewal.vendor.trim();
    _serviceNameController.text = renewal.title.trim();
    _serviceDetailsController.text = renewal.serviceDetails.trim();
    _selectedPlanType = _normalizePlanTypeForForm(renewal.planType);
    _selectedStatus = _normalizeStatusForForm(renewal.status);
    _startDate = renewal.startDateValue;
    _endDate = renewal.endDateValue;
    _billingDate = renewal.billingDateValue;
  }

  String _normalizeStatusForForm(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    if (normalized.contains('inactive') || normalized == '0') {
      return 'inactive';
    }
    if (normalized.contains('pending')) {
      return 'pending';
    }
    if (normalized.contains('expired') || normalized.contains('expire')) {
      return 'expired';
    }
    if (normalized.contains('active') || normalized == '1') {
      return 'active';
    }
    return _statusValues.contains(normalized) ? normalized : 'active';
  }

  String _normalizePlanTypeForForm(String rawPlanType) {
    final normalized = rawPlanType.trim().toLowerCase();
    return normalized.isEmpty ? 'monthly' : normalized;
  }

  List<String> get _planTypeOptions {
    final values = <String>{..._defaultPlanTypes};
    if (_selectedPlanType.trim().isNotEmpty) {
      values.add(_selectedPlanType.trim().toLowerCase());
    }
    return values.toList(growable: false);
  }

  Future<void> _loadFormData() async {
    await _loadLookupData();
    if (_isEditMode) {
      await _loadRenewalDetail();
    }
  }

  Future<void> _loadLookupData() async {
    setState(() => _isLoadingOptions = true);
    try {
      final vendors = await _apiService.getVendorsList();
      _vendors = vendors
          .where((vendor) => vendor.id.trim().isNotEmpty)
          .toList(growable: false);
      _syncVendorSelectionWithLookup();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        title: 'Unable to load vendors',
        message: _readError(error, fallback: 'Please try again later.'),
        backgroundColor: const Color(0xFFB45309),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
      }
    }
  }

  Future<void> _loadRenewalDetail() async {
    final id = (_renewalId ?? '').trim();
    if (id.isEmpty) {
      return;
    }

    setState(() => _isLoadingDetail = true);
    try {
      final detail = await _apiService.getVendorRenewalDetail(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _applyRenewalSeed(detail);
        _syncVendorSelectionWithLookup();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        title: 'Unable to load service detail',
        message: _readError(error, fallback: 'Please try again later.'),
        backgroundColor: const Color(0xFFB45309),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  String? _validate() {
    if ((_selectedVendorId ?? '').trim().isEmpty) {
      return 'Vendor is required.';
    }
    if (_serviceNameController.text.trim().isEmpty) {
      return 'Service name is required.';
    }
    if (_selectedPlanType.trim().isEmpty) {
      return 'Plan type is required.';
    }
    if (_startDate == null) {
      return 'Start date is required.';
    }
    if (_endDate == null) {
      return 'End date is required.';
    }
    if (_billingDate == null) {
      return 'Billing date is required.';
    }
    if (_startDate!.isAfter(_endDate!)) {
      return 'End date must be on or after start date.';
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      _showSnack(
        title: 'Missing details',
        message: validationError,
        backgroundColor: const Color(0xFFB45309),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        await _apiService.updateVendorRenewal(
          id: _renewalId!,
          vendorId: _selectedVendorId!,
          serviceName: _serviceNameController.text.trim(),
          serviceDetails: _serviceDetailsController.text.trim(),
          planType: _selectedPlanType,
          startDate: _startDate!,
          endDate: _endDate!,
          billingDate: _billingDate!,
          status: _selectedStatus,
        );
      } else {
        await _apiService.createVendorRenewal(
          vendorId: _selectedVendorId!,
          serviceName: _serviceNameController.text.trim(),
          serviceDetails: _serviceDetailsController.text.trim(),
          planType: _selectedPlanType,
          startDate: _startDate!,
          endDate: _endDate!,
          billingDate: _billingDate!,
          status: _selectedStatus,
        );
      }

      if (!mounted) {
        return;
      }

      _showSnack(
        title: _isEditMode ? 'Service updated' : 'Service created',
        message: _isEditMode
            ? 'Vendor service has been updated successfully.'
            : 'Vendor service has been created successfully.',
        backgroundColor: const Color(0xFF153A63),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        title: _isEditMode ? 'Update failed' : 'Create failed',
        message: _readError(
          error,
          fallback: _isEditMode
              ? 'Failed to update vendor service.'
              : 'Failed to create vendor service.',
        ),
        backgroundColor: const Color(0xFFB91C1C),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) {
      return;
    }
    onPicked(DateTime(picked.year, picked.month, picked.day));
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'dd-mm-yyyy';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  String _normalizeLookupId(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return '';
    }

    final intValue = int.tryParse(normalized);
    if (intValue != null) {
      return intValue.toString();
    }

    final numValue = num.tryParse(normalized);
    if (numValue != null && numValue == numValue.toInt()) {
      return numValue.toInt().toString();
    }

    return normalized.toLowerCase();
  }

  void _syncVendorSelectionWithLookup() {
    if (_vendors.isEmpty) {
      return;
    }

    final candidateVendorId = (_selectedVendorId ?? '').trim();
    if (candidateVendorId.isNotEmpty) {
      final normalized = _normalizeLookupId(candidateVendorId);
      final matched = _vendors.where(
        (entry) => _normalizeLookupId(entry.id) == normalized,
      );
      if (matched.isNotEmpty) {
        _selectedVendorId = matched.first.id;
      }
    }

    if ((_selectedVendorId ?? '').trim().isEmpty &&
        _seedVendorName.isNotEmpty) {
      final matchedByName = _vendors.where(
        (entry) =>
            entry.vendorName.trim().toLowerCase() ==
            _seedVendorName.toLowerCase(),
      );
      if (matchedByName.isNotEmpty) {
        _selectedVendorId = matchedByName.first.id;
      }
    }
  }

  String _readError(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      final message = error.message?.trim() ?? '';
      if (message.isNotEmpty) {
        return message;
      }
    }
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? fallback : message;
  }

  void _showSnack({
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insetBottom = MediaQuery.of(context).viewInsets.bottom;
    final compact = MediaQuery.of(context).size.width <= 440;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: insetBottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            14,
            compact ? 12 : 16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VENDOR SERVICE FORM',
                style: AppTextStyles.style(
                  color: const Color(0xFF334155),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 12 : 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE6F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditMode
                          ? 'Edit Vendor Services'
                          : 'Add Vendor Services',
                      style: AppTextStyles.style(
                        color: const Color(0xFF17213A),
                        fontSize: compact ? 17 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isLoadingOptions || _isLoadingDetail) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    const SizedBox(height: 18),
                    _LabeledField(
                      label: 'Select Vendor',
                      required: true,
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            _vendors.any(
                              (entry) => entry.id == _selectedVendorId,
                            )
                            ? _selectedVendorId
                            : null,
                        items: _vendors
                            .map(
                              (vendor) => DropdownMenuItem<String>(
                                value: vendor.id,
                                child: Text(
                                  vendor.vendorName.trim().isEmpty
                                      ? 'Vendor #${vendor.id}'
                                      : vendor.vendorName,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _isSubmitting
                            ? null
                            : (value) =>
                                  setState(() => _selectedVendorId = value),
                        decoration: _inputDecoration('Choose a vendor...'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 760;
                        final itemWidth = isWide
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _LabeledField(
                                label: 'Service Name',
                                required: true,
                                child: TextField(
                                  controller: _serviceNameController,
                                  decoration: _inputDecoration(
                                    'Enter service name',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _LabeledField(
                                label: 'Plan Type',
                                required: true,
                                child: DropdownButtonFormField<String>(
                                  initialValue:
                                      _planTypeOptions.contains(
                                        _selectedPlanType,
                                      )
                                      ? _selectedPlanType
                                      : _planTypeOptions.first,
                                  items: _planTypeOptions
                                      .map(
                                        (entry) => DropdownMenuItem<String>(
                                          value: entry,
                                          child: Text(
                                            entry
                                                .split('-')
                                                .map(
                                                  (part) => part.isEmpty
                                                      ? part
                                                      : part[0].toUpperCase() +
                                                            part.substring(1),
                                                )
                                                .join('-'),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: _isSubmitting
                                      ? null
                                      : (value) {
                                          if (value == null) return;
                                          setState(
                                            () => _selectedPlanType = value,
                                          );
                                        },
                                  decoration: _inputDecoration(
                                    'Choose plan type...',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Service Details',
                      child: TextField(
                        controller: _serviceDetailsController,
                        maxLines: 4,
                        decoration: _inputDecoration(
                          'Enter detailed description of the service...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 900;
                        final itemWidth = isWide
                            ? (constraints.maxWidth - 36) / 4
                            : (constraints.maxWidth - 12) / 2;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _LabeledField(
                                label: 'Start Date',
                                required: true,
                                child: _DateInputField(
                                  text: _formatDate(_startDate),
                                  onTap: _isSubmitting
                                      ? null
                                      : () => _pickDate(
                                          initialDate: _startDate,
                                          onPicked: (date) =>
                                              setState(() => _startDate = date),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _LabeledField(
                                label: 'End Date',
                                required: true,
                                child: _DateInputField(
                                  text: _formatDate(_endDate),
                                  onTap: _isSubmitting
                                      ? null
                                      : () => _pickDate(
                                          initialDate: _endDate,
                                          onPicked: (date) =>
                                              setState(() => _endDate = date),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _LabeledField(
                                label: 'Billing Date',
                                required: true,
                                child: _DateInputField(
                                  text: _formatDate(_billingDate),
                                  onTap: _isSubmitting
                                      ? null
                                      : () => _pickDate(
                                          initialDate: _billingDate,
                                          onPicked: (date) => setState(
                                            () => _billingDate = date,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _LabeledField(
                                label: 'Status',
                                required: true,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedStatus,
                                  items: _statusValues
                                      .map(
                                        (entry) => DropdownMenuItem<String>(
                                          value: entry,
                                          child: Text(
                                            entry[0].toUpperCase() +
                                                entry.substring(1),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: _isSubmitting
                                      ? null
                                      : (value) {
                                          if (value == null) return;
                                          setState(
                                            () => _selectedStatus = value,
                                          );
                                        },
                                  decoration: _inputDecoration('Status'),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D8BFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isEditMode
                                        ? 'Update Vendor Services'
                                        : 'Save Vendor Services',
                                  ),
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              side: const BorderSide(color: Color(0xFFDCE6F2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1D8BFF)),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppTextStyles.style(
          color: const Color(0xFF334155),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ]
            : const [],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(text: label, required: required),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DateInputField extends StatelessWidget {
  const _DateInputField({required this.text, required this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE6F2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.style(
                  color: text == 'dd-mm-yyyy'
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}
