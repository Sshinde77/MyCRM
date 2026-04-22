import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/utils/app_snackbar.dart';
import '../models/email_settings_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController();
  final _emailController = TextEditingController();
  final _fromNameController = TextEditingController();
  final _smtpUsernameController = TextEditingController();
  final _smtpPasswordController = TextEditingController();
  final _emailCharsetController = TextEditingController();
  final _bccAllController = TextEditingController();
  final _emailSignatureController = TextEditingController();
  final _predefinedHeaderController = TextEditingController();
  final _predefinedFooterController = TextEditingController();
  final _testEmailController = TextEditingController();

  String _mailEngine = 'phpmailer';
  String _emailProtocol = 'smtp';
  String _emailEncryption = 'tls';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPassword = false;

  static const List<String> _mailEngineOptions = <String>[
    'phpmailer',
    'smtp',
    'sendmail',
    'mail',
  ];

  static const List<String> _emailProtocolOptions = <String>[
    'smtp',
    'sendmail',
    'mail',
  ];

  static const List<String> _emailEncryptionOptions = <String>[
    'tls',
    'ssl',
    'none',
  ];

  @override
  void initState() {
    super.initState();
    _loadEmailSettings();
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _emailController.dispose();
    _fromNameController.dispose();
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    _emailCharsetController.dispose();
    _bccAllController.dispose();
    _emailSignatureController.dispose();
    _predefinedHeaderController.dispose();
    _predefinedFooterController.dispose();
    _testEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadEmailSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.instance.getEmailSettings();
      _mailEngine = data.mailEngine.trim().isNotEmpty
          ? data.mailEngine.trim().toLowerCase()
          : _mailEngine;
      _emailProtocol = data.emailProtocol.trim().isNotEmpty
          ? data.emailProtocol.trim().toLowerCase()
          : _emailProtocol;
      _emailEncryption = data.emailEncryption.trim().isNotEmpty
          ? data.emailEncryption.trim().toLowerCase()
          : _emailEncryption;

      _smtpHostController.text = data.smtpHost;
      _smtpPortController.text = data.smtpPort > 0 ? '${data.smtpPort}' : '';
      _emailController.text = data.email;
      _fromNameController.text = data.mailFromName;
      _smtpUsernameController.text = data.smtpUsername;
      _smtpPasswordController.text = data.smtpPassword;
      _emailCharsetController.text = data.emailCharset;
      _bccAllController.text = data.bccAll;
      _emailSignatureController.text = data.emailSignature;
      _predefinedHeaderController.text = data.predefinedHeader;
      _predefinedFooterController.text = data.predefinedFooter;
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        _messageFromError(error, fallback: 'Unable to load email settings.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        'Unable to load email settings.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveEmailSettings() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final smtpPort = int.tryParse(_smtpPortController.text.trim());
    if (smtpPort == null || smtpPort <= 0) {
      AppSnackbar.show(
        'Validation error',
        'SMTP Port must be a valid positive number.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = EmailSettingsModel(
        mailEngine: _mailEngine,
        emailProtocol: _emailProtocol,
        emailEncryption: _emailEncryption == 'none' ? '' : _emailEncryption,
        smtpHost: _smtpHostController.text.trim(),
        smtpPort: smtpPort,
        email: _emailController.text.trim(),
        smtpUsername: _smtpUsernameController.text.trim(),
        smtpPassword: _smtpPasswordController.text.trim(),
        mailFromName: _fromNameController.text.trim(),
        emailCharset: _emailCharsetController.text.trim(),
        bccAll: _bccAllController.text.trim(),
        emailSignature: _emailSignatureController.text.trim(),
        predefinedHeader: _predefinedHeaderController.text.trim(),
        predefinedFooter: _predefinedFooterController.text.trim(),
      );

      final updated = await ApiService.instance.updateEmailSettings(payload);

      _mailEngine = updated.mailEngine.trim().isNotEmpty
          ? updated.mailEngine.trim().toLowerCase()
          : _mailEngine;
      _emailProtocol = updated.emailProtocol.trim().isNotEmpty
          ? updated.emailProtocol.trim().toLowerCase()
          : _emailProtocol;
      _emailEncryption = updated.emailEncryption.trim().isNotEmpty
          ? updated.emailEncryption.trim().toLowerCase()
          : _emailEncryption;

      if (!mounted) return;
      setState(() {});
      AppSnackbar.show(
        'Saved',
        'Email settings saved successfully.',
        isSuccess: true,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Save failed',
        _messageFromError(error, fallback: 'Unable to save email settings.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Save failed',
        'Unable to save email settings.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _sendTestEmail() {
    final email = _testEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppSnackbar.show(
        'Invalid email',
        'Enter a valid email address for test email.',
        isError: true,
      );
      return;
    }

    AppSnackbar.show(
      'Not integrated',
      'Send test email API is not provided yet.',
    );
  }

  String _messageFromError(DioException error, {required String fallback}) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    final message = error.message?.trim() ?? '';
    return message.isEmpty ? fallback : message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonScreenAppBar(title: 'Email Settings / SMTP'),
      backgroundColor: const Color(0xFFF4F8FC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEmailSettings,
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
                          'Email Settings / SMTP',
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
                                  left: _buildDropdownField(
                                    label: 'Mail Engine *',
                                    value: _mailEngine,
                                    options: _mergedOptions(
                                      _mailEngineOptions,
                                      _mailEngine,
                                    ),
                                    onChanged: (value) {
                                      setState(() => _mailEngine = value);
                                    },
                                  ),
                                  right: _buildDropdownField(
                                    label: 'Email Protocol *',
                                    value: _emailProtocol,
                                    options: _mergedOptions(
                                      _emailProtocolOptions,
                                      _emailProtocol,
                                    ),
                                    onChanged: (value) {
                                      setState(() => _emailProtocol = value);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildDropdownField(
                                    label: 'Email Encryption',
                                    value: _emailEncryption,
                                    options: _mergedOptions(
                                      _emailEncryptionOptions,
                                      _emailEncryption,
                                    ),
                                    onChanged: (value) {
                                      setState(() => _emailEncryption = value);
                                    },
                                  ),
                                  right: _buildTextField(
                                    label: 'Email Charset',
                                    controller: _emailCharsetController,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildTextField(
                                    label: 'SMTP Host *',
                                    controller: _smtpHostController,
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'SMTP host is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  right: _buildTextField(
                                    label: 'SMTP Port *',
                                    controller: _smtpPortController,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      final parsed = int.tryParse(
                                        (value ?? '').trim(),
                                      );
                                      if (parsed == null || parsed <= 0) {
                                        return 'Valid port is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildTextField(
                                    label: 'Email Address *',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      final email = (value ?? '').trim();
                                      if (email.isEmpty) {
                                        return 'Email address is required';
                                      }
                                      if (!email.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  right: _buildTextField(
                                    label: 'From Name',
                                    controller: _fromNameController,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildTextField(
                                    label: 'SMTP Username *',
                                    controller: _smtpUsernameController,
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'SMTP username is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  right: _buildPasswordField(),
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label: 'BCC All Emails To',
                                  controller: _bccAllController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label: 'Email Signature',
                                  controller: _emailSignatureController,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label: 'Predefined Email Header',
                                  controller: _predefinedHeaderController,
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label: 'Predefined Email Footer',
                                  controller: _predefinedFooterController,
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : _saveEmailSettings,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF178BEB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
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
                                            'Save Email Settings',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildTestEmailCard(),
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

  Widget _buildTestEmailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send Test Email',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _testEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
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
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _sendTestEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text(
                  'Send Test',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _mergedOptions(List<String> baseOptions, String selected) {
    final normalized = selected.trim().toLowerCase();
    if (normalized.isEmpty || baseOptions.contains(normalized)) {
      return baseOptions;
    }
    return <String>[...baseOptions, normalized];
  }

  Widget _buildPair({
    required bool isWide,
    required Widget left,
    required Widget right,
  }) {
    if (!isWide) {
      return Column(children: [left, const SizedBox(height: 12), right]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
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
        DropdownButtonFormField<String>(
          value: value,
          items: options
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item.toUpperCase()),
                ),
              )
              .toList(growable: false),
          onChanged: (selected) {
            if (selected == null) return;
            onChanged(selected);
          },
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

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SMTP Password *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _smtpPasswordController,
          obscureText: !_showPassword,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'SMTP password is required';
            }
            return null;
          },
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
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _showPassword = !_showPassword);
              },
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
