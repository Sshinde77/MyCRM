import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/screens/document_preview_screen.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

/// Mobile-first tasks screen inspired by the provided mockup.
class ToDoListScreen extends StatefulWidget {
  const ToDoListScreen({super.key});

  @override
  State<ToDoListScreen> createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  final List<_TodoTask> _unfinishedTasks = [];
  final List<_TodoTask> _completedTasks = [];
  bool _isLoadingTodos = false;
  String? _todoLoadError;

  int get _plannedCount => _unfinishedTasks.length;

  int get _dueTodayCount {
    final now = DateTime.now();
    return _unfinishedTasks.where((task) => _isSameDate(task.date, now)).length;
  }

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEEF5FB)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360
                  ? 16.0
                  : 20.0;
              final contentWidth = constraints.maxWidth > 560
                  ? 560.0
                  : double.infinity;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  14,
                  horizontalPadding,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TasksHeader(onBack: () => Get.back()),
                        const SizedBox(height: 18),
                        _TasksHeroSection(
                          onAddTask: _showAddTaskDialog,
                          plannedCount: _plannedCount,
                          completedCount: _completedTasks.length,
                          dueTodayCount: _dueTodayCount,
                        ),
                        const SizedBox(height: 18),
                        if (_isLoadingTodos)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              color: Color(0xFF1B87E6),
                              backgroundColor: Color(0xFFD8E8F8),
                            ),
                          ),
                        if (_todoLoadError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _TodoLoadErrorCard(
                              message: _todoLoadError!,
                              onRetry: _loadTodos,
                            ),
                          ),
                        _TaskStatePanel(
                          eyebrow: 'Active',
                          title: 'Unfinished Tasks',
                          badge: '${_unfinishedTasks.length}',
                          emptyText:
                              'No unfinished tasks yet. Start by adding your first task.',
                          tasks: _unfinishedTasks,
                          onEditTask: _handleEditTask,
                          onDeleteTask: _handleDeleteTask,
                          onToggleTaskStatus: _handleToggleTaskStatus,
                        ),
                        const SizedBox(height: 16),
                        _TaskStatePanel(
                          eyebrow: 'Archive',
                          title: 'Completed Tasks',
                          badge: '${_completedTasks.length}',
                          badgeColor: const Color(0xFFE9FBF0),
                          badgeTextColor: const Color(0xFF16A34A),
                          emptyText:
                              'Completed tasks will appear here once you finish them.',
                          tasks: _completedTasks,
                          onEditTask: _handleEditTask,
                          onDeleteTask: _handleDeleteTask,
                          onToggleTaskStatus: _handleToggleTaskStatus,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    await _showTaskDialog();
  }

  Future<void> _showTaskDialog({_TodoTask? task}) async {
    final savedTask = await showDialog<_TodoTask>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddTaskDialog(initialTask: task),
    );

    if (savedTask == null) {
      return;
    }

    await _loadTodos(showErrorSnackbar: true, fallbackTask: savedTask);
  }

  Future<void> _loadTodos({
    bool showErrorSnackbar = false,
    _TodoTask? fallbackTask,
  }) async {
    if (mounted) {
      setState(() {
        _isLoadingTodos = true;
        _todoLoadError = null;
      });
    }

    try {
      final records = await ApiService.instance.getTodoList();
      final unfinished = <_TodoTask>[];
      final completed = <_TodoTask>[];

      for (final record in records) {
        final task = _TodoTask.fromJson(record);
        if (task.isCompleted) {
          completed.add(task);
        } else {
          unfinished.add(task);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _unfinishedTasks
          ..clear()
          ..addAll(unfinished);
        _completedTasks
          ..clear()
          ..addAll(completed);
        _isLoadingTodos = false;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final responseData = error.response?.data;
      String message = 'Failed to load tasks.';

      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      setState(() {
        _isLoadingTodos = false;
        _todoLoadError = message;
        if (fallbackTask != null &&
            !_unfinishedTasks.any((task) => task == fallbackTask)) {
          _unfinishedTasks.insert(0, fallbackTask);
        }
      });

      if (showErrorSnackbar) {
        AppSnackbar.show('Refresh failed', message);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.toString().trim().isEmpty
          ? 'Failed to load tasks.'
          : error.toString().trim();

      setState(() {
        _isLoadingTodos = false;
        _todoLoadError = message;
        if (fallbackTask != null &&
            !_unfinishedTasks.any((task) => task == fallbackTask)) {
          _unfinishedTasks.insert(0, fallbackTask);
        }
      });

      if (showErrorSnackbar) {
        AppSnackbar.show('Refresh failed', message);
      }
    }
  }

  Future<void> _handleEditTask(_TodoTask task) async {
    if (task.id == null || task.id!.isEmpty) {
      AppSnackbar.show(
        'Edit task failed',
        'This task is missing an id from the API response.',
      );
      return;
    }

    await _showTaskDialog(task: task);
  }

  Future<void> _handleDeleteTask(_TodoTask task) async {
    if (task.id == null || task.id!.isEmpty) {
      AppSnackbar.show(
        'Delete task failed',
        'This task is missing an id from the API response.',
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
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

    if (shouldDelete != true) {
      return;
    }

    try {
      await ApiService.instance.deleteTodo(
        id: task.id!,
        title: task.title,
        description: task.description,
        taskDate: task.date,
        taskTime: task.startTime,
        repeatInterval: task.repeatEvery,
        repeatUnit: task.repeatUnit,
        reminderTime: task.reminderTime,
        startsOn: task.startsOn,
        endsType: task.endType.apiValue,
        endsOn: task.endsOn,
        endsAfter: task.endsAfterCount,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _removeTaskFromLists(task);
      });

      AppSnackbar.show('Task deleted', task.title);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final responseData = error.response?.data;
      String message = 'Failed to delete task.';
      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      AppSnackbar.show('Delete task failed', message);
    }
  }

  Future<void> _handleToggleTaskStatus(_TodoTask task) async {
    if (task.id == null || task.id!.isEmpty) {
      AppSnackbar.show(
        'Status update failed',
        'This task is missing an id from the API response.',
      );
      return;
    }

    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

    setState(() {
      if (task.isCompleted) {
        _removeTaskFromList(_completedTasks, task);
        _unfinishedTasks.insert(0, updatedTask);
      } else {
        _removeTaskFromList(_unfinishedTasks, task);
        _completedTasks.insert(0, updatedTask);
      }
    });

    try {
      await ApiService.instance.toggleTodoStatus(
        id: task.id!,
        isCompleted: updatedTask.isCompleted,
      );

      if (!mounted) {
        return;
      }

      AppSnackbar.show(
        task.isCompleted ? 'Task marked incomplete' : 'Task marked complete',
        task.title,
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (updatedTask.isCompleted) {
          _removeTaskFromList(_completedTasks, updatedTask);
          _unfinishedTasks.insert(0, task);
        } else {
          _removeTaskFromList(_unfinishedTasks, updatedTask);
          _completedTasks.insert(0, task);
        }
      });

      final responseData = error.response?.data;
      String message = 'Failed to update task status.';
      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      AppSnackbar.show('Status update failed', message);
    }
  }

  void _removeTaskFromLists(_TodoTask task) {
    _removeTaskFromList(_unfinishedTasks, task);
    _removeTaskFromList(_completedTasks, task);
  }

  void _removeTaskFromList(List<_TodoTask> tasks, _TodoTask task) {
    tasks.removeWhere(
      (entry) =>
          (entry.id != null && entry.id == task.id) || identical(entry, task),
    );
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        return CommonTopBar(
          title: 'To-Do List',
          compact: isCompact,
          onBack: onBack,
        );
      },
    );
  }
}

