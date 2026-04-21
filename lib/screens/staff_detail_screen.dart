import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/project_model.dart';
import 'package:mycrm/models/staff_member_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

import '../routes/app_routes.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class StaffDetailScreen extends StatefulWidget {
  const StaffDetailScreen({super.key, this.staffId});

  final String? staffId;

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late final String _staffId;
  late Future<StaffMemberModel> _staffFuture;
  late Future<_StaffActivitySummary> _activityFuture;
  String? _selectedRole;
  String? _selectedStatus;
  String _teamValue = '';
  List<String> _departments = const [];
  bool _didInitializeForm = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _staffId = (widget.staffId ?? Get.arguments ?? '').toString();
    _staffFuture = ApiService.instance.getStaffDetail(_staffId);
    _activityFuture = _loadStaffActivitySummary();
  }

  void _reload() {
    setState(() {
      _staffFuture = ApiService.instance.getStaffDetail(_staffId);
      _activityFuture = _loadStaffActivitySummary();
      _didInitializeForm = false;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CommonScreenAppBar(title: 'User Profile'),
      body: _staffId.isEmpty
          ? const _DetailErrorState(
              title: 'Staff ID missing',
              subtitle: 'Open this page from the staff list.',
            )
          : FutureBuilder<StaffMemberModel>(
              future: _staffFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return _DetailErrorState(
                    title: 'Unable to load staff profile',
                    subtitle: 'Please retry the request.',
                    onRetry: _reload,
                  );
                }

                final member = snapshot.data!;
                _initializeForm(member);

                return FutureBuilder<_StaffActivitySummary>(
                  future: _activityFuture,
                  builder: (context, activitySnapshot) {
                    final summary =
                        activitySnapshot.data ?? _StaffActivitySummary.empty();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileHeaderCard(member: member),
                          const SizedBox(height: 24),
                          _SectionTitle(title: 'ACTIVITY TIME SUMMARY'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionSummaryCard(
                                  title: 'Projects',
                                  value: '${summary.projectCount}',
                                  subtitle: 'Assigned projects',
                                  icon: Icons.assignment_rounded,
                                  color: const Color(0xFF3B82F6),
                                  buttonLabel: 'View All',
                                  onTap: () => Get.toNamed(
                                    AppRoutes.projects,
                                    arguments: <String, dynamic>{
                                      'staffId': _staffId,
                                      'staffName': member.name,
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionSummaryCard(
                                  title: 'Tasks',
                                  value: '${summary.taskCount}',
                                  subtitle: 'Assigned tasks',
                                  icon: Icons.check_circle_outline_rounded,
                                  color: const Color(0xFF22C55E),
                                  buttonLabel: 'View',
                                  onTap: () => Get.toNamed(
                                    AppRoutes.tasks,
                                    arguments: <String, dynamic>{
                                      'staffId': _staffId,
                                      'staffName': member.name,
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _EditProfileForm(
                            formKey: _formKey,
                            firstNameController: _firstNameController,
                            lastNameController: _lastNameController,
                            emailController: _emailController,
                            phoneController: _phoneController,
                            selectedRole: _selectedRole ?? 'Staff',
                            selectedStatus: _selectedStatus ?? 'Active',
                            onRoleChanged: (value) =>
                                setState(() => _selectedRole = value),
                            onStatusChanged: (value) =>
                                setState(() => _selectedStatus = value),
                            isSaving: _isSaving,
                            onSave: _saveChanges,
                          ),
                          const SizedBox(height: 24),
                          const _ChartPlaceholder(
                            title: 'MONTHLY PERFORMANCE TREND',
                          ),
                          const SizedBox(height: 24),
                          _PriorityBreakdownCard(summary: summary),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<_StaffActivitySummary> _loadStaffActivitySummary() async {
    if (_staffId.trim().isEmpty) {
      return _StaffActivitySummary.empty();
    }

    try {
      final responses = await Future.wait<dynamic>([
        ApiService.instance.getStaffProjectsList(_staffId),
        ApiService.instance.getStaffTasksList(_staffId),
      ]);

      final projects = responses[0] as List<ProjectModel>;
      final tasks = responses[1] as List<dynamic>;

      final projectCount = projects.length;

      var taskCount = 0;
      var highCount = 0;
      var mediumCount = 0;
      var lowCount = 0;

      for (final task in tasks) {
        if (task is! Map<String, dynamic> && task is! Map) {
          continue;
        }
        final normalizedTask = task is Map<String, dynamic>
            ? task
            : task.map((key, value) => MapEntry(key.toString(), value));
        if (!_isTaskAssignedToStaff(normalizedTask)) {
          continue;
        }

        taskCount += 1;
        final priority = _readTaskPriority(normalizedTask);
        if (priority == 'high' ||
            priority == 'urgent' ||
            priority == 'critical') {
          highCount += 1;
        } else if (priority == 'medium') {
          mediumCount += 1;
        } else if (priority == 'low') {
          lowCount += 1;
        }
      }

      return _StaffActivitySummary(
        projectCount: projectCount,
        taskCount: taskCount,
        highPriorityTaskCount: highCount,
        mediumPriorityTaskCount: mediumCount,
        lowPriorityTaskCount: lowCount,
      );
    } catch (_) {
      return _StaffActivitySummary.empty();
    }
  }

  bool _isTaskAssignedToStaff(Map<String, dynamic> task) {
    final assigneeSources = <dynamic>[task['assignees'], task['assigned_to']];

    for (final source in assigneeSources) {
      if (source is! List) continue;

      for (final entry in source) {
        if (entry is String && entry.trim() == _staffId) {
          return true;
        }

        if (entry is num && entry.toString().trim() == _staffId) {
          return true;
        }

        if (entry is! Map && entry is! Map<String, dynamic>) {
          continue;
        }

        final normalized = entry is Map<String, dynamic>
            ? entry
            : entry.map((key, value) => MapEntry(key.toString(), value));
        final id =
            (normalized['id'] ??
                    normalized['user_id'] ??
                    normalized['staff_id'] ??
                    '')
                .toString()
                .trim();
        if (id == _staffId) {
          return true;
        }
      }
    }

    return false;
  }

  String _readTaskPriority(Map<String, dynamic> task) {
    final value = (task['priority'] ?? task['priority_level'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return value;
  }

  void _initializeForm(StaffMemberModel member) {
    if (_didInitializeForm) return;

    final nameParts = member.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
    _lastNameController.text = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';
    _emailController.text = member.email;
    _phoneController.text = member.phone ?? '';
    _selectedRole = member.role?.trim().isNotEmpty == true
        ? member.role!.trim()
        : 'Staff';
    _selectedStatus = member.isActive ? 'Active' : 'Inactive';
    _teamValue = member.team ?? '';
    _departments = List<String>.from(member.departments);
    _didInitializeForm = true;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ApiService.instance.editStaff(
        id: _staffId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: (_selectedRole ?? 'Staff').trim(),
        status: (_selectedStatus ?? 'Active').toLowerCase(),
        team: _teamValue.trim(),
        departments: _departments,
      );

      if (!mounted) return;

      AppSnackbar.show(
        'Staff updated',
        'Profile changes were saved successfully.',
      );
      _reload();
    } on DioException catch (error) {
      if (!mounted) return;

      var message = 'Failed to save staff details.';
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      AppSnackbar.show('Save failed', message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.member});

  final StaffMemberModel member;

  @override
  Widget build(BuildContext context) {
    final teamLabel = member.team?.trim().isNotEmpty == true
        ? member.team!
        : member.departments.isNotEmpty
        ? member.departments.join(', ')
        : 'N/A';
    final initials = member.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage: member.profileImage?.trim().isNotEmpty == true
                    ? NetworkImage(member.profileImage!)
                    : null,
                child: member.profileImage?.trim().isNotEmpty == true
                    ? null
                    : Text(
                        initials.isEmpty ? 'ST' : initials,
                        style: AppTextStyles.style(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 5,
                child: Container(
                  height: 18,
                  width: 18,
                  decoration: BoxDecoration(
                    color: member.isActive
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            member.name.isNotEmpty ? member.name : 'Staff Member',
            style: AppTextStyles.style(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            '${member.role?.trim().isNotEmpty == true ? member.role! : 'Staff'} • $teamLabel',
            style: AppTextStyles.style(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3B82F6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.email_outlined, text: member.email),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.phone_outlined,
            text: member.phone?.trim().isNotEmpty == true
                ? member.phone!
                : 'Phone not available',
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.groups_outlined, text: 'Team: $teamLabel'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String buttonLabel;
  final VoidCallback onTap;
  const _ActionSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.style(
              fontSize: 10,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.style(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.style(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withValues(alpha: 0.24)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                buttonLabel,
                style: AppTextStyles.style(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileForm extends StatelessWidget {
  const _EditProfileForm({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.selectedRole,
    required this.selectedStatus,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onSave,
    required this.isSaving,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final String selectedRole;
  final String selectedStatus;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile Details',
              style: AppTextStyles.style(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    label: 'First Name',
                    controller: firstNameController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    label: 'Last Name',
                    controller: lastNameController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InputField(
              label: 'Email Address',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _InputField(
              label: 'Phone',
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DropdownField(
                    label: 'Role',
                    value: selectedRole,
                    items: const ['Admin', 'Manager', 'Staff', 'Viewer'],
                    onChanged: onRoleChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DropdownField(
                    label: 'Status',
                    value: selectedStatus,
                    items: const ['Active', 'Inactive'],
                    onChanged: onStatusChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: AppTextStyles.style(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            fontSize: 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) {
            if ((label == 'First Name' || label == 'Email Address') &&
                (value == null || value.trim().isEmpty)) {
              return 'Required';
            }
            return null;
          },
          style: AppTextStyles.style(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            fontSize: 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : items.first,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(
                      fontSize: 14,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final String title;
  const _ChartPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          const SizedBox(height: 60),
          Center(
            child: Text(
              'Chart Placeholder',
              style: AppTextStyles.style(color: const Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Performance %',
                style: AppTextStyles.style(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityBreakdownCard extends StatelessWidget {
  const _PriorityBreakdownCard({required this.summary});

  final _StaffActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final highPercent = summary.highPriorityPercent;
    final mediumPercent = summary.mediumPriorityPercent;
    final lowPercent = summary.lowPriorityPercent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'TASK PRIORITY BREAKDOWN'),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: highPercent / 100,
                  strokeWidth: 12,
                  color: const Color(0xFFFB923C),
                  backgroundColor: const Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  children: [
                    _PriorityItem(
                      label: 'High',
                      percent: '$highPercent%',
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 8),
                    _PriorityItem(
                      label: 'Medium',
                      percent: '$mediumPercent%',
                      color: const Color(0xFFFB923C),
                    ),
                    const SizedBox(height: 8),
                    _PriorityItem(
                      label: 'Low',
                      percent: '$lowPercent%',
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffActivitySummary {
  const _StaffActivitySummary({
    required this.projectCount,
    required this.taskCount,
    required this.highPriorityTaskCount,
    required this.mediumPriorityTaskCount,
    required this.lowPriorityTaskCount,
  });

  final int projectCount;
  final int taskCount;
  final int highPriorityTaskCount;
  final int mediumPriorityTaskCount;
  final int lowPriorityTaskCount;

  factory _StaffActivitySummary.empty() => const _StaffActivitySummary(
    projectCount: 0,
    taskCount: 0,
    highPriorityTaskCount: 0,
    mediumPriorityTaskCount: 0,
    lowPriorityTaskCount: 0,
  );

  int get _safeTaskTotal => taskCount == 0 ? 1 : taskCount;

  int get highPriorityPercent =>
      ((highPriorityTaskCount / _safeTaskTotal) * 100).round();
  int get mediumPriorityPercent =>
      ((mediumPriorityTaskCount / _safeTaskTotal) * 100).round();
  int get lowPriorityPercent =>
      ((lowPriorityTaskCount / _safeTaskTotal) * 100).round();
}

class _PriorityItem extends StatelessWidget {
  final String label;
  final String percent;
  final Color color;
  const _PriorityItem({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.style(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          percent,
          style: AppTextStyles.style(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.style(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFB42318),
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.style(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: Text(
                    'Retry',
                    style: AppTextStyles.style(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
