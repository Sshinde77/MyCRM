import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/utils/app_snackbar.dart';
import '../models/renewal_settings_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class RenewalSettingsScreen extends StatefulWidget {
  const RenewalSettingsScreen({super.key});

  @override
  State<RenewalSettingsScreen> createState() => _RenewalSettingsScreenState();
}

class _RenewalSettingsScreenState extends State<RenewalSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _renewalAdminEmailController = TextEditingController();
  final _renewalNoticeDaysController = TextEditingController();

  bool _renewalNotificationsEnabled = false;
  TimeOfDay? _renewalNotificationTime;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRenewalSettings();
  }

  @override
  void dispose() {
    _renewalAdminEmailController.dispose();
    _renewalNoticeDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadRenewalSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.instance.getRenewalSettings();
      _renewalNotificationsEnabled = data.renewalNotificationsEnabled;
      _renewalAdminEmailController.text = data.renewalAdminEmail;
      _renewalNoticeDaysController.text = data.renewalNoticeDays > 0
          ? '${data.renewalNoticeDays}'
          : '';
      _renewalNotificationTime = _tryParseTime(data.renewalNotificationTime);
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        _messageFromError(error, fallback: 'Unable to load renewal settings.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        'Unable to load renewal settings.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _renewalNotificationTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _renewalNotificationTime = picked);
  }

  Future<void> _saveRenewalSettings() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final noticeDays = int.tryParse(_renewalNoticeDaysController.text.trim());
    if (noticeDays == null || noticeDays < 0) {
      AppSnackbar.show(
        'Validation error',
        'Notify Before (Days) must be 0 or greater.',
        isError: true,
      );
      return;
    }

    if (_renewalNotificationTime == null) {
      AppSnackbar.show(
        'Validation error',
        'Daily notify time is required.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = RenewalSettingsModel(
        renewalAdminEmail: _renewalAdminEmailController.text.trim(),
        renewalNotificationTime: _format24Hour(_renewalNotificationTime!),
        renewalNoticeDays: noticeDays,
        renewalNotificationsEnabled: _renewalNotificationsEnabled,
      );

      final updated = await ApiService.instance.updateRenewalSettings(payload);
      _renewalNotificationsEnabled = updated.renewalNotificationsEnabled;
      _renewalNotificationTime =
          _tryParseTime(updated.renewalNotificationTime) ??
          _renewalNotificationTime;

      if (!mounted) return;
      setState(() {});
      AppSnackbar.show(
        'Saved',
        'Renewal settings saved successfully.',
        isSuccess: true,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Save failed',
        _messageFromError(error, fallback: 'Unable to save renewal settings.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Save failed',
        'Unable to save renewal settings.',
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
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(
      value.trim(),
    );
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

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
      appBar: const CommonScreenAppBar(title: 'Renewal Manage'),
      backgroundColor: const Color(0xFFF4F8FC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRenewalSettings,
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
                          'Renewal Manage',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Switch(
                              value: _renewalNotificationsEnabled,
                              onChanged: (value) {
                                setState(
                                  () => _renewalNotificationsEnabled = value,
                                );
                              },
                              activeColor: const Color(0xFF178BEB),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Enable Daily Renewal Email Notifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 700;
                            return Column(
                              children: [
                                _buildPair(
                                  isWide: isWide,
                                  left: _buildTextField(
                                    label: 'Renewal Admin Email *',
                                    controller: _renewalAdminEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      final email = (value ?? '').trim();
                                      if (email.isEmpty) {
                                        return 'Renewal admin email is required';
                                      }
                                      if (!email.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  right: _buildTimeField(
                                    label: 'Daily Notify Time *',
                                    value: _renewalNotificationTime,
                                    onTap: _pickTime,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  label: 'Notify Before (Days) *',
                                  controller: _renewalNoticeDaysController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final parsed = int.tryParse(
                                      (value ?? '').trim(),
                                    );
                                    if (parsed == null || parsed < 0) {
                                      return 'Enter 0 or a positive number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 6),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Default 5 days means: 5, 4, 3, 2, 1, 0 days left per daily email.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Note: Server cron must run Laravel scheduler every minute for this timing to work exactly.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : _saveRenewalSettings,
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
                                            'Save Renewal Settings',
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
  }) {
    if (!isWide) {
      return Column(
        children: [
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
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
