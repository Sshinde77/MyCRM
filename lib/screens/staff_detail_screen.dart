import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/api_constants.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/department_setting_model.dart';
import 'package:mycrm/models/project_model.dart';
import 'package:mycrm/models/staff_member_model.dart';
import 'package:mycrm/models/team_setting_model.dart';
import 'package:mycrm/screens/staff_project_analytics_screen.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import 'package:mycrm/screens/staff_analytics_screen.dart';

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
  late Future<_StaffLeadMetricsSummary> _leadMetricsFuture;
  List<TeamSettingModel> _teamOptions = const <TeamSettingModel>[];
  List<DepartmentSettingModel> _departmentOptions =
      const <DepartmentSettingModel>[];
  bool _loadingFormOptions = false;
  String _teamValue = '';
  List<String> _departments = const [];
  bool _didInitializeForm = false;
  bool _isActive = true;
  bool _isSaving = false;
  final ScrollController _pageScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _staffId = _resolveStaffId(widget.staffId ?? Get.arguments);
    debugPrint(
      '[StaffDetail] init staffId="$_staffId" widget.staffId="${widget.staffId}" args="${Get.arguments}"',
    );
    _staffFuture = ApiService.instance.getStaffDetail(_staffId);
    _activityFuture = _loadStaffActivitySummary();
    _leadMetricsFuture = _loadStaffLeadMetricsSummary();
    _loadFormOptions();
  }

  String _resolveStaffId(dynamic source) {
    if (source == null) return '';
    if (source is String) return source.trim();
    if (source is num) return source.toString().trim();
    if (source is Map) {
      final raw =
          source['staffId'] ??
          source['staff_id'] ??
          source['user_id'] ??
          source['employee_id'] ??
          source['id'];
      if (raw == null) return '';
      return raw.toString().trim();
    }
    return source.toString().trim();
  }

  void _reload() {
    setState(() {
      _staffFuture = ApiService.instance.getStaffDetail(_staffId);
      _activityFuture = _loadStaffActivitySummary();
      _leadMetricsFuture = _loadStaffLeadMetricsSummary();
      _didInitializeForm = false;
    });
    _loadFormOptions();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pageScrollController.dispose();
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
                  if (snapshot.hasError) {
                    debugPrint(
                      '[StaffDetail] load failed for staffId="$_staffId": ${snapshot.error}',
                    );
                  } else {
                    debugPrint(
                      '[StaffDetail] load returned empty data for staffId="$_staffId"',
                    );
                  }
                  return _DetailErrorState(
                    title: 'Unable to load staff profile',
                    subtitle: 'Please retry the request.',
                    technicalDetails:
                        'staffId=$_staffId error=${snapshot.error}',
                    onRetry: _reload,
                  );
                }

                final member = snapshot.data!;
                debugPrint(
                  '[StaffDetail] loaded staff member id="${member.id}" name="${member.name}" email="${member.email}"',
                );
                _initializeForm(member);

                return FutureBuilder<_StaffActivitySummary>(
                  future: _activityFuture,
                  builder: (context, activitySnapshot) {
                    final summary =
                        activitySnapshot.data ?? _StaffActivitySummary.empty();

                    return SingleChildScrollView(
                      controller: _pageScrollController,
                      primary: false,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileHeaderCard(member: member),
                          const SizedBox(height: 12),
                          _SectionTitle(title: 'ACTIVITY TIME SUMMARY'),
                          const SizedBox(height: 8),
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
                              const SizedBox(width: 8),
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
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _StaffActionButtonsRow(
                              items: [
                                _StaffActionButtonData(
                                  label: 'Lead Analytics',
                                  icon: Icons.analytics_outlined,
                                  borderColor: const Color(0xFFE2E8F0),
                                  foregroundColor: const Color(0xFF0F172A),
                                  onPressed: () => Get.to(
                                    () => StaffAnalyticsScreen(
                                      staffId: _staffId,
                                      staffName: member.name,
                                    ),
                                  ),
                                ),
                                _StaffActionButtonData(
                                  label: 'Project Analytics',
                                  icon: Icons.insights_outlined,
                                  borderColor: const Color(0xFFC7D2FE),
                                  foregroundColor: const Color(0xFF4338CA),
                                  onPressed: () => Get.to(
                                    () => StaffProjectAnalyticsScreen(
                                      staffId: _staffId,
                                      staffName: member.name,
                                    ),
                                  ),
                                ),
                                _StaffActionButtonData(
                                  label: 'Edit Details',
                                  icon: Icons.edit_outlined,
                                  borderColor: const Color(0xFFBFDBFE),
                                  foregroundColor: const Color(0xFF1D4ED8),
                                  onPressed: () => _openEditDetailPopup(member),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionTitle(title: 'LEAD PERFORMANCE SUMMARY'),
                          const SizedBox(height: 8),
                          FutureBuilder<_StaffLeadMetricsSummary>(
                            future: _leadMetricsFuture,
                            builder: (context, leadMetricsSnapshot) {
                              final metrics =
                                  leadMetricsSnapshot.data ??
                                  _StaffLeadMetricsSummary.empty();
                              return _LeadMetricsGrid(summary: metrics);
                            },
                          ),
                          // const SizedBox(height: 24),
                          // const _ChartPlaceholder(
                          //   title: 'MONTHLY PERFORMANCE TREND',
                          // ),
                          // const SizedBox(height: 24),
                          // _PriorityBreakdownCard(summary: summary),
                          const SizedBox(height: 20),
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
    } catch (error, stackTrace) {
      debugPrint(
        '[StaffDetail] activity summary failed for staffId="$_staffId": $error\n$stackTrace',
      );
      return _StaffActivitySummary.empty();
    }
  }

  Future<_StaffLeadMetricsSummary> _loadStaffLeadMetricsSummary() async {
    if (_staffId.trim().isEmpty) {
      return _StaffLeadMetricsSummary.empty();
    }
    try {
      final payload = await ApiService.instance.getStaffAnalytics(_staffId);
      final flattened = <String, dynamic>{};

      String normalizeKey(String key) =>
          key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      void collect(dynamic source) {
        if (source is Map<String, dynamic>) {
          source.forEach((key, value) {
            flattened[normalizeKey(key)] = value;
            collect(value);
          });
          return;
        }
        if (source is Map) {
          source.forEach((key, value) {
            flattened[normalizeKey(key.toString())] = value;
            collect(value);
          });
          return;
        }
        if (source is List) {
          for (final item in source) {
            collect(item);
          }
        }
      }

      collect(payload);

      int readInt(List<String> keys) {
        for (final key in keys) {
          final value = payload[key] ?? flattened[normalizeKey(key)];
          if (value is num) {
            return value.toInt();
          }
          final parsed = int.tryParse((value ?? '').toString().trim());
          if (parsed != null) {
            return parsed;
          }
        }
        return 0;
      }

      String readText(List<String> keys, {String fallback = '0'}) {
        for (final key in keys) {
          final value = payload[key] ?? flattened[normalizeKey(key)];
          if (value == null) continue;
          final text = value.toString().trim();
          if (text.isNotEmpty) {
            return text;
          }
        }
        return fallback;
      }

      String withSuffixIfNumeric(String value, String suffix) {
        final normalized = value.trim();
        if (normalized.isEmpty) return value;
        if (normalized.endsWith(suffix)) return normalized;
        return num.tryParse(normalized) != null
            ? '$normalized$suffix'
            : normalized;
      }

      return _StaffLeadMetricsSummary(
        totalLeads: readInt(const [
          'total_leads',
          'totalLeads',
          'all_leads',
          'total_leads_assigned',
        ]),
        activeLeads: readInt(const ['active_leads', 'activeLeads']),
        converted: readInt(const ['converted', 'converted_leads']),
        lostLeads: readInt(const ['lost_leads', 'lostLeads']),
        totalFollowups: readInt(const [
          'total_followups',
          'totalFollowups',
          'followups',
        ]),
        pendingFollowups: readInt(const [
          'pending_followups',
          'pendingFollowups',
        ]),
        overdue: readInt(const ['overdue', 'overdue_followups']),
        todaysFollowups: readInt(const [
          'todays_followups',
          'today_followups',
          'todaysFollowups',
        ]),
        meetings: readInt(const [
          'meetings',
          'total_meetings',
          'meetings_scheduled',
        ]),
        conversionPercent: withSuffixIfNumeric(
          readText(const [
            'conversion_percent',
            'conversion_percentage',
            'conversion',
            'conversion_rate',
          ], fallback: '0%'),
          '%',
        ),
        avgResponse: withSuffixIfNumeric(
          readText(const [
            'avg_response',
            'avg_response_time',
            'average_response',
            'avg_response_time_hours',
          ], fallback: '0h'),
          'h',
        ),
        avgConversion: withSuffixIfNumeric(
          readText(const [
            'avg_conversion',
            'average_conversion_time',
            'avg_conversion_time',
            'avg_conversion_time_days',
          ], fallback: '0d'),
          'd',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[StaffDetail] lead metrics failed for staffId="$_staffId": $error\n$stackTrace',
      );
      return _StaffLeadMetricsSummary.empty();
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

  Future<void> _loadFormOptions() async {
    setState(() => _loadingFormOptions = true);
    try {
      final responses = await Future.wait<dynamic>([
        ApiService.instance.getStaffTeams(),
        ApiService.instance.getStaffDepartments(),
      ]);

      final teams = (responses[0] as List<TeamSettingModel>)
          .where((team) => team.name.trim().isNotEmpty)
          .toList(growable: false);
      final departments = (responses[1] as List<DepartmentSettingModel>)
          .where((item) => item.name.trim().isNotEmpty)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _teamOptions = teams;
        _departmentOptions = departments;
      });
    } catch (error, stackTrace) {
      debugPrint('[StaffDetail] form options load failed: $error\n$stackTrace');
      if (!mounted) return;
      AppSnackbar.show('Warning', 'Unable to load team/department options.');
    } finally {
      if (mounted) {
        setState(() => _loadingFormOptions = false);
      }
    }
  }

  dynamic _normalizeStaffOptionValue(dynamic value) {
    if (value is num) return value;
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    return int.tryParse(text) ?? text;
  }

  dynamic _teamPayloadValue(String selectedValue) {
    final selected = selectedValue.trim();
    if (selected.isEmpty) return null;

    for (final team in _teamOptions) {
      final name = team.name.trim();
      final id = (team.id ?? '').trim();
      if (name == selected || (id.isNotEmpty && id == selected)) {
        return name.isNotEmpty ? name : id;
      }
    }
    return null;
  }

  List<dynamic> _departmentPayloadValues(List<String> selectedValues) {
    final payload = <dynamic>[];
    for (final selected in selectedValues) {
      var matched = false;
      for (final department in _departmentOptions) {
        final name = department.name.trim();
        final id = (department.id ?? '').trim();
        if (name == selected || (id.isNotEmpty && id == selected)) {
          if (id.isNotEmpty) {
            payload.add(_normalizeStaffOptionValue(id));
          } else if (name.isNotEmpty) {
            payload.add(name);
          }
          matched = true;
          break;
        }
      }
      if (!matched) {
        return const <dynamic>[];
      }
    }
    return payload;
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
    _teamValue = member.team ?? '';
    _departments = List<String>.from(member.departments);
    _isActive = member.isActive;
    _didInitializeForm = true;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_teamValue.trim().isEmpty) {
      AppSnackbar.show('Validation', 'Please select a team.');
      return;
    }
    if (_departments.isEmpty) {
      AppSnackbar.show('Validation', 'Please select at least one department.');
      return;
    }

    final teamPayload = _teamPayloadValue(_teamValue);
    if (teamPayload == null) {
      AppSnackbar.show(
        'Validation',
        'Please reselect team from the latest team options.',
      );
      return;
    }
    final departmentPayload = _departmentPayloadValues(_departments);
    if (departmentPayload.isEmpty) {
      AppSnackbar.show(
        'Validation',
        'Please reselect departments from the latest department options.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiService.instance.editStaff(
        id: _staffId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        status: _isActive ? 'active' : 'inactive',
        team: teamPayload,
        departments: departmentPayload,
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
      if (data is Map) {
        final normalized = data.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final validationMessage = _readFirstValidationErrorMessage(normalized);
        if (validationMessage != null) {
          message = validationMessage;
        } else if (normalized['message'] != null) {
          message = normalized['message'].toString();
        }
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

  Future<void> _openEditDetailPopup(StaffMemberModel member) async {
    final dialogFormKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final dialogScrollController = ScrollController();
    final nameParts = member.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
    lastNameController.text = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';
    emailController.text = member.email;
    phoneController.text = member.phone ?? '';
    var teamValue = member.team ?? '';
    var departments = List<String>.from(member.departments);
    var isActive = member.isActive;
    var isSaving = false;

    dynamic resolveTeamPayloadValue(String selected) {
      final normalized = selected.trim();
      if (normalized.isEmpty) return null;
      for (final team in _teamOptions) {
        final name = team.name.trim();
        final id = (team.id ?? '').trim();
        if (name == normalized || (id.isNotEmpty && id == normalized)) {
          return name.isNotEmpty ? name : id;
        }
      }
      return null;
    }

    List<dynamic> resolveDepartmentPayloadValues(List<String> selectedValues) {
      final payload = <dynamic>[];
      for (final selected in selectedValues) {
        var matched = false;
        for (final department in _departmentOptions) {
          final name = department.name.trim();
          final id = (department.id ?? '').trim();
          if (name == selected || (id.isNotEmpty && id == selected)) {
            if (id.isNotEmpty) {
              payload.add(_normalizeStaffOptionValue(id));
            } else if (name.isNotEmpty) {
              payload.add(name);
            }
            matched = true;
            break;
          }
        }
        if (!matched) {
          return const <dynamic>[];
        }
      }
      return payload;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveFromDialog() async {
              if (!dialogFormKey.currentState!.validate()) return;
              if (teamValue.trim().isEmpty) {
                AppSnackbar.show('Validation', 'Please select a team.');
                return;
              }
              if (departments.isEmpty) {
                AppSnackbar.show(
                  'Validation',
                  'Please select at least one department.',
                );
                return;
              }
              final teamPayload = resolveTeamPayloadValue(teamValue);
              if (teamPayload == null) {
                AppSnackbar.show(
                  'Validation',
                  'Please reselect team from the latest team options.',
                );
                return;
              }
              final departmentPayload = resolveDepartmentPayloadValues(
                departments,
              );
              if (departmentPayload.isEmpty) {
                AppSnackbar.show(
                  'Validation',
                  'Please reselect departments from the latest department options.',
                );
                return;
              }

              setDialogState(() => isSaving = true);
              try {
                await ApiService.instance.editStaff(
                  id: _staffId,
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  status: isActive ? 'active' : 'inactive',
                  team: teamPayload,
                  departments: departmentPayload,
                );
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                AppSnackbar.show(
                  'Staff updated',
                  'Profile changes were saved successfully.',
                );
                _reload();
              } on DioException catch (error) {
                var message = 'Failed to save staff details.';
                final data = error.response?.data;
                if (data is Map && data['message'] != null) {
                  message = data['message'].toString();
                } else if (error.message != null &&
                    error.message!.trim().isNotEmpty) {
                  message = error.message!.trim();
                }
                AppSnackbar.show('Save failed', message);
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => isSaving = false);
                }
              }
            }

            final media = MediaQuery.of(dialogContext);
            final screenHeight = media.size.height;
            final screenWidth = media.size.width;
            return SafeArea(
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth > 760 ? 720 : screenWidth - 24,
                    maxHeight: screenHeight * 0.84,
                  ),
                  child: SingleChildScrollView(
                    controller: dialogScrollController,
                    primary: false,
                    padding: const EdgeInsets.all(12),
                    child: _EditProfileForm(
                      formKey: dialogFormKey,
                      firstNameController: firstNameController,
                      lastNameController: lastNameController,
                      emailController: emailController,
                      phoneController: phoneController,
                      teamOptions: _teamOptions,
                      departmentOptions: _departmentOptions,
                      selectedTeam: teamValue,
                      selectedDepartments: departments,
                      isActive: isActive,
                      isLoadingOptions: _loadingFormOptions,
                      onTeamChanged: (value) =>
                          setDialogState(() => teamValue = value),
                      onDepartmentToggle: (value, selected) {
                        setDialogState(() {
                          final updated = List<String>.from(departments);
                          if (selected) {
                            if (!updated.contains(value)) {
                              updated.add(value);
                            }
                          } else {
                            updated.remove(value);
                          }
                          departments = updated;
                        });
                      },
                      onStatusChanged: (value) =>
                          setDialogState(() => isActive = value),
                      isSaving: isSaving,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSave: saveFromDialog,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      firstNameController.dispose();
      lastNameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      dialogScrollController.dispose();
    });
  }
}

String? _readFirstValidationErrorMessage(Map<String, dynamic> payload) {
  final errors = <MapEntry<String, String>>[];

  void visit(dynamic node, {String? inheritedField}) {
    if (node == null) return;

    if (node is Map) {
      final normalized = node.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      if (normalized['errors'] != null) {
        visit(normalized['errors'], inheritedField: inheritedField);
      }

      final field =
          normalized['field']?.toString().trim() ??
          normalized['name']?.toString().trim() ??
          inheritedField ??
          '';
      final message =
          normalized['message']?.toString().trim() ??
          normalized['error']?.toString().trim() ??
          normalized['detail']?.toString().trim() ??
          '';

      if (field.isNotEmpty && message.isNotEmpty) {
        errors.add(MapEntry(field, message));
      }

      for (final entry in normalized.entries) {
        final key = entry.key;
        final value = entry.value;

        if (key == 'errors' ||
            key == 'message' ||
            key == 'error' ||
            key == 'detail' ||
            key == 'field' ||
            key == 'name') {
          continue;
        }

        if (value is Map) {
          final fieldName = inheritedField == null || inheritedField.isEmpty
              ? key
              : '$inheritedField.$key';
          visit(value, inheritedField: fieldName);
          continue;
        }

        if (value is Iterable) {
          for (final item in value) {
            if (item is Map) {
              final fieldName = inheritedField == null || inheritedField.isEmpty
                  ? key
                  : '$inheritedField.$key';
              visit(item, inheritedField: fieldName);
              continue;
            }

            final message = item?.toString().trim() ?? '';
            if (message.isNotEmpty) {
              final fieldName = inheritedField == null || inheritedField.isEmpty
                  ? key
                  : '$inheritedField.$key';
              errors.add(MapEntry(fieldName, message));
            }
          }
          continue;
        }

        final message = value?.toString().trim() ?? '';
        if (message.isNotEmpty) {
          final fieldName = inheritedField == null || inheritedField.isEmpty
              ? key
              : '$inheritedField.$key';
          errors.add(MapEntry(fieldName, message));
        }
      }
      return;
    }

    if (node is Iterable) {
      for (final item in node) {
        visit(item, inheritedField: inheritedField);
      }
      return;
    }

    final message = node.toString().trim();
    if (message.isNotEmpty &&
        inheritedField != null &&
        inheritedField.isNotEmpty) {
      errors.add(MapEntry(inheritedField, message));
    }
  }

  visit(payload['errors'] ?? payload);

  if (errors.isNotEmpty) {
    final first = errors.first;
    return '${first.key}: ${first.value}';
  }

  final message = payload['message']?.toString().trim() ?? '';
  return message.isEmpty ? null : message;
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
    final nameParts = member.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    final firstInitial = nameParts.isNotEmpty ? nameParts.first[0] : '';
    final lastInitial = nameParts.length > 1 ? nameParts.last[0] : '';
    final initials = '$firstInitial$lastInitial'.toUpperCase();
    final departmentLabel = member.departments.isNotEmpty
        ? member.departments.join(', ')
        : 'N/A';
    final roleLabel = member.role?.trim().isNotEmpty == true
        ? member.role!
        : 'Staff';
    final phoneLabel = member.phone?.trim().isNotEmpty == true
        ? member.phone!
        : 'Phone not available';
    final statusLabel = member.isActive ? 'ACTIVE' : 'INACTIVE';
    final statusColor = member.isActive
        ? const Color(0xFF166534)
        : const Color(0xFF64748B);
    final statusBg = member.isActive
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFF1F5F9);
    final profileImageUrl = _resolveStaffProfileImageUrl(member.profileImage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl != null
                    ? null
                    : Text(
                        initials.isEmpty ? 'S' : initials,
                        style: AppTextStyles.style(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
              ),
              if (member.isActive)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    height: 11,
                    width: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name.isNotEmpty ? member.name : 'Staff Member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.style(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.style(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$roleLabel - $teamLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.style(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.email_outlined, text: member.email),
                const SizedBox(height: 4),
                _InfoRow(icon: Icons.phone_outlined, text: phoneLabel),
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Icons.apartment_outlined,
                  text: 'Department: $departmentLabel',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _resolveStaffProfileImageUrl(String? rawPath) {
  final path = (rawPath ?? '').trim();
  if (path.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(path);
  if (parsed != null && parsed.hasScheme) {
    return path;
  }

  return Uri.parse(
    ApiConstants.appBaseUrl,
  ).resolve(path.startsWith('/') ? path.substring(1) : path).toString();
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: AppTextStyles.style(
              fontSize: 11.5,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 6),
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.style(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withValues(alpha: 0.24)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                buttonLabel,
                style: AppTextStyles.style(
                  fontSize: 11,
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
    required this.teamOptions,
    required this.departmentOptions,
    required this.selectedTeam,
    required this.selectedDepartments,
    required this.isActive,
    required this.isLoadingOptions,
    required this.onTeamChanged,
    required this.onDepartmentToggle,
    required this.onStatusChanged,
    required this.onSave,
    required this.isSaving,
    this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final List<TeamSettingModel> teamOptions;
  final List<DepartmentSettingModel> departmentOptions;
  final String selectedTeam;
  final List<String> selectedDepartments;
  final bool isActive;
  final bool isLoadingOptions;
  final ValueChanged<String> onTeamChanged;
  final void Function(String value, bool selected) onDepartmentToggle;
  final ValueChanged<bool> onStatusChanged;
  final VoidCallback onSave;
  final bool isSaving;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 520;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (isNarrow)
              Column(
                children: [
                  _InputField(
                    label: 'First Name',
                    controller: firstNameController,
                  ),
                  const SizedBox(height: 10),
                  _InputField(
                    label: 'Last Name',
                    controller: lastNameController,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      label: 'First Name',
                      controller: firstNameController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InputField(
                      label: 'Last Name',
                      controller: lastNameController,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
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
            _DropdownField(
              label: 'Team',
              value: selectedTeam,
              items: <String>{
                selectedTeam.trim(),
                ...teamOptions
                    .map((item) => item.name.trim())
                    .where((name) => name.isNotEmpty),
              }.where((name) => name.isNotEmpty).toList(growable: false),
              onChanged: onTeamChanged,
            ),
            const SizedBox(height: 16),
            _DepartmentCheckboxGroup(
              label: 'Departments',
              options: <String>{
                ...selectedDepartments.map((value) => value.trim()),
                ...departmentOptions
                    .map((item) => item.name.trim())
                    .where((name) => name.isNotEmpty),
              }.where((name) => name.isNotEmpty).toList(growable: false),
              selectedValues: selectedDepartments,
              onToggle: onDepartmentToggle,
            ),
            const SizedBox(height: 16),
            _StatusToggle(isActive: isActive, onChanged: onStatusChanged),
            if (isLoadingOptions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Refreshing team/department options...',
                    style: AppTextStyles.style(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (isNarrow)
              Column(
                children: [
                  if (onCancel != null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: isSaving ? null : onCancel,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.style(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  if (onCancel != null) const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
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
              )
            else
              Row(
                children: [
                  if (onCancel != null)
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: isSaving ? null : onCancel,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.style(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (onCancel != null) const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
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
                  ),
                ],
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
            if ((label == 'First Name' ||
                    label == 'Last Name' ||
                    label == 'Email Address') &&
                (value == null || value.trim().isEmpty)) {
              return 'Required';
            }
            return null;
          },
          style: AppTextStyles.style(
            fontSize: 12.5,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
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
    final normalizedItems = items
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final normalizedValue = value.trim();
    final dropdownValue = normalizedValue.isNotEmpty
        ? normalizedValue
        : (normalizedItems.isNotEmpty ? normalizedItems.first : null);
    final allItems = <String>{
      ...normalizedItems,
      if (normalizedValue.isNotEmpty) normalizedValue,
    }.toList(growable: false);

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
          initialValue: dropdownValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          items: allItems
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(
                      fontSize: 12.5,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              )
              .toList(),
          validator: (_) {
            if (normalizedItems.isEmpty) {
              return 'No options available';
            }
            if ((dropdownValue ?? '').trim().isEmpty) {
              return 'Required';
            }
            return null;
          },
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _DepartmentCheckboxGroup extends StatelessWidget {
  const _DepartmentCheckboxGroup({
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  final String label;
  final List<String> options;
  final List<String> selectedValues;
  final void Function(String value, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.22;
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: options.isEmpty
              ? Text(
                  'No departments available',
                  style: AppTextStyles.style(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        children: options
                            .map((option) {
                              final checked = selectedValues.contains(option);
                              return CheckboxListTile(
                                value: checked,
                                title: Text(
                                  option,
                                  style: AppTextStyles.style(
                                    fontSize: 13,
                                    color: const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -4,
                                ),
                                onChanged: (value) =>
                                    onToggle(option, value ?? false),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({required this.isActive, required this.onChanged});

  final bool isActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isActive ? 'Status: Active' : 'Status: Inactive',
              style: AppTextStyles.style(
                fontSize: 13,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(value: isActive, onChanged: onChanged),
        ],
      ),
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

class _StaffActionButtonsRow extends StatelessWidget {
  const _StaffActionButtonsRow({required this.items});

  final List<_StaffActionButtonData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final compact = width < 430;
        final dense = width < 360;
        final iconSize = dense ? 12.0 : (compact ? 13.0 : 16.0);
        final fontSize = dense ? 10.0 : (compact ? 11.0 : 12.5);
        final horizontalPadding = dense ? 6.0 : (compact ? 8.0 : 10.0);
        final spacing = dense ? 6.0 : 8.0;

        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: items[i].onPressed,
                  icon: Icon(items[i].icon, size: iconSize),
                  label: Text(
                    items[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(fontSize: fontSize),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: items[i].borderColor),
                    foregroundColor: items[i].foregroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StaffActionButtonData {
  const _StaffActionButtonData({
    required this.label,
    required this.icon,
    required this.borderColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color borderColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
}

class _StaffLeadMetricsSummary {
  const _StaffLeadMetricsSummary({
    required this.totalLeads,
    required this.activeLeads,
    required this.converted,
    required this.lostLeads,
    required this.totalFollowups,
    required this.pendingFollowups,
    required this.overdue,
    required this.todaysFollowups,
    required this.meetings,
    required this.conversionPercent,
    required this.avgResponse,
    required this.avgConversion,
  });

  final int totalLeads;
  final int activeLeads;
  final int converted;
  final int lostLeads;
  final int totalFollowups;
  final int pendingFollowups;
  final int overdue;
  final int todaysFollowups;
  final int meetings;
  final String conversionPercent;
  final String avgResponse;
  final String avgConversion;

  factory _StaffLeadMetricsSummary.empty() => const _StaffLeadMetricsSummary(
    totalLeads: 0,
    activeLeads: 0,
    converted: 0,
    lostLeads: 0,
    totalFollowups: 0,
    pendingFollowups: 0,
    overdue: 0,
    todaysFollowups: 0,
    meetings: 0,
    conversionPercent: '0%',
    avgResponse: '0h',
    avgConversion: '0d',
  );
}

class _LeadMetricsGrid extends StatelessWidget {
  const _LeadMetricsGrid({required this.summary});

  final _StaffLeadMetricsSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = <_LeadMetricCardData>[
      _LeadMetricCardData(
        title: 'Total Leads',
        value: '${summary.totalLeads}',
        color: const Color(0xFF0EA5E9),
        icon: Icons.groups_rounded,
      ),
      _LeadMetricCardData(
        title: 'Active Leads',
        value: '${summary.activeLeads}',
        color: const Color(0xFF2563EB),
        icon: Icons.track_changes_rounded,
      ),
      _LeadMetricCardData(
        title: 'Converted',
        value: '${summary.converted}',
        color: const Color(0xFF22C55E),
        icon: Icons.trending_up_rounded,
      ),
      _LeadMetricCardData(
        title: 'Total Followups',
        value: '${summary.totalFollowups}',
        color: const Color(0xFFF59E0B),
        icon: Icons.call_rounded,
      ),
      _LeadMetricCardData(
        title: 'Lost Leads',
        value: '${summary.lostLeads}',
        color: const Color(0xFFF43F5E),
        icon: Icons.trending_down_rounded,
      ),
      _LeadMetricCardData(
        title: 'Conversion %',
        value: summary.conversionPercent,
        color: const Color(0xFF22C55E),
        icon: Icons.percent_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        const crossAxisCount = 3;
        final cardWidth = (width - ((crossAxisCount - 1) * 8)) / crossAxisCount;
        final childAspectRatio = (cardWidth / 124).clamp(0.9, 1.6);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _LeadMetricCard(data: cards[index]);
          },
        );
      },
    );
  }
}

class _LeadMetricCardData {
  const _LeadMetricCardData({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;
}

class _LeadMetricCard extends StatelessWidget {
  const _LeadMetricCard({required this.data});

  final _LeadMetricCardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 165;
        final iconBox = compact ? 24.0 : 30.0;
        final iconSize = compact ? 14.0 : 17.0;
        final titleSize = compact ? 10.0 : 12.0;
        final valueSize = compact ? 24.0 : 32.0;

        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 8 : 12,
            compact ? 8 : 12,
            compact ? 8 : 12,
            compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: iconBox,
                    width: iconBox,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, size: iconSize, color: data.color),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.style(
                        fontSize: titleSize,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                data.value,
                style: AppTextStyles.style(
                  fontSize: valueSize,
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  widthFactor: 0.75,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: data.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
    this.technicalDetails,
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final String? technicalDetails;
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
              if ((technicalDetails ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  technicalDetails!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.style(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
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
