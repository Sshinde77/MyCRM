import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/project_model.dart';
import 'package:mycrm/models/staff_member_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({
    super.key,
    this.taskId,
    this.initialTitle,
    this.initialDescription,
    this.initialProjectId,
    this.initialPriority,
    this.initialStatus,
    this.initialStartDate,
    this.initialDueDate,
    this.initialAssigneeIds = const [],
    this.initialFollowerIds = const [],
    this.initialTags = const [],
  });

  final String? taskId;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialProjectId;
  final String? initialPriority;
  final String? initialStatus;
  final DateTime? initialStartDate;
  final DateTime? initialDueDate;
  final List<String> initialAssigneeIds;
  final List<String> initialFollowerIds;
  final List<String> initialTags;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  static const _statuses = [
    'Not Started',
    'In Progress',
    'On Hold',
    'Completed',
  ];

  List<ProjectModel> _projects = const [];
  List<StaffMemberModel> _staff = const [];
  List<String> _assigneeIds = [];
  List<String> _followerIds = [];
  List<PlatformFile> _files = [];
  String? _projectId;
  String _priority = 'Medium';
  String _status = 'Not Started';
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  bool get _isEditMode {
    final id = widget.taskId?.trim() ?? '';
    return id.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle?.trim() ?? '';
    _descriptionController.text = widget.initialDescription?.trim() ?? '';
    _projectId = widget.initialProjectId?.trim();
    _priority = _normalizePriorityLabel(widget.initialPriority) ?? _priority;
    _status = _normalizeStatusLabel(widget.initialStatus) ?? _status;
    _startDate = widget.initialStartDate;
    _dueDate = widget.initialDueDate;
    _assigneeIds = List<String>.from(widget.initialAssigneeIds);
    _followerIds = List<String>.from(widget.initialFollowerIds);
    _tagsController.text = widget.initialTags.join(', ');
    _loadOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CommonScreenAppBar(title: _isEditMode ? 'Edit Task' : 'Add Task'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Divider(height: 1, color: Color(0xFFDCE4EE)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditMode ? 'Edit Task' : 'Add Task',
                                style: AppTextStyles.style(
                                  color: const Color(0xFF334155),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 22),
                              if (_error != null) ...[
                                _errorBanner(),
                                const SizedBox(height: 16),
                              ],
                              _label('Task Title', required: true),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _titleController,
                                enabled: !_submitting,
                                decoration: _inputDecoration('Task Title'),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Task title is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide = constraints.maxWidth >= 840;
                                  if (!wide) {
                                    return Column(
                                      children: _mobileFields(context),
                                    );
                                  }
                                  return Column(
                                    children: _desktopFields(context),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _label('Attach Files'),
                              const SizedBox(height: 8),
                              _buildAttachmentBox(),
                              const SizedBox(height: 18),
                              _label('Task Description'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descriptionController,
                                enabled: !_submitting,
                                minLines: 4,
                                maxLines: 6,
                                decoration: _inputDecoration(
                                  'Task Description',
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                onPressed: (_loading || _submitting)
                                    ? null
                                    : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D8CFF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        _isEditMode ? 'Update Task' : 'Submit',
                                        style: AppTextStyles.style(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
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
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _mobileFields(BuildContext context) {
    return [
      _projectField(),
      const SizedBox(height: 16),
      _priorityField(),
      const SizedBox(height: 16),
      _statusField(),
      const SizedBox(height: 16),
      _dateField(
        label: 'Start Date',
        value: _formatDate(_startDate),
        onTap: () => _pickDate(
          initial: _startDate ?? DateTime.now(),
          onSelected: (value) => setState(() => _startDate = value),
        ),
      ),
      const SizedBox(height: 16),
      _dateField(
        label: 'Due Date',
        value: _formatDate(_dueDate),
        onTap: () => _pickDate(
          initial: _dueDate ?? _startDate ?? DateTime.now(),
          onSelected: (value) => setState(() => _dueDate = value),
        ),
      ),
      const SizedBox(height: 16),
      _selectorField(
        label: 'Assignees',
        text: _selectedStaffNames(_assigneeIds),
        onTap: () => _openStaffSelector(
          title: 'Assignees',
          selectedIds: _assigneeIds,
          onDone: (ids) => setState(() => _assigneeIds = ids),
        ),
      ),
      const SizedBox(height: 16),
      _selectorField(
        label: 'Followers',
        text: _selectedStaffNames(_followerIds),
        onTap: () => _openStaffSelector(
          title: 'Followers',
          selectedIds: _followerIds,
          onDone: (ids) => setState(() => _followerIds = ids),
        ),
      ),
      const SizedBox(height: 16),
      _tagField(),
    ];
  }

  List<Widget> _desktopFields(BuildContext context) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _projectField()),
          const SizedBox(width: 14),
          Expanded(child: _priorityField()),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _statusField()),
          const SizedBox(width: 14),
          Expanded(
            child: _dateField(
              label: 'Start Date',
              value: _formatDate(_startDate),
              onTap: () => _pickDate(
                initial: _startDate ?? DateTime.now(),
                onSelected: (value) => setState(() => _startDate = value),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _dateField(
              label: 'Due Date',
              value: _formatDate(_dueDate),
              onTap: () => _pickDate(
                initial: _dueDate ?? _startDate ?? DateTime.now(),
                onSelected: (value) => setState(() => _dueDate = value),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _selectorField(
              label: 'Assignees',
              text: _selectedStaffNames(_assigneeIds),
              onTap: () => _openStaffSelector(
                title: 'Assignees',
                selectedIds: _assigneeIds,
                onDone: (ids) => setState(() => _assigneeIds = ids),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _selectorField(
              label: 'Followers',
              text: _selectedStaffNames(_followerIds),
              onTap: () => _openStaffSelector(
                title: 'Followers',
                selectedIds: _followerIds,
                onDone: (ids) => setState(() => _followerIds = ids),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: _tagField()),
        ],
      ),
    ];
  }

  Widget _projectField() {
    final uniqueProjects = _dedupeProjectsById(_projects);
    final selectedProjectId = _resolveValidProjectValue(
      _projectId,
      uniqueProjects,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Project Related To'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: selectedProjectId,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'No Project (Optional)',
                style: AppTextStyles.style(
                  color: const Color(0xFF334155),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...uniqueProjects.map(
              (project) => DropdownMenuItem<String?>(
                value: project.id,
                child: Text(project.title, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (_loading || _submitting)
              ? null
              : (value) => setState(() => _projectId = value),
          decoration: _inputDecoration('No Project (Optional)'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ],
    );
  }

  Widget _priorityField() => _simpleDropdown(
    label: 'Priority',
    value: _priority,
    items: _priorities,
    onChanged: (value) => setState(() => _priority = value),
  );

  Widget _statusField() => _simpleDropdown(
    label: 'Main Status',
    value: _status,
    items: _statuses,
    onChanged: (value) => setState(() => _status = value),
  );

  Widget _simpleDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: _submitting
              ? null
              : (next) => next == null ? null : onChanged(next),
          decoration: _inputDecoration(label),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: _submitting ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: _inputDecoration(label).copyWith(
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              value,
              style: AppTextStyles.style(
                color: value == 'dd-mm-yyyy'
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF334155),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectorField({
    required String label,
    required String text,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: (_loading || _submitting || _staff.isEmpty) ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: _inputDecoration(label),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: text == 'Choose...'
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF334155),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tagField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Tags'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tagsController,
          enabled: !_submitting,
          decoration: _inputDecoration('Select or add tags'),
        ),
      ],
    );
  }

  Widget _buildAttachmentBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7E0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: _submitting ? null : _pickFiles,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Choose Files'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _files.isEmpty
                      ? 'No file chosen'
                      : '${_files.length} file${_files.length == 1 ? '' : 's'} selected',
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _files.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            _files[i].name,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.style(
                              color: const Color(0xFF334155),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: _submitting ? null : () => _removeFile(i),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFBE123C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: AppTextStyles.style(
                color: const Color(0xFF9F1239),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _loadOptions,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: AppTextStyles.style(
              color: const Color(0xFF334155),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: AppTextStyles.style(
                color: const Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.style(
        color: const Color(0xFF94A3B8),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1D8CFF), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        ApiService.instance.getProjectsList(),
        ApiService.instance.getStaffList(),
      ]);
      if (!mounted) return;

      setState(() {
        _projects = _dedupeProjectsById(results[0] as List<ProjectModel>);
        _staff = results[1] as List<StaffMemberModel>;
        if (_projectId != null &&
            !_projects.any((project) => project.id == _projectId)) {
          _projectId = null;
        }
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorText(error, 'Unable to load task form options.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load task form options.';
      });
    }
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (result == null || !mounted) return;
    setState(() => _files = result.files);
  }

  void _removeFile(int index) {
    if (index < 0 || index >= _files.length) return;
    setState(() {
      final next = List<PlatformFile>.from(_files);
      next.removeAt(index);
      _files = next;
    });
  }

  Future<void> _openStaffSelector({
    required String title,
    required List<String> selectedIds,
    required ValueChanged<List<String>> onDone,
  }) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StaffSelectorSheet(
        title: title,
        staff: _staff,
        initialSelectedIds: selectedIds,
      ),
    );
    if (result != null) {
      onDone(result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startDate != null &&
        _dueDate != null &&
        _dueDate!.isBefore(_startDate!)) {
      AppSnackbar.show(
        'Invalid date range',
        'Due date cannot be earlier than start date.',
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      if (_isEditMode) {
        await ApiService.instance.updateTaskRecord(
          id: widget.taskId!.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          priority: _priority,
          projectId: _projectId,
          startDate: _startDate,
          deadline: _dueDate,
          assigneeIds: _assigneeIds,
          followerIds: _followerIds,
          tags: tags,
        );
      } else {
        await ApiService.instance.createTaskRecord(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          priority: _priority,
          projectId: _projectId,
          startDate: _startDate,
          deadline: _dueDate,
          assigneeIds: _assigneeIds,
          followerIds: _followerIds,
          tags: tags,
        );
      }
      if (!mounted) return;

      AppSnackbar.show(
        _isEditMode ? 'Task updated' : 'Task created',
        _isEditMode
            ? 'The task has been updated successfully.'
            : 'The task has been created successfully.',
      );
      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackbar.show(
        _isEditMode ? 'Update task failed' : 'Create task failed',
        _errorText(
          error,
          _isEditMode ? 'Failed to update task.' : 'Failed to create task.',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackbar.show(
        _isEditMode ? 'Update task failed' : 'Create task failed',
        error.toString(),
      );
    }
  }

  String _selectedStaffNames(List<String> ids) {
    if (ids.isEmpty) return 'Choose...';
    final names = _staff
        .where((member) => ids.contains(member.id))
        .map(
          (member) => member.name.trim().isEmpty ? member.email : member.name,
        )
        .toList();
    return names.isEmpty ? 'Choose...' : names.join(', ');
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'dd-mm-yyyy';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day-$month-${value.year}';
  }

  String? _normalizePriorityLabel(String? value) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return null;
    }
  }

  String? _normalizeStatusLabel(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'not_started':
        return 'Not Started';
      case 'in_progress':
        return 'In Progress';
      case 'on_hold':
        return 'On Hold';
      case 'completed':
        return 'Completed';
      default:
        return null;
    }
  }

  List<ProjectModel> _dedupeProjectsById(List<ProjectModel> projects) {
    final byId = <String, ProjectModel>{};
    final withoutId = <ProjectModel>[];
    for (final project in projects) {
      final id = project.id.trim();
      if (id.isEmpty) {
        withoutId.add(project);
        continue;
      }
      byId.putIfAbsent(id, () => project);
    }
    return <ProjectModel>[...byId.values, ...withoutId];
  }

  String? _resolveValidProjectValue(
    String? value,
    List<ProjectModel> projects,
  ) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final matches = projects
        .where((project) => project.id == normalized)
        .length;
    return matches == 1 ? normalized : null;
  }
}

class _StaffSelectorSheet extends StatefulWidget {
  const _StaffSelectorSheet({
    required this.title,
    required this.staff,
    required this.initialSelectedIds,
  });

  final String title;
  final List<StaffMemberModel> staff;
  final List<String> initialSelectedIds;

  @override
  State<_StaffSelectorSheet> createState() => _StaffSelectorSheetState();
}

class _StaffSelectorSheetState extends State<_StaffSelectorSheet> {
  late final Set<String> _selected = widget.initialSelectedIds.toSet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.48,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select ${widget.title}',
                        style: AppTextStyles.style(
                          color: const Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_selected.toList()),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: widget.staff.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final member = widget.staff[index];
                    final title = member.name.trim().isEmpty
                        ? member.email
                        : member.name;
                    final subtitle = (member.role ?? member.email).trim();
                    return CheckboxListTile(
                      value: _selected.contains(member.id),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selected.add(member.id);
                          } else {
                            _selected.remove(member.id);
                          }
                        });
                      },
                      title: Text(
                        title,
                        style: AppTextStyles.style(
                          color: const Color(0xFF334155),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: subtitle.isEmpty
                          ? null
                          : Text(
                              subtitle,
                              style: AppTextStyles.style(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                      secondary: CircleAvatar(
                        backgroundColor: const Color(0xFFE0ECFF),
                        backgroundImage:
                            (member.profileImage ?? '').trim().isEmpty
                            ? null
                            : NetworkImage(member.profileImage!.trim()),
                        child: (member.profileImage ?? '').trim().isNotEmpty
                            ? null
                            : Text(
                                _initials(title),
                                style: AppTextStyles.style(
                                  color: const Color(0xFF1D4ED8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: const Color(0xFF1D8CFF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _errorText(DioException error, String fallback) {
  final responseData = error.response?.data;
  if (responseData is Map && responseData['message'] != null) {
    return responseData['message'].toString();
  }
  final message = error.message?.trim() ?? '';
  return message.isEmpty ? fallback : message;
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((entry) => entry.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
