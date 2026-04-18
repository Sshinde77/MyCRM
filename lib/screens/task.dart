import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/screens/create_task_screen.dart';
import 'package:mycrm/screens/task_detail_screen.dart';
import 'package:mycrm/screens/to_do_list.dart' as to_do;
import 'package:mycrm/services/api_service.dart';

import '../widgets/app_bottom_navigation.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.staffId, this.staffName});

  final String? staffId;
  final String? staffName;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<_TaskRecord> _tasks = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _loadError;
  String? _staffFilterId;
  String _staffFilterName = '';

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
    _searchController.addListener(_handleSearchChanged);
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  int get _runningCount => _tasks.where((task) => !task.completed).length;
  int get _completedCount => _tasks.where((task) => task.completed).length;

  List<_TaskRecord> get _filteredTasks {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _tasks;
    }

    return _tasks.where((task) {
      return task.title.toLowerCase().contains(query) ||
          task.projectName.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.status.toLowerCase().contains(query) ||
          task.priority.toLowerCase().contains(query) ||
          task.id.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.tasks,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
          child: Column(
            children: [
              SizedBox(height: compact ? 8 : 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks',
                    style: AppTextStyles.style(
                      color: const Color(0xFF111827),
                      fontSize: compact ? 22 : 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      _circleIcon(
                        Icons.checklist_rounded,
                        compact: compact,
                        onTap: () => Get.to(() => const to_do.ToDoListScreen()),
                      ),
                      SizedBox(width: compact ? 8 : 10),
                      _circleIcon(
                        Icons.notifications_none_rounded,
                        compact: compact,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: compact ? 14 : 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Running Tasks',
                      value: '$_runningCount',
                      percent: '${_tasks.length} total',
                      color: const Color(0xFF3B82F6),
                      bgColor: const Color(0xFFE7F0FF),
                      compact: compact,
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Completed',
                      value: '$_completedCount',
                      percent: _tasks.isEmpty
                          ? '0%'
                          : '${((_completedCount / _tasks.length) * 100).round()}%',
                      color: const Color(0xFF22C55E),
                      bgColor: const Color(0xFFE8F8EE),
                      compact: compact,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 14 : 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: compact ? 42 : 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 18,
                          ),
                          SizedBox(width: compact ? 8 : 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search tasks...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                isCollapsed: true,
                              ),
                              style: AppTextStyles.style(
                                color: const Color(0xFF111827),
                                fontSize: compact ? 12 : 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  Container(
                    height: compact ? 42 : 44,
                    width: compact ? 42 : 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _openCreateTaskScreen,
                      icon: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: compact ? 20 : 22,
                      ),
                    ),
                  ),
                ],
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
                _ErrorCard(message: _loadError!, onRetry: _loadTasks),
              ],
              SizedBox(height: compact ? 14 : 16),
              Expanded(
                child: _filteredTasks.isEmpty
                    ? _EmptyState(
                        compact: compact,
                        hasQuery: _searchController.text.trim().isNotEmpty,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return _TaskCard(
                              task: task,
                              compact: compact,
                              onTap: () => _openTaskDetail(task),
                              onEdit: () => _openEditTaskScreen(task),
                              onDelete: () => _deleteTask(task),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadTasks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final staffId = _staffFilterId?.trim() ?? '';
      final useStaffEndpoint = staffId.isNotEmpty;
      final records = useStaffEndpoint
          ? await ApiService.instance.getStaffTasksList(staffId)
          : await ApiService.instance.getTasksList();
      final tasks = <_TaskRecord>[];
      for (final record in records) {
        final parsed = _TaskRecord.fromApiRecord(record);
        if (useStaffEndpoint) {
          tasks.addAll(parsed);
          continue;
        }

        for (final task in parsed) {
          if (_matchesStaffFilter(task, record)) {
            tasks.add(task);
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _tasks
          ..clear()
          ..addAll(tasks);
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
        _loadError = error.toString().trim().isEmpty
            ? 'Failed to load tasks.'
            : error.toString().trim();
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
    final updated = await Get.to<bool>(
      () => CreateTaskScreen(
        taskId: task.id,
        initialTitle: task.title,
        initialDescription: task.description,
        initialProjectId: task.projectId,
        initialPriority: task.priority,
        initialStatus: task.status,
        initialStartDate: task.startDate,
        initialDueDate: task.deadline,
        initialAssigneeIds: task.assigneeIds,
        initialFollowerIds: task.followerIds,
        initialTags: task.tags,
      ),
    );
    if (updated != true) {
      return;
    }

    await _loadTasks();
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

      Get.snackbar(
        'Task deleted',
        task.title,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF166534),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      await _loadTasks();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      Get.snackbar(
        'Delete task failed',
        _extractErrorMessage(error, fallback: 'Failed to delete task.'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB42318),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      Get.snackbar(
        'Delete task failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB42318),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  static Widget _circleIcon(
    IconData icon, {
    required bool compact,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          height: compact ? 40 : 42,
          width: compact ? 40 : 42,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(icon, color: Colors.grey, size: compact ? 18 : 20),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String percent;
  final Color color;
  final Color bgColor;
  final bool compact;

  const _StatCard({
    required this.title,
    required this.value,
    required this.percent,
    required this.color,
    required this.bgColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 108 : 116,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              percent,
              style: AppTextStyles.style(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.style(
              fontSize: compact ? 22 : 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.style(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          LinearProgressIndicator(
            value: 1,
            color: color,
            backgroundColor: color.withValues(alpha: 0.2),
            minHeight: compact ? 5 : 6,
          ),
        ],
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: EdgeInsets.only(bottom: compact ? 10 : 12),
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.id,
                    style: AppTextStyles.style(
                      color: Colors.grey,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Flexible(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _PillBadge(
                          label: task.status,
                          background: statusColors.$1,
                          foreground: statusColors.$2,
                          compact: compact,
                        ),
                        _PillBadge(
                          label: task.priority,
                          background: priorityColors.$1,
                          foreground: priorityColors.$2,
                          compact: compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 8 : 10),
              Text(
                task.title,
                style: AppTextStyles.style(
                  color: const Color(0xFF111827),
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: compact ? 4 : 6),
              Row(
                children: [
                  Icon(
                    Icons.work_outline_rounded,
                    size: compact ? 14 : 16,
                    color: const Color(0xFF2563EB),
                  ),
                  SizedBox(width: compact ? 5 : 6),
                  Expanded(
                    child: Text(
                      task.projectName,
                      style: AppTextStyles.style(
                        color: const Color(0xFF2563EB),
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.assigneeImageUrls.isNotEmpty) ...[
                SizedBox(height: compact ? 10 : 12),
                Row(
                  children: [
                    _AssigneeAvatarStack(
                      imageUrls: task.assigneeImageUrls,
                      compact: compact,
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    Expanded(
                      child: Text(
                        task.assigneeSummary,
                        style: AppTextStyles.style(
                          color: const Color(0xFF475569),
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (task.description.isNotEmpty) ...[
                SizedBox(height: compact ? 8 : 10),
                Text(
                  task.description,
                  style: AppTextStyles.style(
                    color: const Color(0xFF6B7280),
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              SizedBox(height: compact ? 10 : 12),
              Container(
                padding: EdgeInsets.all(compact ? 10 : 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _InfoMetric(
                        icon: Icons.play_arrow_rounded,
                        label: 'Start',
                        value: task.startDateText,
                        compact: compact,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: compact ? 34 : 38,
                      color: const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: _InfoMetric(
                        icon: Icons.flag_outlined,
                        label: 'Deadline',
                        value: task.deadlineText,
                        compact: compact,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 10 : 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _TaskActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: const Color(0xFF2563EB),
                    compact: compact,
                    onTap: onEdit,
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  _TaskActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: const Color(0xFFDC2626),
                    compact: compact,
                    onTap: onDelete,
                  ),
                ],
              ),
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
  if (value is! List) {
    return const [];
  }

  return value
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty && entry.toLowerCase() != 'null')
      .toList();
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
