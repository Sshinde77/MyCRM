import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/utils/app_snackbar.dart';
import '../models/department_setting_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class DepartmentSettingsScreen extends StatefulWidget {
  const DepartmentSettingsScreen({super.key});

  @override
  State<DepartmentSettingsScreen> createState() =>
      _DepartmentSettingsScreenState();
}

class _DepartmentSettingsScreenState extends State<DepartmentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _departmentControllers =
      <TextEditingController>[];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDepartmentSettings();
  }

  @override
  void dispose() {
    for (final controller in _departmentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDepartmentSettings() async {
    setState(() => _isLoading = true);
    try {
      final records = await ApiService.instance.getDepartmentSettings();
      for (final controller in _departmentControllers) {
        controller.dispose();
      }
      _departmentControllers
        ..clear()
        ..addAll(
          records.isEmpty
              ? <TextEditingController>[TextEditingController()]
              : records
                    .map((entry) => TextEditingController(text: entry.name))
                    .toList(growable: false),
        );
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        _messageFromError(
          error,
          fallback: 'Unable to load department settings.',
        ),
        isError: true,
      );
      if (_departmentControllers.isEmpty) {
        _departmentControllers.add(TextEditingController());
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        'Unable to load department settings.',
        isError: true,
      );
      if (_departmentControllers.isEmpty) {
        _departmentControllers.add(TextEditingController());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addDepartment() {
    setState(() => _departmentControllers.add(TextEditingController()));
  }

  void _removeDepartment(int index) {
    if (index < 0 || index >= _departmentControllers.length) return;
    setState(() {
      if (_departmentControllers.length == 1) {
        _departmentControllers.first.clear();
        return;
      }
      final controller = _departmentControllers.removeAt(index);
      controller.dispose();
    });
  }

  Future<void> _saveDepartments() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final departments = _departmentControllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .map((name) => DepartmentSettingModel(name: name))
        .toList(growable: false);

    setState(() => _isSaving = true);
    try {
      final updated = await ApiService.instance.updateDepartmentSettings(
        departments,
      );
      for (final controller in _departmentControllers) {
        controller.dispose();
      }
      _departmentControllers
        ..clear()
        ..addAll(
          updated.isEmpty
              ? <TextEditingController>[TextEditingController()]
              : updated
                    .map((entry) => TextEditingController(text: entry.name))
                    .toList(growable: false),
        );

      if (!mounted) return;
      setState(() {});
      AppSnackbar.show(
        'Saved',
        'Department settings saved successfully.',
        isSuccess: true,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Save failed',
        _messageFromError(
          error,
          fallback: 'Unable to save department settings.',
        ),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Save failed',
        'Unable to save department settings.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonScreenAppBar(title: 'Department Settings'),
      backgroundColor: const Color(0xFFF4F8FC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDepartmentSettings,
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
                          'Department Settings',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),
                        const Text(
                          'Departments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < _departmentControllers.length; i++) ...[
                          _buildDepartmentRow(i),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 4),
                        const Text(
                          'Add department names that should be available in the system.',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _addDepartment,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Department'),
                            ),
                            ElevatedButton(
                              onPressed: _isSaving ? null : _saveDepartments,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF178BEB),
                                foregroundColor: Colors.white,
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
                                  : const Text('Save Departments'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDepartmentRow(int index) {
    final controller = _departmentControllers[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;

          final field = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Department Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: controller,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Department name is required';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Enter department name',
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

          final deleteButton = OutlinedButton(
            onPressed: () => _removeDepartment(index),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
            ),
            child: const Icon(Icons.delete_outline),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                field,
                const SizedBox(height: 10),
                deleteButton,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: field),
              const SizedBox(width: 10),
              deleteButton,
            ],
          );
        },
      ),
    );
  }
}
