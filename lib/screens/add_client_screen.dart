import 'package:dio/dio.dart';
import 'package:country_state_city_selector/country_state_city_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/create_client_request_model.dart';
import '../models/update_client_request_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../models/client_detail_model.dart';
import '../widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key, this.clientId, this.isEdit = false});

  final String? clientId;
  final bool isEdit;

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _defaultDueDaysController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _clientType;
  String? _status;
  String? _priorityLevel;
  String? _billingType;
  String? _role;
  bool _sendWelcomeEmail = true;
  bool _isSubmitting = false;
  bool _isEditMode = false;
  bool _isLoading = false;
  String? _clientId;
  String _selectedCountry = 'India';
  String _selectedState = 'Maharashtra';
  String _selectedCity = 'Mumbai Suburban';

  @override
  void initState() {
    super.initState();
    _hydrateFromArgs();
  }

  void _hydrateFromArgs() {
    _countryController.text = _selectedCountry;
    _stateController.text = _selectedState;
    _cityController.text = _selectedCity;

    final args = Get.arguments;
    String? resolvedId = widget.clientId;
    bool editFlag = widget.isEdit;

    if (args is Map) {
      final rawId = args['id'] ?? args['clientId'] ?? args['client_id'];
      if (rawId != null) {
        resolvedId = rawId.toString();
      }
      final rawEdit = args['isEdit'];
      editFlag = rawEdit == true || rawEdit == 'true' || rawEdit == 1;
    } else if (args is String || args is int) {
      resolvedId = args.toString();
    }

    resolvedId ??= Get.parameters['id'];

    if (resolvedId != null && resolvedId.trim().isNotEmpty) {
      _clientId = resolvedId.trim();
      _isEditMode = editFlag || resolvedId.isNotEmpty;
      _loadClientDetail();
    }
  }

  Future<void> _loadClientDetail() async {
    if (_clientId == null) return;

    setState(() => _isLoading = true);

    try {
      final detail = await ApiService.instance.getClientDetail(_clientId!);
      _applyDetail(detail);
    } on DioException catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Unable to load client',
        'Please try again later.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyDetail(ClientDetailModel detail) {
    _clientNameController.text = detail.companyName.isNotEmpty
        ? detail.companyName
        : detail.name;
    _contactPersonController.text = detail.contactPerson;
    _emailController.text = detail.email;
    _phoneController.text = detail.phone;
    _websiteController.text = detail.website;
    _addressLine1Controller.text = detail.addressLine1;
    _addressLine2Controller.text = detail.addressLine2;
    _cityController.text = detail.city;
    _stateController.text = detail.state;
    _postalCodeController.text = detail.postalCode;
    _countryController.text = detail.country;
    _selectedCity = detail.city.trim().isNotEmpty
        ? detail.city
        : 'Mumbai Suburban';
    _selectedState = detail.state.trim().isNotEmpty
        ? detail.state
        : 'Maharashtra';
    _selectedCountry = detail.country.trim().isNotEmpty
        ? detail.country
        : 'India';
    _industryController.text = detail.industry;
    _defaultDueDaysController.text = detail.dueDays;

    _clientType = _matchValue(detail.clientType, const [
      'Individual',
      'Company',
      'Enterprise',
    ]);
    _status = _matchValue(detail.status, const ['Active', 'Inactive']);
    _priorityLevel = _matchValue(detail.priorityLevel, const [
      'Low',
      'Medium',
      'High',
    ]);
    _billingType = detail.billingType.trim().isNotEmpty
        ? detail.billingType
        : null;
    _role = detail.role.trim().isNotEmpty ? detail.role : 'client';

    setState(() {});
  }

  String? _matchValue(String value, List<String> options) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    for (final option in options) {
      if (option.toLowerCase() == normalized.toLowerCase()) {
        return option;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _industryController.dispose();
    _defaultDueDaysController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: CommonScreenAppBar(
        title: _isEditMode ? 'Edit Client' : 'Add Client',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditMode ? 'Edit Client' : 'Add New Client',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Fields marked with * are mandatory.',
                style: TextStyle(color: Colors.grey),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Basic Information',
                child: _ResponsiveFields(
                  children: [
                    _TextFieldTile(
                      label: 'Client Name',
                      isRequired: true,
                      controller: _clientNameController,
                      hintText: 'Enter client name',
                    ),
                    _TextFieldTile(
                      label: 'Contact Person',
                      isRequired: true,
                      controller: _contactPersonController,
                      hintText: 'Enter contact person name',
                    ),
                    _TextFieldTile(
                      label: 'Email',
                      isRequired: true,
                      controller: _emailController,
                      hintText: 'Enter email',
                      keyboardType: TextInputType.emailAddress,
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
                      hintText: 'https://example.com',
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Address Information',
                child: Column(
                  children: [
                    _ResponsiveFields(
                      children: [
                        _TextFieldTile(
                          label: 'Address Line 1',
                          isRequired: true,
                          controller: _addressLine1Controller,
                          hintText: 'Enter address line 1',
                        ),
                        _TextFieldTile(
                          label: 'Address Line 2',
                          controller: _addressLine2Controller,
                          hintText: 'Enter address line 2 (optional)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ClientLocationPickerCard(
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
                          _countryController.text = _selectedCountry;
                          _stateController.text = _selectedState;
                          _cityController.text = _selectedCity;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _ResponsiveFields(
                      children: [
                        _TextFieldTile(
                          label: 'Postal Code',
                          isRequired: true,
                          controller: _postalCodeController,
                          hintText: 'Enter postal code',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Business Information',
                child: _ResponsiveFields(
                  children: [
                    _DropdownFieldTile(
                      label: 'Client Type',
                      isRequired: true,
                      value: _clientType,
                      hintText: 'Select type',
                      items: _clientTypeItems(),
                      onChanged: (value) => setState(() => _clientType = value),
                    ),
                    _TextFieldTile(
                      label: 'Industry',
                      isRequired: true,
                      controller: _industryController,
                      hintText: 'Enter industry',
                    ),
                    _DropdownFieldTile(
                      label: 'Status',
                      isRequired: true,
                      value: _status,
                      hintText: 'Select status',
                      items: _statusItems(),
                      onChanged: (value) => setState(() => _status = value),
                    ),
                    _DropdownFieldTile(
                      label: 'Priority Level',
                      value: _priorityLevel,
                      hintText: 'Select priority',
                      items: _priorityItems(),
                      onChanged: (value) =>
                          setState(() => _priorityLevel = value),
                    ),
                    _DropdownFieldTile(
                      label: 'Billing Type',
                      value: _billingType,
                      hintText: 'Select billing type',
                      items: _billingTypeItems(),
                      onChanged: (value) =>
                          setState(() => _billingType = value),
                    ),
                    _TextFieldTile(
                      label: 'Default Due Days',
                      controller: _defaultDueDaysController,
                      hintText: 'Due days',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Login Information',
                child: Column(
                  children: [
                    _DropdownFieldTile(
                      label: 'Role',
                      value: _role,
                      hintText: 'Select role',
                      items: _roleItems(),
                      onChanged: (value) => setState(() => _role = value),
                    ),
                    const SizedBox(height: 12),
                    _TextFieldTile(
                      label: 'Password',
                      controller: _passwordController,
                      hintText: 'Enter password (minimum 8 characters)',
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _sendWelcomeEmail,
                      onChanged: (value) {
                        setState(() => _sendWelcomeEmail = value ?? true);
                      },
                      title: const Text('Send Welcome Email'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _isLoading
                      ? null
                      : (_isEditMode ? _submitUpdateClient : _submitClient),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D6FEA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(_isEditMode ? 'Update Client' : 'Add Client'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _billingTypeItems() {
    final items = ['Hourly', 'Fixed', 'Retainer'];
    if (_isEditMode && _billingType != null && !items.contains(_billingType)) {
      items.add(_billingType!);
    }
    return items;
  }

  List<String> _clientTypeItems() {
    final items = ['Individual', 'Company', 'Enterprise'];
    if (_isEditMode && _clientType != null && !items.contains(_clientType)) {
      items.add(_clientType!);
    }
    return items;
  }

  List<String> _statusItems() {
    final items = ['Active', 'Inactive'];
    if (_isEditMode && _status != null && !items.contains(_status)) {
      items.add(_status!);
    }
    return items;
  }

  List<String> _priorityItems() {
    final items = ['Low', 'Medium', 'High'];
    if (_isEditMode &&
        _priorityLevel != null &&
        !items.contains(_priorityLevel)) {
      items.add(_priorityLevel!);
    }
    return items;
  }

  List<String> _roleItems() {
    final items = ['super-admin', 'staff', 'client'];
    if (_isEditMode && _role != null && !items.contains(_role)) {
      items.add(_role!);
    }
    return items;
  }

  String? _validateForm() {
    if (_clientNameController.text.trim().isEmpty) {
      return 'Client name is required.';
    }
    if (_contactPersonController.text.trim().isEmpty) {
      return 'Contact person is required.';
    }
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      return 'Enter a valid email address.';
    }
    if (_addressLine1Controller.text.trim().isEmpty) {
      return 'Address line 1 is required.';
    }
    if (_cityController.text.trim().isEmpty) {
      return 'City is required.';
    }
    if (_stateController.text.trim().isEmpty) {
      return 'State is required.';
    }
    if (_postalCodeController.text.trim().isEmpty) {
      return 'Postal code is required.';
    }
    if (_countryController.text.trim().isEmpty) {
      return 'Country is required.';
    }
    if (_clientType == null || _clientType!.trim().isEmpty) {
      return 'Client type is required.';
    }
    if (_industryController.text.trim().isEmpty) {
      return 'Industry is required.';
    }
    if (_status == null || _status!.trim().isEmpty) {
      return 'Status is required.';
    }
    final dueDaysText = _defaultDueDaysController.text.trim();
    if (dueDaysText.isNotEmpty && int.tryParse(dueDaysText) == null) {
      return 'Default due days must be a number.';
    }
    final password = _passwordController.text.trim();
    if (password.isNotEmpty && password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  Future<void> _submitClient() async {
    final validationError = _validateForm();
    if (validationError != null) {
      AppSnackbar.show(
        'Missing details',
        validationError,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    final dueDays = int.tryParse(_defaultDueDaysController.text.trim());

    final request = CreateClientRequestModel(
      clientName: _clientNameController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      website: _websiteController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
      clientType: _clientType!.trim(),
      industry: _industryController.text.trim(),
      status: _status!.trim(),
      priorityLevel: _priorityLevel,
      assignedManagerId: null,
      defaultDueDays: dueDays,
      billingType: _billingType,
      role: _role?.trim().toLowerCase() ?? 'client',
      password: _passwordController.text.trim(),
      sendWelcomeEmail: _sendWelcomeEmail,
    );

    try {
      await ApiService.instance.createClient(request);
      if (!mounted) return;

      AppSnackbar.show(
        'Client created',
        'The client has been added successfully.',

      );
      Get.offNamed(AppRoutes.clients);
    } on DioException catch (error) {
      if (!mounted) return;

      final responseData = error.response?.data;
      String message = 'Failed to create client.';

      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      AppSnackbar.show(
        'Create client failed',
        message,

      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitUpdateClient() async {
    if (_clientId == null) {
      AppSnackbar.show(
        'Unable to update',
        'Client id is missing.',

      );
      return;
    }

    final validationError = _validateForm();
    if (validationError != null) {
      AppSnackbar.show(
        'Missing details',
        validationError,

      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    final dueDays = int.tryParse(_defaultDueDaysController.text.trim());

    final request = UpdateClientRequestModel(
      clientName: _clientNameController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      website: _websiteController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
      clientType: _clientType!.trim(),
      industry: _industryController.text.trim(),
      status: _status!.trim(),
      priorityLevel: _priorityLevel,
      assignedManagerId: null,
      defaultDueDays: dueDays,
      billingType: _billingType,
      role: _role?.trim().toLowerCase() ?? 'client',
      password: _passwordController.text.trim(),
      sendWelcomeEmail: _sendWelcomeEmail,
    );

    try {
      await ApiService.instance.updateClient(id: _clientId!, request: request);
      if (!mounted) return;

      AppSnackbar.show(
        'Client updated',
        'The client has been updated successfully.',

      );
      Get.offNamed(AppRoutes.clients);
    } on DioException catch (error) {
      if (!mounted) return;

      final responseData = error.response?.data;
      String message = 'Failed to update client.';

      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      AppSnackbar.show(
        'Update failed',
        message,

      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ClientLocationPickerCard extends StatelessWidget {
  const _ClientLocationPickerCard({
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          CountryStateCitySelector(
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
            labelFontSize: 12,
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
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final itemWidth = isWide
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          runSpacing: 12,
          spacing: 16,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _TextFieldTile extends StatelessWidget {
  const _TextFieldTile({
    required this.label,
    this.isRequired = false,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
  });

  final String label;
  final bool isRequired;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ]
                : const [],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1D6FEA)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownFieldTile extends StatelessWidget {
  const _DropdownFieldTile({
    required this.label,
    this.isRequired = false,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final bool isRequired;
  final String? value;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ]
                : const [],
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1D6FEA)),
            ),
          ),
        ),
      ],
    );
  }
}

