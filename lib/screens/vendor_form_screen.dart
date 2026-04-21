import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/vendor_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class VendorFormScreen extends StatefulWidget {
  const VendorFormScreen({super.key, this.vendorId, this.vendor});

  final String? vendorId;
  final VendorModel? vendor;

  @override
  State<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends State<VendorFormScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoading = false;
  bool _isActive = true;
  String? _vendorId;

  bool get _isEditMode => _vendorId != null && _vendorId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _vendorId = widget.vendorId?.trim();
    _applyVendor(widget.vendor);
    if (_isEditMode) {
      _loadVendorDetail();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _applyVendor(VendorModel? vendor) {
    if (vendor == null) {
      return;
    }

    _nameController.text = vendor.vendorName;
    _emailController.text = vendor.email;
    _phoneController.text = vendor.contactNo;
    _addressController.text = vendor.address;
    _isActive = vendor.isActive;
  }

  Future<void> _loadVendorDetail() async {
    if (!_isEditMode) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final detail = await ApiService.instance.getVendorDetail(_vendorId!);
      if (!mounted) {
        return;
      }
      _applyVendor(detail);
      setState(() {});
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        title: 'Unable to load vendor',
        message: _readVendorFormError(
          error,
          fallback: 'Please try again later.',
        ),
        backgroundColor: const Color(0xFFB45309),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validate() {
    if (_nameController.text.trim().isEmpty) {
      return 'Vendor name is required.';
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      return 'Enter a valid email address.';
    }

    if (_phoneController.text.trim().isEmpty) {
      return 'Mobile number is required.';
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

    final payload = (
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      status: _isActive ? '1' : '0',
    );

    try {
      if (_isEditMode) {
        await ApiService.instance.updateVendor(
          id: _vendorId!,
          name: payload.name,
          email: payload.email,
          phone: payload.phone,
          address: payload.address,
          status: payload.status,
        );
      } else {
        await ApiService.instance.createVendor(
          name: payload.name,
          email: payload.email,
          phone: payload.phone,
          address: payload.address,
          status: payload.status,
        );
      }

      if (!mounted) {
        return;
      }

      _showSnack(
        title: _isEditMode ? 'Vendor updated' : 'Vendor created',
        message: _isEditMode
            ? 'The vendor has been updated successfully.'
            : 'The vendor has been added successfully.',
        backgroundColor: const Color(0xFF153A63),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _showSnack(
        title: _isEditMode ? 'Update failed' : 'Create vendor failed',
        message: _readVendorFormError(
          error,
          fallback: _isEditMode
              ? 'Failed to update vendor.'
              : 'Failed to create vendor.',
        ),
        backgroundColor: const Color(0xFFB91C1C),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack({
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    AppSnackbar.show(title, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: const CommonScreenAppBar(title: 'Vendor Form'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 1, color: const Color(0xFFD9E1EF)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditMode ? 'Edit Vendor' : 'Add Vendor',
                      style: AppTextStyles.style(
                        color: const Color(0xFF17213A),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    const SizedBox(height: 24),
                    _VendorFormFields(
                      children: [
                        _VendorTextField(
                          label: 'Vendor Name',
                          required: true,
                          controller: _nameController,
                          hintText: 'Enter vendor name',
                        ),
                        _VendorTextField(
                          label: 'Email ID',
                          required: true,
                          controller: _emailController,
                          hintText: 'Enter email address',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _VendorTextField(
                          label: 'Mobile Number',
                          required: true,
                          controller: _phoneController,
                          hintText: 'Enter mobile number',
                          keyboardType: TextInputType.phone,
                        ),
                        _VendorTextField(
                          label: 'Address',
                          controller: _addressController,
                          hintText: 'Enter address (optional)',
                          maxLines: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Status',
                              style: AppTextStyles.style(
                                color: const Color(0xFF334155),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _isActive ? 'Active' : 'Inactive',
                            style: AppTextStyles.style(
                              color: _isActive
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _isActive,
                            onChanged: _isSubmitting || _isLoading
                                ? null
                                : (value) => setState(() => _isActive = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isSubmitting || _isLoading
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D8BFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
                                : Text(
                                    _isEditMode
                                        ? 'Update Vendor'
                                        : 'Add Vendor',
                                  ),
                          ),
                        ),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF17213A),
                              backgroundColor: const Color(0xFFF8FAFC),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
}

class _VendorFormFields extends StatelessWidget {
  const _VendorFormFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final width = isWide
            ? (constraints.maxWidth - 20) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 20,
          runSpacing: 18,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _VendorTextField extends StatelessWidget {
  const _VendorTextField({
    required this.label,
    this.required = false,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final bool required;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
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
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.style(
              color: const Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD4DCE8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD4DCE8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1D8BFF)),
            ),
          ),
        ),
      ],
    );
  }
}

String _readVendorFormError(DioException error, {required String fallback}) {
  final responseData = error.response?.data;
  if (responseData is Map && responseData['message'] != null) {
    return responseData['message'].toString();
  }

  final message = error.message?.trim() ?? '';
  if (message.isNotEmpty) {
    return message;
  }

  return fallback;
}
