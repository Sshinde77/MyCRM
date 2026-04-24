import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

import '../models/calendar_event_model.dart';
import '../models/client_issue_model.dart';
import '../models/project_model.dart';
import '../models/renewal_model.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../screens/to_do_list.dart' as to_do;
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';

/// Main CRM dashboard shown after a successful login.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService.instance;
  late List<_Appointment> _appointments;
  bool _isLoadingCalendar = false;
  bool _isSavingCalendar = false;
  bool _isLoadingSummary = false;
  bool _isLoadingRenewals = false;
  bool _isLoadingTickets = false;
  String? _calendarLoadError;
  String? _summaryLoadError;
  String? _renewalLoadError;
  String? _ticketsLoadError;
  late DateTime _displayedMonth;
  int _projectCount = 0;
  int _taskCount = 0;
  List<int> _projectMonthlySeries = List<int>.filled(6, 0);
  List<int> _taskMonthlySeries = List<int>.filled(6, 0);
  Map<String, int> _taskStatusCounts = const {
    'notStarted': 0,
    'inProgress': 0,
    'onHold': 0,
    'completed': 0,
    'cancelled': 0,
  };
  List<_UpcomingRenewalItem> _upcomingRenewals = const <_UpcomingRenewalItem>[];
  List<ClientIssueModel> _recentIssues = const <ClientIssueModel>[];

  UserModel? _currentUser;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
    _appointments = _seedAppointments();
    _loadCurrentUser();
    _loadAllowedDashboardData();
  }

  Future<void> _loadAllowedDashboardData() async {
    final user = await PermissionService.getCurrentUser();
    if (!mounted || user == null) {
      return;
    }

    if (PermissionService.userHas(user, AppPermission.viewCalendar)) {
      _loadCalendarEvents();
    }
    if (PermissionService.userHas(user, AppPermission.viewProjects) ||
        PermissionService.userHas(user, AppPermission.viewTasks)) {
      _loadDashboardSummary();
    }
    if (PermissionService.userHas(user, AppPermission.viewRenewals)) {
      _loadUpcomingRenewals();
    }
    if (PermissionService.userHas(user, AppPermission.viewRaiseIssue)) {
      _loadRecentIssues();
    }
  }

  Future<void> _loadCurrentUser() async {
    final storedUser = await _apiService.getStoredUser();
    if (!mounted) {
      return;
    }

    if (storedUser != null) {
      PermissionService.setCurrentUser(storedUser);
      setState(() {
        _currentUser = storedUser;
      });
    }

    try {
      final user = await _apiService.getCurrentUser();
      if (!mounted) {
        return;
      }
      PermissionService.setCurrentUser(user);
      setState(() {
        _currentUser = user;
      });
    } on DioException {
      // Keep showing the cached user if profile refresh fails.
    } catch (_) {
      // Ignore non-critical profile refresh failures on dashboard load.
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBackground = Color(0xFFF5F7FB);
    const textSecondary = Color(0xFF74839D);

    return Scaffold(
      backgroundColor: pageBackground,
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.dashboard,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderSection(user: _currentUser),
                  const SizedBox(height: 18),
                  PermissionGate(
                    permission: AppPermission.viewRenewals,
                    child: Column(
                      children: [
                        _SectionCard(
                          padding: EdgeInsets.fromLTRB(18, 20, 18, 16),
                          child: _RenewalSection(
                            items: _upcomingRenewals,
                            isLoading: _isLoadingRenewals,
                            errorMessage: _renewalLoadError,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  PermissionGate(
                    permission: AppPermission.viewProjects,
                    child: Column(
                      children: [
                        _SectionCard(
                          padding: EdgeInsets.fromLTRB(18, 18, 18, 18),
                          child: _ProjectSummarySection(
                            projectCount: _projectCount,
                            taskCount: _taskCount,
                            projectMonthlySeries: _projectMonthlySeries,
                            taskMonthlySeries: _taskMonthlySeries,
                            monthLabels: _last6MonthLabels(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  PermissionGate(
                    permission: AppPermission.viewTasks,
                    child: Column(
                      children: [
                        _SectionCard(
                          padding: EdgeInsets.fromLTRB(18, 18, 18, 20),
                          child: _TaskSummarySection(
                            taskStatusCounts: _taskStatusCounts,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  PermissionGate(
                    permission: AppPermission.viewRaiseIssue,
                    child: Column(
                      children: [
                        _SectionCard(
                          padding: EdgeInsets.fromLTRB(18, 18, 18, 18),
                          child: _SupportTicketsSection(
                            issues: _recentIssues,
                            isLoading: _isLoadingTickets,
                            errorMessage: _ticketsLoadError,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  PermissionGate(
                    permission: AppPermission.viewCalendar,
                    child: _CalendarAppointmentsSection(
                      appointments: _appointments,
                      displayedMonth: _displayedMonth,
                      onAddAppointment: _handleCreateAppointment,
                      onDateTap: _showAppointmentsForDate,
                      onPreviousMonth: () {
                        setState(() {
                          _displayedMonth = DateTime(
                            _displayedMonth.year,
                            _displayedMonth.month - 1,
                          );
                        });
                      },
                      onNextMonth: () {
                        setState(() {
                          _displayedMonth = DateTime(
                            _displayedMonth.year,
                            _displayedMonth.month + 1,
                          );
                        });
                      },
                    ),
                  ),
                  if (_isLoadingCalendar || _isSavingCalendar) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (_isLoadingSummary) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (_calendarLoadError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _calendarLoadError!,
                      style: AppTextStyles.style(
                        color: const Color(0xFFB42318),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_summaryLoadError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _summaryLoadError!,
                      style: AppTextStyles.style(
                        color: const Color(0xFFB42318),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_renewalLoadError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _renewalLoadError!,
                      style: AppTextStyles.style(
                        color: const Color(0xFFB42318),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_ticketsLoadError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _ticketsLoadError!,
                      style: AppTextStyles.style(
                        color: const Color(0xFFB42318),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                ],
              ),
            ),
          ),
        ),
      ),
    );

  }

  Future<void> _loadCalendarEvents() async {
    setState(() {
      _isLoadingCalendar = true;
      _calendarLoadError = null;
    });

    try {
      final events = await _apiService.getCalendarEvents();
      if (!mounted) {
        return;
      }

      final mapped = events.map(_appointmentFromEvent).toList()
        ..sort((a, b) {
          final aDate = DateTime(
            a.date.year,
            a.date.month,
            a.date.day,
            a.time.hour,
            a.time.minute,
          );
          final bDate = DateTime(
            b.date.year,
            b.date.month,
            b.date.day,
            b.time.hour,
            b.time.minute,
          );
          return aDate.compareTo(bDate);
        });

      setState(() {
        _appointments = mapped;
        _isLoadingCalendar = false;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCalendar = false;
        _calendarLoadError =
            'Calendar failed to load (${error.response?.statusCode ?? 'network'}).';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCalendar = false;
        _calendarLoadError = 'Calendar failed to load.';
      });
    }
  }

  Future<void> _loadDashboardSummary() async {
    if (mounted) {
      setState(() {
        _isLoadingSummary = true;
        _summaryLoadError = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _apiService.getProjectsList(),
        _apiService.getTasksList(),
      ]);

      final projectRecords = (results[0] as List)
          .whereType<ProjectModel>()
          .toList();
      final projects = projectRecords.length;
      final taskRecords = (results[1] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      final taskStatuses = _extractTaskStatuses(taskRecords);
      final projectSeries = List<int>.filled(6, 0);
      final taskSeries = List<int>.filled(6, 0);
      _populateProjectMonthlySeries(projectRecords, projectSeries);
      _populateTaskMonthlySeries(taskRecords, taskSeries);

      final statusCounts = <String, int>{
        'notStarted': 0,
        'inProgress': 0,
        'onHold': 0,
        'completed': 0,
        'cancelled': 0,
      };
      for (final status in taskStatuses) {
        final bucket = _statusBucket(status);
        statusCounts[bucket] = (statusCounts[bucket] ?? 0) + 1;
      }

      if (!mounted) return;
      setState(() {
        _projectCount = projects;
        _taskCount = taskStatuses.length;
        _projectMonthlySeries = projectSeries;
        _taskMonthlySeries = taskSeries;
        _taskStatusCounts = statusCounts;
        _isLoadingSummary = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingSummary = false;
        _summaryLoadError =
            'Summary failed to load (${error.response?.statusCode ?? 'network'}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingSummary = false;
        _summaryLoadError = 'Summary failed to load.';
      });
    }
  }

  Future<void> _loadUpcomingRenewals() async {
    if (mounted) {
      setState(() {
        _isLoadingRenewals = true;
        _renewalLoadError = null;
      });
    }

    try {
      final results = await Future.wait<List<RenewalModel>>([
        _apiService.getClientRenewalsList(),
        _apiService.getVendorRenewalsList(),
      ]);

      final clientRenewals = results[0];
      final vendorRenewals = results[1];
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final combined = <_UpcomingRenewalItem>[
        ...clientRenewals.map(
          (entry) => _UpcomingRenewalItem.fromRenewal(
            entry,
            source: _RenewalSource.client,
          ),
        ),
        ...vendorRenewals.map(
          (entry) => _UpcomingRenewalItem.fromRenewal(
            entry,
            source: _RenewalSource.vendor,
          ),
        ),
      ];

      final upcoming =
          combined.where((item) {
            final date = item.renewalDateValue;
            if (date == null) {
              return false;
            }
            final normalized = DateTime(date.year, date.month, date.day);
            return !normalized.isBefore(todayDate);
          }).toList()..sort((a, b) {
            final aDate = a.renewalDateValue;
            final bDate = b.renewalDateValue;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });

      if (!mounted) return;
      setState(() {
        _upcomingRenewals = upcoming;
        _isLoadingRenewals = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingRenewals = false;
        _renewalLoadError =
            'Renewals failed to load (${error.response?.statusCode ?? 'network'}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRenewals = false;
        _renewalLoadError = 'Renewals failed to load.';
      });
    }
  }

  Future<void> _loadRecentIssues() async {
    if (mounted) {
      setState(() {
        _isLoadingTickets = true;
        _ticketsLoadError = null;
      });
    }

    try {
      final issues = await _apiService.getClientIssuesList();
      final sorted = List<ClientIssueModel>.from(issues)
        ..sort((a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

      if (!mounted) return;
      setState(() {
        _recentIssues = sorted.take(3).toList(growable: false);
        _isLoadingTickets = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingTickets = false;
        _ticketsLoadError =
            'Support tickets failed to load (${error.response?.statusCode ?? 'network'}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingTickets = false;
        _ticketsLoadError = 'Support tickets failed to load.';
      });
    }
  }

  List<String> _extractTaskStatuses(List<Map<String, dynamic>> taskRecords) {
    final statuses = <String>[];

    for (final record in taskRecords) {
      final nested = record['tasks'];
      if (nested is List && nested.isNotEmpty) {
        for (final task in nested) {
          final taskMap = task is Map<String, dynamic>
              ? task
              : task is Map
              ? task.map((key, value) => MapEntry(key.toString(), value))
              : const <String, dynamic>{};
          statuses.add(_readTaskStatus(taskMap));
        }
        continue;
      }

      statuses.add(_readTaskStatus(record));
    }

    return statuses;
  }

  String _readTaskStatus(Map<String, dynamic> task) {
    final status = (task['status'] ?? task['task_status'] ?? '')
        .toString()
        .trim();
    return status.isEmpty ? 'Not Started' : status;
  }

  String _statusBucket(String status) {
    final value = status.toLowerCase();
    if (value.contains('cancel')) {
      return 'cancelled';
    }
    if (value.contains('complete') || value == 'done' || value == 'closed') {
      return 'completed';
    }
    if (value.contains('hold')) {
      return 'onHold';
    }
    if (value.contains('progress') ||
        value.contains('running') ||
        value.contains('active')) {
      return 'inProgress';
    }
    return 'notStarted';
  }

  List<String> _last6MonthLabels() {
    final now = DateTime.now();
    return List<String>.generate(6, (index) {
      final monthDate = DateTime(now.year, now.month - 5 + index, 1);
      return _monthShortLabel(monthDate);
    });
  }

  void _populateProjectMonthlySeries(
    List<ProjectModel> projects,
    List<int> series,
  ) {
    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month - 5, 1);
    for (final project in projects) {
      final startDate = DateTime.tryParse(project.startDate.trim());
      if (startDate == null) {
        continue;
      }
      final monthIndex =
          ((startDate.year - firstMonth.year) * 12) +
          (startDate.month - firstMonth.month);
      if (monthIndex >= 0 && monthIndex < series.length) {
        series[monthIndex] = series[monthIndex] + 1;
      }
    }
  }

  void _populateTaskMonthlySeries(
    List<Map<String, dynamic>> records,
    List<int> series,
  ) {
    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month - 5, 1);

    DateTime? parseTaskDate(Map<String, dynamic> source) {
      for (final key in const [
        'start_date',
        'startDate',
        'created_at',
        'createdAt',
        'deadline',
        'due_date',
      ]) {
        final value = source[key];
        if (value == null) {
          continue;
        }
        final parsed = DateTime.tryParse(value.toString().trim());
        if (parsed != null) {
          return parsed;
        }
      }
      return null;
    }

    void addToSeries(DateTime date) {
      final monthIndex =
          ((date.year - firstMonth.year) * 12) +
          (date.month - firstMonth.month);
      if (monthIndex >= 0 && monthIndex < series.length) {
        series[monthIndex] = series[monthIndex] + 1;
      }
    }

    for (final record in records) {
      final nested = record['tasks'];
      if (nested is List && nested.isNotEmpty) {
        for (final task in nested) {
          final taskMap = task is Map<String, dynamic>
              ? task
              : task is Map
              ? task.map((key, value) => MapEntry(key.toString(), value))
              : const <String, dynamic>{};
          final date = parseTaskDate(taskMap);
          if (date != null) {
            addToSeries(date);
          }
        }
        continue;
      }

      final date = parseTaskDate(record);
      if (date != null) {
        addToSeries(date);
      }
    }
  }

  _Appointment _appointmentFromEvent(CalendarEventModel event) {
    final start = event.startAt ?? DateTime.now();
    final date = DateTime(start.year, start.month, start.day);
    final time = TimeOfDay.fromDateTime(start);

    return _Appointment(
      id: event.id.trim().isEmpty ? null : event.id.trim(),
      title: event.title.trim().isEmpty ? 'Calendar Event' : event.title.trim(),
      description: event.description.trim().isEmpty
          ? 'Calendar event'
          : event.description.trim(),
      date: date,
      time: time,
      emailRecipients: event.emailRecipients?.trim() ?? '',
      whatsappRecipients: event.whatsappRecipients?.trim() ?? '',
      isFromApi: true,
    );
  }

  Future<void> _showAppointmentDetail(_Appointment appointment) async {
    final id = appointment.id;
    if (id == null || id.trim().isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(appointment.title),
            content: Text(appointment.description),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return FutureBuilder<CalendarEventModel>(
          future: _apiService.getCalendarEventDetail(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('Event Detail'),
                content: SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return AlertDialog(
                title: const Text('Event Detail'),
                content: const Text('Unable to load event detail.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final event = snapshot.data!;
            final startAt = event.startAt;
            final endAt = event.endAt ?? startAt?.add(const Duration(hours: 1));
            final friendlyWhen = startAt == null
                ? 'Not available'
                : '${_formatCalendarSheetDate(startAt)} at ${_formatTime(TimeOfDay.fromDateTime(startAt))}';
            final friendlyEnd = endAt == null
                ? null
                : '${_formatCalendarSheetDate(endAt)} at ${_formatTime(TimeOfDay.fromDateTime(endAt))}';

            final appointmentDraft = _appointmentFromEvent(event);

            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              title: Text(
                event.title.trim().isEmpty
                    ? 'Event Detail'
                    : event.title.trim(),
                style: AppTextStyles.style(
                  color: const Color(0xFF22314A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailLine(
                      icon: Icons.schedule_rounded,
                      label: 'When',
                      value: friendlyWhen,
                    ),
                    if (friendlyEnd != null) ...[
                      const SizedBox(height: 8),
                      _DetailLine(
                        icon: Icons.timelapse_rounded,
                        label: 'Ends',
                        value: friendlyEnd,
                      ),
                    ],
                    if (event.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE3EBF5)),
                        ),
                        child: Text(
                          event.description.trim(),
                          style: AppTextStyles.style(
                            color: const Color(0xFF5F738F),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    if ((event.location ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _DetailLine(
                        icon: Icons.place_outlined,
                        label: 'Location',
                        value: event.location!.trim(),
                      ),
                    ],
                    if ((event.emailRecipients ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _DetailLine(
                        icon: Icons.email_outlined,
                        label: 'Emails',
                        value: event.emailRecipients!.trim(),
                      ),
                    ],
                    if ((event.whatsappRecipients ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailLine(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'WhatsApp',
                        value: event.whatsappRecipients!.trim(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _handleEditAppointment(appointmentDraft);
                  },
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Delete appointment?'),
                          content: const Text(
                            'This will permanently delete the appointment.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFB42318),
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed != true) {
                      return;
                    }

                    Navigator.of(context).pop();
                    await _deleteCalendarEvent(id);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB42318),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCreateAppointment() async {
    final draft = await _showAppointmentDialog();
    if (draft == null) {
      return;
    }

    await _createCalendarEvent(draft);
  }

  Future<void> _handleEditAppointment(_Appointment initial) async {
    final draft = await _showAppointmentDialog(initial: initial);
    if (draft == null) {
      return;
    }

    final id = draft.id;
    if (id == null || id.trim().isEmpty) {
      AppSnackbar.show('Notice', 'Cannot edit: event id missing.');
      return;
    }

    await _updateCalendarEvent(draft);
  }

  String _formatApiTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String? _extractThirtyMinuteSlotError(DioException error) {
    String? message;

    final data = error.response?.data;
    if (data is Map) {
      final mapped = data.map((key, value) => MapEntry(key.toString(), value));
      final candidate = mapped['message'];
      if (candidate is String && candidate.trim().isNotEmpty) {
        message = candidate.trim();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      message = data.trim();
    }

    if (message == null) {
      return null;
    }

    if (message.contains(
      'Another appointment already exists within 30 minutes',
    )) {
      return message;
    }

    return null;
  }

  Future<void> _createCalendarEvent(_Appointment draft) async {
    setState(() {
      _isSavingCalendar = true;
      _calendarLoadError = null;
    });

    try {
      await _apiService.createCalendarEvent(
        title: draft.title.trim(),
        description: draft.description.trim(),
        eventDate: draft.date,
        eventTime: _formatApiTime(draft.time),
        emailRecipients: draft.emailRecipients.trim(),
        whatsappRecipients: draft.whatsappRecipients.trim(),
      );

      if (!mounted) return;
      await _loadCalendarEvents();
      if (!mounted) return;

      AppSnackbar.show('Success', 'Appointment created.');
    } on DioException catch (error) {
      if (!mounted) return;
      final slotError = _extractThirtyMinuteSlotError(error);
      if (slotError != null) {
        setState(() => _calendarLoadError = slotError);
        AppSnackbar.show('Notice', slotError);
        return;
      }
      setState(() {
        _calendarLoadError =
            'Failed to create appointment (${error.response?.statusCode ?? 'network'}).';
      });
      AppSnackbar.show('Error', 'Failed to create appointment.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _calendarLoadError = 'Failed to create appointment.');
      AppSnackbar.show('Error', 'Failed to create appointment.');
    } finally {
      if (mounted) {
        setState(() => _isSavingCalendar = false);
      }
    }
  }

  Future<void> _updateCalendarEvent(_Appointment draft) async {
    final id = draft.id;
    if (id == null || id.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSavingCalendar = true;
      _calendarLoadError = null;
    });

    try {
      await _apiService.updateCalendarEvent(
        id: id,
        title: draft.title.trim(),
        description: draft.description.trim(),
        eventDate: draft.date,
        eventTime: _formatApiTime(draft.time),
        emailRecipients: draft.emailRecipients.trim(),
        whatsappRecipients: draft.whatsappRecipients.trim(),
      );

      if (!mounted) return;
      await _loadCalendarEvents();
      if (!mounted) return;

      AppSnackbar.show('Success', 'Appointment updated.');
    } on DioException catch (error) {
      if (!mounted) return;
      final slotError = _extractThirtyMinuteSlotError(error);
      if (slotError != null) {
        setState(() => _calendarLoadError = slotError);
        AppSnackbar.show('Notice', slotError);
        return;
      }
      setState(() {
        _calendarLoadError =
            'Failed to update appointment (${error.response?.statusCode ?? 'network'}).';
      });
      AppSnackbar.show('Error', 'Failed to update appointment.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _calendarLoadError = 'Failed to update appointment.');
      AppSnackbar.show('Error', 'Failed to update appointment.');
    } finally {
      if (mounted) {
        setState(() => _isSavingCalendar = false);
      }
    }
  }

  Future<void> _deleteCalendarEvent(String id) async {
    setState(() {
      _isSavingCalendar = true;
      _calendarLoadError = null;
    });

    try {
      await _apiService.deleteCalendarEvent(id);
      if (!mounted) return;
      await _loadCalendarEvents();
      if (!mounted) return;

      AppSnackbar.show('Success', 'Appointment deleted.');
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _calendarLoadError =
            'Failed to delete appointment (${error.response?.statusCode ?? 'network'}).';
      });
      AppSnackbar.show('Error', 'Failed to delete appointment.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _calendarLoadError = 'Failed to delete appointment.');
      AppSnackbar.show('Error', 'Failed to delete appointment.');
    } finally {
      if (mounted) {
        setState(() => _isSavingCalendar = false);
      }
    }
  }

  Future<_Appointment?> _showAppointmentDialog({_Appointment? initial}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: initial?.title ?? '');
    final descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    final emailController = TextEditingController(
      text: initial?.emailRecipients ?? '',
    );
    final whatsappController = TextEditingController(
      text: initial?.whatsappRecipients ?? '',
    );

    DateTime? selectedDate = initial?.date;
    TimeOfDay? selectedTime = initial?.time;

    final saved = await showDialog<_Appointment>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) {
                setModalState(() => selectedDate = picked);
              }
            }

            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime:
                    selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
              );
              if (picked != null) {
                setModalState(() => selectedTime = picked);
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                initial == null
                                    ? 'Add Calendar Appointments'
                                    : 'Edit Calendar Appointments',
                                style: AppTextStyles.style(
                                  color: const Color(0xFF3A4656),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFFE5EAF3)),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD5E4FF),
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.style(
                                  color: const Color(0xFF48617D),
                                  fontSize: 12.5,
                                  height: 1.5,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Notification Flow: ',
                                    style: TextStyle(
                                      color: Color(0xFF234B92),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'WhatsApp template message automatically at selected meeting time.\n'
                                        'Note: Same day meetings require at least 30 minutes gap between time slots.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _AppointmentFormField(
                            label: 'Title',
                            requiredMark: true,
                            child: TextFormField(
                              controller: titleController,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Please enter a title'
                                  : null,
                              decoration: _appointmentInputDecoration(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AppointmentFormField(
                            label: 'Description',
                            child: TextFormField(
                              controller: descriptionController,
                              minLines: 3,
                              maxLines: 4,
                              decoration: _appointmentInputDecoration(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _AppointmentFormField(
                                  label: 'Date',
                                  requiredMark: true,
                                  child: TextFormField(
                                    readOnly: true,
                                    onTap: pickDate,
                                    controller: TextEditingController(
                                      text: selectedDate == null
                                          ? ''
                                          : _formatDate(selectedDate!),
                                    ),
                                    validator: (_) => selectedDate == null
                                        ? 'Select a date'
                                        : null,
                                    decoration: _appointmentInputDecoration(
                                      hintText: 'dd-mm-yyyy',
                                      suffixIcon: const Icon(
                                        Icons.calendar_today_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _AppointmentFormField(
                                  label: 'Time',
                                  requiredMark: true,
                                  helperText:
                                      'Choose a slot with minimum 30 minutes difference from existing meetings.',
                                  child: TextFormField(
                                    readOnly: true,
                                    onTap: pickTime,
                                    controller: TextEditingController(
                                      text: selectedTime == null
                                          ? ''
                                          : _formatTime(selectedTime!),
                                    ),
                                    validator: (_) => selectedTime == null
                                        ? 'Select time'
                                        : null,
                                    decoration: _appointmentInputDecoration(
                                      hintText: '--:--',
                                      suffixIcon: const Icon(
                                        Icons.access_time_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _AppointmentFormField(
                            label: 'Email Recipients (Optional)',
                            helperText:
                                'Comma-separated emails. You can keep this empty if WhatsApp numbers are added.',
                            child: TextFormField(
                              controller: emailController,
                              decoration: _appointmentInputDecoration(
                                hintText:
                                    'email1@example.com, email2@example.com',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AppointmentFormField(
                            label: 'WhatsApp Recipients (Phone Numbers)',
                            requiredMark: true,
                            helperText:
                                'Use international format. Multiple numbers comma separated.',
                            child: TextFormField(
                              controller: whatsappController,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Please enter at least one WhatsApp number'
                                  : null,
                              decoration: _appointmentInputDecoration(
                                hintText: '919876543210, 919876543211',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 22, color: Color(0xFFE5EAF3)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF6F7782),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Close',
                                  style: AppTextStyles.style(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  Navigator.of(context).pop(
                                    _Appointment(
                                      id: initial?.id,
                                      title: titleController.text.trim(),
                                      description:
                                          descriptionController.text
                                              .trim()
                                              .isEmpty
                                          ? 'New calendar appointment'
                                          : descriptionController.text.trim(),
                                      date: selectedDate!,
                                      time: selectedTime!,
                                      emailRecipients: emailController.text
                                          .trim(),
                                      whatsappRecipients: whatsappController
                                          .text
                                          .trim(),
                                      isFromApi: initial?.isFromApi ?? false,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1683F2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  initial == null
                                      ? 'Save Appointment'
                                      : 'Update Appointment',
                                  style: AppTextStyles.style(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
          },
        );
      },
    );

    return saved;
  }

  Future<void> _showAppointmentsForDate(DateTime date) async {
    final dayAppointments =
        _appointments
            .where((appointment) => _isSameDate(appointment.date, date))
            .toList()
          ..sort((a, b) => _toMinutes(a.time).compareTo(_toMinutes(b.time)));

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7E2F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _formatCalendarSheetDate(date),
                  style: AppTextStyles.style(
                    color: const Color(0xFF22314A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayAppointments.isEmpty
                      ? 'No appointments scheduled for this date.'
                      : '${dayAppointments.length} appointment${dayAppointments.length == 1 ? '' : 's'} scheduled.',
                  style: AppTextStyles.style(
                    color: const Color(0xFF7B8CA5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                if (dayAppointments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFE),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE3EBF5)),
                    ),
                    child: Text(
                      'Tap "Add Appointments" to schedule a meeting for this day.',
                      style: AppTextStyles.style(
                        color: const Color(0xFF5F738F),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  ...dayAppointments.map(
                    (appointment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: appointment.id == null
                            ? null
                            : () => _showAppointmentDetail(appointment),
                        child: _AppointmentSheetCard(appointment: appointment),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_Appointment> _seedAppointments() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    DateTime dateFor(int preferredDay) {
      return DateTime(year, month, _clampDay(year, month, preferredDay));
    }

    return [
      _Appointment(
        title: 'Testing Review',
        description: 'Product QA sync with internal team',
        date: dateFor(now.day > 3 ? now.day - 2 : 5),
        time: const TimeOfDay(hour: 15, minute: 26),
        emailRecipients: 'qa@mycrm.com',
        whatsappRecipients: '+919876543210',
      ),
      _Appointment(
        title: 'Client Demo',
        description: 'Live walkthrough for billing dashboard',
        date: dateFor(now.day),
        time: const TimeOfDay(hour: 11, minute: 0),
        emailRecipients: 'sales@mycrm.com',
        whatsappRecipients: '+919876543211',
      ),
      _Appointment(
        title: 'Contract Signing',
        description: 'Stripe integration services closure',
        date: dateFor(now.day + 9),
        time: const TimeOfDay(hour: 15, minute: 9),
        emailRecipients: 'contracts@mycrm.com',
        whatsappRecipients: '+919876543212',
      ),
      _Appointment(
        title: 'Renewal Check-in',
        description: 'Follow-up with enterprise support account',
        date: dateFor(now.day + 11),
        time: const TimeOfDay(hour: 10, minute: 15),
        emailRecipients: 'renewals@mycrm.com',
        whatsappRecipients: '+919876543213',
      ),
    ];
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'MyCRM User';
    final role = user?.role?.trim().isNotEmpty == true
        ? user!.role!.trim()
        : 'Team Member';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTextStyles.style(
                  color: const Color(0xFF1B2237),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: AppTextStyles.style(
                  color: const Color(0xFF7F90A9),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _HeaderActionButton(
              icon: Icons.checklist_rounded,
              size: 24,
              onTap: () => Get.to(() => const to_do.ToDoListScreen()),
            ),
            const SizedBox(width: 10),
            _HeaderActionButton(
              icon: Icons.notifications_none_rounded,
              size: 25,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F3F9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, color: const Color(0xFF61728F), size: size),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7ECF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RenewalSection extends StatelessWidget {
  const _RenewalSection({
    this.items = const <_UpcomingRenewalItem>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<_UpcomingRenewalItem> items;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveSectionHeader(
          title: 'Upcoming Renewals',
          forceInline: true,
          trailing: _SectionActionLabel(
            label: 'View All',
            onTap: () => Get.toNamed(AppRoutes.dashboardRenewals),
          ),
        ),
        if (isLoading) ...[
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ] else if (visibleItems.isNotEmpty) ...[
          const SizedBox(height: 18),
          ...visibleItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == visibleItems.length - 1 ? 0 : 14,
              ),
              child: _RenewalTile(
                initials: item.initials,
                company: item.title,
                amount: item.subtitle,
                date: item.dateLabel,
                tagLabel: item.tagLabel,
                tagColor: item.tagColor,
                logoColor: item.logoColor,
              ),
            );
          }),
        ] else ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4EAF3)),
            ),
            child: Text(
              errorMessage == null
                  ? 'No upcoming renewals from today.'
                  : 'Unable to load upcoming renewals.',
              style: AppTextStyles.style(
                color: const Color(0xFF677A94),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (DateTime.now().microsecond == -1) ...[
          const SizedBox(height: 18),
          const _RenewalTile(
            initials: 'AE',
            company: 'Acme Corporation',
            amount: '₹12,500',
            date: 'Oct 15, 2023',
            tagLabel: '7 DAYS LEFT',
            tagColor: Color(0xFFF5A623),
            logoColor: Color(0xFFB9B899),
          ),
          const SizedBox(height: 14),
          const _RenewalTile(
            initials: 'GT',
            company: 'Global Tech Solut',
            amount: '₹12,500',
            date: 'Oct 15, 2023',
            tagLabel: 'EARLY BIRD',
            tagColor: Color(0xFF20BF7A),
            logoColor: Color(0xFF102B3B),
          ),
          const SizedBox(height: 14),
          const _RenewalTile(
            initials: 'NX',
            company: 'Acme Corporation',
            amount: '₹12,500',
            date: 'Oct 15, 2023',
            tagLabel: '7 DAYS LEFT',
            tagColor: Color(0xFFF5A623),
            logoColor: Color(0xFF63AFA8),
          ),
        ],
      ],
    );
  }
}

enum _RenewalSource { client, vendor }

class _UpcomingRenewalItem {
  const _UpcomingRenewalItem({
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.renewalDateValue,
    required this.tagLabel,
    required this.tagColor,
    required this.logoColor,
  });

  final String initials;
  final String title;
  final String subtitle;
  final String dateLabel;
  final DateTime? renewalDateValue;
  final String tagLabel;
  final Color tagColor;
  final Color logoColor;

  factory _UpcomingRenewalItem.fromRenewal(
    RenewalModel renewal, {
    required _RenewalSource source,
  }) {
    final title = source == _RenewalSource.client
        ? (renewal.client.trim().isEmpty ? renewal.vendor : renewal.client)
        : (renewal.vendor.trim().isEmpty ? renewal.client : renewal.vendor);
    final normalizedTitle = title.trim().isEmpty ? 'Renewal' : title.trim();
    final initials = _buildInitials(normalizedTitle);
    final renewalDate = renewal.endDateValue ?? renewal.startDateValue;
    final tag = _buildTagLabel(renewalDate);
    final tagColor = _buildTagColor(tag);

    return _UpcomingRenewalItem(
      initials: initials,
      title: normalizedTitle,
      subtitle: source == _RenewalSource.client
          ? 'Client Renewal'
          : 'Vendor Renewal',
      dateLabel: renewal.endDate.trim().isEmpty
          ? (renewal.startDate.trim().isEmpty ? 'N/A' : renewal.startDate)
          : renewal.endDate,
      renewalDateValue: renewalDate,
      tagLabel: tag,
      tagColor: tagColor,
      logoColor: _pickLogoColor(normalizedTitle),
    );
  }

  static String _buildInitials(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'RN';
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String _buildTagLabel(DateTime? date) {
    if (date == null) return 'UPCOMING';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(date.year, date.month, date.day);
    final days = current.difference(today).inDays;
    if (days <= 0) return 'TODAY';
    if (days == 1) return '1 DAY LEFT';
    if (days <= 7) return '$days DAYS LEFT';
    return 'UPCOMING';
  }

  static Color _buildTagColor(String tag) {
    if (tag == 'TODAY') return const Color(0xFFEF4444);
    if (tag.contains('DAY')) return const Color(0xFFF5A623);
    return const Color(0xFF20BF7A);
  }

  static Color _pickLogoColor(String seed) {
    const palette = <Color>[
      Color(0xFF1E3A8A),
      Color(0xFF0F766E),
      Color(0xFF6D28D9),
      Color(0xFF0F172A),
      Color(0xFF9A3412),
      Color(0xFF0B3B66),
    ];
    final code = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[code % palette.length];
  }
}

class _SectionActionLabel extends StatelessWidget {
  const _SectionActionLabel({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.style(
        color: const Color(0xFF1769F3),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );

    if (onTap == null) {
      return text;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: text,
        ),
      ),
    );
  }
}

class _RenewalTile extends StatelessWidget {
  const _RenewalTile({
    required this.initials,
    required this.company,
    required this.amount,
    required this.date,
    required this.tagLabel,
    required this.tagColor,
    required this.logoColor,
  });

  final String initials;
  final String company;
  final String amount;
  final String date;
  final String tagLabel;
  final Color tagColor;
  final Color logoColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;

        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE9EEF6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isCompact ? 48 : 52,
                height: isCompact ? 48 : 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: isCompact ? 32 : 36,
                  height: isCompact ? 32 : 36,
                  decoration: BoxDecoration(
                    color: logoColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTextStyles.style(
                      color: Colors.white,
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCompact) ...[
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.style(
                          color: const Color(0xFF1E263B),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amount,
                        style: AppTextStyles.style(
                          color: const Color(0xFF1E263B),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.style(
                                color: const Color(0xFF1E263B),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              amount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: AppTextStyles.style(
                                color: const Color(0xFF1E263B),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Color(0xFF91A2BD),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              date,
                              style: AppTextStyles.style(
                                color: const Color(0xFF7587A3),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 7, color: tagColor),
                              const SizedBox(width: 4),
                              Text(
                                tagLabel,
                                style: AppTextStyles.style(
                                  color: tagColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProjectSummarySection extends StatelessWidget {
  const _ProjectSummarySection({
    required this.projectCount,
    required this.taskCount,
    required this.projectMonthlySeries,
    required this.taskMonthlySeries,
    required this.monthLabels,
  });

  final int projectCount;
  final int taskCount;
  final List<int> projectMonthlySeries;
  final List<int> taskMonthlySeries;
  final List<String> monthLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ResponsiveSectionHeader(
          title: 'Projects Summary',
          trailing: SizedBox.shrink(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ProjectMetricCard(
                title: 'Projects',
                value: '$projectCount',
                accentColor: Color(0xFF2D9CDB),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _ProjectMetricCard(
                title: 'Tasks',
                value: '$taskCount',
                accentColor: Color(0xFFFFB020),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EBF4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LineChartMock(
                projectCount: projectCount,
                taskCount: taskCount,
                projectMonthlySeries: projectMonthlySeries,
                taskMonthlySeries: taskMonthlySeries,
                monthLabels: monthLabels,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineChartMock extends StatelessWidget {
  const _LineChartMock({
    required this.projectCount,
    required this.taskCount,
    required this.projectMonthlySeries,
    required this.taskMonthlySeries,
    required this.monthLabels,
  });

  final int projectCount;
  final int taskCount;
  final List<int> projectMonthlySeries;
  final List<int> taskMonthlySeries;
  final List<String> monthLabels;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: CustomPaint(
        painter: _ProjectSummaryBarsPainter(
          projectCount: projectCount,
          taskCount: taskCount,
          projectMonthlySeries: projectMonthlySeries,
          taskMonthlySeries: taskMonthlySeries,
          monthLabels: monthLabels,
        ),
      ),
    );
  }
}

class _ProjectSummaryBarsPainter extends CustomPainter {
  const _ProjectSummaryBarsPainter({
    required this.projectCount,
    required this.taskCount,
    required this.projectMonthlySeries,
    required this.taskMonthlySeries,
    required this.monthLabels,
  });

  final int projectCount;
  final int taskCount;
  final List<int> projectMonthlySeries;
  final List<int> taskMonthlySeries;
  final List<String> monthLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = 28.0;
    final chartRight = size.width - 10;
    final chartTop = 10.0;
    final chartBottom = size.height - 28;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final maxValue = [
      ...projectMonthlySeries,
      ...taskMonthlySeries,
      projectCount,
      taskCount,
      1,
    ].reduce((a, b) => a > b ? a : b);
    final axisMax = ((maxValue + 1) / 2).ceil() * 2;
    const yTicks = 6;
    final yStep = axisMax / yTicks;

    final gridPaint = Paint()
      ..color = const Color(0xFFE3E8F0)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFCDD6E3)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labelStyle = AppTextStyles.style(
      color: const Color(0xFF74839D),
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
    );

    for (var tick = 0; tick <= yTicks; tick++) {
      final y = chartBottom - (chartHeight * (tick / yTicks));
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      final value = (tick * yStep).round().toString();
      textPainter.text = TextSpan(text: value, style: labelStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - (textPainter.height / 2)));
    }

    final monthCount = monthLabels.length.clamp(1, 6).toInt();
    final bucketWidth = chartWidth / monthCount;
    final projectsPaint = Paint()..color = const Color(0xFF2D9CDB);
    final tasksPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFFFFC83A), Color(0xFFF97D4B)],
      ).createShader(Rect.fromLTWH(0, chartTop, 1, chartHeight));

    for (var i = 0; i < monthCount; i++) {
      final x = chartLeft + (bucketWidth * i);
      canvas.drawLine(Offset(x, chartTop), Offset(x, chartBottom), gridPaint);

      final projectsValue = i < projectMonthlySeries.length
          ? projectMonthlySeries[i]
          : 0;
      final tasksValue = i < taskMonthlySeries.length
          ? taskMonthlySeries[i]
          : 0;
      final projectsHeight = (projectsValue / axisMax) * chartHeight;
      final tasksHeight = (tasksValue / axisMax) * chartHeight;
      final barWidth = bucketWidth * 0.18;
      final centerX = x + (bucketWidth / 2);

      if (projectsValue > 0) {
        final projectsRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - (barWidth * 1.2),
            chartBottom - projectsHeight,
            barWidth,
            projectsHeight,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(projectsRect, projectsPaint);
      }

      if (tasksValue > 0) {
        final tasksRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX + (barWidth * 0.2),
            chartBottom - tasksHeight,
            barWidth,
            tasksHeight,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(tasksRect, tasksPaint);
      }

      textPainter.text = TextSpan(text: monthLabels[i], style: labelStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - (textPainter.width / 2), chartBottom + 8),
      );
    }

    canvas.drawLine(
      Offset(chartLeft, chartBottom),
      Offset(chartRight, chartBottom),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProjectSummaryBarsPainter oldDelegate) {
    return oldDelegate.projectCount != projectCount ||
        oldDelegate.taskCount != taskCount ||
        oldDelegate.projectMonthlySeries != projectMonthlySeries ||
        oldDelegate.taskMonthlySeries != taskMonthlySeries ||
        oldDelegate.monthLabels != monthLabels;
  }
}

class _TaskSummarySection extends StatelessWidget {
  const _TaskSummarySection({required this.taskStatusCounts});

  final Map<String, int> taskStatusCounts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionTitle(title: 'Task Summary'),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.tasks),
              child: const _SectionActionLabel(label: 'View All'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _TaskSummaryChart(taskStatusCounts: taskStatusCounts),
      ],
    );
  }
}

class _TaskSummaryChart extends StatelessWidget {
  const _TaskSummaryChart({required this.taskStatusCounts});

  final Map<String, int> taskStatusCounts;

  @override
  Widget build(BuildContext context) {
    final taskItems = [
      (
        'Not Started',
        taskStatusCounts['notStarted'] ?? 0,
        const Color(0xFF6C778D),
      ),
      (
        'In Progress',
        taskStatusCounts['inProgress'] ?? 0,
        const Color(0xFF1769F3),
      ),
      ('On Hold', taskStatusCounts['onHold'] ?? 0, const Color(0xFFF5B71F)),
      (
        'Completed',
        taskStatusCounts['completed'] ?? 0,
        const Color(0xFF20D39B),
      ),
      (
        'Cancelled',
        taskStatusCounts['cancelled'] ?? 0,
        const Color(0xFFFF4D6D),
      ),
    ];
    final total = taskItems.fold<int>(0, (sum, item) => sum + item.$2);
    final donutSegments = taskItems
        .where((item) => item.$2 > 0)
        .map(
          (item) =>
              _TaskDonutSegment(value: item.$2.toDouble(), color: item.$3),
        )
        .toList();

    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _TaskDonutPainter(
                segments: donutSegments,
                backgroundColor: const Color(0xFFEAF0F8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: AppTextStyles.style(
                        color: const Color(0xFF1B2237),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Total Tasks',
                      style: AppTextStyles.style(
                        color: const Color(0xFF8A99AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final isCompact = maxWidth < 360;
            final crossAxisCount = maxWidth < 280
                ? 1
                : maxWidth < 620
                ? 2
                : 3;
            final childAspectRatio = isCompact ? 3.3 : 3.8;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: taskItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final item = taskItems[index];
                return _TaskStatusRow(
                  label: item.$1,
                  value: item.$2,
                  color: item.$3,
                  compact: isCompact,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _SupportTicketsSection extends StatelessWidget {
  const _SupportTicketsSection({
    required this.issues,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<ClientIssueModel> issues;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionTitle(title: 'Support Tickets'),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(flex: 7, child: ColoredBox(color: Color(0xFF1769F3))),
                Expanded(flex: 11, child: ColoredBox(color: Color(0xFFF5B71F))),
                Expanded(flex: 6, child: ColoredBox(color: Color(0xFF39D0A0))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (issues.isEmpty)
          Text(
            errorMessage ?? 'No support tickets available.',
            style: AppTextStyles.style(
              color: const Color(0xFF73839B),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Column(
            children: issues
                .map((issue) => _SupportTicketPreviewCard(issue: issue))
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _SupportTicketPreviewCard extends StatelessWidget {
  const _SupportTicketPreviewCard({required this.issue});

  final ClientIssueModel issue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  issue.displayClient,
                  style: AppTextStyles.style(
                    color: const Color(0xFF6C7D96),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _priorityPillBg(issue.priority),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  issue.displayPriority,
                  style: AppTextStyles.style(
                    color: _priorityPillFg(issue.priority),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            issue.displayTitle,
            style: AppTextStyles.style(
              color: const Color(0xFF1B2237),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                issue.displayProject,
                style: AppTextStyles.style(
                  color: const Color(0xFF73839B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusPillBg(issue.status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  issue.displayStatus,
                  style: AppTextStyles.style(
                    color: _statusPillFg(issue.status),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF73839B),
              ),
              const SizedBox(width: 6),
              Text(
                issue.displayDate,
                style: AppTextStyles.style(
                  color: const Color(0xFF73839B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _priorityPillBg(String priority) {
  final normalized = priority.trim().toLowerCase();
  if (normalized == 'high' || normalized == 'critical') {
    return const Color(0xFFFFEEF1);
  }
  if (normalized == 'medium') {
    return const Color(0xFFFFF5E5);
  }
  return const Color(0xFFE3F8FE);
}

Color _priorityPillFg(String priority) {
  final normalized = priority.trim().toLowerCase();
  if (normalized == 'high' || normalized == 'critical') {
    return const Color(0xFFE11D48);
  }
  if (normalized == 'medium') {
    return const Color(0xFFD97706);
  }
  return const Color(0xFF1DB8E9);
}

Color _statusPillBg(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.contains('closed') ||
      normalized.contains('done') ||
      normalized.contains('resolved') ||
      normalized.contains('complete')) {
    return const Color(0xFFE8F8EE);
  }
  if (normalized.contains('progress') || normalized.contains('review')) {
    return const Color(0xFFE3F8FE);
  }
  return const Color(0xFFFFEEF1);
}

Color _statusPillFg(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.contains('closed') ||
      normalized.contains('done') ||
      normalized.contains('resolved') ||
      normalized.contains('complete')) {
    return const Color(0xFF16A34A);
  }
  if (normalized.contains('progress') || normalized.contains('review')) {
    return const Color(0xFF1D4ED8);
  }
  return const Color(0xFFFF4D6D);
}

class _CalendarAppointmentsSection extends StatelessWidget {
  const _CalendarAppointmentsSection({
    required this.appointments,
    required this.displayedMonth,
    required this.onAddAppointment,
    required this.onDateTap,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final List<_Appointment> appointments;
  final DateTime displayedMonth;
  final VoidCallback onAddAppointment;
  final ValueChanged<DateTime> onDateTap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(displayedMonth.year, displayedMonth.month);
    final today = DateTime.now();
    final firstGridDate = monthStart.subtract(
      Duration(days: monthStart.weekday % 7),
    );
    final calendarDays = List.generate(
      42,
      (index) => DateTime(
        firstGridDate.year,
        firstGridDate.month,
        firstGridDate.day + index,
      ),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE3EAF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7FAFF), Color(0xFFEEF4FF)],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 380;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calendar Appointments',
                              style: AppTextStyles.style(
                                color: const Color(0xFF2D3B54),
                                fontSize: isCompact ? 16 : 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create meetings and keep WhatsApp reminders aligned with scheduled time.',
                              style: AppTextStyles.style(
                                color: const Color(0xFF7A8CA5),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        PermissionGate(
                          permission: AppPermission.manageCalendar,
                          child: ElevatedButton.icon(
                            onPressed: onAddAppointment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B84FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Add Appointments',
                              style: AppTextStyles.style(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _CalendarIconButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: onPreviousMonth,
                        ),
                        const SizedBox(width: 8),
                        _CalendarIconButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: onNextMonth,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formatMonthYear(monthStart),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.style(
                              color: const Color(0xFF2D3B54),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const _CalendarPillButton(
                          label: 'Month',
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    for (final label in _weekdayLabels)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.style(
                              color: const Color(0xFF2480F0),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: calendarDays.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 0,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    final date = calendarDays[index];
                    final dayAppointments =
                        appointments
                            .where(
                              (appointment) =>
                                  _isSameDate(appointment.date, date),
                            )
                            .toList()
                          ..sort(
                            (a, b) => _toMinutes(
                              a.time,
                            ).compareTo(_toMinutes(b.time)),
                          );

                    return _CalendarDayCell(
                      date: date,
                      displayedMonth: monthStart,
                      today: today,
                      appointments: dayAppointments,
                      onTap: () => onDateTap(date),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.displayedMonth,
    required this.today,
    required this.appointments,
    required this.onTap,
  });

  final DateTime date;
  final DateTime displayedMonth;
  final DateTime today;
  final List<_Appointment> appointments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = date.month == displayedMonth.month;
    final isToday = _isSameDate(date, today);
    final hasAppointments = appointments.isNotEmpty && isCurrentMonth;
    final accentColor = hasAppointments
        ? _appointmentAccentColor(appointments.first)
        : const Color(0xFF2480F0);
    final highlightColor = isToday
        ? const Color(0xFFFFF8D9)
        : hasAppointments
        ? accentColor.withOpacity(0.08)
        : Colors.white;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(0.35),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        decoration: BoxDecoration(
          color: highlightColor,
          border: Border.all(
            color: hasAppointments
                ? accentColor.withOpacity(0.45)
                : const Color(0xFFE8EDF5),
            width: hasAppointments ? 1.25 : 1,
          ),
          boxShadow: hasAppointments
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFFFFF0A6)
                      : hasAppointments
                      ? accentColor.withOpacity(0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${date.day}',
                  style: AppTextStyles.style(
                    color: isCurrentMonth
                        ? hasAppointments
                              ? accentColor
                              : const Color(0xFF2480F0)
                        : const Color(0xFFBDD0E8),
                    fontSize: 11,
                    fontWeight: isToday || hasAppointments
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (hasAppointments) ...[
              for (final appointment in appointments.take(2)) ...[
                _CalendarEventBadge(appointment: appointment),
                const SizedBox(height: 4),
              ],
              if (appointments.length > 2)
                Padding(
                  padding: const EdgeInsets.only(left: 2, top: 2),
                  child: Text(
                    '+${appointments.length - 2} more',
                    style: AppTextStyles.style(
                      color: const Color(0xFF7084A2),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ] else if (isToday) ...[
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 6),
                child: Text(
                  'Focus time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.style(
                    color: const Color(0xFFB38B00),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarEventBadge extends StatelessWidget {
  const _CalendarEventBadge({required this.appointment});

  final _Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final color = _appointmentAccentColor(appointment);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${_formatTimeNumber(appointment.time)} ${appointment.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: color,
                fontSize: 9.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentSheetCard extends StatelessWidget {
  const _AppointmentSheetCard({required this.appointment});

  final _Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final color = _appointmentAccentColor(appointment);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  style: AppTextStyles.style(
                    color: const Color(0xFF22314A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.description,
                  style: AppTextStyles.style(
                    color: const Color(0xFF70839F),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _AppointmentMetaChip(
                      icon: Icons.access_time_rounded,
                      label: _formatTime(appointment.time),
                      color: color,
                    ),
                    _AppointmentMetaChip(
                      icon: Icons.mail_outline_rounded,
                      label: appointment.emailRecipients.isEmpty
                          ? 'No email'
                          : appointment.emailRecipients,
                      color: const Color(0xFF5E7290),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5E7290)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.style(
                  color: const Color(0xFF7A8798),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.style(
                  color: const Color(0xFF22314A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppointmentMetaChip extends StatelessWidget {
  const _AppointmentMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarIconButton extends StatelessWidget {
  const _CalendarIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF2D3B54),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

class _CalendarPillButton extends StatelessWidget {
  const _CalendarPillButton({required this.label, this.isPrimary = false});

  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF2D3B54) : const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: isPrimary ? Colors.white : const Color(0xFF687B98),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AppointmentFormField extends StatelessWidget {
  const _AppointmentFormField({
    required this.label,
    required this.child,
    this.requiredMark = false,
    this.helperText,
  });

  final String label;
  final Widget child;
  final bool requiredMark;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.style(
              color: const Color(0xFF59677A),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(text: label),
              if (requiredMark)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFD93025)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: AppTextStyles.style(
              color: const Color(0xFF7A8798),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _Appointment {
  const _Appointment({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.emailRecipients,
    required this.whatsappRecipients,
    this.isFromApi = false,
  });

  final String? id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay time;
  final String emailRecipients;
  final String whatsappRecipients;
  final bool isFromApi;
}

InputDecoration _appointmentInputDecoration({
  String? hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyles.style(
      color: const Color(0xFFB2BDCC),
      fontSize: 14,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1683F2), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD93025)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD93025), width: 1.5),
    ),
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

String _formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}

String _formatTimeNumber(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

int _clampDay(int year, int month, int day) {
  if (day < 1) {
    return 1;
  }

  final lastDay = DateTime(year, month + 1, 0).day;
  return day > lastDay ? lastDay : day;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

String _formatMonthYear(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[date.month - 1]} ${date.year}';
}

String _formatCalendarSheetDate(DateTime date) {
  const weekdays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
}

Color _appointmentAccentColor(_Appointment appointment) {
  final palette = [
    const Color(0xFF22B573),
    const Color(0xFF2A7FFF),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
    const Color(0xFFEF4444),
  ];
  final key = '${appointment.title}${appointment.description}';
  final index =
      key.codeUnits.fold<int>(0, (sum, code) => sum + code) % palette.length;
  return palette[index];
}

class _TaskStatusRow extends StatelessWidget {
  const _TaskStatusRow({
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: const Color(0xFFE7ECF4)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 7 : 8,
            height: compact ? 7 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: const Color(0xFF1C2438),
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          Container(
            constraints: BoxConstraints(minWidth: compact ? 18 : 22),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 6,
              vertical: compact ? 1.5 : 2,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: AppTextStyles.style(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectMetricCard extends StatelessWidget {
  const _ProjectMetricCard({
    required this.title,
    required this.value,
    required this.accentColor,
  });

  final String title;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBF4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.style(
                  color: const Color(0xFF70819A),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.style(
                  color: const Color(0xFF1C2438),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _monthShortLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[date.month - 1];
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.style(
        color: const Color(0xFF1C2438),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ResponsiveSectionHeader extends StatelessWidget {
  const _ResponsiveSectionHeader({
    required this.title,
    required this.trailing,
    this.forceInline = false,
  });

  final String title;
  final Widget trailing;
  final bool forceInline;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320 && !forceInline;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: title),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: trailing),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _SectionTitle(title: title)),
            const SizedBox(width: 12),
            trailing,
          ],
        );
      },
    );
  }
}

class _TaskDonutSegment {
  const _TaskDonutSegment({required this.value, required this.color});

  final double value;
  final Color color;
}

class _TaskDonutPainter extends CustomPainter {
  _TaskDonutPainter({required this.segments, required this.backgroundColor});

  final List<_TaskDonutSegment> segments;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 22.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
    if (total <= 0) {
      return;
    }

    var startAngle = -1.5708;
    const gapAngle = 0.03;

    for (final segment in segments) {
      if (segment.value <= 0) {
        continue;
      }

      final sweepAngle = (6.2831 * (segment.value / total)) - gapAngle;
      final segmentPaint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        segmentPaint,
      );

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _TaskDonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
