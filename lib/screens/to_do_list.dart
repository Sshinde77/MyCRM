import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/services/api_service.dart';

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
                        // _SmartListsPanel(),
                        // SizedBox(height: 16),
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
                        const SizedBox(height: 18),
                        // _FocusTipsCard(),
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
        Get.snackbar(
          'Refresh failed',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFB45309),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
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
        Get.snackbar(
          'Refresh failed',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFB45309),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }

  Future<void> _handleEditTask(_TodoTask task) async {
    if (task.id == null || task.id!.isEmpty) {
      Get.snackbar(
        'Edit task failed',
        'This task is missing an id from the API response.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB91C1C),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    await _showTaskDialog(task: task);
  }

  Future<void> _handleDeleteTask(_TodoTask task) async {
    if (task.id == null || task.id!.isEmpty) {
      Get.snackbar(
        'Delete task failed',
        'This task is missing an id from the API response.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB91C1C),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
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

      Get.snackbar(
        'Task deleted',
        task.title,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF991B1B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
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

      Get.snackbar(
        'Delete task failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB91C1C),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _handleToggleTaskStatus(_TodoTask task) async {
    if (task.id == null || task.id!.isEmpty) {
      Get.snackbar(
        'Status update failed',
        'This task is missing an id from the API response.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB91C1C),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
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

      Get.snackbar(
        task.isCompleted ? 'Task marked incomplete' : 'Task marked complete',
        task.title,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: task.isCompleted
            ? const Color(0xFFB45309)
            : const Color(0xFF166534),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
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

      Get.snackbar(
        'Status update failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB91C1C),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
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
        final buttonSize = isCompact ? 38.0 : 42.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
              size: buttonSize,
            ),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To-Do List',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(
                      color: const Color(0xFF1E2B3C),
                      fontSize: isCompact ? 19 : 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Plan your day with a clean personal task flow.',
                    maxLines: isCompact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(
                      color: const Color(0xFF72839A),
                      fontSize: isCompact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isCompact ? 8 : 10),
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'S',
                style: AppTextStyles.style(
                  color: const Color(0xFF1B87E6),
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.icon, this.onTap, this.size = 42});

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF2F4158), size: size * 0.45),
        ),
      ),
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
                            'Add task',
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

class _SmartListsPanel extends StatelessWidget {
  const _SmartListsPanel();

  @override
  Widget build(BuildContext context) {
    return _TasksCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _CardEyebrow(label: 'Overview'),
          SizedBox(height: 4),
          _CardTitle(title: 'Smart lists'),
          SizedBox(height: 8),
          _SectionDescription(
            text:
                'Keep recurring, reminder, and today-specific tasks in one place.',
          ),
          SizedBox(height: 18),
          _SmartListTile(
            icon: Icons.wb_sunny_outlined,
            iconColor: Color(0xFF22B6FF),
            iconBackground: Color(0xFFE8F8FF),
            title: 'My Day',
            subtitle: 'Tasks you should keep in front of you.',
          ),
          SizedBox(height: 12),
          _SmartListTile(
            icon: Icons.autorenew_rounded,
            iconColor: Color(0xFFFF9C43),
            iconBackground: Color(0xFFFFF3E6),
            title: 'Recurring',
            subtitle: 'Day, week, month and year schedules.',
          ),
          SizedBox(height: 12),
          _SmartListTile(
            icon: Icons.notifications_active_outlined,
            iconColor: Color(0xFF28B86B),
            iconBackground: Color(0xFFEAFBF1),
            title: 'Reminders',
            subtitle: 'Email alerts arrive at your selected time.',
          ),
          SizedBox(height: 16),
          _HowItWorksCard(),
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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _repeatEveryController = TextEditingController(text: '1');
  final _afterCountController = TextEditingController(text: '1');

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
        useTwoColumns
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTitleField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateField()),
                ],
              )
            : Column(
                children: [
                  _buildTitleField(),
                  const SizedBox(height: 12),
                  _buildDateField(),
                ],
              ),
        SizedBox(height: isCompact ? 10 : 12),
        _FormFieldLabel(label: 'Description'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          minLines: descriptionLines,
          maxLines: descriptionLines,
          decoration: _taskInputDecoration(
            hintText: 'Add extra details for this task',
          ),
        ),
        SizedBox(height: isCompact ? 10 : 12),
        useTwoColumns
            ? Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTimeField()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildReminderField()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRepeatField(),
                ],
              )
            : Column(
                children: [
                  _buildTimeField(),
                  const SizedBox(height: 10),
                  _buildReminderField(),
                  const SizedBox(height: 10),
                  _buildRepeatField(),
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
        const _FormFieldLabel(label: 'Title'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
          decoration: _taskInputDecoration(),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormFieldLabel(label: 'Select Date'),
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
        const _FormFieldLabel(label: 'Select Time'),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: _selectedTime == null ? '--:--' : _formatTime(_selectedTime!),
          ),
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
        const _FormFieldLabel(label: 'Repeats Every'),
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

  Widget _buildReminderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormFieldLabel(label: 'Set Time'),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: _reminderTime == null ? '--:--' : _formatTime(_reminderTime!),
          ),
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
        const _FormFieldLabel(label: 'Starts'),
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
        );
      }
      if (!mounted) {
        return;
      }

      Get.snackbar(
        _isEditMode ? 'Task updated' : 'Task created',
        _isEditMode
            ? 'The task has been updated successfully.'
            : 'The task has been added successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF153A63),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
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

      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      Get.snackbar(
        _isEditMode ? 'Update task failed' : 'Create task failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB91C1C),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
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
  const _FormFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.style(
        color: const Color(0xFF55606E),
        fontSize: 13,
        fontWeight: FontWeight.w700,
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
      endsAfterCount: _readInt(source, const ['ends_after']),
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
  final bool isCompleted;
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

class _FocusTipsCard extends StatelessWidget {
  const _FocusTipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF67E8F9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stay consistent',
                  style: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Build a modern daily workflow by adding recurring patterns, reminders, and clear task priorities for each user.',
            style: AppTextStyles.style(
              color: const Color(0xFFB9C7DB),
              fontSize: 12.5,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
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

class _SectionDescription extends StatelessWidget {
  const _SectionDescription({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.style(
        color: const Color(0xFF7F90A6),
        fontSize: 12.5,
        height: 1.0,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SmartListTile extends StatelessWidget {
  const _SmartListTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4ECF4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.style(
                    color: const Color(0xFF2B3B54),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.style(
                    color: const Color(0xFF8D9CB0),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
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

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38BDF8), Color(0xFF67E8F9)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: AppTextStyles.style(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set a repeat pattern, choose reminder time, and the task stays personal to the current logged-in user.',
            style: AppTextStyles.style(
              color: Colors.white,
              fontSize: 12,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
