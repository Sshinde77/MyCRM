import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/routes/app_routes.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isActive = true;
  bool _sendInvite = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  XFile? _selectedProfileImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEEF5FB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 24,
              16,
              compact ? 16 : 24,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(compact),
                      const SizedBox(height: 20),
                      _formPane(),
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

  Widget _header(bool compact) {
    return CommonTopBar(
      title: 'Add New Staff',
      compact: compact,
      onBack: Get.back,
    );
  }

  Widget _formPane() {
    return Column(
      children: [
        _card(
          title: 'Staff Information',
          subtitle:
              'Fields based on the member data shown in your staff directory.',
          child: _fieldGrid([
            _field('Profile Image', _profileImagePicker(), fullWidth: true),
            _field(
              'Full Name',
              _textField(
                _nameController,
                'Philip Hartman',
                Icons.person_outline_rounded,
                onChanged: true,
              ),
              requiredField: true,
            ),
            _field(
              'Work Email',
              _textField(
                _emailController,
                'name@company.com',
                Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                onChanged: true,
              ),
              requiredField: true,
            ),
            _field(
              'Phone Number',
              _textField(
                _phoneController,
                '+91 98765 43210',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        _card(
          title: 'Role and Access',
          subtitle: 'Configure role, department, and account status.',
          child: Column(
            children: [
              _fieldGrid([
                _field(
                  'Role',
                  _textField(
                    _roleController,
                    'Client Manager',
                    Icons.work_outline_rounded,
                    onChanged: true,
                  ),
                  requiredField: true,
                ),
                _field(
                  'Department / Team',
                  _textField(
                    _departmentController,
                    'Sales Operations',
                    Icons.groups_2_outlined,
                    onChanged: true,
                  ),
                ),
                _field(
                  'Account Status',
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD7E2EF)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isActive
                              ? Icons.toggle_on_rounded
                              : Icons.toggle_off_outlined,
                          color: _isActive
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isActive ? 'Active' : 'Inactive',
                            style: AppTextStyles.style(
                              color: const Color(0xFF162033),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDCE7F3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.send_outlined, color: Color(0xFF1D6FEA)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Send invite email after creation',
                        style: AppTextStyles.style(
                          color: const Color(0xFF162033),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch(
                      value: _sendInvite,
                      onChanged: (value) => setState(() => _sendInvite = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _card(
          title: 'Account Setup',
          subtitle: 'Prepare login credentials for the new staff account.',
          child: Column(
            children: [
              _fieldGrid([
                _field(
                  'Temporary Password',
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration:
                        _decoration(
                          'Create password',
                          Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                    validator: (value) {
                      if (value == null || value.trim().length < 6)
                        return 'Use at least 6 characters';
                      return null;
                    },
                  ),
                  requiredField: true,
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : Get.back,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: Color(0xFFD7E2EF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.style(
                    color: const Color(0xFF475569),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _showPreviewDialog,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF1D6FEA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isSubmitting
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
                    : const Icon(
                        Icons.visibility_outlined,
                        color: Colors.white,
                      ),
                label: Text(
                  _isSubmitting ? 'Creating...' : 'Preview',
                  style: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _profileImagePicker() {
    final hasImage = _selectedProfileImage != null;
    final fileName = hasImage
        ? _selectedProfileImage!.name
        : 'No image selected';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7F3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(18),
                  image: hasImage
                      ? DecorationImage(
                          image: FileImage(File(_selectedProfileImage!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: hasImage
                    ? null
                    : const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF1D6FEA),
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.style(
                        color: const Color(0xFF162033),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a profile image from camera or gallery.',
                      style: AppTextStyles.style(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _pickProfileImage,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: const Color(0xFF1D6FEA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    hasImage ? Icons.edit_outlined : Icons.image_outlined,
                    color: Colors.white,
                  ),
                  label: Text(
                    hasImage ? 'Change Image' : 'Choose Image',
                    style: AppTextStyles.style(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _selectedProfileImage = null),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: Color(0xFFD7E2EF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF475569),
                    ),
                    label: Text(
                      'Remove',
                      style: AppTextStyles.style(
                        color: const Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewPane({bool isDialog = false}) {
    final name = _nameController.text.trim().isEmpty
        ? 'New Staff Member'
        : _nameController.text.trim();
    final role = _roleController.text.trim().isEmpty
        ? 'Role not set'
        : _roleController.text.trim();
    final email = _emailController.text.trim().isEmpty
        ? 'email@company.com'
        : _emailController.text.trim();
    final department = _departmentController.text.trim().isEmpty
        ? 'Department not assigned'
        : _departmentController.text.trim();
    final initials = name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join()
        .toUpperCase();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDialog ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163B64), Color(0xFF1D6FEA)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261D6FEA),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Preview',
            style: AppTextStyles.style(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 62,
                      width: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCE7FF),
                        borderRadius: BorderRadius.circular(20),
                        image: _selectedProfileImage != null
                            ? DecorationImage(
                                image: FileImage(
                                  File(_selectedProfileImage!.path),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: _selectedProfileImage == null
                          ? Text(
                              initials.isEmpty ? 'NS' : initials,
                              style: AppTextStyles.style(
                                color: const Color(0xFF1D6FEA),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.style(
                              color: const Color(0xFF162033),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip(
                                role,
                                const Color(0xFFE8F0FE),
                                const Color(0xFF1D4ED8),
                              ),
                              _chip(
                                _isActive ? 'ACTIVE' : 'INACTIVE',
                                _isActive
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFE2E8F0),
                                _isActive
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF475569),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _info(Icons.mail_outline_rounded, email),
                const SizedBox(height: 10),
                _info(Icons.groups_2_outlined, department),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Onboarding Summary',
                  style: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _summary(
                  'Invite email',
                  _sendInvite ? 'Will be sent' : 'Manual onboarding',
                ),
                const SizedBox(height: 8),
                _summary('First login', 'Pending account creation'),
                const SizedBox(height: 8),
                _summary('Account status', _isActive ? 'Active' : 'Inactive'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth >= 640
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children
              .map(
                (child) => SizedBox(
                  width: child is _FullWidthField && constraints.maxWidth >= 640
                      ? constraints.maxWidth
                      : width,
                  child: child is _FullWidthField ? child.child : child,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _field(
    String label,
    Widget child, {
    bool requiredField = false,
    bool fullWidth = false,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${requiredField ? ' *' : ''}',
          style: AppTextStyles.style(
            color: const Color(0xFF334155),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
    return fullWidth ? _FullWidthField(child: content) : content;
  }

  Widget _textField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    bool onChanged = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged ? (_) => setState(() {}) : null,
      decoration: _decoration(hint, icon),
      validator: (value) {
        if ((controller == _nameController ||
                controller == _emailController ||
                controller == _roleController) &&
            (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        if (controller == _emailController &&
            value != null &&
            value.isNotEmpty &&
            !value.contains('@')) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }

  InputDecoration _decoration(
    String hint,
    IconData icon, {
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      hintStyle: AppTextStyles.style(
        color: const Color(0xFF94A3B8),
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD7E2EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1D6FEA), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDCE7F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.style(
              color: const Color(0xFF162033),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.style(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.style(
              color: const Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.style(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.style(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if (_selectedProfileImage != null) {
      final hasPermission = await _ensureUploadPermission(
        actionLabel: 'upload the selected image',
      );
      if (!hasPermission) return;
    }

    final (firstName, lastName) = _splitName(_nameController.text.trim());

    setState(() => _isSubmitting = true);

    try {
      await ApiService.instance.createStaff(
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _roleController.text.trim().toLowerCase(),
        status: _isActive ? 'active' : 'inactive',
        team: _departmentController.text.trim(),
        departments: _buildDepartments(_departmentController.text.trim()),
        password: _passwordController.text.trim(),
        profileImagePath: _selectedProfileImage?.path,
      );

      if (!mounted) return;

      AppSnackbar.show(
        'Staff created',
        'The staff account has been created successfully.',

      );
      Get.offNamed(AppRoutes.staff);
    } on DioException catch (error) {
      if (!mounted) return;

      final responseData = error.response?.data;
      String message = 'Failed to create staff.';

      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      AppSnackbar.show(
        'Create staff failed',
        message,

      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final source = await _showImageSourcePicker();
    if (source == null) return;

    final hasPermission = await _ensurePickerPermission(
      source: source,
      actionLabel: source == ImageSource.camera
          ? 'capture a profile image'
          : 'choose a profile image from gallery',
    );
    if (!hasPermission) return;

    final result = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (result == null) return;

    setState(() {
      _selectedProfileImage = result;
    });
  }

  Future<void> _showPreviewDialog() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _previewPane(isDialog: true),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(color: Color(0xFFD7E2EF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: AppTextStyles.style(
                              color: const Color(0xFF475569),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  Navigator.of(dialogContext).pop();
                                  await _submit();
                                },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFF1D6FEA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Create Staff',
                            style: AppTextStyles.style(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return ('', '');
    }

    if (parts.length == 1) {
      return (parts.first, parts.first);
    }

    return (parts.first, parts.sublist(1).join(' '));
  }

  List<String> _buildDepartments(String team) {
    final normalized = team.trim();
    if (normalized.isEmpty) {
      return const ['General'];
    }

    return [normalized];
  }

  Future<ImageSource?> _showImageSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Image Source',
                  style: AppTextStyles.style(
                    color: const Color(0xFF162033),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose whether to capture a new photo or pick one from gallery.',
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                _sourceTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera',
                  subtitle: 'Take a new profile picture',
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _sourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Gallery',
                  subtitle: 'Pick an image from device gallery',
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE7F3)),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1D6FEA)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.style(
                      color: const Color(0xFF162033),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.style(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Future<bool> _ensurePickerPermission({
    required ImageSource source,
    required String actionLabel,
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return true;
    }

    PermissionStatus status;

    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else if (Platform.isAndroid) {
      status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.storage.request();
      }
    } else {
      return true;
    }

    if (status.isGranted || status.isLimited) {
      return true;
    }

    final deniedMessage = 'Permission is required to $actionLabel.';
    final blockedMessage =
        'Permission is permanently denied. Enable it from app settings to $actionLabel.';

    if (status.isPermanentlyDenied || status.isRestricted) {
      AppSnackbar.show(
        'Permission required',
        blockedMessage,

      );
      return false;
    }

    AppSnackbar.show(
      'Permission required',
      deniedMessage,

    );
    return false;
  }

  Future<bool> _ensureUploadPermission({required String actionLabel}) async {
    if (_selectedProfileImage == null) {
      return true;
    }

    return _ensurePickerPermission(
      source: ImageSource.gallery,
      actionLabel: actionLabel,
    );
  }
}

class _FullWidthField extends StatelessWidget {
  const _FullWidthField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

