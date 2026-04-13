import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/project_detail_model.dart';
import 'package:mycrm/routes/app_routes.dart';
import 'package:mycrm/services/api_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, this.projectId});

  final String? projectId;

  static const background = Color(0xFFF5F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE1E8F2);
  static const title = Color(0xFF1E2740);
  static const muted = Color(0xFF6E7F98);
  static const blue = Color(0xFF3F7EF7);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Future<ProjectDetailModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ProjectDetailModel> _load() async {
    final id = (widget.projectId ?? '').trim();
    if (id.isEmpty) throw Exception('Project id is missing.');
    return ApiService.instance.getProjectDetail(id);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjectDetailScreen.background,
      body: SafeArea(
        child: FutureBuilder<ProjectDetailModel>(
          future: _future,
          builder: (context, snapshot) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const _StateCard(
                        icon: Icons.hourglass_top_rounded,
                        title: 'Loading project...',
                      )
                    : snapshot.hasError
                    ? _ErrorCard(onRetry: _reload)
                    : _Body(project: snapshot.data!),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.project});

  final ProjectDetailModel project;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  _ProjectDetailTab _selectedTab = _ProjectDetailTab.employees;
  String _employeeQuery = '';

  List<ProjectAssignedEmployee> get _employees {
    if (widget.project.employeeRecords.isNotEmpty) {
      return widget.project.employeeRecords;
    }

    return widget.project.members
        .map(
          (member) => ProjectAssignedEmployee(
            name: member,
            avatarUrl: '',
            firstName: member,
            lastName: '',
            email: 'Not available',
            phone: 'Not available',
            role: 'Staff',
            status: 'Unknown',
            team: 'Not assigned',
            departments: const [],
            startDate: widget.project.startDate,
            deadline: widget.project.deadline,
            totalTimeHours: '0.0h',
          ),
        )
        .toList();
  }

  List<ProjectAssignedEmployee> get _filteredEmployees {
    final query = _employeeQuery.trim().toLowerCase();
    if (query.isEmpty) return _employees;
    return _employees
        .where((employee) => employee.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final accent = _accent(project.status);
    final descriptionChips = [
      ...project.technologies,
      ...project.tags,
    ].take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF5E6E86),
                size: 30,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Project Details',
                style: AppTextStyles.style(
                  color: ProjectDetailScreen.title,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF5E6E86),
              size: 26,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Badge(
                    label: project.priority.toUpperCase(),
                    bg: _priorityColors(project.priority).background,
                    fg: _priorityColors(project.priority).foreground,
                  ),
                  _Badge(
                    label: project.status.toUpperCase(),
                    bg: accent.withOpacity(0.14),
                    fg: accent,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFEDF2F7)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _LabelValue(
                      label: 'Project Name',
                      value: project.title,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LabelValue(label: 'Name', value: project.client),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _LabelValue(
                      label: 'Start Date',
                      value: project.startDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LabelValue(
                      label: 'Deadline',
                      value: project.deadline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Overall Progress',
                      style: AppTextStyles.style(
                        color: ProjectDetailScreen.title,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${(project.progress * 100).toInt()}%',
                    style: AppTextStyles.style(
                      color: ProjectDetailScreen.blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: project.progress,
                  minHeight: 14,
                  backgroundColor: const Color(0xFFE9EEF5),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4A86F7)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Total Tasks',
                      value: project.taskTotal,
                      color: const Color(0xFF4A86F7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      label: 'Completed',
                      value: project.taskCompleted,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      label: 'Remaining',
                      value: project.taskRemaining,
                      color: const Color(0xFFF26A22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Description',
                style: AppTextStyles.style(
                  color: ProjectDetailScreen.title,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Html(
                data: project.description.trim().isEmpty
                    ? '<p>No description available</p>'
                    : project.description,
                style: {
                  'body': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    color: ProjectDetailScreen.muted,
                    fontSize: FontSize(14),
                    lineHeight: const LineHeight(1.7),
                    fontWeight: FontWeight.w500,
                  ),
                  'p': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                },
              ),
              if (descriptionChips.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: descriptionChips
                      .map(
                        (chip) => _Chip(
                          label: chip,
                          accent: project.technologies.contains(chip),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Client Information',
                style: AppTextStyles.style(
                  color: ProjectDetailScreen.title,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Name', value: project.client),
              const SizedBox(height: 14),
              _InfoRow(label: 'Email', value: project.clientEmail),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionTabs(
          selected: _selectedTab,
          onSelected: (tab) => setState(() => _selectedTab = tab),
        ),
        const SizedBox(height: 18),
        _buildSelectedSection(project),
      ],
    );
  }

  Widget _buildSelectedSection(ProjectDetailModel project) {
    switch (_selectedTab) {
      case _ProjectDetailTab.employees:
        return _EmployeesSection(
          employees: _filteredEmployees,
          onSearchChanged: (value) => setState(() => _employeeQuery = value),
        );
      case _ProjectDetailTab.tasks:
        return _TasksSection(tasks: project.taskRecords);
      case _ProjectDetailTab.files:
      case _ProjectDetailTab.usage:
      case _ProjectDetailTab.milestones:
      case _ProjectDetailTab.issues:
      case _ProjectDetailTab.comments:
        return _PlaceholderSection(title: _selectedTab.title);
    }
  }
}

enum _ProjectDetailTab {
  employees('Employees'),
  tasks('Tasks'),
  files('Files'),
  usage('Usage'),
  milestones('Milestones'),
  issues('Issues'),
  comments('Comments');

  const _ProjectDetailTab(this.title);
  final String title;
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.selected, required this.onSelected});

  final _ProjectDetailTab selected;
  final ValueChanged<_ProjectDetailTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _ProjectDetailTab.values
            .map(
              (tab) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => onSelected(tab),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected == tab
                          ? Colors.white
                          : const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected == tab
                            ? const Color(0xFFD5E0F4)
                            : const Color(0xFFDCE7FA),
                      ),
                      boxShadow: selected == tab
                          ? const [
                              BoxShadow(
                                color: Color(0x120F172A),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      tab.title,
                      style: AppTextStyles.style(
                        color: selected == tab
                            ? ProjectDetailScreen.title
                            : ProjectDetailScreen.blue,
                        fontSize: 14,
                        fontWeight: selected == tab
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmployeesSection extends StatelessWidget {
  const _EmployeesSection({
    required this.employees,
    required this.onSearchChanged,
  });

  final List<ProjectAssignedEmployee> employees;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              return compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned Employees',
                          style: AppTextStyles.style(
                            color: ProjectDetailScreen.title,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SearchBox(
                          hintText: 'Search employees...',
                          onChanged: onSearchChanged,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Assigned Employees',
                            style: AppTextStyles.style(
                              color: ProjectDetailScreen.title,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 280,
                          child: _SearchBox(
                            hintText: 'Search employees...',
                            onChanged: onSearchChanged,
                          ),
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 18),
          if (employees.isEmpty)
            const _EmptySectionState(message: 'No assigned employees found.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final cardWidth = width >= 1100
                    ? (width - 24) / 3
                    : width >= 720
                    ? (width - 16) / 2
                    : width;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: employees
                      .map(
                        (employee) => SizedBox(
                          width: cardWidth,
                          child: _EmployeeInfoCard(employee: employee),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection({required this.tasks});

  final List<ProjectTaskRecord> tasks;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              return compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Tasks',
                          style: AppTextStyles.style(
                            color: ProjectDetailScreen.title,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _PrimaryActionButton(
                          label: 'Create Task',
                          onTap: () => Get.toNamed(AppRoutes.tasks),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Project Tasks',
                            style: AppTextStyles.style(
                              color: ProjectDetailScreen.title,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _PrimaryActionButton(
                          label: 'Create Task',
                          onTap: () => Get.toNamed(AppRoutes.tasks),
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 18),
          if (tasks.isEmpty)
            const _EmptySectionState(
              message: 'No tasks available for this project.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 980,
                child: Column(
                  children: [
                    const _TableHeader(
                      columns: [
                        _TableColumn(title: 'Task ID', width: 90),
                        _TableColumn(title: 'Task', width: 320),
                        _TableColumn(title: 'Created On', width: 140),
                        _TableColumn(title: 'Priority', width: 120),
                        _TableColumn(title: 'Status', width: 120),
                        _TableColumn(title: 'Assignee', width: 190),
                      ],
                    ),
                    ...tasks.map(
                      (task) => _TableRow(
                        cells: [
                          _TextCell(
                            task.id.isEmpty ? '--' : '#${task.id}',
                            width: 90,
                          ),
                          _TextCell(task.title, width: 320, accent: true),
                          _TextCell(task.createdOn, width: 140),
                          _BadgeCell(
                            label: task.priority,
                            width: 120,
                            colors: _priorityColors(task.priority),
                          ),
                          _BadgeCell(
                            label: task.status,
                            width: 120,
                            colors: _statusColors(task.status),
                          ),
                          _AssigneeCell(task: task, width: 190),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  const _PlaceholderSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: const _EmptySectionState(
        message: 'This section is ready for API data and UI mapping.',
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hintText, required this.onChanged});

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD8E1EF)),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
          hintText: hintText,
          hintStyle: AppTextStyles.style(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: ProjectDetailScreen.blue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.style(
                  color: Colors.white,
                  fontSize: 14,
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

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.columns});

  final List<_TableColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7EDF6))),
      ),
      child: Row(
        children: columns
            .map(
              (column) => SizedBox(
                width: column.width,
                child: Text(
                  column.title,
                  style: AppTextStyles.style(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TableColumn {
  const _TableColumn({required this.title, required this.width});

  final String title;
  final double width;
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEFF4FA))),
      ),
      child: Row(children: cells),
    );
  }
}

class _TextCell extends StatelessWidget {
  const _TextCell(this.text, {required this.width, this.accent = false});

  final String text;
  final double width;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTextStyles.style(
          color: accent ? ProjectDetailScreen.blue : ProjectDetailScreen.title,
          fontSize: 14,
          fontWeight: accent ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmployeeInfoCard extends StatelessWidget {
  const _EmployeeInfoCard({required this.employee});

  final ProjectAssignedEmployee employee;

  @override
  Widget build(BuildContext context) {
    final displayName = [
      employee.firstName.trim(),
      employee.lastName.trim(),
    ].where((value) => value.isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE7F7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(name: employee.name, imageUrl: employee.avatarUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isEmpty ? '--' : displayName,
                  style: AppTextStyles.style(
                    color: ProjectDetailScreen.title,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  'Departments',
                  style: AppTextStyles.style(
                    color: ProjectDetailScreen.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  employee.departmentLabel,
                  style: AppTextStyles.style(
                    color: ProjectDetailScreen.title,
                    fontSize: 13,
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

class _AssigneeCell extends StatelessWidget {
  const _AssigneeCell({required this.task, required this.width});

  final ProjectTaskRecord task;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          _Avatar(name: task.assigneeName, imageUrl: task.assigneeAvatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.assigneeName,
              style: AppTextStyles.style(
                color: ProjectDetailScreen.title,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCell extends StatelessWidget {
  const _BadgeCell({
    required this.label,
    required this.width,
    required this.colors,
  });

  final String label;
  final double width;
  final _BadgeColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTextStyles.style(
              color: colors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final hasImage = imageUrl.trim().isNotEmpty;

    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE8EEF8),
      backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
      child: hasImage
          ? null
          : Text(
              initials,
              style: AppTextStyles.style(
                color: ProjectDetailScreen.blue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _EmptySectionState extends StatelessWidget {
  const _EmptySectionState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.style(
            color: ProjectDetailScreen.muted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BadgeColors {
  const _BadgeColors(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: ProjectDetailScreen.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: ProjectDetailScreen.border),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppTextStyles.style(
        color: fg,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.style(
          color: ProjectDetailScreen.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        value,
        style: AppTextStyles.style(
          color: ProjectDetailScreen.title,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withOpacity(0.16)),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: AppTextStyles.style(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.style(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.accent = false});
  final String label;
  final bool accent;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: accent ? const Color(0xFFEAF1FF) : const Color(0xFFF2F5F9),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppTextStyles.style(
        color: accent ? ProjectDetailScreen.blue : const Color(0xFF53657E),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTextStyles.style(
            color: ProjectDetailScreen.muted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(width: 1),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: AppTextStyles.style(
            color: ProjectDetailScreen.title,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      children: [
        Icon(icon, size: 34, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text(
          title,
          style: AppTextStyles.style(
            color: ProjectDetailScreen.title,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, size: 34, color: Color(0xFFB42318)),
        const SizedBox(height: 12),
        Text(
          'Unable to load project details',
          style: AppTextStyles.style(
            color: ProjectDetailScreen.title,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pull to refresh or retry the request.',
          textAlign: TextAlign.center,
          style: AppTextStyles.style(
            color: ProjectDetailScreen.muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: const Color(0xFF1D6FEA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: Text(
              'Retry',
              style: AppTextStyles.style(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Color _accent(String status) {
  final s = status.toLowerCase();
  if (s.contains('progress') || s.contains('active'))
    return const Color(0xFF1D6FEA);
  if (s.contains('planning')) return const Color(0xFF8B5CF6);
  if (s.contains('hold') || s.contains('pending'))
    return const Color(0xFFF59E0B);
  if (s.contains('complete') || s.contains('done'))
    return const Color(0xFF10B981);
  return const Color(0xFF4F5D74);
}

_BadgeColors _priorityColors(String priority) {
  final value = priority.toLowerCase();
  if (value.contains('high')) {
    return const _BadgeColors(Color(0xFFFFE3E1), Color(0xFFFF3B30));
  }
  if (value.contains('medium')) {
    return const _BadgeColors(Color(0xFFFFF3D6), Color(0xFFD97706));
  }
  if (value.contains('low')) {
    return const _BadgeColors(Color(0xFFE8F7EE), Color(0xFF16A34A));
  }
  return const _BadgeColors(Color(0xFFF1F5F9), Color(0xFF475569));
}

_BadgeColors _statusColors(String status) {
  final value = status.toLowerCase();
  if (value.contains('complete') || value.contains('done')) {
    return const _BadgeColors(Color(0xFFDCFCE7), Color(0xFF16A34A));
  }
  if (value.contains('progress') || value.contains('active')) {
    return const _BadgeColors(Color(0xFFDBEAFE), Color(0xFF2563EB));
  }
  if (value.contains('pending') || value.contains('hold')) {
    return const _BadgeColors(Color(0xFFFFF3D6), Color(0xFFD97706));
  }
  return const _BadgeColors(Color(0xFFF1F5F9), Color(0xFF475569));
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
