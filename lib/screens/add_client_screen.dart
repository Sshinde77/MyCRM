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
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final List<_BusinessInformationForm> _businessInformationForms = [];
  String? _profileImagePath;

  String? _status;
  bool _isSubmitting = false;
  bool _isEditMode = false;
  bool _isLoading = false;
  bool _loadedHadBusinessInformation = false;
  bool _sendMail = false;
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
    final contactName = detail.contactPerson.trim().isNotEmpty
        ? detail.contactPerson
        : detail.name;
    _applyContactName(contactName);
    _emailController.text = detail.email;
    _phoneController.text = detail.phone;
    _addressLine1Controller.text = detail.addressLine1;
    _addressLine2Controller.text = detail.addressLine2;
    _cityController.text = detail.city;
    _stateController.text = detail.state;
    _postalCodeController.text = detail.postalCode;
    _countryController.text = detail.country;

    for (final form in _businessInformationForms) {
      form.dispose();
    }
    _businessInformationForms.clear();
    for (final business in detail.businessInformation) {
      final businessForm = _BusinessInformationForm(
        clientType: _matchValue(business['client_type'] ?? '', const [
          'Individual',
          'Company',
          'Organization',
          'Enterprise',
        ]),
        companyName: business['company_name'],
        industry: business['industry'],
        website: business['website'],
      );
      if (businessForm.hasValue) {
        _businessInformationForms.add(businessForm);
      } else {
        businessForm.dispose();
      }
    }
    _loadedHadBusinessInformation = _businessInformationForms.isNotEmpty;
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _passwordController.dispose();
    for (final form in _businessInformationForms) {
      form.dispose();
    }
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

  void _addBusinessInformation() {
    setState(() {
      _businessInformationForms.add(
        _BusinessInformationForm(clientType: 'Company'),
      );
    });
  }

  void _removeBusinessInformation(_BusinessInformationForm form) {
    setState(() {
      _businessInformationForms.remove(form);
      form.dispose();
    });
  }

  List<Map<String, String>> _businessInformationPayload() {
    return _businessInformationForms
        .map((form) => form.toPayload())
        .where((payload) => payload.isNotEmpty)
        .toList(growable: false);
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
                          controller: _firstNameController,
                          hintText: 'Enter first name',
                        ),
                        _TextFieldTile(
                          label: 'Last Name',
                          controller: _lastNameController,
                          hintText: 'Enter last name',
                        ),
                        _TextFieldTile(
                          label: 'Email',
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
                            labelHelperText: 'Minimum 8 characters',
                            controller: _passwordController,
                            hintText: 'Enter password',
                            obscureText: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _sendMail,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() => _sendMail = value ?? false);
                            },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Send mail',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: const Text(
                        'Send client login or welcome details by email.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
              if (_businessInformationForms.isNotEmpty)
                _SectionCard(
                  title: 'Business Information',
                  action: TextButton.icon(
                    onPressed: _isSubmitting ? null : _addBusinessInformation,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add More'),
                  ),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < _businessInformationForms.length;
                        index++
                      ) ...[
                        _BusinessInformationEditor(
                          form: _businessInformationForms[index],
                          index: index,
                          clientTypeItems: _clientTypeItems(
                            _businessInformationForms[index].clientType,
                          ),
                          canRemove: true,
                          onChanged: () => setState(() {}),
                          onRemove: () => _removeBusinessInformation(
                            _businessInformationForms[index],
                          ),
                        ),
                        if (index != _businessInformationForms.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ],
                  ),
                )
              else
                _AddBusinessInformationButton(
                  onTap: _isSubmitting ? null : _addBusinessInformation,
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

  List<String> _clientTypeItems(String? clientType) {
    final items = ['Individual', 'Company', 'Organization', 'Enterprise'];
    if (_isEditMode && clientType != null && !items.contains(clientType)) {
      items.add(clientType);
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
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      return 'Enter a valid email address.';
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
      AppSnackbar.show('Missing details', validationError);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    final businessInformation = _businessInformationPayload();
    final primaryBusiness = businessInformation.isNotEmpty
        ? businessInformation.first
        : const <String, String>{};
    final request = CreateClientRequestModel(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      sendMail: _sendMail,
      website: primaryBusiness['website'] ?? '',
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
      clientType: primaryBusiness['client_type'],
      companyName: primaryBusiness['company_name'],
      industry: primaryBusiness['industry'],
      businessInformation: businessInformation,
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

      AppSnackbar.show(
        'Create client failed',
        _resolveClientSubmitError(error, fallback: 'Failed to create client.'),
      );
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

    final businessInformation = _businessInformationPayload();
    final primaryBusiness = businessInformation.isNotEmpty
        ? businessInformation.first
        : const <String, String>{};
    final request = UpdateClientRequestModel(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      sendMail: _sendMail,
      website: primaryBusiness['website'] ?? '',
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
      clientType: primaryBusiness['client_type'],
      companyName: primaryBusiness['company_name'],
      industry: primaryBusiness['industry'],
      businessInformation: businessInformation,
      clearBusinessInformation:
          _loadedHadBusinessInformation && businessInformation.isEmpty,
      status: _status?.trim().toLowerCase(),
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

      AppSnackbar.show(
        'Update failed',
        _resolveClientSubmitError(error, fallback: 'Failed to update client.'),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _resolveClientSubmitError(
    DioException error, {
    required String fallback,
  }) {
    final response = error.response;
    final responseData = response?.data;

    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }
    if (responseData is Map && responseData['errors'] is Map) {
      final errors = responseData['errors'] as Map;
      final messages = <String>[];
      for (final entry in errors.entries) {
        final field = entry.key.toString();
        final value = entry.value;
        if (value is Iterable) {
          for (final item in value) {
            final message = item.toString().trim();
            if (message.isNotEmpty) {
              messages.add('$field: $message');
            }
          }
        } else {
          final message = value.toString().trim();
          if (message.isNotEmpty) {
            messages.add('$field: $message');
          }
        }
      }
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    final statusCode = response?.statusCode;
    if (statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 307 ||
        statusCode == 308) {
      final location = response?.headers.value('location');
      final target = location == null || location.trim().isEmpty
          ? 'another page'
          : location.trim();
      return 'The API redirected to $target. Please check the client API '
          'base URL and login token.';
    }

    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!.trim();
    }

    return fallback;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AddBusinessInformationButton extends StatelessWidget {
  const _AddBusinessInformationButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD2DDEA)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  color: Color(0xFF1D6FEA),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add Business Information',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.add_rounded, color: Color(0xFF1D6FEA), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessInformationForm {
  _BusinessInformationForm({
    String? clientType,
    String? companyName,
    String? industry,
    String? website,
  }) : clientType = clientType,
       companyNameController = TextEditingController(text: companyName ?? ''),
       industryController = TextEditingController(text: industry ?? ''),
       websiteController = TextEditingController(text: website ?? '');

  String? clientType;
  final TextEditingController companyNameController;
  final TextEditingController industryController;
  final TextEditingController websiteController;

  bool get hasValue {
    return (clientType ?? '').trim().isNotEmpty ||
        companyNameController.text.trim().isNotEmpty ||
        industryController.text.trim().isNotEmpty ||
        websiteController.text.trim().isNotEmpty;
  }

  Map<String, String> toPayload() {
    final payload = <String, String>{};
    void addIfNotEmpty(String key, String? value) {
      final normalized = (value ?? '').trim();
      if (normalized.isNotEmpty) {
        payload[key] = normalized;
      }
    }

    addIfNotEmpty('client_type', clientType);
    addIfNotEmpty('company_name', companyNameController.text);
    addIfNotEmpty('industry', industryController.text);
    addIfNotEmpty('website', websiteController.text);
    return payload;
  }

  void dispose() {
    companyNameController.dispose();
    industryController.dispose();
    websiteController.dispose();
  }
}

class _BusinessInformationEditor extends StatelessWidget {
  const _BusinessInformationEditor({
    required this.form,
    required this.index,
    required this.clientTypeItems,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final _BusinessInformationForm form;
  final int index;
  final List<String> clientTypeItems;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Business ${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove business',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _ResponsiveFields(
            children: [
              _DropdownFieldTile(
                label: 'Client Type',
                value: form.clientType,
                hintText: 'Select type',
                items: clientTypeItems,
                onChanged: (value) {
                  form.clientType = value;
                  onChanged();
                },
              ),
              _TextFieldTile(
                label: 'Company Name',
                controller: form.companyNameController,
                hintText: 'Enter Company Name',
              ),
              _TextFieldTile(
                label: 'Industry',
                controller: form.industryController,
                hintText: 'Enter industry',
              ),
              _TextFieldTile(
                label: 'Website',
                controller: form.websiteController,
                hintText: 'https://example.com',
                keyboardType: TextInputType.url,
              ),
            ],
          ),
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
