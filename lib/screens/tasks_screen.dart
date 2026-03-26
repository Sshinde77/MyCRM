import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';

import '../routes/app_routes.dart';
import '../widgets/app_bottom_navigation.dart';

/// Mobile-first tasks screen inspired by the provided mockup.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<_TodoTask> _unfinishedTasks = [];
  final List<_TodoTask> _completedTasks = [];

  int get _plannedCount => _unfinishedTasks.length;

  int get _dueTodayCount {
    final now = DateTime.now();
    return _unfinishedTasks.where((task) => _isSameDate(task.date, now)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      bottomNavigationBar: MagicBottomNavigation(
        items: const [
          MagicNavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
          MagicNavItem(label: 'Leads', icon: Icons.person_outline_rounded),
          MagicNavItem(label: 'Projects', icon: Icons.assignment_rounded),
          MagicNavItem(label: 'Tasks', icon: Icons.check_circle_outline_rounded),
          MagicNavItem(label: 'Profile', icon: Icons.person_rounded),
        ],
        initialIndex: 3,
        onChanged: (index) {
          if (index == 3) return;
          if (index == 0) {
            Get.toNamed(AppRoutes.dashboard);
          } else if (index == 1) {
            Get.toNamed(AppRoutes.leads);
          } else if (index == 2) {
            Get.toNamed(AppRoutes.projects);
          } else if (index == 4) {
            Get.toNamed(AppRoutes.profile);
          }
        },
      ),
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
              final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
              final contentWidth = constraints.maxWidth > 560 ? 560.0 : double.infinity;

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
                        const _TasksHeader(),
                        const SizedBox(height: 18),
                        _TasksHeroSection(
                          onAddTask: _showAddTaskDialog,
                          plannedCount: _plannedCount,
                          completedCount: _completedTasks.length,
                          dueTodayCount: _dueTodayCount,
                        ),
                        const SizedBox(height: 18),
                        // _SmartListsPanel(),
                        // SizedBox(height: 16),
                        _TaskStatePanel(
                          eyebrow: 'Active',
                          title: 'Unfinished Tasks',
                          badge: '${_unfinishedTasks.length}',
                          emptyText:
                              'No unfinished tasks yet. Start by adding your first task.',
                          tasks: _unfinishedTasks,
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
    final task = await showDialog<_TodoTask>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AddTaskDialog(),
    );

    if (task == null) {
      return;
    }

    setState(() {
      _unfinishedTasks.insert(0, task);
    });
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final buttonSize = isCompact ? 38.0 : 42.0;

        return Row(
          children: [
            _HeaderCircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Get.back(),
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
  const _HeaderCircleButton({
    required this.icon,
    this.onTap,
    this.size = 42,
  });

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
            text: 'Keep recurring, reminder, and today-specific tasks in one place.',
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
    this.tasks = const [],
    this.badgeColor = const Color(0xFFE9F5FF),
    this.badgeTextColor = const Color(0xFF2D7DD2),
  });

  final String eyebrow;
  final String title;
  final String badge;
  final String emptyText;
  final List<_TodoTask> tasks;
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
  });

  final _TodoTask task;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final accentColor = isCompleted ? const Color(0xFF16A34A) : const Color(0xFF2D7DD2);
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
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.style(
                    color: const Color(0xFF263548),
                    fontSize: isCompact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
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
                    _TaskMetaChip(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(task.date),
                    ),
                    _TaskMetaChip(
                      icon: Icons.access_time_rounded,
                      label: task.startTime == null ? '--:--' : _formatTime(task.startTime!),
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

class _TaskMetaChip extends StatelessWidget {
  const _TaskMetaChip({
    required this.icon,
    required this.label,
  });

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
  const _AddTaskDialog();

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
  TimeOfDay? _selectedTime;
  TimeOfDay? _reminderTime;
  String _repeatUnit = 'Day';
  _TaskEndType _endType = _TaskEndType.never;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = screenWidth > 520 ? 520.0 : screenWidth - 16;
    final isCompact = screenWidth < 380;
    final useTwoColumns = screenWidth > 420;
    final descriptionLines = screenHeight < 740 ? 2 : 3;
    final shouldScroll = isCompact || screenHeight < 760;
    final maxDialogHeight = isCompact ? screenHeight * 0.8 : screenHeight * 0.84;
    final dialogBody = Form(
      key: _formKey,
      child: Column(
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
                      'Add New Todo',
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
          SizedBox(height: isCompact ? 14 : 18),
          if (isCompact) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C86F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Save Task',
                  style: AppTextStyles.style(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
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
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F7FB),
                    foregroundColor: const Color(0xFF222222),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
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
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C86F2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Save Task',
                    style: AppTextStyles.style(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 10 : 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCompact ? 22 : 28)),
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 14 : 18,
            isCompact ? 14 : 18,
            isCompact ? 14 : 18,
            isCompact ? 12 : 16,
          ),
          child: shouldScroll
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxDialogHeight),
                  child: SingleChildScrollView(child: dialogBody),
                )
              : dialogBody,
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

  void _saveTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _TodoTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        startTime: _selectedTime,
        reminderTime: _reminderTime,
        repeatEvery: int.parse(_repeatEveryController.text.trim()),
        repeatUnit: _repeatUnit,
        startsOn: _startsDate,
        endType: _endType,
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
    required this.title,
    required this.description,
    required this.date,
    required this.repeatEvery,
    required this.repeatUnit,
    required this.startsOn,
    required this.endType,
    this.startTime,
    this.reminderTime,
  });

  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? reminderTime;
  final int repeatEvery;
  final String repeatUnit;
  final DateTime startsOn;
  final _TaskEndType endType;
}

enum _TaskEndType { never, on, after }

InputDecoration _taskInputDecoration({
  String? hintText,
  Widget? suffixIcon,
}) {
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

