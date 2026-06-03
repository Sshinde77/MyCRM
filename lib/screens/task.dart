import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/core/utils/app_error_handler.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';
import 'package:mycrm/screens/create_task_screen.dart';
import 'package:mycrm/screens/task_detail_screen.dart';
import 'package:mycrm/services/api_service.dart';

import '../widgets/app_bottom_navigation.dart';
import '../widgets/common_screen_app_bar.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.staffId, this.staffName});

  final String? staffId;
  final String? staffName;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  static const int _fallbackPageSize = 10;
  final List<_TaskRecord> _tasks = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isLoading = false;
  String? _loadError;
  String? _staffFilterId;
  String _staffFilterName = '';
  String _appliedSearchTerm = '';
  String _selectedStatus = 'all';
  int _currentPage = 1;
  int _lastPage = 1;
  int _perPage = _fallbackPageSize;
  int _totalRecords = 0;
  int _totalTasksCount = 0;
  int _completedTasksCount = 0;
  bool _hasStatusCounts = false;

  @override
  void initState() {
    super.initState();
    final widgetStaffId = (widget.staffId ?? '').toString().trim();
    final widgetStaffName = (widget.staffName ?? '').toString().trim();
    if (widgetStaffId.isNotEmpty) {
      _staffFilterId = widgetStaffId;
    }
    if (widgetStaffName.isNotEmpty) {
      _staffFilterName = widgetStaffName;
    }

    if ((_staffFilterId ?? '').trim().isEmpty) {
      final arguments = Get.arguments;
      if (arguments is Map) {
        final map = arguments.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final staffId = (map['staffId'] ?? '').toString().trim();
        final staffName = (map['staffName'] ?? '').toString().trim();
        if (staffId.isNotEmpty) {
          _staffFilterId = staffId;
        }
        if (_staffFilterName.trim().isEmpty && staffName.isNotEmpty) {
          _staffFilterName = staffName;
        }
      }
    }
    _loadTasks();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  int get _resolvedTotalTasks =>
      _hasStatusCounts ? _totalTasksCount : _totalRecords;
  int get _resolvedCompletedTasks => _hasStatusCounts
      ? _completedTasksCount
      : _tasks.where((task) => task.completed).length;

  List<_TaskRecord> get _visibleTasks {
    // Status filtering is handled by backend query params.
    return _tasks;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 360;
    final visibleTasks = _visibleTasks;
    final isFilterApplied = _selectedStatus != 'all';
    final totalTasks = isFilterApplied ? visibleTasks.length : _totalRecords;
    final totalPages = _lastPage < 1 ? 1 : _lastPage;
    final safeCurrentPage = _currentPage > totalPages
        ? totalPages
        : _currentPage;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.tasks,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
          child: RefreshIndicator(
            onRefresh: () => _loadTasks(page: 1),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: compact ? 8 : 10),
                CommonTopBar(
                  title: 'Tasks',
                  showBackButton: false,
                  compact: compact,
                ),
                SizedBox(height: compact ? 14 : 16),
                _TasksSummaryRow(
                  isCompact: compact,
                  totalTasks: _resolvedTotalTasks,
                  completedTasks: _resolvedCompletedTasks,
                ),
                SizedBox(height: compact ? 14 : 16),
                _TasksToolbar(
                  controller: _searchController,
                  onSearchTap: _isLoading ? null : _applySearch,
                  onSearchChanged: _onSearchChanged,
                  onFilterTap: _isLoading ? null : _openFilterPopup,
                  onCreateTap: _isLoading ? null : _openCreateTaskScreen,
                ),
                if (_isLoading) ...[
                  SizedBox(height: compact ? 10 : 12),
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: Color(0xFF2563EB),
                    backgroundColor: Color(0xFFD8E7FB),
                  ),
                ],
                if (_loadError != null) ...[
                  SizedBox(height: compact ? 10 : 12),
                  _ErrorCard(message: _loadError!, onRetry: () => _loadTasks()),
                ],
                SizedBox(height: compact ? 14 : 16),
                if (visibleTasks.isEmpty)
                  SizedBox(
                    height: compact ? 260 : 320,
                    child: _EmptyState(
                      compact: compact,
                      hasQuery:
                          _appliedSearchTerm.trim().isNotEmpty ||
                          _selectedStatus != 'all',
                    ),
                  )
                else
                  ...visibleTasks.map(
                    (task) => _TaskCard(
                      task: task,
                      compact: compact,
                      onTap: () => _openTaskDetail(task),
                      onEdit: () => _openEditTaskScreen(task),
                      onDelete: () => _deleteTask(task),
                    ),
                  ),
                if (totalTasks > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Showing ${visibleTasks.length} of $totalTasks (Page $safeCurrentPage/$totalPages)',
                    style: AppTextStyles.style(
                      color: const Color(0xFF475569),
                      fontSize: compact ? 12 : 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TasksPaginationBar(
                    compact: compact,
                    currentPage: safeCurrentPage,
                    totalPages: totalPages,
                    onPageTap: (page) => _loadTasks(page: page),
                  ),
                ],
                SizedBox(height: compact ? 8 : 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadTasks({int page = 1}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final staffId = _staffFilterId?.trim() ?? '';
      final useStaffEndpoint = staffId.isNotEmpty;
      final selectedStatus = _apiStatusFromFilter(_selectedStatus);
      TaskListPageResult? pageResult;
      List<Map<String, dynamic>> records = const <Map<String, dynamic>>[];
      var usedFallbackListEndpoint = false;

      try {
        pageResult = useStaffEndpoint
            ? await ApiService.instance.getStaffTasksListPage(
                staffId: staffId,
                page: page,
                search: _appliedSearchTerm,
                status: selectedStatus,
              )
            : await ApiService.instance.getTasksListPage(
                page: page,
                search: _appliedSearchTerm,
                status: selectedStatus,
              );
        records = pageResult.items;
      } on DioException {
        // Some deployments do not support paginated task params consistently.
        // Fall back to full-list endpoint and paginate locally.
        usedFallbackListEndpoint = true;
        records = useStaffEndpoint
            ? await ApiService.instance.getStaffTasksList(
                staffId,
                status: selectedStatus,
              )
            : await ApiService.instance.getTasksList(status: selectedStatus);
      }

      final allTasks = <_TaskRecord>[];
      for (final record in records) {
        final parsed = _TaskRecord.fromApiRecord(record);
        if (useStaffEndpoint) {
          allTasks.addAll(parsed);
          continue;
        }

        for (final task in parsed) {
          if (_matchesStaffFilter(task, record)) {
            allTasks.add(task);
          }
        }
      }

      final statusCounts = pageResult?.statusCounts ?? const <String, int>{};
      final countedTotal = statusCounts['all'] ?? statusCounts['total'] ?? 0;
      final countedCompleted = statusCounts['completed'] ?? 0;

      final backendPaginated =
          !usedFallbackListEndpoint &&
          pageResult != null &&
          (pageResult.hasNextPage ||
              pageResult.lastPage > 1 ||
              (pageResult.perPage > 0 &&
                  pageResult.total > pageResult.perPage));

      List<_TaskRecord> visibleTasks = allTasks;
      var resolvedCurrentPage = (pageResult?.currentPage ?? page) < 1
          ? page
          : (pageResult?.currentPage ?? page);
      var resolvedLastPage = (pageResult?.lastPage ?? 1) < 1
          ? 1
          : (pageResult?.lastPage ?? 1);
      var resolvedPerPage = (pageResult?.perPage ?? _fallbackPageSize) < 1
          ? _fallbackPageSize
          : (pageResult?.perPage ?? _fallbackPageSize);
      var resolvedTotal = (pageResult?.total ?? allTasks.length) >= 0
          ? (pageResult?.total ?? allTasks.length)
          : allTasks.length;

      // Some task endpoints ignore page/per_page and return a full list.
      // In that case, provide client-side pagination so UI behavior remains
      // consistent with other list screens.
      if (!backendPaginated && allTasks.length > _fallbackPageSize) {
        resolvedTotal = allTasks.length;
        resolvedPerPage = _fallbackPageSize;
        resolvedLastPage = (resolvedTotal / _fallbackPageSize).ceil();
        final safePage = page < 1
            ? 1
            : (page > resolvedLastPage ? resolvedLastPage : page);
        resolvedCurrentPage = safePage;
        final start = (safePage - 1) * _fallbackPageSize;
        final end = (start + _fallbackPageSize) > allTasks.length
            ? allTasks.length
            : (start + _fallbackPageSize);
        visibleTasks = allTasks.sublist(start, end);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _tasks
          ..clear()
          ..addAll(visibleTasks);
        _currentPage = resolvedCurrentPage;
        _lastPage = resolvedLastPage;
        _perPage = resolvedPerPage;
        _totalRecords = resolvedTotal;
        _totalTasksCount = countedTotal > 0 ? countedTotal : resolvedTotal;
        _completedTasksCount = countedCompleted;
        _hasStatusCounts = statusCounts.isNotEmpty;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = _extractErrorMessage(
          error,
          fallback: 'Failed to load tasks.',
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = AppErrorHandler.messageFromError(
          error,
          fallback: 'Failed to load tasks.',
        );
      });
    }
  }

  bool _matchesStaffFilter(_TaskRecord task, Map<String, dynamic> rawRecord) {
    final staffId = _staffFilterId?.trim() ?? '';
    final staffName = _normalizeName(_staffFilterName);
    if (staffId.isEmpty && staffName.isEmpty) {
      return true;
    }

    if (staffId.isNotEmpty && task.assigneeIds.contains(staffId)) {
      return true;
    }

    if (staffName.isEmpty) {
      return false;
    }

    final assignees = rawRecord['assignees'];
    if (assignees is! List) {
      return false;
    }

    for (final entry in assignees) {
      if (entry is String &&
          _normalizeName(entry) == staffName &&
          staffName.isNotEmpty) {
        return true;
      }

      if (entry is! Map && entry is! Map<String, dynamic>) {
        continue;
      }

      final normalized = entry is Map<String, dynamic>
          ? entry
          : entry.map((key, value) => MapEntry(key.toString(), value));

      final combinedName = [
        (normalized['first_name'] ?? normalized['firstName'] ?? '').toString(),
        (normalized['last_name'] ?? normalized['lastName'] ?? '').toString(),
      ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(' ');

      final name =
          (combinedName.isNotEmpty
                  ? combinedName
                  : (normalized['name'] ??
                            normalized['full_name'] ??
                            normalized['employee_name'] ??
                            normalized['staff_name'] ??
                            '')
                        .toString())
              .trim();

      final normalizedName = _normalizeName(name);
      if (normalizedName.isNotEmpty && normalizedName == staffName) {
        return true;
      }
      if (normalizedName.length >= 3 &&
          staffName.length >= 3 &&
          (normalizedName.contains(staffName) ||
              staffName.contains(normalizedName))) {
        return true;
      }
    }

    return false;
  }

  String _normalizeName(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(' ').toLowerCase();
  }

  Future<void> _openCreateTaskScreen() async {
    final created = await Get.to<bool>(() => const CreateTaskScreen());
    if (created != true) {
      return;
    }

    await _loadTasks();
  }

  Future<void> _openEditTaskScreen(_TaskRecord task) async {
    var editTask = task;
    try {
      final detail = await ApiService.instance.getTaskDetail(task.id);
      editTask = _hydrateTaskForEdit(task, detail);
    } catch (_) {
      // Fall back to list payload if detail endpoint fails.
    }

    final updated = await Get.to<bool>(
      () => CreateTaskScreen(
        taskId: editTask.id,
        initialTitle: editTask.title,
        initialDescription: editTask.description,
        initialProjectId: editTask.projectId,
        initialPriority: editTask.priority,
        initialStatus: editTask.status,
        initialStartDate: editTask.startDate,
        initialDueDate: editTask.deadline,
        initialAssigneeIds: editTask.assigneeIds,
        initialFollowerIds: editTask.followerIds,
        initialTags: editTask.tags,
      ),
    );
    if (updated != true) {
      return;
    }

    await _loadTasks();
  }

  _TaskRecord _hydrateTaskForEdit(
    _TaskRecord base,
    Map<String, dynamic> detail,
  ) {
    final title =
        _readString(detail, const ['title', 'name', 'task_title']) ??
        base.title;
    final description =
        _readString(detail, const [
          'description',
          'details',
          'task_description',
        ]) ??
        base.description;
    final projectId = _readProjectId(detail) ?? base.projectId;
    final projectName = _readProjectName(detail);
    final status =
        _readString(detail, const ['status', 'task_status']) ?? base.status;
    final priority =
        _readString(detail, const ['priority', 'priority_level']) ??
        base.priority;
    final startDate = _tryParseDate(
      _readString(detail, const ['start_date', 'starts_on', 'created_at']),
    );
    final deadline = _tryParseDate(
      _readString(detail, const ['deadline', 'due_date', 'end_date']),
    );

    final assigneeIds = _readPersonIds(detail, const [
      'assignees',
      'assigned_to',
      'assigned',
    ]);
    final followerIds = _readPersonIds(detail, const ['followers', 'watchers']);
    final tags = _readTaskTags(detail);
    final assigneeImageUrls = _readAssigneeImageUrls(detail);

    return _TaskRecord(
      id: base.id,
      title: title,
      projectId: projectId,
      projectName: projectName,
      description: description,
      status: status,
      priority: priority,
      startDate: startDate ?? base.startDate,
      deadline: deadline ?? base.deadline,
      assigneeIds: assigneeIds.isEmpty ? base.assigneeIds : assigneeIds,
      followerIds: followerIds.isEmpty ? base.followerIds : followerIds,
      tags: tags.isEmpty ? base.tags : tags,
      assigneeImageUrls: assigneeImageUrls.isEmpty
          ? base.assigneeImageUrls
          : assigneeImageUrls,
    );
  }

  void _openTaskDetail(_TaskRecord task) {
    Get.to(
      () => TaskDetailScreen(
        taskId: task.id,
        initialTaskData: task.toDetailMap(),
      ),
    );
  }

  Future<void> _deleteTask(_TaskRecord task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiService.instance.deleteTaskRecord(task.id);

      if (!mounted) {
        return;
      }

      AppSnackbar.show('Task deleted', task.title);
      await _loadTasks();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      AppSnackbar.show(
        'Delete task failed',
        _extractErrorMessage(error, fallback: 'Failed to delete task.'),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      AppSnackbar.show(
        'Delete task failed',
        AppErrorHandler.messageFromError(
          error,
          fallback: 'Failed to delete task.',
        ),
      );
    }
  }

  void _applySearch() {
    final nextTerm = _searchController.text.trim();
    if (nextTerm == _appliedSearchTerm) {
      return;
    }
    setState(() {
      _appliedSearchTerm = nextTerm;
      _currentPage = 1;
    });
    _loadTasks(page: 1);
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _applySearch);
  }

  Future<void> _openFilterPopup() async {
    var tempStatus = _selectedStatus;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Tasks',
                      style: AppTextStyles.style(
                        color: const Color(0xFF1E2A3B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TaskStatusDropdown(
                      value: tempStatus,
                      onChanged: (value) {
                        setSheetState(() => tempStatus = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _selectedStatus = 'all');
                              _loadTasks(page: 1);
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _selectedStatus = tempStatus);
                              _loadTasks(page: 1);
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _apiStatusFromFilter(String filterValue) {
    switch (filterValue.trim().toLowerCase()) {
      case 'all':
        return null;
      case 'not started':
        return 'not_started';
      case 'in progress':
        return 'in_progress';
      case 'on hold':
        return 'on_hold';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return filterValue.trim().isEmpty ? null : filterValue.trim();
    }
  }
}

class _TasksPaginationBar extends StatelessWidget {
  const _TasksPaginationBar({
    required this.compact,
    required this.currentPage,
    required this.totalPages,
    required this.onPageTap,
  });

  final bool compact;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageTap;

  @override
  Widget build(BuildContext context) {
    final tokens = _buildPageTokens(currentPage, totalPages);
    final canGoPrev = currentPage > 1;
    final canGoNext = currentPage < totalPages;

    return Padding(
      padding: EdgeInsets.only(top: compact ? 6 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationArrowButton(
            compact: compact,
            icon: Icons.chevron_left_rounded,
            enabled: canGoPrev,
            onTap: () => onPageTap(currentPage - 1),
          ),
          SizedBox(width: compact ? 10 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tokens
                .map((token) {
                  if (token == null) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2 : 4,
                        vertical: compact ? 8 : 9,
                      ),
                      child: Text(
                        '...',
                        style: AppTextStyles.style(
                          color: const Color(0xFF64748B),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  final selected = token == currentPage;
                  return InkWell(
                    onTap: () => onPageTap(token),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: compact ? 34 : 36,
                      height: compact ? 34 : 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF122B52)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$token',
                        style: AppTextStyles.style(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF334155),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          SizedBox(width: compact ? 10 : 12),
          _PaginationArrowButton(
            compact: compact,
            icon: Icons.chevron_right_rounded,
            enabled: canGoNext,
            onTap: () => onPageTap(currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<int?> _buildPageTokens(int current, int total) {
    if (total <= 7) {
      return List<int?>.generate(total, (index) => index + 1);
    }
    final tokens = <int?>[1];
    var start = current - 1;
    var end = current + 1;
    if (current <= 3) {
      start = 2;
      end = 4;
    } else if (current >= total - 2) {
      start = total - 3;
      end = total - 1;
    } else {
      start = start < 2 ? 2 : start;
      end = end > total - 1 ? total - 1 : end;
    }
    if (start > 2) tokens.add(null);
    for (var page = start; page <= end; page += 1) {
      tokens.add(page);
    }
    if (end < total - 1) tokens.add(null);
    tokens.add(total);
    return tokens;
  }
}

class _PaginationArrowButton extends StatelessWidget {
  const _PaginationArrowButton({
    required this.compact,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final bool compact;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: compact ? 34 : 40,
        height: compact ? 34 : 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE6F2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: compact ? 20 : 22,
          color: enabled ? const Color(0xFF122B52) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _TasksSummaryRow extends StatelessWidget {
  const _TasksSummaryRow({
    required this.isCompact,
    required this.totalTasks,
    required this.completedTasks,
  });

  final bool isCompact;
  final int totalTasks;
  final int completedTasks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TaskMetricCard(
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFF4F5D74),
            value: '$totalTasks',
            label: 'Total Tasks',
            isCompact: isCompact,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _TaskMetricCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF1D6FEA),
            value: '$completedTasks',
            label: 'Completed',
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }
}

class _TasksToolbar extends StatelessWidget {
  const _TasksToolbar({
    required this.controller,
    required this.onSearchTap,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.onCreateTap,
  });

  final TextEditingController controller;
  final VoidCallback? onSearchTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD2DDEA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    onChanged: onSearchChanged,
                    onSubmitted: (_) => onSearchTap?.call(),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle: AppTextStyles.style(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                    style: AppTextStyles.style(
                      color: const Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _TaskToolbarIconButton(
          icon: Icons.filter_alt_outlined,
          onTap: onFilterTap,
        ),
        const SizedBox(width: 8),
        _CreateTaskButton(onTap: onCreateTap),
      ],
    );
  }
}

class _TaskMetricCard extends StatelessWidget {
  const _TaskMetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isCompact,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 18,
        isCompact ? 16 : 18,
        isCompact ? 14 : 18,
        isCompact ? 16 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: AppTextStyles.style(
                  color: const Color(0xFF1E2A3B),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.style(
              color: const Color(0xFF7C8BA1),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateTaskButton extends StatelessWidget {
  const _CreateTaskButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permission: AppPermission.createTasks,
      child: Material(
        color: const Color(0xFF1D6FEA),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _TaskToolbarIconButton extends StatelessWidget {
  const _TaskToolbarIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD2DDEA)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF475569), size: 20),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.compact,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final _TaskRecord task;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusPalette(task.status);
    final priorityColors = _priorityPalette(task.priority);
    final cardRadius = BorderRadius.circular(compact ? 18 : 20);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Container(
          margin: EdgeInsets.only(bottom: compact ? 10 : 12),
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 16,
            compact ? 14 : 16,
            compact ? 14 : 16,
            compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: cardRadius,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100F172A),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.style(
                        color: const Color(0xFF1E293B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _PillBadge(
                    label: task.status,
                    background: statusColors.$1,
                    foreground: statusColors.$2,
                    compact: compact,
                  ),
                ],
              ),
              SizedBox(height: compact ? 6 : 7),
              Row(
                children: [
                  Icon(
                    Icons.work_outline_rounded,
                    size: compact ? 14 : 16,
                    color: const Color(0xFF94A3B8),
                  ),
                  SizedBox(width: compact ? 5 : 6),
                  Expanded(
                    child: Text(
                      task.projectName,
                      style: AppTextStyles.style(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  _PillBadge(
                    label: task.priority,
                    background: priorityColors.$1,
                    foreground: priorityColors.$2,
                    compact: compact,
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 12),
              Row(
                children: [
                  Expanded(
                    child: _TaskMetaItem(
                      icon: Icons.access_time_rounded,
                      value: task.startDateText,
                      compact: compact,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: _TaskMetaItem(
                      icon: Icons.flag_outlined,
                      value: task.deadlineText,
                      compact: compact,
                    ),
                  ),
                ],
              ),
              if (task.assigneeImageUrls.isNotEmpty) ...[
                SizedBox(height: compact ? 10 : 11),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                SizedBox(height: compact ? 9 : 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AssigneeAvatarStack(
                      imageUrls: task.assigneeImageUrls,
                      compact: compact,
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    Text(
                      'Assigned',
                      style: AppTextStyles.style(
                        color: const Color(0xFF475569),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    Flexible(
                      child: Text(
                        task.assigneeSummary,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.style(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _TaskQuickIconAction(
                      icon: Icons.remove_red_eye_outlined,
                      background: const Color(0xFFE8F0FE),
                      foreground: const Color(0xFF1D4ED8),
                      compact: compact,
                      onTap: onTap,
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    PermissionGate(
                      permission: AppPermission.editTasks,
                      child: _TaskQuickIconAction(
                        icon: Icons.edit_outlined,
                        background: const Color(0xFFE8F0FE),
                        foreground: const Color(0xFF1D4ED8),
                        compact: compact,
                        onTap: onEdit,
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    PermissionGate(
                      permission: AppPermission.deleteTasks,
                      child: _TaskQuickIconAction(
                        icon: Icons.delete_outline_rounded,
                        background: const Color(0xFFFEE4E2),
                        foreground: const Color(0xFFB42318),
                        compact: compact,
                        onTap: onDelete,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(height: compact ? 10 : 11),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                SizedBox(height: compact ? 9 : 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _TaskQuickIconAction(
                      icon: Icons.remove_red_eye_outlined,
                      background: const Color(0xFFE8F0FE),
                      foreground: const Color(0xFF1D4ED8),
                      compact: compact,
                      onTap: onTap,
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    PermissionGate(
                      permission: AppPermission.editTasks,
                      child: _TaskQuickIconAction(
                        icon: Icons.edit_outlined,
                        background: const Color(0xFFE8F0FE),
                        foreground: const Color(0xFF1D4ED8),
                        compact: compact,
                        onTap: onEdit,
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    PermissionGate(
                      permission: AppPermission.deleteTasks,
                      child: _TaskQuickIconAction(
                        icon: Icons.delete_outline_rounded,
                        background: const Color(0xFFFEE4E2),
                        foreground: const Color(0xFFB42318),
                        compact: compact,
                        onTap: onDelete,
                      ),
                    ),
                  ],
                ),
              ],
              if (task.description.isNotEmpty) ...[
                SizedBox(height: compact ? 9 : 10),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.style(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFBE123C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.style(
                color: const Color(0xFF9F1239),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.compact, required this.hasQuery});

  final bool compact;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.task_alt_outlined,
              size: compact ? 42 : 50,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? 'No tasks matched your search.'
                  : 'No tasks available yet.',
              textAlign: TextAlign.center,
              style: AppTextStyles.style(
                color: const Color(0xFF334155),
                fontSize: compact ? 15 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRecord {
  const _TaskRecord({
    required this.id,
    required this.title,
    required this.projectId,
    required this.projectName,
    required this.description,
    required this.status,
    required this.priority,
    required this.startDate,
    required this.deadline,
    required this.assigneeIds,
    required this.followerIds,
    required this.tags,
    required this.assigneeImageUrls,
  });

  final String id;
  final String title;
  final String? projectId;
  final String projectName;
  final String description;
  final String status;
  final String priority;
  final DateTime? startDate;
  final DateTime? deadline;
  final List<String> assigneeIds;
  final List<String> followerIds;
  final List<String> tags;
  final List<String> assigneeImageUrls;

  bool get completed => _looksCompleted(status);
  String get startDateText => _formatDisplayDate(startDate);
  String get deadlineText => _formatDisplayDate(deadline);
  String get assigneeSummary {
    final count = assigneeImageUrls.length;
    if (count == 1) {
      return '1 assignee';
    }
    return '$count assignees';
  }

  Map<String, dynamic> toDetailMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'start_date': startDate?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'project': <String, dynamic>{'name': projectName},
      'assignees': assigneeImageUrls
          .map((url) => <String, dynamic>{'profile_image': url})
          .toList(),
    };
  }

  static List<_TaskRecord> fromApiRecord(Map<String, dynamic> source) {
    return [
      _TaskRecord(
        id: _readString(source, const ['id', 'task_id']) ?? 'TASK',
        title:
            _readString(source, const ['title', 'name', 'task_title']) ??
            'Untitled Task',
        projectId: _readProjectId(source),
        projectName: _readProjectName(source),
        description:
            _readString(source, const ['description', 'details']) ?? '',
        status:
            _readString(source, const ['status', 'task_status']) ?? 'Pending',
        priority:
            _readString(source, const ['priority', 'priority_level']) ??
            'Normal',
        startDate: _tryParseDate(
          _readString(source, const ['start_date', 'starts_on', 'created_at']),
        ),
        deadline: _tryParseDate(
          _readString(source, const ['deadline', 'due_date', 'end_date']),
        ),
        assigneeIds: _readPersonIds(source, const ['assignees', 'assigned_to']),
        followerIds: _readPersonIds(source, const ['followers', 'watchers']),
        tags: _readStringList(source['tags']),
        assigneeImageUrls: _readAssigneeImageUrls(source),
      ),
    ];
  }
}

String _extractErrorMessage(DioException error, {required String fallback}) {
  final responseData = error.response?.data;
  if (responseData is Map && responseData['message'] != null) {
    return responseData['message'].toString();
  }

  final message = error.message?.trim() ?? '';
  return message.isEmpty ? fallback : message;
}

String? _readString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) {
      continue;
    }

    final normalized = value.toString().trim();
    if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
      return normalized;
    }
  }

  return null;
}

Map<String, dynamic> _normalizeMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

DateTime? _tryParseDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.trim());
}

String _formatDisplayDate(DateTime? value) {
  if (value == null) {
    return '--';
  }

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day-$month-${value.year}';
}

String _readProjectName(Map<String, dynamic> source) {
  final project = source['project'];
  if (project is Map<String, dynamic>) {
    return _readString(project, const ['name', 'title']) ??
        'Unassigned Project';
  }
  if (project is Map) {
    final normalized = _normalizeMap(project);
    return _readString(normalized, const ['name', 'title']) ??
        'Unassigned Project';
  }

  return _readString(source, const ['project_name', 'project']) ??
      'Unassigned Project';
}

String? _readProjectId(Map<String, dynamic> source) {
  final project = source['project'];
  if (project is Map<String, dynamic>) {
    return _readString(project, const ['id', 'project_id']);
  }
  if (project is Map) {
    final normalized = _normalizeMap(project);
    return _readString(normalized, const ['id', 'project_id']);
  }

  return _readString(source, const ['project_id']);
}

List<String> _readPersonIds(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is! List) {
      continue;
    }

    final ids = <String>[];
    for (final entry in value) {
      final normalized = _normalizeMap(entry);
      final id = _readString(normalized, const ['id', 'user_id', 'staff_id']);
      if (id != null && id.isNotEmpty) {
        ids.add(id);
      }
    }
    if (ids.isNotEmpty) {
      return ids;
    }
  }

  return const [];
}

List<String> _readStringList(dynamic value) {
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return const [];
    }
    return text
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty && entry.toLowerCase() != 'null')
        .toList();
  }

  if (value is! List) {
    return const [];
  }

  return value
      .map((entry) {
        if (entry is String) {
          return entry.trim();
        }
        if (entry is Map) {
          final item = _normalizeMap(entry);
          return _readString(item, const ['name', 'title', 'label']) ?? '';
        }
        return entry.toString().trim();
      })
      .where((entry) => entry.isNotEmpty && entry.toLowerCase() != 'null')
      .toList();
}

List<String> _readTaskTags(Map<String, dynamic> source) {
  final candidates = [source['tags'], source['tag'], source['task_tags']];
  for (final value in candidates) {
    final parsed = _readStringList(value);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }
  return const [];
}

List<String> _readAssigneeImageUrls(Map<String, dynamic> source) {
  final assignees = source['assignees'];
  if (assignees is! List) {
    return const [];
  }

  final urls = <String>[];
  for (final assignee in assignees) {
    final normalized = _normalizeMap(assignee);
    final url = _readString(normalized, const [
      'profile_image',
      'avatar',
      'image',
      'photo',
    ]);
    if (url != null && url.isNotEmpty) {
      urls.add(url);
    }
  }
  return urls;
}

bool _looksCompleted(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized == 'completed' ||
      normalized == 'complete' ||
      normalized == 'done' ||
      normalized == 'closed';
}

String _taskStatusCategory(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.contains('cancel')) {
    return 'cancelled';
  }
  if (normalized.contains('hold')) {
    return 'on hold';
  }
  if (normalized.contains('complete') ||
      normalized.contains('done') ||
      normalized.contains('closed')) {
    return 'completed';
  }
  if (normalized.contains('progress') || normalized.contains('active')) {
    return 'in progress';
  }
  if (normalized.contains('not_started') ||
      normalized.contains('not started') ||
      normalized.contains('todo') ||
      normalized.contains('pending')) {
    return 'not started';
  }
  return 'not started';
}

String _formatTaskStatusLabel(String value) {
  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'all':
      return 'All';
    case 'completed':
      return 'Completed';
    case 'in progress':
      return 'In Progress';
    case 'not started':
      return 'Not Started';
    case 'on hold':
      return 'On Hold';
    case 'cancelled':
      return 'Cancelled';
    default:
      return value;
  }
}

class _TaskFilterTabs extends StatelessWidget {
  const _TaskFilterTabs({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    const options = <String>[
      'all',
      'not started',
      'in progress',
      'on hold',
      'completed',
      'cancelled',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options
            .map((option) {
              final selected = value == option;
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: InkWell(
                  onTap: onChanged == null ? null : () => onChanged!(option),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: selected
                        ? BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          )
                        : null,
                    child: Text(
                      _formatTaskStatusLabel(option),
                      style: AppTextStyles.style(
                        color: const Color(0xFF0B63F6),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _TaskMetaItem extends StatelessWidget {
  const _TaskMetaItem({
    required this.icon,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: compact ? 14 : 15, color: const Color(0xFF94A3B8)),
        SizedBox(width: compact ? 6 : 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

Map<String, int> _buildTaskStatusCounts(List<_TaskRecord> tasks) {
  final counts = <String, int>{
    'all': tasks.length,
    'completed': 0,
    'in progress': 0,
    'pending': 0,
  };
  for (final task in tasks) {
    final category = _taskStatusCategory(task.status);
    counts[category] = (counts[category] ?? 0) + 1;
  }
  return counts;
}

(Color, Color) _statusPalette(String status) {
  final value = status.trim().toLowerCase();
  if (value == 'completed' || value == 'done' || value == 'closed') {
    return (const Color(0xFFE8F8EE), const Color(0xFF15803D));
  }
  if (value == 'in progress' || value == 'running' || value == 'active') {
    return (const Color(0xFFE7F0FF), const Color(0xFF1D4ED8));
  }
  if (value == 'pending' || value == 'todo') {
    return (const Color(0xFFFFF4E5), const Color(0xFFB45309));
  }
  return (const Color(0xFFF1F5F9), const Color(0xFF475569));
}

(Color, Color) _priorityPalette(String priority) {
  final value = priority.trim().toLowerCase();
  if (value == 'high' || value == 'urgent' || value == 'critical') {
    return (const Color(0xFFFFE6E6), const Color(0xFFDC2626));
  }
  if (value == 'medium') {
    return (const Color(0xFFFFF4E5), const Color(0xFFD97706));
  }
  if (value == 'low') {
    return (const Color(0xFFE8F8EE), const Color(0xFF16A34A));
  }
  return (const Color(0xFFF1F5F9), const Color(0xFF475569));
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({
    required this.label,
    required this.background,
    required this.foreground,
    required this.compact,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.style(
          color: foreground,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TaskStatusDropdown extends StatelessWidget {
  const _TaskStatusDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = <String>[
      'all',
      'not started',
      'in progress',
      'on hold',
      'completed',
      'cancelled',
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD2DDEA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: AppTextStyles.style(
            color: const Color(0xFF334155),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 9,
                        color: Color(0xFF334155),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatTaskStatusLabel(option),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (next) {
            if (next == null) {
              return;
            }
            onChanged(next);
          },
        ),
      ),
    );
  }
}

class _TaskQuickIconAction extends StatelessWidget {
  const _TaskQuickIconAction({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: compact ? 34 : 36,
          height: compact ? 34 : 36,
          child: Icon(icon, size: compact ? 17 : 18, color: foreground),
        ),
      ),
    );
  }
}

class _TaskActionButton extends StatelessWidget {
  const _TaskActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 7 : 8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 15 : 16, color: color),
            SizedBox(width: compact ? 5 : 6),
            Text(
              label,
              style: AppTextStyles.style(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
      child: Row(
        children: [
          Icon(icon, size: compact ? 16 : 18, color: const Color(0xFF64748B)),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: compact ? 2 : 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.style(
                    color: const Color(0xFF0F172A),
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssigneeAvatarStack extends StatelessWidget {
  const _AssigneeAvatarStack({required this.imageUrls, required this.compact});

  final List<String> imageUrls;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visible = imageUrls.take(3).toList();
    final avatarSize = compact ? 28.0 : 32.0;
    final overlap = compact ? 18.0 : 20.0;

    return SizedBox(
      width: visible.length == 1
          ? avatarSize
          : avatarSize + ((visible.length - 1) * overlap),
      height: avatarSize,
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * overlap,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFE2E8F0),
                  backgroundImage: NetworkImage(visible[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
