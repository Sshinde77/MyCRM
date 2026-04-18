import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/project_detail_model.dart';
import 'package:mycrm/models/project_form_options_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key, this.projectId});

  final String? projectId;

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _totalRateController = TextEditingController();
  final TextEditingController _estimatedHoursController =
      TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _technologiesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<PlatformFile> _selectedFiles = [];

  String? _selectedCustomer;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedBillingType;
  bool _isLoadingFormOptions = true;
  bool _isLoadingProject = false;
  bool _isSubmitting = false;
  String? _formOptionsError;
  List<ProjectSelectOption> _customerOptions = const [];
  List<String> _statusOptions = const [];
  List<String> _priorityOptions = const [];
  List<ProjectSelectOption> _memberOptions = const [];
  List<String> _billingOptions = const [];
  List<String> _selectedMemberIds = const [];

  bool get _isEditMode {
    final projectId = widget.projectId?.trim() ?? '';
    return projectId.isNotEmpty;
  }

  bool get _isBusy => _isLoadingFormOptions || _isLoadingProject;

  @override
  void initState() {
    super.initState();
    _loadProjectFormOptions();
    if (_isEditMode) {
      _loadProjectForEdit();
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _startDateController.dispose();
    _deadlineController.dispose();
    _totalRateController.dispose();
    _estimatedHoursController.dispose();
    _tagsController.dispose();
    _technologiesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectFormOptions() async {
    setState(() {
      _isLoadingFormOptions = true;
      _formOptionsError = null;
    });

    try {
      final options = await ApiService.instance.getProjectFormOptions();
      if (!mounted) return;

      setState(() {
        _customerOptions = options.customers;
        _statusOptions = options.statuses;
        _priorityOptions = options.priorities;
        _memberOptions = options.staff;
        _billingOptions = options.billingTypes;
        _selectedCustomer = _resolveSelectedOption(
          _selectedCustomer,
          _customerOptions.map((item) => item.id).toList(growable: false),
        );
        _selectedStatus = _resolveSelectedOption(
          _selectedStatus,
          _statusOptions,
        );
        _selectedPriority = _resolveSelectedOption(
          _selectedPriority,
          _priorityOptions,
        );
        _selectedMemberIds = _resolveSelectedMemberIds(
          _selectedMemberIds,
          _memberOptions.map((item) => item.id).toSet(),
        );
        _selectedBillingType = _resolveSelectedOption(
          _selectedBillingType,
          _billingOptions,
        );
        _isLoadingFormOptions = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _formOptionsError = _resolveFormOptionsError(error);
        _isLoadingFormOptions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _formOptionsError = 'Unable to load project form options.';
        _isLoadingFormOptions = false;
      });
    }
  }

  Future<void> _loadProjectForEdit() async {
    final projectId = widget.projectId?.trim() ?? '';
    if (projectId.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingProject = true;
    });

    try {
      final project = await ApiService.instance.getProjectDetail(projectId);
      if (!mounted) return;
      _applyProjectValues(project);
    } on DioException catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Project details unavailable',
        _resolveFormOptionsError(error),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF991B1B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'Project details unavailable',
        'Unable to load the project for editing.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF991B1B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProject = false;
        });
      }
    }
  }

  void _applyProjectValues(ProjectDetailModel project) {
    _projectNameController.text = project.title.trim();
    _startDateController.text = _formatDateForField(project.startDate);
    _deadlineController.text = _formatDateForField(project.deadline);
    _totalRateController.text = project.totalRate.trim();
    _estimatedHoursController.text = project.estimatedHours.trim();
    _tagsController.text = project.tags.join(', ');
    _technologiesController.text = project.technologies.join(', ');
    _descriptionController.text =
        project.description == 'No description available.'
        ? ''
        : project.description.trim();

    final matchedCustomerId = _resolveCustomerSelection(
      project.customerId,
      project.client,
    );

    setState(() {
      _selectedCustomer = matchedCustomerId;
      _selectedStatus = project.status.trim().isEmpty
          ? _selectedStatus
          : project.status.trim();
      _selectedPriority = project.priority.trim().isEmpty
          ? _selectedPriority
          : project.priority.trim();
      _selectedBillingType = project.billingType.trim().isEmpty
          ? _selectedBillingType
          : project.billingType.trim();
      _selectedMemberIds = _resolveSelectedMemberIds(
        project.memberIds.isNotEmpty ? project.memberIds : _selectedMemberIds,
        _memberOptions.map((item) => item.id).toSet(),
      );
    });
  }

  String? _resolveSelectedOption(String? current, List<String> options) {
    if (options.isEmpty) {
      return null;
    }
    if (current != null && options.contains(current)) {
      return current;
    }
    return options.first;
  }

  List<String> _resolveSelectedMemberIds(
    List<String> current,
    Set<String> validIds,
  ) {
    if (validIds.isEmpty) {
      return current;
    }

    return current.where(validIds.contains).toList(growable: false);
  }

  String? _resolveCustomerSelection(String currentId, String currentName) {
    final normalizedId = currentId.trim();
    if (normalizedId.isNotEmpty) {
      if (_customerOptions.isEmpty ||
          _customerOptions.any((item) => item.id == normalizedId)) {
        return normalizedId;
      }
    }

    final normalizedName = currentName.trim().toLowerCase();
    if (normalizedName.isEmpty) {
      return _selectedCustomer;
    }

    for (final option in _customerOptions) {
      if (option.name.trim().toLowerCase() == normalizedName) {
        return option.id;
      }
    }

    return _selectedCustomer;
  }

  Future<void> _pickMembers() async {
    if (_memberOptions.isEmpty) {
      return;
    }

    final initialSelection = _selectedMemberIds.toSet();
    final selectedIds = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        final tempSelection = {...initialSelection};
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Members'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _memberOptions
                        .map(
                          (option) => CheckboxListTile(
                            value: tempSelection.contains(option.id),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            title: Text(option.name),
                            onChanged: (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  tempSelection.add(option.id);
                                } else {
                                  tempSelection.remove(option.id);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => setDialogState(() {
                    tempSelection.clear();
                  }),
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(tempSelection),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedIds == null || !mounted) {
      return;
    }

    setState(() {
      _selectedMemberIds = selectedIds.toList(growable: false);
    });
  }

  List<ProjectSelectOption> get _selectedMembers {
    final selectedIds = _selectedMemberIds.toSet();
    return _memberOptions
        .where((option) => selectedIds.contains(option.id))
        .toList(growable: false);
  }

  String _resolveFormOptionsError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString().trim() ?? '';
      if (message.isNotEmpty) {
        return message;
      }
    }

    final fallback = error.message?.trim() ?? '';
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'Unable to load project form options.';
  }

  String _formatDateForField(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized == 'Not set' ||
        !normalized.contains('-')) {
      return '';
    }

    final datePortion = normalized.split(' ').first;
    final parts = datePortion.split('-');
    if (parts.length != 3) {
      return normalized;
    }

    if (parts[0].length == 4) {
      final year = parts[0];
      final month = parts[1].padLeft(2, '0');
      final day = parts[2].padLeft(2, '0');
      return '$day-$month-$year';
    }

    return normalized;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;

    final day = picked.day.toString().padLeft(2, '0');
    final month = picked.month.toString().padLeft(2, '0');
    controller.text = '$day-$month-${picked.year}';
  }

  Future<void> _pickProjectFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _selectedFiles
        ..clear()
        ..addAll(result.files.where((file) => (file.path ?? '').isNotEmpty));
    });
  }

  void _removeFileAt(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final customer = (_selectedCustomer ?? '').trim();
    final status = (_selectedStatus ?? '').trim();
    final priority = (_selectedPriority ?? '').trim();
    final billingType = (_selectedBillingType ?? '').trim();

    if (customer.isEmpty || status.isEmpty || priority.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isEditMode) {
        await ApiService.instance.updateProject(
          id: widget.projectId!.trim(),
          projectName: _projectNameController.text.trim(),
          customer: _normalizeIdValue(customer),
          status: status,
          startDate: _normalizeDateForApi(_startDateController.text),
          deadline: _normalizeDateForApi(_deadlineController.text),
          billingType: billingType,
          totalRate: _parseNumber(_totalRateController.text),
          estimatedHours: _parseNumber(_estimatedHoursController.text),
          tags: _splitCommaSeparated(_tagsController.text),
          members: _selectedMemberIds
              .map(_normalizeIdValue)
              .toList(growable: false),
          description: _descriptionController.text.trim(),
          priority: priority,
          technologies: _splitCommaSeparated(_technologiesController.text),
        );
      } else {
        await ApiService.instance.createProject(
          projectName: _projectNameController.text.trim(),
          customer: _normalizeIdValue(customer),
          status: status,
          startDate: _normalizeDateForApi(_startDateController.text),
          deadline: _normalizeDateForApi(_deadlineController.text),
          billingType: billingType,
          totalRate: _parseNumber(_totalRateController.text),
          estimatedHours: _parseNumber(_estimatedHoursController.text),
          tags: _splitCommaSeparated(_tagsController.text),
          members: _selectedMemberIds
              .map(_normalizeIdValue)
              .toList(growable: false),
          description: _descriptionController.text.trim(),
          priority: priority,
          technologies: _splitCommaSeparated(_technologiesController.text),
        );
      }

      if (!mounted) return;

      Get.snackbar(
        _isEditMode ? 'Project updated' : 'Project created',
        _isEditMode
            ? 'The project has been updated successfully.'
            : 'The project has been created successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF166534),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) return;

      Get.snackbar(
        _isEditMode ? 'Update project failed' : 'Create project failed',
        _resolveSubmitError(error),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF991B1B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (_) {
      if (!mounted) return;

      Get.snackbar(
        _isEditMode ? 'Update project failed' : 'Create project failed',
        _isEditMode
            ? 'Unable to update the project. Please try again.'
            : 'Unable to create the project. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF991B1B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  dynamic _normalizeIdValue(String value) {
    final normalized = value.trim();
    return int.tryParse(normalized) ?? normalized;
  }

  double? _parseNumber(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  List<String> _splitCommaSeparated(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String? _normalizeDateForApi(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final parts = normalized.split('-');
    if (parts.length != 3) {
      return normalized;
    }

    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    if (year.length != 4) {
      return normalized;
    }

    return '$year-$month-$day';
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

    return _isEditMode
        ? 'Unable to update the project. Please try again.'
        : 'Unable to create the project. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CommonScreenAppBar(
        title: _isEditMode ? 'Edit Project' : 'Create Project',
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
            final maxWidth = constraints.maxWidth > 720
                ? 720.0
                : double.infinity;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProjectFormCard(
                          title: _isEditMode
                              ? 'Edit Project'
                              : 'Project Details',
                          subtitle: _isEditMode
                              ? 'Update project information'
                              : 'Basic Information',
                        ),
                        if (_isBusy || _formOptionsError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _FormOptionsStatusCard(
                              isLoading: _isBusy,
                              errorMessage: _formOptionsError,
                              onRetry: () {
                                _loadProjectFormOptions();
                                if (_isEditMode) {
                                  _loadProjectForEdit();
                                }
                              },
                            ),
                          ),
                        _FormSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AdaptiveFields(
                                children: [
                                  _TextFieldBlock(
                                    label: 'Project Name *',
                                    child: TextFormField(
                                      controller: _projectNameController,
                                      decoration: _inputDecoration(
                                        'Project Name',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Project name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _TextFieldBlock(
                                    label: 'Customer',
                                    child: DropdownButtonFormField<String>(
                                      value:
                                          _customerOptions.any(
                                            (option) =>
                                                option.id == _selectedCustomer,
                                          )
                                          ? _selectedCustomer
                                          : null,
                                      decoration: _inputDecoration('Choose...'),
                                      items: _customerOptions
                                          .map(
                                            (option) => DropdownMenuItem(
                                              value: option.id,
                                              child: Text(option.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _isBusy
                                          ? null
                                          : (value) => setState(
                                              () => _selectedCustomer = value,
                                            ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Customer is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _AdaptiveFields(
                                children: [
                                  _TextFieldBlock(
                                    label: 'Status',
                                    child: DropdownButtonFormField<String>(
                                      value:
                                          _statusOptions.contains(
                                            _selectedStatus,
                                          )
                                          ? _selectedStatus
                                          : null,
                                      decoration: _inputDecoration('Choose...'),
                                      items: _statusOptions
                                          .map(
                                            (option) => DropdownMenuItem(
                                              value: option,
                                              child: Text(option),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => setState(
                                        () => _selectedStatus = value,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Status is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _TextFieldBlock(
                                    label: 'Priority',
                                    child: DropdownButtonFormField<String>(
                                      value:
                                          _priorityOptions.contains(
                                            _selectedPriority,
                                          )
                                          ? _selectedPriority
                                          : null,
                                      decoration: _inputDecoration('Choose...'),
                                      items: _priorityOptions
                                          .map(
                                            (option) => DropdownMenuItem(
                                              value: option,
                                              child: Text(option),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => setState(
                                        () => _selectedPriority = value,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Priority is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _TextFieldBlock(
                                    label: 'Start Date',
                                    child: TextFormField(
                                      controller: _startDateController,
                                      readOnly: true,
                                      onTap: () =>
                                          _pickDate(_startDateController),
                                      decoration: _inputDecoration('dd-mm-yyyy')
                                          .copyWith(
                                            suffixIcon: const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 18,
                                            ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _AdaptiveFields(
                                children: [
                                  _TextFieldBlock(
                                    label: 'Deadline',
                                    child: TextFormField(
                                      controller: _deadlineController,
                                      readOnly: true,
                                      onTap: () =>
                                          _pickDate(_deadlineController),
                                      decoration: _inputDecoration('dd-mm-yyyy')
                                          .copyWith(
                                            suffixIcon: const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 18,
                                            ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _SectionLabel(title: 'Billing Information'),
                              const SizedBox(height: 16),
                              _AdaptiveFields(
                                children: [
                                  _TextFieldBlock(
                                    label: 'Billing Type',
                                    child: DropdownButtonFormField<String>(
                                      value:
                                          _billingOptions.contains(
                                            _selectedBillingType,
                                          )
                                          ? _selectedBillingType
                                          : null,
                                      decoration: _inputDecoration('Choose...'),
                                      items: _billingOptions
                                          .map(
                                            (option) => DropdownMenuItem(
                                              value: option,
                                              child: Text(option),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => setState(
                                        () => _selectedBillingType = value,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Billing type is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _TextFieldBlock(
                                    label: 'Total Rate',
                                    child: TextFormField(
                                      controller: _totalRateController,
                                      decoration: _inputDecoration(
                                        'Total rate',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  _TextFieldBlock(
                                    label: 'Estimated Hours',
                                    child: TextFormField(
                                      controller: _estimatedHoursController,
                                      decoration: _inputDecoration(
                                        'Estimated hours',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FormSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(title: 'Project Details'),
                              const SizedBox(height: 16),
                              _AdaptiveFields(
                                children: [
                                  _TextFieldBlock(
                                    label: 'Tags',
                                    child: TextFormField(
                                      controller: _tagsController,
                                      decoration: _inputDecoration(
                                        'Select or add tags',
                                      ),
                                    ),
                                  ),
                                  _TextFieldBlock(
                                    label: 'Technologies',
                                    child: TextFormField(
                                      controller: _technologiesController,
                                      decoration: _inputDecoration(
                                        'Select or add technologies',
                                      ),
                                    ),
                                  ),
                                  _TextFieldBlock(
                                    label: 'Members',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: _isBusy ? null : _pickMembers,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: InputDecorator(
                                            decoration: _inputDecoration(
                                              'Select members',
                                            ),
                                            child: Text(
                                              _selectedMembers.isEmpty
                                                  ? 'Select members'
                                                  : _selectedMembers
                                                        .map(
                                                          (member) =>
                                                              member.name,
                                                        )
                                                        .join(', '),
                                              style: AppTextStyles.style(
                                                color: _selectedMembers.isEmpty
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF0F172A),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_selectedMembers.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: _selectedMembers
                                                .map(
                                                  (member) => Chip(
                                                    label: Text(member.name),
                                                    onDeleted: () {
                                                      setState(() {
                                                        _selectedMemberIds =
                                                            _selectedMemberIds
                                                                .where(
                                                                  (id) =>
                                                                      id !=
                                                                      member.id,
                                                                )
                                                                .toList(
                                                                  growable:
                                                                      false,
                                                                );
                                                      });
                                                    },
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _TextFieldBlock(
                                label: 'Description',
                                child: TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 6,
                                  minLines: 5,
                                  decoration: _inputDecoration(
                                    'Write project description',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FormSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(title: 'Project Files'),
                              const SizedBox(height: 16),
                              Text(
                                'Upload Files',
                                style: AppTextStyles.style(
                                  color: const Color(0xFF475569),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 34,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFD9E2EC),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 42,
                                      color: Color(0xFF1D6FEA),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Click to browse project files',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.style(
                                        color: const Color(0xFF334155),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Supported: Word, PDF, Excel, images and other documents',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.style(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _pickProjectFiles,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(44),
                                        backgroundColor: const Color(
                                          0xFF1D6FEA,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.attach_file_rounded,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        _selectedFiles.isEmpty
                                            ? 'Choose Files'
                                            : 'Change Files',
                                        style: AppTextStyles.style(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedFiles.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < _selectedFiles.length;
                                      i++
                                    )
                                      _SelectedFileTile(
                                        file: _selectedFiles[i],
                                        onRemove: () => _removeFileAt(i),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 110,
                                child: ElevatedButton(
                                  onPressed: (_isBusy || _isSubmitting)
                                      ? null
                                      : _submit,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                    backgroundColor: const Color(0xFF1D6FEA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          _isEditMode ? 'Update' : 'Submit',
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
                ),
              ),
            );
          },
        ),
      ),
    );
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
                  ? 'Loading customer, status, priority, member, and billing options...'
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

class _SelectedFileTile extends StatelessWidget {
  const _SelectedFileTile({required this.file, required this.onRemove});

  final PlatformFile file;
  final VoidCallback onRemove;

  bool get _isImage {
    final extension = (file.extension ?? '').toLowerCase();
    return {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'bmp',
      'heic',
    }.contains(extension);
  }

  IconData get _fileIcon {
    final extension = (file.extension ?? '').toLowerCase();
    if (_isImage) return Icons.image_outlined;
    if (extension == 'pdf') return Icons.picture_as_pdf_outlined;
    if ({'doc', 'docx'}.contains(extension)) return Icons.description_outlined;
    if ({'xls', 'xlsx', 'csv'}.contains(extension))
      return Icons.table_chart_outlined;
    if ({'ppt', 'pptx'}.contains(extension)) return Icons.slideshow_outlined;
    if ({'zip', 'rar', '7z'}.contains(extension))
      return Icons.folder_zip_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color get _fileIconColor {
    final extension = (file.extension ?? '').toLowerCase();
    if (_isImage) return const Color(0xFF1D6FEA);
    if (extension == 'pdf') return const Color(0xFFDC2626);
    if ({'doc', 'docx'}.contains(extension)) return const Color(0xFF2563EB);
    if ({'xls', 'xlsx', 'csv'}.contains(extension))
      return const Color(0xFF15803D);
    if ({'ppt', 'pptx'}.contains(extension)) return const Color(0xFFEA580C);
    return const Color(0xFF475569);
  }

  String get _fileSizeLabel {
    final size = file.size;
    if (size <= 0) return '';
    if (size < 1024) return '${size} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final filePath = file.path;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD9E2EC)),
          ),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFF8FAFC),
                ),
                alignment: Alignment.center,
                child: _isImage && filePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(filePath),
                          width: 96,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(_fileIcon, size: 32, color: _fileIconColor),
              ),
              const SizedBox(height: 8),
              Text(
                file.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.style(
                  color: const Color(0xFF475569),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_fileSizeLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _fileSizeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.style(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: const Color(0xFFB42318),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 22,
                height: 22,
                child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectFormCard extends StatelessWidget {
  const _ProjectFormCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.style(
              color: const Color(0xFF1E2740),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.style(
            color: const Color(0xFF1E2740),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
      ],
    );
  }
}

class _AdaptiveFields extends StatelessWidget {
  const _AdaptiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleColumn = constraints.maxWidth < 560;
        if (isSingleColumn) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }
}

class _TextFieldBlock extends StatelessWidget {
  const _TextFieldBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF475569),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.style(
      color: const Color(0xFF94A3B8),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF1D6FEA)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDC2626)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDC2626)),
    ),
  );
}
