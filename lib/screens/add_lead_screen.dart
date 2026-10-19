import '../models/lead_flow.dart';
import '../core/services/in_app_notifications.dart';
import 'package:country_state_city_selector/country_state_city_selector.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_text_styles.dart';
import '../models/lead_form_options_model.dart';
import '../models/lead_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key, this.leadId});

  final String? leadId;

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _leadValueController = TextEditingController(
    text: '0',
  );
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoadingFormOptions = true;
  bool _isLoadingLead = false;
  bool _isSubmitting = false;
  String? _formOptionsError;
  String? _selectedStatus = 'new';
  final Set<String> _selectedTags = {};
  final Set<String> _selectedStaffIds = {};
  Map<String, String> _fieldErrors = {};
  List<String> _statusOptions = const [];
  List<String> _tagOptions = const [];
  List<LeadStaffOption> _staffOptions = const [];
  String _selectedCountry = 'India';
  String _selectedState = 'Maharashtra';
  String _selectedCity = 'Mumbai Suburban';

  bool get _isEditMode {
    final leadId = widget.leadId?.trim() ?? '';
    return leadId.isNotEmpty;
  }

  bool get _isBusy => _isLoadingFormOptions || _isLoadingLead;

  @override
  void initState() {
    super.initState();
    _loadLeadFormOptions();
    if (_isEditMode) {
      _loadLeadForEdit();
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _zipCodeController.dispose();
    _leadValueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadLeadFormOptions() async {
    setState(() {
      _isLoadingFormOptions = true;
      _formOptionsError = null;
    });

    try {
      final options = await ApiService.instance.getLeadFormOptions();
      if (!mounted) return;

      setState(() {
        _statusOptions = options.statuses.isEmpty
            ? LeadFlow.statuses
            : options.statuses;
        _tagOptions = options.tags;
        _staffOptions = options.staff;
        _selectedStatus = _resolveSelectedValue(
          _selectedStatus,
          _statusOptions,
        );

        _isLoadingFormOptions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _formOptionsError = 'Unable to load lead form options.';
        _isLoadingFormOptions = false;
      });
    }
  }

  Future<void> _loadLeadForEdit() async {
    final leadId = widget.leadId?.trim() ?? '';
    if (leadId.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingLead = true;
    });

    try {
      final lead = await ApiService.instance.getLeadDetail(leadId);
      if (!mounted) return;
      _applyLeadValues(lead);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Lead details unavailable',
        'Unable to load the lead for editing.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLead = false;
        });
      }
    }
  }

  Future<void> _reloadScreenData() async {
    await _loadLeadFormOptions();
    if (_isEditMode) {
      await _loadLeadForEdit();
    }
  }

  void _applyLeadValues(LeadModel lead) {
    _sourceController.text = lead.source?.trim() ?? '';
    _nameController.text = lead.name.trim();
    _emailController.text = lead.email?.trim() ?? '';
    _companyController.text = lead.company?.trim() ?? '';
    _positionController.text = lead.position?.trim() ?? '';
    _phoneController.text = lead.phone?.trim() ?? '';
    _websiteController.text = lead.website?.trim() ?? '';
    _addressController.text = lead.address?.trim() ?? '';
    _zipCodeController.text = lead.zipCode?.trim() ?? '';
    _leadValueController.text = _formatLeadValueForField(lead.amount);
    _descriptionController.text = lead.description?.trim() ?? '';

    setState(() {
      _selectedCountry = (lead.country?.trim().isNotEmpty ?? false)
          ? lead.country!.trim()
          : _selectedCountry;
      _selectedState = (lead.state?.trim().isNotEmpty ?? false)
          ? lead.state!.trim()
          : _selectedState;
      _selectedCity = (lead.city?.trim().isNotEmpty ?? false)
          ? lead.city!.trim()
          : _selectedCity;
      _selectedStatus =
          _resolveSelectedValue(lead.status?.trim(), _statusOptions) ??
          lead.status?.trim();
      _selectedTags
        ..clear()
        ..addAll(lead.tags);
      _selectedStaffIds
        ..clear()
        ..addAll(lead.assignedStaffIds);
    });
  }

  String? _resolveSelectedValue(String? current, List<String> options) {
    if (options.isEmpty) {
      return null;
    }
    if (current != null && options.contains(current)) {
      return current;
    }
    return options.contains('new') ? 'new' : options.first;
  }

  String _formatLeadValueForField(double? value) {
    if (value == null) {
      return '';
    }
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSubmitting) {
      return;
    }

    final parsedLeadValue = double.tryParse(_leadValueController.text.trim());
    final assignedValues = _selectedStaffIds
        .map((id) => int.tryParse(id) ?? id)
        .toList();
    final tags = _selectedTags.toList();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final company = _companyController.text.trim();
      final position = _positionController.text.trim();
      final website = _websiteController.text.trim();
      final address = _addressController.text.trim();
      final city = _selectedCity.trim();
      final state = _selectedState.trim();
      final country = _selectedCountry.trim();
      final zipCode = _zipCodeController.text.trim();
      final source = _sourceController.text.trim();
      final description = _descriptionController.text.trim();
      final status = (_selectedStatus ?? '').trim();

      if (_isEditMode) {
        await ApiService.instance.updateLead(
          id: widget.leadId!.trim(),
          name: name,
          email: email,
          phone: phone,
          company: company,
          position: position,
          website: website,
          address: address,
          city: city,
          state: state,
          country: country,
          zipCode: zipCode,
          leadValue: parsedLeadValue,
          source: source,
          assigned: assignedValues,
          tags: tags,
          description: description,
          status: status,
        );
      } else {
        await ApiService.instance.createLead(
          name: name,
          email: email,
          phone: phone,
          company: company,
          position: position,
          website: website,
          address: address,
          city: city,
          state: state,
          country: country,
          zipCode: zipCode,
          leadValue: parsedLeadValue,
          source: source,
          assigned: assignedValues,
          tags: tags,
          description: description,
          status: status,
        );
      }

      if (!mounted) {
        return;
      }

      AppSnackbar.show(
        _isEditMode ? 'Lead updated' : 'Lead created',
        _isEditMode
            ? 'The lead has been updated successfully.'
            : 'The lead has been created successfully.',
      );
      InAppNotifications.instance.refresh();
      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (mounted && error.response?.data is Map) {
        final errors = (error.response!.data as Map)['errors'];
        if (errors is Map)
          setState(
            () => _fieldErrors = {
              for (final e in errors.entries)
                e.key.toString(): e.value is List
                    ? (e.value as List).join('\n')
                    : e.value.toString(),
            },
          );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _formKey.currentState?.validate();
        });
      }
      if (!mounted) {
        return;
      }

      AppSnackbar.show(
        _isEditMode ? 'Update lead failed' : 'Create lead failed',
        _resolveSubmitError(error),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      AppSnackbar.show(
        _isEditMode ? 'Update lead failed' : 'Create lead failed',
        _isEditMode
            ? 'Unable to update the lead. Please try again.'
            : 'Unable to create the lead. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: CommonScreenAppBar(
        title: _isEditMode ? 'Edit Lead' : 'Add New Lead',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditMode ? 'Edit Lead' : 'Add New Lead',
                        style: AppTextStyles.style(
                          color: const Color(0xFF0F172A),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 18),
                      if (_isBusy || _formOptionsError != null) ...[
                        _FormOptionsStatusCard(
                          isLoading: _isBusy,
                          errorMessage: _formOptionsError,
                          onRetry: () {
                            _reloadScreenData();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _ResponsiveFormGrid(
                        children: [
                          _TextFieldTile(
                            label: 'Source',
                            controller: _sourceController,
                            hintText: 'Enter lead source',
                            validator: (v) => _fieldErrors['source'],
                          ),
                          _DropdownTile(
                            label: 'Status',
                            value: _selectedStatus,
                            hintText: 'Select status',
                            items: _statusOptions
                                .map(
                                  (item) => _DropdownItem(
                                    value: item,
                                    label: LeadFlow.label(item),
                                  ),
                                )
                                .toList(growable: false),
                            enabled: !_isBusy && _statusOptions.isNotEmpty,
                            validator: (v) =>
                                _fieldErrors['status'] ?? _requiredValidator(v),
                            onChanged: (value) {
                              setState(() => _selectedStatus = value);
                            },
                          ),
                          _MultiSelectTile(
                            label: 'Assigned Staff',
                            options: {
                              for (final o in _staffOptions)
                                if (o.id.isNotEmpty) o.id: o.name,
                              for (final id in _selectedStaffIds)
                                id:
                                    _staffOptions
                                        .where((o) => o.id == id)
                                        .map((o) => o.name)
                                        .firstOrNull ??
                                    id,
                            },
                            selected: _selectedStaffIds,
                            enabled: !_isBusy && !_isSubmitting,
                            error: _fieldErrors.entries
                                .where(
                                  (e) =>
                                      e.key == 'assigned' ||
                                      e.key.startsWith('assigned.'),
                                )
                                .map((e) => e.value)
                                .firstOrNull,
                            onChanged: () => setState(() {}),
                          ),
                          _MultiSelectTile(
                            label: 'Tags',
                            options: {
                              for (final t in {
                                ..._tagOptions,
                                ..._selectedTags,
                              })
                                if (t.isNotEmpty) t: t,
                            },
                            selected: _selectedTags,
                            enabled: !_isBusy && !_isSubmitting,
                            error: _fieldErrors.entries
                                .where(
                                  (e) =>
                                      e.key == 'tags' ||
                                      e.key.startsWith('tags.'),
                                )
                                .map((e) => e.value)
                                .firstOrNull,
                            onChanged: () => setState(() {}),
                          ),
                          _TextFieldTile(
                            label: 'Name',
                            controller: _nameController,
                            hintText: 'Enter lead name (optional)',
                            validator: (v) => _fieldErrors['name'],
                          ),
                          _TextFieldTile(
                            label: 'Email Address',
                            controller: _emailController,
                            hintText: 'Enter email address',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                _fieldErrors['email'] ??
                                ((v ?? '').trim().isEmpty ||
                                        RegExp(
                                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                        ).hasMatch(v!.trim())
                                    ? null
                                    : 'Enter a valid email address.'),
                          ),
                          _TextFieldTile(
                            label: 'Company',
                            controller: _companyController,
                            hintText: 'Enter company name',
                          ),
                          _TextFieldTile(
                            label: 'Position',
                            controller: _positionController,
                            hintText: 'Enter position',
                          ),
                          _TextFieldTile(
                            label: 'Phone',
                            controller: _phoneController,
                            hintText: 'Enter phone number',
                            keyboardType: TextInputType.phone,
                          ),
                          _TextFieldTile(
                            label: 'Website',
                            controller: _websiteController,
                            hintText: 'Enter website URL',
                            keyboardType: TextInputType.url,
                            validator: (v) {
                              if (_fieldErrors['website'] != null)
                                return _fieldErrors['website'];
                              if ((v ?? '').trim().isEmpty) return null;
                              final uri = Uri.tryParse(v!.trim());
                              return uri != null &&
                                      const [
                                        'http',
                                        'https',
                                      ].contains(uri.scheme) &&
                                      uri.host.isNotEmpty
                                  ? null
                                  : 'Enter a valid website URL.';
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _TextFieldTile(
                        label: 'Address',
                        controller: _addressController,
                        hintText: 'Enter full address',
                      ),
                      const SizedBox(height: 16),
                      _LocationPickerCard(
                        initialCountry: _selectedCountry,
                        initialState: _selectedState,
                        initialCity: _selectedCity,
                        onChanged: (country, state, city) {
                          setState(() {
                            _selectedCountry = country.isEmpty
                                ? 'India'
                                : country;
                            _selectedState = state.isEmpty
                                ? 'Maharashtra'
                                : state;
                            _selectedCity = city.isEmpty
                                ? 'Mumbai Suburban'
                                : city;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _ResponsiveFormGrid(
                        children: [
                          _TextFieldTile(
                            label: 'Zip Code',
                            controller: _zipCodeController,
                            hintText: 'Enter zip code',
                            keyboardType: TextInputType.number,
                          ),
                          _TextFieldTile(
                            label: 'Lead Value',
                            controller: _leadValueController,
                            hintText: 'Enter lead value',
                            validator: (v) {
                              if (_fieldErrors['lead_value'] != null)
                                return _fieldErrors['lead_value'];
                              if ((v ?? '').trim().isEmpty) return null;
                              final n = double.tryParse(v!.trim());
                              return n != null && n.isFinite && n >= 0
                                  ? null
                                  : 'Enter a value of zero or more.';
                            },
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _TextFieldTile(
                        label: 'Description',
                        controller: _descriptionController,
                        hintText: 'Enter description',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isSubmitting || _isBusy)
                              ? null
                              : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D8EF0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _isEditMode ? 'Update Lead' : 'Add Lead',
                                  style: AppTextStyles.style(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _resolveSubmitError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString().trim() ?? '';
      if (message.isNotEmpty) {
        return message;
      }

      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first.toString().trim();
            if (first.isNotEmpty) {
              return first;
            }
          }

          final text = value?.toString().trim() ?? '';
          if (text.isNotEmpty) {
            return text;
          }
        }
      }
    }

    final fallback = error.message?.trim() ?? '';
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'Unable to create the lead. Please try again.';
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}

class _FormOptionsStatusCard extends StatelessWidget {
  const _FormOptionsStatusCard({
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? const Color(0xFFFDBA74) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFF9A3412),
              size: 20,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isLoading
                  ? 'Loading source, status, tag, and staff options...'
                  : errorMessage!,
              style: AppTextStyles.style(
                color: const Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasError)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ResponsiveFormGrid extends StatelessWidget {
  const _ResponsiveFormGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleColumn = constraints.maxWidth < 720;
        final fieldWidth = isSingleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children
              .map((child) => SizedBox(width: fieldWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _TextFieldTile extends StatelessWidget {
  const _TextFieldTile({
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFFAFCFF),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 14 : 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1D8EF0)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.hintText,
    required this.onChanged,
    this.enabled = true,
    this.validator,
  });

  final String label;
  final String? value;
  final List<_DropdownItem> items;
  final String hintText;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.any((item) => item.value == value) ? value : null,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          hint: Text(hintText),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFAFCFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1D8EF0)),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.value,
                  child: Text(item.label),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _DropdownItem {
  const _DropdownItem({required this.value, required this.label});

  final String value;
  final String label;
}

class _LocationPickerCard extends StatelessWidget {
  const _LocationPickerCard({
    required this.initialCountry,
    required this.initialState,
    required this.initialCity,
    required this.onChanged,
  });

  final String initialCountry;
  final String initialState;
  final String initialCity;
  final void Function(String country, String state, String city) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: AppTextStyles.style(
            color: const Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFCFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD9E2EC)),
          ),
          child: CountryStateCitySelector(
            enableLabels: true,
            initialCountry: initialCountry,
            initialState: initialState,
            initialCity: initialCity,
            defaultCountry: 'India',
            countryHintText: 'Country',
            stateHintText: 'State',
            cityHintText: 'City',
            fillColor: Colors.white,
            borderColor: const Color(0xFFD9E2EC),
            borderWidth: 1,
            labelColor: const Color(0xFF475569),
            labelFontSize: 13,
            labelFontWeight: FontWeight.w600,
            selectedTextColor: const Color(0xFF0F172A),
            selectedTextFontSize: 14,
            selectedTextFontWeight: FontWeight.w500,
            pickerItemTextColor: const Color(0xFF0F172A),
            pickerItemFontSize: 14,
            pickerItemFontWeight: FontWeight.w500,
            modalBackgroundColor: Colors.white,
            modalTitleColor: const Color(0xFF0F172A),
            modalTitleFontSize: 18,
            modalTitleFontWeight: FontWeight.w700,
            onSelectionChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _MultiSelectTile extends StatelessWidget {
  const _MultiSelectTile({
    required this.label,
    required this.options,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    this.error,
  });
  final String label;
  final Map<String, String> options;
  final Set<String> selected;
  final bool enabled;
  final VoidCallback onChanged;
  final String? error;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: !enabled
            ? null
            : () async {
                final draft = {...selected};
                final accepted = await showDialog<bool>(
                  context: context,
                  builder: (context) => StatefulBuilder(
                    builder: (context, update) => AlertDialog(
                      title: Text(label),
                      content: SizedBox(
                        width: 420,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final e in options.entries)
                                CheckboxListTile(
                                  title: Text(e.value),
                                  value: draft.contains(e.key),
                                  onChanged: (v) => update(() {
                                    if (v == true) {
                                      draft.add(e.key);
                                    } else {
                                      draft.remove(e.key);
                                    }
                                  }),
                                ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                );
                if (accepted == true) {
                  selected
                    ..clear()
                    ..addAll(draft);
                  onChanged();
                }
              },
        child: InputDecorator(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            errorText: error,
            enabled: enabled,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            selected.isEmpty
                ? 'Select (optional)'
                : selected.map((id) => options[id] ?? id).join(', '),
          ),
        ),
      ),
    ],
  );
}
