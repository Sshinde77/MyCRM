import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
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
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
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
  final TextEditingController _passwordController = TextEditingController();
  String? _profileImagePath;

  String? _clientType;
  String? _status;
  bool _isSubmitting = false;
  bool _isEditMode = false;
  bool _isLoading = false;
  String? _clientId;

  @override
  void initState() {
    super.initState();
    _hydrateFromArgs();
  }

  void _hydrateFromArgs() {
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
      AppSnackbar.show('Unable to load client', 'Please try again later.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyDetail(ClientDetailModel detail) {
    _companyNameController.text = detail.companyName;
    final contactName = detail.contactPerson.trim().isNotEmpty
        ? detail.contactPerson
        : detail.name;
    _applyContactName(contactName);
    _emailController.text = detail.email;
    _phoneController.text = detail.phone;
    _websiteController.text = detail.website;
    _addressLine1Controller.text = detail.addressLine1;
    _addressLine2Controller.text = detail.addressLine2;
    _cityController.text = detail.city;
    _stateController.text = detail.state;
    _postalCodeController.text = detail.postalCode;
    _countryController.text = detail.country;
    _industryController.text = detail.industry;

    _clientType = _matchValue(detail.clientType, const [
      'Individual',
      'Company',
      'Enterprise',
    ]);
    _status = _matchValue(detail.status, const ['Active', 'Inactive']);
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

  void _applyContactName(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.isEmpty) {
      _firstNameController.text = '';
      _lastNameController.text = '';
      return;
    }

    final parts = normalized.split(RegExp(r'\s+'));
    _firstNameController.text = parts.first.trim();
    _lastNameController.text = parts.length > 1
        ? parts.sublist(1).join(' ').trim()
        : '';
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.first.path;
    if (filePath == null || filePath.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _profileImagePath = filePath.trim());
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
                child: Column(
                  children: [
                    _FilePickerFieldTile(
                      label: 'Profile Image',
                      filePath: _profileImagePath,
                      buttonText: 'Choose File',
                      emptyText: 'No file chosen',
                      onTap: _pickProfileImage,
                    ),
                    const SizedBox(height: 12),
                    _ResponsiveFields(
                      children: [
                        _TextFieldTile(
                          label: 'First Name',
                          isRequired: true,
                          controller: _firstNameController,
                          hintText: 'Enter first name',
                        ),
                        _TextFieldTile(
                          label: 'Last Name',
                          isRequired: true,
                          controller: _lastNameController,
                          hintText: 'Enter last name',
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
                          isRequired: true,
                          controller: _phoneController,
                          hintText: 'Enter phone number',
                          keyboardType: TextInputType.phone,
                        ),
                        _DropdownFieldTile(
                          label: 'Status',
                          value: _status,
                          hintText: 'Select status',
                          items: _statusItems(),
                          onChanged: (value) => setState(() => _status = value),
                        ),
                        if (!_isEditMode)
                          _TextFieldTile(
                            label: 'Password',
                            isRequired: true,
                            labelHelperText: 'Minimum 8 characters',
                            controller: _passwordController,
                            hintText: 'Enter password',
                            obscureText: true,
                          ),
                      ],
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
                    _ResponsiveFields(
                      maxColumns: 4,
                      children: [
                        _TextFieldTile(
                          label: 'City',
                          controller: _cityController,
                          hintText: 'City',
                        ),
                        _TextFieldTile(
                          label: 'State',
                          controller: _stateController,
                          hintText: 'State',
                        ),
                        _TextFieldTile(
                          label: 'Country',
                          controller: _countryController,
                          hintText: 'Country',
                        ),
                        _TextFieldTile(
                          label: 'Pincode',
                          controller: _postalCodeController,
                          hintText: 'Pincode',
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
                      value: _clientType,
                      hintText: 'Select type',
                      items: _clientTypeItems(),
                      onChanged: (value) => setState(() => _clientType = value),
                    ),
                    _TextFieldTile(
                      label: 'Company Name',
                      controller: _companyNameController,
                      hintText: 'Enter Company Name',
                    ),
                    _TextFieldTile(
                      label: 'Industry',
                      controller: _industryController,
                      hintText: 'Enter industry',
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

  String? _validateForm() {
    if (_firstNameController.text.trim().isEmpty) {
      return 'First name is required.';
    }
    if (_lastNameController.text.trim().isEmpty) {
      return 'Last name is required.';
    }
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      return 'Enter a valid email address.';
    }
    if (_phoneController.text.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final password = _passwordController.text.trim();
    if (!_isEditMode && password.isEmpty) {
      return 'Password is required for new clients.';
    }
    if (password.isNotEmpty && password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  Future<void> _submitClient() async {
    final validationError = _validateForm();
    if (validationError != null) {
      AppSnackbar.show('Missing details', validationError);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    final request = CreateClientRequestModel(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      website: _websiteController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
      clientType: _clientType?.trim(),
      companyName: _companyNameController.text.trim(),
      industry: _industryController.text.trim(),
      status: (_status ?? 'active').trim().toLowerCase(),
      profileImagePath: _profileImagePath,
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

      AppSnackbar.show('Create client failed', message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitUpdateClient() async {
    if (_clientId == null) {
      AppSnackbar.show('Unable to update', 'Client id is missing.');
      return;
    }

    final validationError = _validateForm();
    if (validationError != null) {
      AppSnackbar.show('Missing details', validationError);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    final request = UpdateClientRequestModel(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      website: _websiteController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
      clientType: _clientType?.trim(),
      companyName: _companyNameController.text.trim(),
      industry: _industryController.text.trim(),
      status: (_status ?? 'active').trim().toLowerCase(),
      profileImagePath: _profileImagePath,
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
      final statusCode = error.response?.statusCode;

      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (statusCode == 301 ||
          statusCode == 302 ||
          statusCode == 307 ||
          statusCode == 308) {
        message =
            'Server redirected the update request. Please try again. If it still fails, contact backend support to verify update route/method.';
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      AppSnackbar.show('Update failed', message);
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

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children, this.maxColumns = 2});

  final List<Widget> children;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desiredColumns = maxColumns < 1 ? 1 : maxColumns;
        final columns = constraints.maxWidth >= 640 ? desiredColumns : 1;
        final spacing = 16.0;
        final itemWidth = columns > 1
            ? (constraints.maxWidth - (spacing * (columns - 1))) / columns
            : constraints.maxWidth;

        return Wrap(
          runSpacing: 12,
          spacing: spacing,
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
    this.labelHelperText,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
  });

  final String label;
  final bool isRequired;
  final String? labelHelperText;
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
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              if (labelHelperText != null && labelHelperText!.trim().isNotEmpty)
                TextSpan(
                  text: ' ($labelHelperText)',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
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

class _FilePickerFieldTile extends StatelessWidget {
  const _FilePickerFieldTile({
    required this.label,
    required this.filePath,
    required this.buttonText,
    required this.emptyText,
    required this.onTap,
  });

  final String label;
  final String? filePath;
  final String buttonText;
  final String emptyText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fileName = (filePath ?? '').trim().isEmpty
        ? emptyText
        : (filePath!.split(RegExp(r'[\\/]')).last);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      fileName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ],
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