class _TasksHeroSection extends StatelessWidget {
  const _TasksHeroSection({
    required this.onAddTask,
    required this.plannedCount,
    required this.completedCount,
    required this.dueTodayCount,
  });

  final Future<void> Function() onAddTask;
  final int plannedCount;
  final int completedCount;
  final int dueTodayCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isCompact ? 16 : 20,
            isCompact ? 18 : 20,
            isCompact ? 16 : 20,
            isCompact ? 16 : 18,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF47C8EF), Color(0xFF168FCF), Color(0xFF214E8B)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x221F5B8E),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: isCompact ? -36 : -24,
                bottom: isCompact ? -46 : -36,
                child: Container(
                  width: isCompact ? 120 : 150,
                  height: isCompact ? 120 : 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: isCompact ? 58 : 74,
                  height: isCompact ? 58 : 74,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _HeroBadge(
                        label: 'MY DAY',
                        foreground: Colors.white,
                        background: Color(0x26FFFFFF),
                      ),
                      _HeroBadge(
                        label: 'PERSONAL',
                        foreground: Color(0xFFEAF8FF),
                        background: Color(0x1FFFFFFF),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 14 : 18),
                  Text(
                    'Focus on what matters today',
                    style: AppTextStyles.style(
                      color: const Color(0xFF203751),
                      fontSize: isCompact ? 23 : 28,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 10),
                  Text(
                    'Each logged-in user will only see their own recurring todos with reminders and daily focus.',
                    style: AppTextStyles.style(
                      color: Colors.white,
                      fontSize: isCompact ? 12 : 13,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: isCompact ? 14 : 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAddTask,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF174B88),
                            padding: EdgeInsets.symmetric(
                              vertical: isCompact ? 14 : 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isCompact ? 16 : 18,
                              ),
                            ),
                          ),
                          icon: Icon(
                            Icons.add_rounded,
                            size: isCompact ? 18 : 20,
                          ),
                          label: Text(
                            'Add To DO',
                            style: AppTextStyles.style(
                              fontSize: isCompact ? 13.5 : 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isCompact ? 8 : 10),
                      _TodayChip(isCompact: isCompact),
                    ],
                  ),
                  SizedBox(height: isCompact ? 14 : 18),
                  _HeroStatsGrid(
                    plannedCount: plannedCount,
                    completedCount: completedCount,
                    dueTodayCount: dueTodayCount,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip({this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 14,
        vertical: isCompact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            color: Colors.white,
            size: isCompact ? 16 : 18,
          ),
          SizedBox(width: isCompact ? 6 : 8),
          Text(
            'Today',
            style: AppTextStyles.style(
              color: Colors.white,
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _HeroStatsGrid extends StatelessWidget {
  const _HeroStatsGrid({
    required this.plannedCount,
    required this.completedCount,
    required this.dueTodayCount,
  });

  final int plannedCount;
  final int completedCount;
  final int dueTodayCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Row(
          children: [
            Expanded(
              child: _HeroStatCard(
                label: 'Planned',
                value: '$plannedCount',
                isCompact: isCompact,
              ),
            ),
            SizedBox(width: isCompact ? 6 : 10),
            Expanded(
              child: _HeroStatCard(
                label: 'Completed',
                value: '$completedCount',
                isCompact: isCompact,
              ),
            ),
            SizedBox(width: isCompact ? 6 : 10),
            Expanded(
              child: _HeroStatCard(
                label: 'Due Today',
                value: '$dueTodayCount',
                isCompact: isCompact,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({
    required this.label,
    required this.value,
    this.isCompact = false,
  });

  final String label;
  final String value;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 12 : 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: Colors.white.withOpacity(0.76),
              fontSize: isCompact ? 8.5 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: isCompact ? 0.4 : 0.7,
            ),
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            value,
            style: AppTextStyles.style(
              color: Colors.white,
              fontSize: isCompact ? 22 : 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskStatePanel extends StatelessWidget {
  const _TaskStatePanel({
    required this.eyebrow,
    required this.title,
    required this.badge,
    required this.emptyText,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onToggleTaskStatus,
    this.tasks = const [],
    this.badgeColor = const Color(0xFFE9F5FF),
    this.badgeTextColor = const Color(0xFF2D7DD2),
  });

  final String eyebrow;
  final String title;
  final String badge;
  final String emptyText;
  final List<_TodoTask> tasks;
  final ValueChanged<_TodoTask> onEditTask;
  final ValueChanged<_TodoTask> onDeleteTask;
  final ValueChanged<_TodoTask> onToggleTaskStatus;
  final Color badgeColor;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) {
    return _TasksCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardEyebrow(label: eyebrow),
                    const SizedBox(height: 4),
                    _CardTitle(title: title),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badge,
                  style: AppTextStyles.style(
                    color: badgeTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFDFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCE7F2)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      eyebrow == 'Archive'
                          ? Icons.task_alt_rounded
                          : Icons.assignment_late_outlined,
                      color: eyebrow == 'Archive'
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2D7DD2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.style(
                      color: const Color(0xFF91A0B5),
                      fontSize: 12.5,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: tasks
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TaskListTile(
                        task: task,
                        isCompleted: eyebrow == 'Archive',
                        onEdit: () => onEditTask(task),
                        onDelete: () => onDeleteTask(task),
                        onToggleStatus: () => onToggleTaskStatus(task),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({
    required this.task,
    required this.isCompleted,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  final _TodoTask task;
  final bool isCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final accentColor = isCompleted
        ? const Color(0xFF16A34A)
        : const Color(0xFF2D7DD2);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFF),
        borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        border: Border.all(color: const Color(0xFFDCE7F2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isCompact ? 38 : 42,
            height: isCompact ? 38 : 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
            ),
            alignment: Alignment.center,
            child: Icon(
              isCompleted ? Icons.task_alt_rounded : Icons.assignment_outlined,
              color: accentColor,
              size: isCompact ? 20 : 22,
            ),
          ),
          SizedBox(width: isCompact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.style(
                          color: const Color(0xFF263548),
                          fontSize: isCompact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    _TaskActionButton(
                      icon: Icons.edit_outlined,
                      iconColor: const Color(0xFF2D7DD2),
                      backgroundColor: const Color(0xFFEAF4FF),
                      onTap: onEdit,
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    _TaskActionButton(
                      icon: Icons.delete_outline_rounded,
                      iconColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFFFEEEE),
                      onTap: onDelete,
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(
                      color: const Color(0xFF7B8CA3),
                      fontSize: isCompact ? 11.5 : 12,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (task.attachments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attachments',
                        style: AppTextStyles.style(
                          color: const Color(0xFF5D7491),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: task.attachments
                            .map(
                              (attachment) => _TaskAttachmentPreview(
                                attachment: attachment,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TaskStatusButton(
                      isCompleted: isCompleted,
                      onTap: onToggleStatus,
                    ),
                    _TaskMetaChip(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(task.date),
                    ),
                    _TaskMetaChip(
                      icon: Icons.access_time_rounded,
                      label: task.startTime == null
                          ? '--:--'
                          : _formatTime(task.startTime!),
                    ),
                    _TaskMetaChip(
                      icon: Icons.repeat_rounded,
                      label: '${task.repeatEvery} ${task.repeatUnit}',
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

class _TaskStatusButton extends StatelessWidget {
  const _TaskStatusButton({required this.isCompleted, required this.onTap});

  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isCompleted
        ? const Color(0xFFFFF4E5)
        : const Color(0xFFEAFBF1);
    final foregroundColor = isCompleted
        ? const Color(0xFFB45309)
        : const Color(0xFF15803D);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompleted ? Icons.undo_rounded : Icons.task_alt_rounded,
                size: 14,
                color: foregroundColor,
              ),
              const SizedBox(width: 6),
              Text(
                isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
                style: AppTextStyles.style(
                  color: foregroundColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskActionButton extends StatelessWidget {
  const _TaskActionButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

class _TaskMetaChip extends StatelessWidget {
  const _TaskMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5D7491)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: const Color(0xFF5D7491),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog({this.initialTask});

  final _TodoTask? initialTask;

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  static const int _maxAttachmentSizeBytes = 10240 * 1024;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _repeatEveryController = TextEditingController(text: '1');
  final _afterCountController = TextEditingController(text: '1');

  List<_TodoAttachment> _selectedAttachments = const [];
  DateTime _selectedDate = DateTime.now();
  DateTime _startsDate = DateTime.now();
  DateTime _endsOnDate = DateTime.now();
  TimeOfDay? _selectedTime;
  TimeOfDay? _reminderTime;
  String _repeatUnit = 'Day';
  _TaskEndType _endType = _TaskEndType.never;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    if (task == null) {
      return;
    }

    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _repeatEveryController.text = task.repeatEvery.toString();
    _afterCountController.text = (task.endsAfterCount ?? 1).toString();
    _selectedDate = task.date;
    _startsDate = task.startsOn;
    _endsOnDate = task.endsOn ?? task.date;
    _selectedTime = task.startTime;
    _reminderTime = task.reminderTime;
    _repeatUnit = _toTitleCase(task.repeatUnit);
    _endType = task.endType;
    _selectedAttachments = List<_TodoAttachment>.from(task.attachments);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _repeatEveryController.dispose();
    _afterCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final dialogWidth = screenWidth > 520 ? 520.0 : screenWidth - 16;
    final isCompact = screenWidth < 380;
    final useTwoColumns = screenWidth > 420;
    final descriptionLines = screenHeight < 740 ? 2 : 3;
    final maxDialogHeight =
        (screenHeight - keyboardHeight) - (isCompact ? 20 : 32);
    final dialogContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TASK SETUP',
                    style: AppTextStyles.style(
                      color: const Color(0xFF556273),
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isEditMode ? 'Edit Todo' : 'Add New Todo',
                    style: AppTextStyles.style(
                      color: const Color(0xFF2D3846),
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFF6E7A89),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 10 : 12),
        _buildTitleField(),
        SizedBox(height: isCompact ? 10 : 12),
        _FormFieldLabel(label: 'Description', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          minLines: descriptionLines,
          maxLines: descriptionLines,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
          decoration: _taskInputDecoration(
            hintText: 'Add extra details for this task',
          ),
        ),
        SizedBox(height: isCompact ? 10 : 12),
        _buildAttachmentsField(),
        SizedBox(height: isCompact ? 10 : 12),
        useTwoColumns
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDateField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeField()),
                ],
              )
            : Column(
                children: [
                  _buildDateField(),
                  const SizedBox(height: 10),
                  _buildTimeField(),
                ],
              ),
        SizedBox(height: isCompact ? 12 : 14),
        const Divider(height: 1, color: Color(0xFFD6E2EF)),
        SizedBox(height: isCompact ? 12 : 14),
        Text(
          'TASK REMINDER',
          style: AppTextStyles.style(
            color: const Color(0xFF556273),
            fontSize: isCompact ? 10 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'To Do Reminder',
          style: AppTextStyles.style(
            color: const Color(0xFF2D3846),
            fontSize: isCompact ? 16 : 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: isCompact ? 10 : 12),
        useTwoColumns
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRepeatField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildReminderField()),
                ],
              )
            : Column(
                children: [
                  _buildRepeatField(),
                  const SizedBox(height: 10),
                  _buildReminderField(),
                ],
              ),
        SizedBox(height: isCompact ? 10 : 12),
        useTwoColumns
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStartsField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildEndsField()),
                ],
              )
            : Column(
                children: [
                  _buildStartsField(),
                  const SizedBox(height: 10),
                  _buildEndsField(),
                ],
              ),
      ],
    );
    final dialogActions = isCompact
        ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C86F2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Update Task' : 'Save Task',
                          style: AppTextStyles.style(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F7FB),
                    foregroundColor: const Color(0xFF222222),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: AppTextStyles.style(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F7FB),
                  foregroundColor: const Color(0xFF222222),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Close',
                  style: AppTextStyles.style(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C86F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Update Task' : 'Save Task',
                        style: AppTextStyles.style(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          );
    final dialogBody = Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dialogContent,
            SizedBox(height: isCompact ? 14 : 18),
            dialogActions,
          ],
        ),
      ),
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 10 : 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 22 : 28),
      ),
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 14 : 18,
            isCompact ? 14 : 18,
            isCompact ? 14 : 18,
            isCompact ? 12 : 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogHeight),
            child: dialogBody,
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormFieldLabel(label: 'Title', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
          decoration: _taskInputDecoration(hintText: 'Enter Title'),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormFieldLabel(label: 'Select Date', required: true),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(text: _formatDate(_selectedDate)),
          onTap: () => _pickDate(
            initialDate: _selectedDate,
            onSelected: (date) => setState(() => _selectedDate = date),
          ),
          decoration: _taskInputDecoration(
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormFieldLabel(label: 'Select Time', required: true),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: _selectedTime == null ? '--:--' : _formatTime(_selectedTime!),
          ),
          validator: (_) {
            if (_selectedTime == null) {
              return 'Please select a time';
            }
            return null;
          },
          onTap: () => _pickTime(
            initialTime: _selectedTime,
            onSelected: (time) => setState(() => _selectedTime = time),
          ),
          decoration: _taskInputDecoration(
            suffixIcon: const Icon(Icons.access_time_outlined, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormFieldLabel(label: 'Repeats Every', required: true),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _repeatEveryController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final count = int.tryParse(value ?? '');
                  if (count == null || count <= 0) {
                    return 'Enter a valid repeat count';
                  }
                  return null;
                },
                decoration: _taskInputDecoration(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _repeatUnit,
                decoration: _taskInputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'Day', child: Text('Day')),
                  DropdownMenuItem(value: 'Week', child: Text('Week')),
                  DropdownMenuItem(value: 'Month', child: Text('Month')),
                  DropdownMenuItem(value: 'Year', child: Text('Year')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _repeatUnit = value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentsField() {
    final existingAttachments = _selectedAttachments
        .where((attachment) => !attachment.isLocalFile)
        .toList();
    final pendingAttachments = _selectedAttachments
        .where((attachment) => attachment.isLocalFile)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _FormFieldLabel(label: 'Attachments')),
            TextButton.icon(
              onPressed: _isSubmitting ? null : _pickAttachments,
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: Text(
                pendingAttachments.isEmpty ? 'Add Files' : 'Add More',
                style: AppTextStyles.style(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1C86F2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD6E2EF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (existingAttachments.isNotEmpty) ...[
                Text(
                  'Existing files',
                  style: AppTextStyles.style(
                    color: const Color(0xFF55606E),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: existingAttachments
                      .map(
                        (attachment) => _AttachmentChip(
                          label: attachment.name,
                          onRemove: () => _removeAttachment(attachment),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (existingAttachments.isNotEmpty &&
                  pendingAttachments.isNotEmpty)
                const SizedBox(height: 12),
              if (pendingAttachments.isNotEmpty) ...[
                Text(
                  'Selected to upload',
                  style: AppTextStyles.style(
                    color: const Color(0xFF55606E),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pendingAttachments
                      .map(
                        (attachment) => _AttachmentChip(
                          label: attachment.name,
                          onRemove: () => _removeAttachment(attachment),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (_selectedAttachments.isEmpty)
                Text(
                  'No attachments added yet.',
                  style: AppTextStyles.style(
                    color: const Color(0xFF91A0B5),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormFieldLabel(label: 'Set Time', required: true),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: _reminderTime == null ? '--:--' : _formatTime(_reminderTime!),
          ),
          validator: (_) {
            if (_reminderTime == null) {
              return 'Please set reminder time';
            }
            return null;
          },
          onTap: () => _pickTime(
            initialTime: _reminderTime,
            onSelected: (time) => setState(() => _reminderTime = time),
          ),
          decoration: _taskInputDecoration(
            suffixIcon: const Icon(Icons.access_time_outlined, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildStartsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormFieldLabel(label: 'Starts', required: true),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(text: _formatDate(_startsDate)),
          onTap: () => _pickDate(
            initialDate: _startsDate,
            onSelected: (date) => setState(() => _startsDate = date),
          ),
          decoration: _taskInputDecoration(
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildEndsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormFieldLabel(label: 'Ends'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _EndOptionChip(
              label: 'Never',
              selected: _endType == _TaskEndType.never,
              onTap: () => setState(() => _endType = _TaskEndType.never),
            ),
            _EndOptionChip(
              label: 'On',
              selected: _endType == _TaskEndType.on,
              onTap: () => setState(() => _endType = _TaskEndType.on),
            ),
            _EndOptionChip(
              label: 'After',
              selected: _endType == _TaskEndType.after,
              onTap: () => setState(() => _endType = _TaskEndType.after),
            ),
          ],
        ),
        if (_endType == _TaskEndType.on) ...[
          const SizedBox(height: 10),
          const _FormFieldLabel(label: 'Ends On'),
          const SizedBox(height: 8),
          TextFormField(
            readOnly: true,
            controller: TextEditingController(text: _formatDate(_endsOnDate)),
            onTap: () => _pickDate(
              initialDate: _endsOnDate,
              onSelected: (date) => setState(() => _endsOnDate = date),
            ),
            decoration: _taskInputDecoration(
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
          ),
        ],
        if (_endType == _TaskEndType.after) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: 120,
            child: TextFormField(
              controller: _afterCountController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_endType != _TaskEndType.after) {
                  return null;
                }
                final count = int.tryParse((value ?? '').trim());
                if (count == null || count <= 0) {
                  return 'Enter valid count';
                }
                return null;
              },
              decoration: _taskInputDecoration(hintText: 'Count'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _pickTime({
    required TimeOfDay? initialTime,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (result == null || !mounted) {
      return;
    }

    final oversizedFiles = <String>[];
    final pickedAttachments = <_TodoAttachment>[];

    for (final file in result.files) {
      final path = (file.path ?? '').trim();
      if (path.isEmpty) {
        continue;
      }

      if (file.size > _maxAttachmentSizeBytes) {
        oversizedFiles.add(file.name);
        continue;
      }

      pickedAttachments.add(_TodoAttachment(name: file.name, localPath: path));
    }

    if (oversizedFiles.isNotEmpty) {
      final details = oversizedFiles.length == 1
          ? oversizedFiles.first
          : '${oversizedFiles.length} files';
      AppSnackbar.show('File too large', '$details exceed 10240 KB limit.');
    }

    if (pickedAttachments.isEmpty) {
      return;
    }

    setState(() {
      final next = List<_TodoAttachment>.from(_selectedAttachments);
      for (final attachment in pickedAttachments) {
        final duplicate = next.any(
          (item) =>
              item.localPath != null &&
              item.localPath!.toLowerCase() ==
                  attachment.localPath!.toLowerCase(),
        );
        if (!duplicate) {
          next.add(attachment);
        }
      }
      _selectedAttachments = next;
    });
  }

  void _removeAttachment(_TodoAttachment attachment) {
    final targetPath = (attachment.localPath ?? '').trim();
    final targetUrl = (attachment.url ?? '').trim();
    setState(() {
      _selectedAttachments = _selectedAttachments.where((item) {
        final itemPath = (item.localPath ?? '').trim();
        final itemUrl = (item.url ?? '').trim();
        final sameLocal = targetPath.isNotEmpty && itemPath == targetPath;
        final sameUrl = targetUrl.isNotEmpty && itemUrl == targetUrl;
        final sameNameNoSource =
            targetPath.isEmpty &&
            targetUrl.isEmpty &&
            item.name == attachment.name;
        return !(sameLocal || sameUrl || sameNameNoSource);
      }).toList();
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final task = _TodoTask(
      id: widget.initialTask?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      startTime: _selectedTime,
      reminderTime: _reminderTime,
      repeatEvery: int.parse(_repeatEveryController.text.trim()),
      repeatUnit: _repeatUnit,
      startsOn: _startsDate,
      endType: _endType,
      endsOn: _endType == _TaskEndType.on ? _endsOnDate : null,
      endsAfterCount: _endType == _TaskEndType.after
          ? int.tryParse(_afterCountController.text.trim())
          : null,
      attachments: _selectedAttachments,
    );

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        final id = widget.initialTask?.id;
        if (id == null || id.isEmpty) {
          throw Exception('This task is missing an id from the API response.');
        }

        await ApiService.instance.updateTodo(
          id: id,
          title: task.title,
          description: task.description,
          taskDate: task.date,
          taskTime: task.startTime,
          repeatInterval: task.repeatEvery,
          repeatUnit: task.repeatUnit,
          reminderTime: task.reminderTime,
          startsOn: task.startsOn,
          endsType: task.endType.apiValue,
          endsOn: task.endsOn,
          endsAfter: task.endsAfterCount,
          attachmentPaths: task.attachments
              .where((attachment) => attachment.isLocalFile)
              .map((attachment) => attachment.localPath!)
              .toList(),
          existingAttachmentUrls: task.attachments
              .where((attachment) => !attachment.isLocalFile)
              .map((attachment) => (attachment.url ?? '').trim())
              .where((url) => url.isNotEmpty)
              .toList(),
        );
      } else {
        await ApiService.instance.createTodo(
          title: task.title,
          description: task.description,
          taskDate: task.date,
          taskTime: task.startTime,
          repeatInterval: task.repeatEvery,
          repeatUnit: task.repeatUnit,
          reminderTime: task.reminderTime,
          startsOn: task.startsOn,
          endsType: task.endType.apiValue,
          endsOn: task.endsOn,
          endsAfter: task.endsAfterCount,
          attachmentPaths: task.attachments
              .where((attachment) => attachment.isLocalFile)
              .map((attachment) => attachment.localPath!)
              .toList(),
        );
      }
      if (!mounted) {
        return;
      }

      AppSnackbar.show(
        _isEditMode ? 'Task updated' : 'Task created',
        _isEditMode
            ? 'The task has been updated successfully.'
            : 'The task has been added successfully.',
      );

      Navigator.of(context).pop(task);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final responseData = error.response?.data;
      String message = _isEditMode
          ? 'Failed to update task.'
          : 'Failed to create task.';

      if (responseData is Map) {
        final normalized = responseData.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final validationMessage = _readFirstValidationErrorMessage(normalized);
        if (validationMessage != null && validationMessage.trim().isNotEmpty) {
          message = validationMessage.trim();
        } else if (normalized['message'] != null) {
          message = normalized['message'].toString();
        }
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      AppSnackbar.show(
        _isEditMode ? 'Update task failed' : 'Create task failed',
        message,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _TodoLoadErrorCard extends StatelessWidget {
  const _TodoLoadErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB45309),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load tasks',
                  style: AppTextStyles.style(
                    color: const Color(0xFF9A3412),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.style(
                    color: const Color(0xFF9A3412),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: AppTextStyles.style(fontWeight: FontWeight.w700),
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

class _EndOptionChip extends StatelessWidget {
  const _EndOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5FAFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFB7D7FF) : const Color(0xFFD6E2EF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF9AA8B7)),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1C86F2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.style(
                color: const Color(0xFF52606F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormFieldLabel extends StatelessWidget {
  const _FormFieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AppTextStyles.style(
          color: const Color(0xFF55606E),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFD93025)),
                ),
              ]
            : const [],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.label, this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.attach_file_rounded,
            size: 14,
            color: Color(0xFF5D7491),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: const Color(0xFF5D7491),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Color(0xFF5D7491),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskAttachmentPreview extends StatelessWidget {
  const _TaskAttachmentPreview({required this.attachment});

  final _TodoAttachment attachment;

  Future<void> _handleTap(BuildContext context) async {
    final imageUrl = (attachment.url ?? '').trim();
    final localPath = (attachment.localPath ?? '').trim();
    final isImage =
        _looksLikeImageAttachment(attachment.name) ||
        _looksLikeImageAttachment(imageUrl);

    if (isImage) {
      final mediaSize = MediaQuery.of(context).size;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.all(18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  SizedBox(
                    width: mediaSize.width * 0.9,
                    height: mediaSize.height * 0.75,
                    child: ColoredBox(
                      color: Colors.black,
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Center(
                          child: localPath.isNotEmpty
                              ? Image.file(
                                  File(localPath),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white70,
                                    size: 44,
                                  ),
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white70,
                                    size: 44,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    if (imageUrl.isNotEmpty) {
      await DocumentPreviewScreen.openDocument(
        context,
        fileUrl: imageUrl,
        localPath: localPath.isEmpty ? null : localPath,
      );
      return;
    }

    if (localPath.isNotEmpty) {
      await DocumentPreviewScreen.openDocument(
        context,
        fileUrl: localPath,
        localPath: localPath,
      );
      return;
    }

    AppSnackbar.show(
      'Preview unavailable',
      'This file cannot be opened from here.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Set your rectangle size here
    final previewWidth = 240.0;
    final previewHeight = 90.0;

    final imageUrl = attachment.url;
    final localPath = attachment.localPath;

    final canPreviewAsImage =
        _looksLikeImageAttachment(attachment.name) ||
        _looksLikeImageAttachment(imageUrl);

    final fallbackPreview = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FC),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.insert_drive_file_rounded,
        size: 22,
        color: Color(0xFF5D7491),
      ),
    );

    Widget previewContent = fallbackPreview;

    // 🔹 Local image preview
    if (canPreviewAsImage && localPath != null && localPath.trim().isNotEmpty) {
      previewContent = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallbackPreview,
        ),
      );
    }
    // 🔹 Network image preview
    else if (canPreviewAsImage &&
        imageUrl != null &&
        imageUrl.trim().isNotEmpty) {
      previewContent = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallbackPreview,
        ),
      );
    }

    return SizedBox(
      width: previewWidth,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: previewWidth,
              height: previewHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD6E2EF)),
              ),
              clipBehavior: Clip.antiAlias,
              child: previewContent,
            ),
            const SizedBox(height: 4),
            Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: const Color(0xFF5D7491),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoTask {
  const _TodoTask({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.repeatEvery,
    required this.repeatUnit,
    required this.startsOn,
    required this.endType,
    this.endsOn,
    this.endsAfterCount,
    this.startTime,
    this.reminderTime,
    this.attachments = const [],
    this.isCompleted = false,
  });

  _TodoTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? reminderTime,
    int? repeatEvery,
    String? repeatUnit,
    DateTime? startsOn,
    _TaskEndType? endType,
    DateTime? endsOn,
    int? endsAfterCount,
    List<_TodoAttachment>? attachments,
    bool? isCompleted,
  }) {
    return _TodoTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      reminderTime: reminderTime ?? this.reminderTime,
      repeatEvery: repeatEvery ?? this.repeatEvery,
      repeatUnit: repeatUnit ?? this.repeatUnit,
      startsOn: startsOn ?? this.startsOn,
      endType: endType ?? this.endType,
      endsOn: endsOn ?? this.endsOn,
      endsAfterCount: endsAfterCount ?? this.endsAfterCount,
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory _TodoTask.fromJson(Map<String, dynamic> source) {
    final taskDate =
        _tryParseApiDate(
          _readString(source, const ['task_date', 'date', 'due_date']),
        ) ??
        _tryParseApiDate(
          _readString(source, const ['starts_on', 'start_date']),
        ) ??
        DateTime.now();
    final startsOn =
        _tryParseApiDate(
          _readString(source, const ['starts_on', 'start_date']),
        ) ??
        taskDate;
    final endType = _taskEndTypeFromString(
      _readString(source, const ['ends_type', 'end_type']),
    );

    return _TodoTask(
      id: _readString(source, const ['id', 'todo_id', 'task_id']),
      title:
          _readString(source, const ['title', 'name', 'task_title']) ??
          'Untitled Task',
      description: _readString(source, const ['description', 'details']) ?? '',
      date: taskDate,
      startTime: _tryParseApiTime(
        _readString(source, const ['task_time', 'start_time', 'time']),
      ),
      reminderTime: _tryParseApiTime(
        _readString(source, const ['reminder_time', 'reminder']),
      ),
      repeatEvery:
          _readInt(source, const ['repeat_interval', 'repeat_every']) ?? 1,
      repeatUnit: _toTitleCase(
        _readString(source, const ['repeat_unit', 'repeat']) ?? 'day',
      ),
      startsOn: startsOn,
      endType: endType,
      endsOn: _tryParseApiDate(_readString(source, const ['ends_on'])),
      endsAfterCount: _readInt(source, const [
        'ends_after_occurrences',
        'ends_after',
      ]),
      attachments: _readAttachments(source),
      isCompleted: _readCompletionState(source),
    );
  }

  final String? id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? reminderTime;
  final int repeatEvery;
  final String repeatUnit;
  final DateTime startsOn;
  final _TaskEndType endType;
  final DateTime? endsOn;
  final int? endsAfterCount;
  final List<_TodoAttachment> attachments;
  final bool isCompleted;
}

class _TodoAttachment {
  const _TodoAttachment({required this.name, this.url, this.localPath});

  final String name;
  final String? url;
  final String? localPath;

  bool get isLocalFile => (localPath ?? '').trim().isNotEmpty;
}

enum _TaskEndType { never, on, after }

extension on _TaskEndType {
  String get apiValue => name;
}

InputDecoration _taskInputDecoration({String? hintText, Widget? suffixIcon}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyles.style(
      color: const Color(0xFF9AA8B7),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD6E2EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1C86F2), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD93025)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD93025), width: 1.4),
    ),
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String? _readString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) {
      continue;
    }

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    final asString = value.toString().trim();
    if (asString.isNotEmpty && asString.toLowerCase() != 'null') {
      return asString;
    }
  }

  return null;
}

String? _readFirstValidationErrorMessage(Map<String, dynamic> payload) {
  final rawErrors = payload['errors'];
  if (rawErrors is Map) {
    for (final value in rawErrors.values) {
      if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first != null) {
          final asText = first.toString().trim();
          if (asText.isNotEmpty) {
            return asText;
          }
        }
      }

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  }
  return null;
}

int? _readInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return null;
}

List<_TodoAttachment> _readAttachments(Map<String, dynamic> source) {
  dynamic raw = source['attachments'];
  if (raw == null) {
    raw = source['attachment'];
  }
  if (raw is! List) {
    return const [];
  }

  return raw
      .map((entry) {
        if (entry is String) {
          final trimmed = entry.trim();
          if (trimmed.isEmpty) {
            return null;
          }
          return _TodoAttachment(name: trimmed, url: trimmed);
        }

        if (entry is! Map) {
          return null;
        }

        final item = entry.map((key, value) => MapEntry(key.toString(), value));
        return _TodoAttachment(
          name:
              _readString(item, const [
                'name',
                'file_name',
                'filename',
                'title',
              ]) ??
              'Attachment',
          url: _readString(item, const ['url', 'file', 'path']),
        );
      })
      .whereType<_TodoAttachment>()
      .toList();
}

bool _looksLikeImageAttachment(String? value) {
  if (value == null || value.trim().isEmpty) {
    return false;
  }

  final normalized = value.trim().toLowerCase();
  final path = normalized.split('?').first;
  return path.endsWith('.png') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.gif') ||
      path.endsWith('.webp') ||
      path.endsWith('.bmp') ||
      path.endsWith('.svg');
}

DateTime? _tryParseApiDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final normalized = value.trim();
  return DateTime.tryParse(normalized);
}

TimeOfDay? _tryParseApiTime(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final parts = value.trim().split(':');
  if (parts.length < 2) {
    return null;
  }

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }

  return TimeOfDay(hour: hour, minute: minute);
}

_TaskEndType _taskEndTypeFromString(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'on':
      return _TaskEndType.on;
    case 'after':
      return _TaskEndType.after;
    default:
      return _TaskEndType.never;
  }
}

bool _readCompletionState(Map<String, dynamic> source) {
  for (final key in const ['is_completed', 'completed', 'isComplete']) {
    final value = source[key];
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
  }

  final status = _readString(source, const [
    'status',
    'task_status',
    'state',
  ])?.toLowerCase();
  if (status == null) {
    return false;
  }

  return status.contains('complete') ||
      status.contains('completed') ||
      status.contains('done') ||
      status.contains('closed') ||
      status.contains('finish');
}

String _toTitleCase(String value) {
  if (value.isEmpty) {
    return value;
  }

  final normalized = value.trim().toLowerCase();
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2EBF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardEyebrow extends StatelessWidget {
  const _CardEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.style(
        color: const Color(0xFF4E5B6E),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.style(
        color: const Color(0xFF28384B),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
