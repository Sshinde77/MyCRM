import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/utils/app_snackbar.dart';
import '../models/company_information_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class CompanyInformationScreen extends StatefulWidget {
  const CompanyInformationScreen({super.key});

  @override
  State<CompanyInformationScreen> createState() =>
      _CompanyInformationScreenState();
}

class _CompanyInformationScreenState extends State<CompanyInformationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();
  final _gstController = TextEditingController();

  TimeOfDay? _officeStartTime;
  TimeOfDay? _lunchStartTime;
  TimeOfDay? _lunchEndTime;
  TimeOfDay? _officeEndTime;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyInformation();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyInformation() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.instance.getCompanyInformation();
      _companyNameController.text = data.companyName;
      _companyEmailController.text = data.companyEmail;
      _companyPhoneController.text = data.companyPhone;
      _websiteController.text = data.website;
      _addressController.text = data.address;
      _cityController.text = data.city;
      _stateController.text = data.state;
      _zipController.text = data.zip;
      _countryController.text = data.country;
      _gstController.text = data.gstNumber;

      _officeStartTime = _tryParseTime(data.officeStartTime);
      _lunchStartTime = _tryParseTime(data.lunchStartTime);
      _lunchEndTime = _tryParseTime(data.lunchEndTime);
      _officeEndTime = _tryParseTime(data.officeEndTime);
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        _messageFromError(error, fallback: 'Unable to load company data.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        'Unable to load company data.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickTime(
    TimeOfDay? current,
    ValueChanged<TimeOfDay> onSelected,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => onSelected(picked));
  }

  Future<void> _saveCompanyInformation() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (_officeStartTime == null ||
        _lunchStartTime == null ||
        _lunchEndTime == null ||
        _officeEndTime == null) {
      AppSnackbar.show(
        'Validation error',
        'All office and lunch times are required.',
        isError: true,
      );
      return;
    }

    final officeStartMinutes = _toMinutes(_officeStartTime!);
    final lunchStartMinutes = _toMinutes(_lunchStartTime!);
    final lunchEndMinutes = _toMinutes(_lunchEndTime!);
    final officeEndMinutes = _toMinutes(_officeEndTime!);

    final isValidOrder =
        officeStartMinutes < lunchStartMinutes &&
        lunchStartMinutes < lunchEndMinutes &&
        lunchEndMinutes < officeEndMinutes;

    if (!isValidOrder) {
      AppSnackbar.show(
        'Validation error',
        'Use: office start < lunch start < lunch end < office end.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = CompanyInformationModel(
        companyName: _companyNameController.text.trim(),
        companyEmail: _companyEmailController.text.trim(),
        companyPhone: _companyPhoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zip: _zipController.text.trim(),
        country: _countryController.text.trim(),
        website: _websiteController.text.trim(),
        gstNumber: _gstController.text.trim(),
        officeStartTime: _format24Hour(_officeStartTime!),
        lunchStartTime: _format24Hour(_lunchStartTime!),
        lunchEndTime: _format24Hour(_lunchEndTime!),
        officeEndTime: _format24Hour(_officeEndTime!),
      );

      final updated = await ApiService.instance.updateCompanyInformation(
        payload,
      );
      _officeStartTime =
          _tryParseTime(updated.officeStartTime) ?? _officeStartTime;
      _lunchStartTime =
          _tryParseTime(updated.lunchStartTime) ?? _lunchStartTime;
      _lunchEndTime = _tryParseTime(updated.lunchEndTime) ?? _lunchEndTime;
      _officeEndTime = _tryParseTime(updated.officeEndTime) ?? _officeEndTime;

      if (!mounted) return;
      setState(() {});
      AppSnackbar.show(
        'Saved',
        'Company information saved successfully.',
        isSuccess: true,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Save failed',
        _messageFromError(error, fallback: 'Unable to save company data.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Save failed',
        'Unable to save company data.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _messageFromError(DioException error, {required String fallback}) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    final message = error.message?.trim() ?? '';
    return message.isEmpty ? fallback : message;
  }

  TimeOfDay? _tryParseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  String _format24Hour(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _displayTime(TimeOfDay? time) {
    if (time == null) return '';
    return _format24Hour(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonScreenAppBar(title: 'Company Information'),
      backgroundColor: const Color(0xFFF4F8FC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCompanyInformation,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Company Information',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 700;
                            return Column(
                              children: [
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildTextField(
                                    label: 'Company Name *',
                                    controller: _companyNameController,
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'Company name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  right: _buildTextField(
                                    label: 'Company Email *',
                                    controller: _companyEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      final email = (value ?? '').trim();
                                      if (email.isEmpty) {
                                        return 'Company email is required';
                                      }
                                      if (!email.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildTextField(
                                    label: 'Phone',
                                    controller: _companyPhoneController,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  right: _buildTextField(
                                    label: 'Website',
                                    controller: _websiteController,
                                    keyboardType: TextInputType.url,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label: 'Address',
                                  controller: _addressController,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 12),
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildTextField(
                                    label: 'City',
                                    controller: _cityController,
                                  ),
                                  right: _buildTextField(
                                    label: 'State',
                                    controller: _stateController,
                                  ),
                                  third: _buildTextField(
                                    label: 'ZIP Code',
                                    controller: _zipController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildTextField(
                                    label: 'Country',
                                    controller: _countryController,
                                  ),
                                  right: _buildTextField(
                                    label: 'GST Number',
                                    controller: _gstController,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE2E8F0),
                                ),
                                const SizedBox(height: 14),
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildTimeField(
                                    label: 'Office Start Time *',
                                    value: _officeStartTime,
                                    onTap: () => _pickTime(
                                      _officeStartTime,
                                      (time) => _officeStartTime = time,
                                    ),
                                  ),
                                  right: _buildTimeField(
                                    label: 'Office End Time *',
                                    value: _officeEndTime,
                                    onTap: () => _pickTime(
                                      _officeEndTime,
                                      (time) => _officeEndTime = time,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildTimeField(
                                    label: 'Lunch Start Time *',
                                    value: _lunchStartTime,
                                    onTap: () => _pickTime(
                                      _lunchStartTime,
                                      (time) => _lunchStartTime = time,
                                    ),
                                  ),
                                  right: _buildTimeField(
                                    label: 'Lunch End Time *',
                                    value: _lunchEndTime,
                                    onTap: () => _pickTime(
                                      _lunchEndTime,
                                      (time) => _lunchEndTime = time,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : _saveCompanyInformation,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF178BEB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Save Company Information',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPair({
    required bool isWide,
    required Widget left,
    required Widget right,
    Widget? third,
  }) {
    final widgets = [Expanded(child: left), Expanded(child: right)];
    if (third != null) {
      widgets.add(Expanded(child: third));
    }

    if (!isWide) {
      return Column(
        children: [
          left,
          const SizedBox(height: 12),
          right,
          if (third != null) ...[const SizedBox(height: 12), third],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widgets.length; i++) ...[
          widgets[i],
          if (i != widgets.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF178BEB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayTime(value),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(Icons.access_time_outlined, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
