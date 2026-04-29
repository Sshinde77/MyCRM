import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';
import 'package:mycrm/models/project_milestone_model.dart';
import 'package:mycrm/models/project_issue_model.dart';
import 'package:mycrm/models/project_detail_model.dart';
import 'package:mycrm/models/project_comment_model.dart';
import 'package:mycrm/models/project_usage_model.dart';
import 'package:mycrm/providers/project_issue_provider.dart';
import 'package:mycrm/providers/project_milestone_provider.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

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
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
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
        const CommonTopBar(title: 'Project Details'),
        const SizedBox(height: 14),
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
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFEDF2F7)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _LabelValue(
                      label: 'Project Name',
                      value: project.title,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabelValue(label: 'Name', value: project.client),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _LabelValue(
                      label: 'Start Date',
                      value: project.startDate,
                    ),
                  ),
                  const SizedBox(width: 12),
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
        const SizedBox(height: 14),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${(project.progress * 100).toInt()}%',
                    style: AppTextStyles.style(
                      color: ProjectDetailScreen.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: project.progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE9EEF5),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4A86F7)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Total Tasks',
                      value: project.taskTotal,
                      color: const Color(0xFF4A86F7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      label: 'Completed',
                      value: project.taskCompleted,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 10),
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
        const SizedBox(height: 14),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Description',
                style: AppTextStyles.style(
                  color: ProjectDetailScreen.title,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Html(
                data: project.description.trim().isEmpty
                    ? '<p>No description available</p>'
                    : project.description,
                style: {
                  'body': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    color: ProjectDetailScreen.muted,
                    fontSize: FontSize(13),
                    lineHeight: const LineHeight(1.7),
                    fontWeight: FontWeight.w500,
                  ),
                  'p': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                },
              ),
              if (descriptionChips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
        const SizedBox(height: 14),
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
              const SizedBox(height: 12),
              _InfoRow(label: 'Name', value: project.client),
              const SizedBox(height: 10),
              _InfoRow(label: 'Email', value: project.clientEmail),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionTabs(
          selected: _selectedTab,
          onSelected: (tab) => setState(() => _selectedTab = tab),
        ),
        const SizedBox(height: 14),
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
        return _TasksSection(projectId: project.id);
      case _ProjectDetailTab.files:
        return _FilesSection(projectId: project.id);
      case _ProjectDetailTab.usage:
        return _UsageSection(projectId: project.id);
      case _ProjectDetailTab.milestones:
        return _MilestonesSection(projectId: project.id);
      case _ProjectDetailTab.issues:
        return _IssuesSection(projectId: project.id);
      case _ProjectDetailTab.comments:
        return _CommentsSection(projectId: project.id);
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
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelected(tab),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected == tab
                          ? Colors.white
                          : const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(12),
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
                        fontSize: 13,
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
                            fontSize: 16,
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
                              fontSize: 16,
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

class _TasksSection extends StatefulWidget {
  const _TasksSection({required this.projectId});

  final String projectId;

  @override
  State<_TasksSection> createState() => _TasksSectionState();
}

class _TasksSectionState extends State<_TasksSection> {
  late Future<List<_ProjectTaskListRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_ProjectTaskListRecord>> _load() async {
    final records = await ApiService.instance.getTasksList();
    final projectId = widget.projectId.trim();
    if (projectId.isEmpty) {
      return const [];
    }

    bool matchesProject(Map<String, dynamic> record) {
      final extracted = _extractProjectId(record);
      return extracted.isNotEmpty && extracted == projectId;
    }

    return records
        .where(matchesProject)
        .map(_ProjectTaskListRecord.fromJson)
        .toList();
  }

  String _extractProjectId(Map<String, dynamic> json) {
    dynamic tryRead(Map<String, dynamic> source, String key) => source[key];

    String normalize(dynamic value) {
      if (value == null) return '';
      if (value is String) return value.trim();
      if (value is num) return value.toString();
      if (value is Map) {
        final mapped = value.map((k, v) => MapEntry(k.toString(), v));
        for (final nestedKey in const [
          'id',
          '_id',
          'project_id',
          'projectId',
        ]) {
          final nested = normalize(mapped[nestedKey]);
          if (nested.isNotEmpty) return nested;
        }
      }
      return '';
    }

    for (final key in const ['project_id', 'projectId', 'project']) {
      final value = normalize(tryRead(json, key));
      if (value.isNotEmpty) {
        return value;
      }
    }

    // Occasionally nested under relations.
    for (final key in const ['project_detail', 'projectDetail', 'relation']) {
      final value = tryRead(json, key);
      if (value is Map) {
        final mapped = value.map((k, v) => MapEntry(k.toString(), v));
        final nested = _extractProjectId(mapped);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return '';
  }

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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<_ProjectTaskListRecord>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _EmptySectionState(message: 'Loading tasks...');
              }

              if (snapshot.hasError) {
                return _EmptySectionState(
                  message: 'Unable to load tasks for this project.',
                );
              }

              final tasks = snapshot.data ?? const <_ProjectTaskListRecord>[];
              if (tasks.isEmpty) {
                return const _EmptySectionState(
                  message: 'No tasks available for this project.',
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _ProjectTaskListItem(record: tasks[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProjectTaskListItem extends StatelessWidget {
  const _ProjectTaskListItem({required this.record});

  final _ProjectTaskListRecord record;

  @override
  Widget build(BuildContext context) {
    final priorityColors = _priorityColors(record.priority);
    final statusColors = _statusColors(record.status);
    final assignees = record.assigneeImageUrls;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: ProjectDetailScreen.title,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Badge(
                      label: record.priority.toUpperCase(),
                      bg: priorityColors.background,
                      fg: priorityColors.foreground,
                    ),
                    _Badge(
                      label: record.status.toUpperCase(),
                      bg: statusColors.background,
                      fg: statusColors.foreground,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (assignees.isNotEmpty)
                _AssigneeAvatarStack(imageUrls: assignees)
              else
                Text(
                  'Unassigned',
                  style: AppTextStyles.style(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssigneeAvatarStack extends StatelessWidget {
  const _AssigneeAvatarStack({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final visible = imageUrls.take(3).toList();
    const avatarSize = 28.0;
    const overlap = 18.0;

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

class _ProjectTaskListRecord {
  const _ProjectTaskListRecord({
    required this.title,
    required this.priority,
    required this.status,
    required this.assigneeImageUrls,
  });

  final String title;
  final String priority;
  final String status;
  final List<String> assigneeImageUrls;

  factory _ProjectTaskListRecord.fromJson(Map<String, dynamic> json) {
    String readValue(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is num) return value.toString();
      }
      return fallback;
    }

    List<String> readAssigneeImages() {
      final images = <String>[];
      final raw = json['assignees'];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final mapped = item.map((k, v) => MapEntry(k.toString(), v));
            for (final key in const [
              'profile_image',
              'profileImage',
              'avatar',
              'avatar_url',
              'image',
              'photo',
            ]) {
              final value = mapped[key];
              if (value is String && value.trim().isNotEmpty) {
                images.add(value.trim());
                break;
              }
            }
          } else if (item is String && item.trim().isNotEmpty) {
            images.add(item.trim());
          }
        }
      }

      final single = json['assignee'];
      if (images.isEmpty && single is Map) {
        final mapped = single.map((k, v) => MapEntry(k.toString(), v));
        for (final key in const [
          'profile_image',
          'profileImage',
          'avatar',
          'avatar_url',
          'image',
          'photo',
        ]) {
          final value = mapped[key];
          if (value is String && value.trim().isNotEmpty) {
            images.add(value.trim());
            break;
          }
        }
      }

      return images;
    }

    return _ProjectTaskListRecord(
      title: readValue(const [
        'title',
        'name',
        'task_title',
        'subject',
      ], fallback: 'Task'),
      priority: readValue(const [
        'priority',
        'priority_level',
      ], fallback: 'Normal'),
      status: readValue(const ['status', 'task_status'], fallback: 'Unknown'),
      assigneeImageUrls: readAssigneeImages(),
    );
  }
}

class _MilestonesSection extends StatefulWidget {
  const _MilestonesSection({required this.projectId});

  final String projectId;

  @override
  State<_MilestonesSection> createState() => _MilestonesSectionState();
}

class _MilestonesSectionState extends State<_MilestonesSection> {
  late ProjectMilestoneProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ProjectMilestoneProvider(projectId: widget.projectId)
      ..loadMilestones();
  }

  @override
  void didUpdateWidget(covariant _MilestonesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId) {
      _provider.dispose();
      _provider = ProjectMilestoneProvider(projectId: widget.projectId)
        ..loadMilestones(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProjectMilestoneProvider>.value(
      value: _provider,
      child: Consumer<ProjectMilestoneProvider>(
        builder: (context, milestoneProvider, _) {
          final milestones = milestoneProvider.milestones;

          return _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 640;
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PrimaryActionButton(
                            label: 'Create Milestone',
                            onTap: milestoneProvider.isSaving
                                ? () {}
                                : _openCreateMilestoneDialog,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        _PrimaryActionButton(
                          label: 'Create Milestone',
                          onTap: milestoneProvider.isSaving
                              ? () {}
                              : _openCreateMilestoneDialog,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (milestoneProvider.isLoading && milestones.isEmpty)
                  const _EmptySectionState(message: 'Loading milestones...')
                else if (milestoneProvider.errorMessage != null &&
                    milestones.isEmpty)
                  _EmptySectionState(message: milestoneProvider.errorMessage!)
                else if (milestones.isEmpty)
                  const _EmptySectionState(message: 'No milestones available.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: milestones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final milestone = milestones[index];
                      return _MilestoneCard(
                        milestone: milestone,
                        onEdit: () => _openEditMilestoneDialog(milestone),
                        onDelete: () => _deleteMilestone(milestone),
                        isDeleting: milestoneProvider.isDeletingMilestone(
                          milestone.id,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateMilestoneDialog() async {
    final request = await showDialog<_MilestoneFormRequest>(
      context: context,
      builder: (_) =>
          const _MilestoneFormDialog(mode: _MilestoneFormMode.create),
    );
    if (request == null || !mounted) return;
    try {
      await _provider.createMilestone(
        title: request.title,
        description: request.description,
        status: request.status,
        dueDate: request.dueDate,
      );
      if (!mounted) return;
      _showSnack('Milestone created successfully');
    } catch (error) {
      if (!mounted) return;
      _showSnack(_provider.errorMessage ?? error.toString());
    }
  }

  Future<void> _openEditMilestoneDialog(ProjectMilestoneModel milestone) async {
    final request = await showDialog<_MilestoneFormRequest>(
      context: context,
      builder: (_) => _MilestoneFormDialog(
        mode: _MilestoneFormMode.edit,
        initialTitle: milestone.title,
        initialDescription: milestone.description,
        initialStatus: milestone.status,
        initialDueDate: milestone.dueDate,
      ),
    );
    if (request == null || !mounted) return;
    final milestoneId = milestone.id.trim();
    if (milestoneId.isEmpty) {
      _showSnack('Unable to edit milestone: missing milestone id');
      return;
    }
    try {
      await _provider.updateMilestone(
        milestoneId: milestoneId,
        title: request.title,
        description: request.description,
        status: request.status,
        dueDate: request.dueDate,
      );
      if (!mounted) return;
      _showSnack('Milestone updated successfully');
    } catch (error) {
      if (!mounted) return;
      _showSnack(_provider.errorMessage ?? error.toString());
    }
  }

  Future<void> _deleteMilestone(ProjectMilestoneModel milestone) async {
    final milestoneId = milestone.id.trim();
    if (milestoneId.isEmpty) {
      _showSnack('Unable to delete milestone: missing milestone id');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Milestone'),
        content: Text(
          'Delete ${milestone.title.trim().isEmpty ? 'this milestone' : milestone.title.trim()} permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await _provider.deleteMilestone(milestoneId);
      if (!mounted) return;
      _showSnack('Milestone deleted successfully');
    } catch (error) {
      if (!mounted) return;
      _showSnack(_provider.errorMessage ?? error.toString());
    }
  }

  void _showSnack(String message) {
    AppSnackbar.show('Notice', message);
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
  });

  final ProjectMilestoneModel milestone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MilestoneField(label: 'title', value: milestone.title),
          const SizedBox(height: 8),
          _MilestoneField(
            label: 'description',
            value: milestone.description,
            isDescription: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MilestoneField(
                  label: 'status',
                  value: milestone.status,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MilestoneField(
                  label: 'due_date',
                  value: milestone.dueDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ProjectDetailScreen.blue,
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    'Edit',
                    style: AppTextStyles.style(
                      color: ProjectDetailScreen.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isDeleting ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  icon: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    isDeleting ? 'Deleting...' : 'Delete',
                    style: AppTextStyles.style(
                      color: const Color(0xFFDC2626),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneField extends StatelessWidget {
  const _MilestoneField({
    required this.label,
    required this.value,
    this.isDescription = false,
  });

  final String label;
  final String value;
  final bool isDescription;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: ProjectDetailScreen.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.trim().isEmpty ? '--' : value.trim(),
          maxLines: isDescription ? 3 : 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.style(
            color: ProjectDetailScreen.title,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

enum _MilestoneFormMode { create, edit }

class _MilestoneFormRequest {
  const _MilestoneFormRequest({
    required this.title,
    required this.description,
    required this.status,
    required this.dueDate,
  });

  final String title;
  final String description;
  final String status;
  final String dueDate;
}

class _MilestoneFormDialog extends StatefulWidget {
  const _MilestoneFormDialog({
    required this.mode,
    this.initialTitle = '',
    this.initialDescription = '',
    this.initialStatus = '',
    this.initialDueDate = '',
  });

  final _MilestoneFormMode mode;
  final String initialTitle;
  final String initialDescription;
  final String initialStatus;
  final String initialDueDate;

  @override
  State<_MilestoneFormDialog> createState() => _MilestoneFormDialogState();
}

class _MilestoneFormDialogState extends State<_MilestoneFormDialog> {
  static const List<String> _statusOptions = [
    'Pending',
    'In Progress',
    'Completed',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dueDateController;
  late String _selectedStatus;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle.trim());
    _descriptionController = TextEditingController(
      text: widget.initialDescription.trim(),
    );
    _dueDateController = TextEditingController(
      text: widget.initialDueDate.trim(),
    );
    _selectedStatus = _resolveInitialStatus(widget.initialStatus);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  String _resolveInitialStatus(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Pending';
    for (final option in _statusOptions) {
      if (option.toLowerCase() == value.toLowerCase()) return option;
    }
    return 'Pending';
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
    );
    if (!mounted || picked == null) return;
    _dueDateController.text =
        '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
  }

  void _submit() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final dueDate = _dueDateController.text.trim();
    if (title.isEmpty) {
      setState(() => _inlineError = 'Please enter milestone title');
      return;
    }

    setState(() => _inlineError = null);
    Navigator.of(context).pop(
      _MilestoneFormRequest(
        title: title,
        description: description,
        status: _selectedStatus,
        dueDate: dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.mode == _MilestoneFormMode.create
        ? 'Add Milestone'
        : 'Edit Milestone';

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        heading,
                        style: AppTextStyles.style(
                          color: const Color(0xFF374151),
                          fontSize: 33,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),
                _DialogLabel(text: 'Title'),
                const SizedBox(height: 8),
                _DialogInput(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: 'Enter milestone title',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _DialogLabel(text: 'Description'),
                const SizedBox(height: 8),
                _DialogInput(
                  height: 84,
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: 'Add milestone details...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Due Date
                    _DialogLabel(text: 'Due Date'),
                    const SizedBox(height: 8),
                    _DialogInput(
                      child: TextField(
                        controller: _dueDateController,
                        readOnly: true,
                        onTap: _pickDueDate,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          hintText: 'dd-mm-yyyy',
                          suffixIcon: IconButton(
                            onPressed: _pickDueDate,
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Status
                    _DialogLabel(text: 'Status'),
                    const SizedBox(height: 8),
                    _DialogInput(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF374151),
                          ),
                          items: _statusOptions
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: AppTextStyles.style(
                                      color: const Color(0xFF374151),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedStatus = value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (_inlineError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _inlineError!,
                    style: AppTextStyles.style(
                      color: const Color(0xFFB42318),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFF9CA3AF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(78, 40),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D8CF8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(126, 40),
                      ),
                      child: Text(
                        'Save Milestone',
                        style: AppTextStyles.style(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _DialogLabel extends StatelessWidget {
  const _DialogLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.style(
        color: const Color(0xFF4B5563),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DialogInput extends StatelessWidget {
  const _DialogInput({required this.child, this.height = 44});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        color: Colors.white,
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

class _IssuesSection extends StatefulWidget {
  const _IssuesSection({required this.projectId});

  final String projectId;

  @override
  State<_IssuesSection> createState() => _IssuesSectionState();
}

class _IssuesSectionState extends State<_IssuesSection> {
  late ProjectIssueProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ProjectIssueProvider(projectId: widget.projectId)..loadIssues();
  }

  @override
  void didUpdateWidget(covariant _IssuesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId) {
      _provider.dispose();
      _provider = ProjectIssueProvider(projectId: widget.projectId)
        ..loadIssues(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProjectIssueProvider>.value(
      value: _provider,
      child: Consumer<ProjectIssueProvider>(
        builder: (context, issueProvider, _) {
          final issues = issueProvider.issues;
          return _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrimaryActionButton(
                  label: 'Report New Issue',
                  onTap: issueProvider.isSaving
                      ? () {}
                      : _openCreateIssueDialog,
                ),
                const SizedBox(height: 16),
                if (issueProvider.isLoading && issues.isEmpty)
                  const _EmptySectionState(message: 'Loading issues...')
                else if (issueProvider.errorMessage != null && issues.isEmpty)
                  _EmptySectionState(message: issueProvider.errorMessage!)
                else if (issues.isEmpty)
                  const _EmptySectionState(message: 'No issues available.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: issues.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final issue = issues[index];
                      return _IssueCard(
                        issue: issue,
                        onEdit: () => _openEditIssueDialog(issue),
                        onDelete: () => _deleteIssue(issue),
                        isDeleting: issueProvider.isDeletingIssue(issue.id),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateIssueDialog() async {
    final request = await showDialog<_IssueFormRequest>(
      context: context,
      builder: (_) => const _IssueFormDialog(mode: _IssueFormMode.create),
    );
    if (request == null || !mounted) return;
    try {
      await _provider.createIssue(
        issueDescription: request.issueDescription,
        priority: request.priority,
        status: request.status,
      );
      if (!mounted) return;
      _showSnack('Issue reported successfully');
    } catch (error) {
      if (!mounted) return;
      _showSnack(_provider.errorMessage ?? error.toString());
    }
  }

  Future<void> _openEditIssueDialog(ProjectIssueModel issue) async {
    final request = await showDialog<_IssueFormRequest>(
      context: context,
      builder: (_) => _IssueFormDialog(
        mode: _IssueFormMode.edit,
        initialDescription: issue.issueDescription,
        initialPriority: issue.priority,
        initialStatus: issue.status,
      ),
    );
    if (request == null || !mounted) return;
    final issueId = issue.id.trim();
    if (issueId.isEmpty) {
      _showSnack('Unable to edit issue: missing issue id');
      return;
    }
    try {
      await _provider.updateIssue(
        issueId: issueId,
        issueDescription: request.issueDescription,
        priority: request.priority,
        status: request.status,
      );
      if (!mounted) return;
      _showSnack('Issue updated successfully');
    } catch (error) {
      if (!mounted) return;
      _showSnack(_provider.errorMessage ?? error.toString());
    }
  }

  Future<void> _deleteIssue(ProjectIssueModel issue) async {
    final issueId = issue.id.trim();
    if (issueId.isEmpty) {
      _showSnack('Unable to delete issue: missing issue id');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Issue'),
        content: const Text('Delete this issue permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await _provider.deleteIssue(issueId);
      if (!mounted) return;
      _showSnack('Issue deleted successfully');
    } catch (error) {
      if (!mounted) return;
      _showSnack(_provider.errorMessage ?? error.toString());
    }
  }

  void _showSnack(String message) {
    AppSnackbar.show('Notice', message);
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
  });

  final ProjectIssueModel issue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final priorityColors = _priorityColors(issue.priority);
    final statusColors = _statusColors(issue.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            issue.issueDescription.trim().isEmpty
                ? '--'
                : issue.issueDescription.trim(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: ProjectDetailScreen.title,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Badge(
                label: _toTitleCase(issue.priority),
                bg: priorityColors.background,
                fg: priorityColors.foreground,
              ),
              _Badge(
                label: _toTitleCase(issue.status),
                bg: statusColors.background,
                fg: statusColors.foreground,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ProjectDetailScreen.blue,
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    'Edit',
                    style: AppTextStyles.style(
                      color: ProjectDetailScreen.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isDeleting ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  icon: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    isDeleting ? 'Deleting...' : 'Delete',
                    style: AppTextStyles.style(
                      color: const Color(0xFFDC2626),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _toTitleCase(String value) {
    final source = value.trim().replaceAll('_', ' ');
    if (source.isEmpty) return '--';
    return source
        .split(RegExp(r'\s+'))
        .where((entry) => entry.isNotEmpty)
        .map((word) {
          if (word.length == 1) return word.toUpperCase();
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}

enum _IssueFormMode { create, edit }

class _IssueFormRequest {
  const _IssueFormRequest({
    required this.issueDescription,
    required this.priority,
    required this.status,
  });

  final String issueDescription;
  final String priority;
  final String status;
}

class _IssueFormDialog extends StatefulWidget {
  const _IssueFormDialog({
    required this.mode,
    this.initialDescription = '',
    this.initialPriority = '',
    this.initialStatus = '',
  });

  final _IssueFormMode mode;
  final String initialDescription;
  final String initialPriority;
  final String initialStatus;

  @override
  State<_IssueFormDialog> createState() => _IssueFormDialogState();
}

class _IssueFormDialogState extends State<_IssueFormDialog> {
  static const List<String> _priorityOptions = ['Low', 'Medium', 'High'];
  static const List<String> _statusOptions = [
    'Open',
    'In Progress',
    'Resolved',
    'Closed',
  ];

  late final TextEditingController _descriptionController;
  late String _selectedPriority;
  late String _selectedStatus;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialDescription.trim(),
    );
    _selectedPriority = _resolveInitialOption(
      raw: widget.initialPriority,
      options: _priorityOptions,
      fallback: 'Medium',
    );
    _selectedStatus = _resolveInitialOption(
      raw: widget.initialStatus,
      options: _statusOptions,
      fallback: 'Open',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _resolveInitialOption({
    required String raw,
    required List<String> options,
    required String fallback,
  }) {
    final value = raw.trim().toLowerCase().replaceAll('_', ' ');
    if (value.isEmpty) return fallback;
    for (final option in options) {
      if (option.toLowerCase() == value) {
        return option;
      }
    }
    return fallback;
  }

  void _submit() {
    final issueDescription = _descriptionController.text.trim();
    if (issueDescription.isEmpty) {
      setState(() => _inlineError = 'Please enter issue description');
      return;
    }

    setState(() => _inlineError = null);
    Navigator.of(context).pop(
      _IssueFormRequest(
        issueDescription: issueDescription,
        priority: _selectedPriority,
        status: _selectedStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.mode == _IssueFormMode.create
        ? 'Report New Issue'
        : 'Edit Issue';
    final actionLabel = widget.mode == _IssueFormMode.create
        ? 'Report Issue'
        : 'Update Issue';

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        heading,
                        style: AppTextStyles.style(
                          color: const Color(0xFF374151),
                          fontSize: 33,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),
                const _DialogLabel(text: 'Issue Description'),
                const SizedBox(height: 8),
                _DialogInput(
                  height: 110,
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: 'Describe the issue in detail...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _DialogLabel(text: 'Priority'),
                          const SizedBox(height: 8),
                          _DialogInput(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPriority,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF374151),
                                ),
                                items: _priorityOptions
                                    .map(
                                      (priority) => DropdownMenuItem(
                                        value: priority,
                                        child: Text(
                                          priority,
                                          style: AppTextStyles.style(
                                            color: const Color(0xFF374151),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedPriority = value);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _DialogLabel(text: 'Status'),
                          const SizedBox(height: 8),
                          _DialogInput(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF374151),
                                ),
                                items: _statusOptions
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: AppTextStyles.style(
                                            color: const Color(0xFF374151),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedStatus = value);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_inlineError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _inlineError!,
                    style: AppTextStyles.style(
                      color: const Color(0xFFB42318),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFF9CA3AF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(78, 40),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF43F5E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(124, 40),
                      ),
                      child: Text(
                        actionLabel,
                        style: AppTextStyles.style(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _CommentsSection extends StatefulWidget {
  const _CommentsSection({required this.projectId});

  final String projectId;

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<ProjectCommentModel>> _future;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _CommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _future = _load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<ProjectCommentModel>> _load() async {
    final projectId = widget.projectId.trim();
    if (projectId.isEmpty) {
      return const [];
    }
    return ApiService.instance.getProjectComments(projectId);
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _submitError = 'Please enter a comment.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await ApiService.instance.createProjectComment(
        projectId: widget.projectId.trim(),
        comment: text,
      );
      _controller.clear();
      if (!mounted) return;
      setState(() {
        _future = _load();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: AppTextStyles.style(
              color: ProjectDetailScreen.title,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFDFE7F2), height: 1),
          const SizedBox(height: 14),
          FutureBuilder<List<ProjectCommentModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: _EmptySectionState(message: 'Loading comments...'),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unable to load comments. Pull to refresh or retry.',
                        style: AppTextStyles.style(
                          color: const Color(0xFFB42318),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _future = _load();
                        }),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final comments = snapshot.data ?? const <ProjectCommentModel>[];
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: _EmptySectionState(message: 'No comments yet.'),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: comments
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _CommentItem(comment: entry),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD2DAE6)),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              onChanged: (_) {
                if (_submitError != null) {
                  setState(() => _submitError = null);
                }
              },
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: AppTextStyles.style(
                  color: const Color(0xFF637184),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: 8),
            Text(
              _submitError!,
              style: AppTextStyles.style(
                color: const Color(0xFFB42318),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitComment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D8CF8),
              foregroundColor: Colors.white,
              minimumSize: const Size(138, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Post Comment',
                    style: AppTextStyles.style(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({required this.comment});

  final ProjectCommentModel comment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(name: comment.userName, imageUrl: comment.userAvatarUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.userName,
                style: AppTextStyles.style(
                  color: ProjectDetailScreen.title,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                comment.comment,
                style: AppTextStyles.style(
                  color: ProjectDetailScreen.title,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _timeAgo(comment.createdAtRaw),
                style: AppTextStyles.style(
                  color: ProjectDetailScreen.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilesSection extends StatefulWidget {
  const _FilesSection({required this.projectId});

  final String projectId;

  @override
  State<_FilesSection> createState() => _FilesSectionState();
}

class _FilesSectionState extends State<_FilesSection> {
  static const String _fileHost = 'https://mycrm.technofra.com/';
  late Future<List<ProjectFileRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _FilesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId) {
      _future = _load();
    }
  }

  Future<List<ProjectFileRecord>> _load() async {
    final projectId = widget.projectId.trim();
    if (projectId.isEmpty) {
      return const [];
    }
    return ApiService.instance.getProjectFiles(projectId);
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Project Files',
                  style: AppTextStyles.style(
                    color: ProjectDetailScreen.title,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _PrimaryActionButton(label: 'Create', onTap: _showUploadDialog),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<ProjectFileRecord>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _EmptySectionState(message: 'Loading files...');
              }

              if (snapshot.hasError) {
                return Column(
                  children: [
                    const _EmptySectionState(
                      message: 'Unable to load project files.',
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                );
              }

              final files = snapshot.data ?? const <ProjectFileRecord>[];

              if (files.isEmpty) {
                return const _EmptySectionState(
                  message: 'No files available for this project.',
                );
              }

              return Column(
                children: [
                  ...files.map((file) {
                    final fileUrl = _resolveFileUrl(file);
                    return Column(
                      children: [
                        _FileRow(
                          file: file,
                          previewUrl: fileUrl,
                          onDownload: () => _downloadFile(file),
                          onDelete: () => _showDeleteInfo(file),
                        ),
                        if (file != files.last) const SizedBox(height: 14),
                      ],
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _showUploadDialog() async {
    final request = await showDialog<_ProjectFileUploadRequest>(
      context: context,
      builder: (_) => const _ProjectFileUploadDialog(),
    );

    if (request == null) return;

    try {
      await ApiService.instance.createProjectFile(
        projectId: widget.projectId.trim(),
        filePath: request.filePath,
        description: request.description,
      );
      if (!mounted) return;
      _showSnack('File uploaded successfully');
      _reload();
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to upload file');
    }
  }

  void _downloadFile(ProjectFileRecord file) async {
    final url = _resolveFileUrl(file);
    if (url.isEmpty) {
      _showSnack('No download link available');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack('Invalid file link');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    _showSnack(
      opened ? 'Opening download link...' : 'Unable to open file link',
    );
  }

  Future<void> _showDeleteInfo(ProjectFileRecord file) async {
    final name = file.name.trim().isEmpty ? 'this file' : file.name.trim();
    final fileId = file.id.trim();
    if (fileId.isEmpty) {
      _showSnack('Unable to delete $name (missing file id)');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.instance.deleteProjectFile(
        projectId: widget.projectId.trim(),
        fileId: fileId,
      );
      if (!mounted) return;
      _showSnack('File deleted successfully');
      _reload();
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to delete $name');
    }
  }

  String _resolveFileUrl(ProjectFileRecord file) {
    final raw = file.url.trim().replaceAll('\\', '/');
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final normalizedBase = _fileHost.endsWith('/') ? _fileHost : '$_fileHost/';
    final normalizedPath = raw.startsWith('/') ? raw.substring(1) : raw;
    return '$normalizedBase$normalizedPath';
  }

  void _showSnack(String message) {
    AppSnackbar.show('Notice', message);
  }
}

class _ProjectFileUploadRequest {
  const _ProjectFileUploadRequest({
    required this.filePath,
    required this.description,
  });

  final String filePath;
  final String description;
}

class _ProjectFileUploadDialog extends StatefulWidget {
  const _ProjectFileUploadDialog();

  @override
  State<_ProjectFileUploadDialog> createState() =>
      _ProjectFileUploadDialogState();
}

class _ProjectFileUploadDialogState extends State<_ProjectFileUploadDialog> {
  static const int _maxUploadBytes = 10 * 1024 * 1024;
  static const List<String> _supportedUploadExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'svg',
    'webp',
    'bmp',
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'zip',
    'rar',
  ];

  final TextEditingController _descriptionController = TextEditingController();
  PlatformFile? _selectedFile;
  String? _inlineError;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: _supportedUploadExtensions,
      withData: false,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final candidate = result.files.first;
    if (candidate.size > _maxUploadBytes) {
      setState(() {
        _inlineError = 'Selected file exceeds 10MB limit';
      });
      return;
    }

    setState(() {
      _selectedFile = candidate;
      _inlineError = null;
    });
  }

  void _submit() {
    final selected = _selectedFile;
    if (selected == null) {
      setState(() {
        _inlineError = 'Please choose a file first';
      });
      return;
    }

    final filePath = selected.path?.trim() ?? '';
    if (filePath.isEmpty) {
      setState(() {
        _inlineError = 'Unable to read selected file path';
      });
      return;
    }

    Navigator.of(context).pop(
      _ProjectFileUploadRequest(
        filePath: filePath,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedName = _selectedFile?.name.trim() ?? '';
    final hasSelection = selectedName.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Upload File',
                        style: AppTextStyles.style(
                          color: ProjectDetailScreen.title,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22, color: Color(0xFFE5E7EB)),
                Text(
                  'Select File',
                  style: AppTextStyles.style(
                    color: const Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _pickFile,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1F2937),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              bottomLeft: Radius.circular(6),
                            ),
                          ),
                          minimumSize: const Size(96, 44),
                        ),
                        child: const Text('Choose File'),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: const Color(0xFFE5E7EB),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasSelection ? selectedName : 'No file chosen',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.style(
                            color: const Color(0xFF4B5563),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supported formats: JPG, JPEG, PNG, GIF, SVG, WEBP, BMP, PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT, ZIP, RAR (Max 10MB)',
                  style: AppTextStyles.style(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if ((_inlineError ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _inlineError!,
                    style: AppTextStyles.style(
                      color: const Color(0xFFDC2626),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Description (Optional)',
                  style: AppTextStyles.style(
                    color: const Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add a description for this file...',
                    hintStyle: AppTextStyles.style(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: ProjectDetailScreen.blue,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4B5563),
                        side: const BorderSide(color: Color(0xFF9CA3AF)),
                        minimumSize: const Size(88, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D8CF8),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Upload'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.previewUrl,
    required this.onDownload,
    required this.onDelete,
  });

  final ProjectFileRecord file;
  final String previewUrl;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final meta = _buildMeta();
    final iconData = _iconForExt(file.extension);
    final colors = _colorsForExt(file.extension);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(iconData, color: colors.foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name.trim().isEmpty ? 'Untitled file' : file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.style(
                        color: ProjectDetailScreen.title,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.style(
                          color: ProjectDetailScreen.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilePreview(file: file, previewUrl: previewUrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProjectDetailScreen.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 6,
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    'Download',
                    style: AppTextStyles.style(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    'Delete',
                    style: AppTextStyles.style(
                      color: const Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildMeta() {
    final parts = <String>[];
    if (file.sizeBytes != null) {
      parts.add(_formatBytes(file.sizeBytes!));
    }
    if (file.uploadedOn.trim().isNotEmpty) {
      parts.add(file.uploadedOn.trim());
    }
    if (file.extension.isNotEmpty) {
      parts.add(file.extension.toUpperCase());
    }
    return parts.join(' | ');
  }

  static IconData _iconForExt(String ext) {
    if (const {'pdf'}.contains(ext)) return Icons.picture_as_pdf_rounded;
    if (const {'doc', 'docx', 'txt', 'rtf'}.contains(ext)) {
      return Icons.description_rounded;
    }
    if (const {'xls', 'xlsx', 'csv'}.contains(ext)) {
      return Icons.grid_on_rounded;
    }
    if (const {'ppt', 'pptx'}.contains(ext)) {
      return Icons.slideshow_rounded;
    }
    if (const {'zip', 'rar', '7z', 'tar', 'gz'}.contains(ext)) {
      return Icons.folder_zip_rounded;
    }
    if (const {
      'png',
      'jpg',
      'jpeg',
      'gif',
      'webp',
      'bmp',
      'svg',
      'heic',
    }.contains(ext)) {
      return Icons.image_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  static _BadgeColors _colorsForExt(String ext) {
    if (ext == 'pdf') {
      return const _BadgeColors(Color(0xFFFEE2E2), Color(0xFFDC2626));
    }
    if (const {
      'png',
      'jpg',
      'jpeg',
      'gif',
      'webp',
      'bmp',
      'svg',
      'heic',
    }.contains(ext)) {
      return const _BadgeColors(Color(0xFFDCFCE7), Color(0xFF16A34A));
    }
    if (const {'xls', 'xlsx', 'csv'}.contains(ext)) {
      return const _BadgeColors(Color(0xFFDCFCE7), Color(0xFF15803D));
    }
    if (const {'doc', 'docx', 'txt', 'rtf'}.contains(ext)) {
      return const _BadgeColors(Color(0xFFDBEAFE), Color(0xFF2563EB));
    }
    return const _BadgeColors(Color(0xFFEFF6FF), Color(0xFF3F7EF7));
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    final mb = kb / 1024.0;
    if (mb < 1024) return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
    final gb = mb / 1024.0;
    return '${gb.toStringAsFixed(gb < 10 ? 1 : 0)} GB';
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.file, required this.previewUrl});

  final ProjectFileRecord file;
  final String previewUrl;

  @override
  Widget build(BuildContext context) {
    if (_isImage(file.extension) && previewUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            previewUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _DocumentPreviewCard(file: file, expanded: false),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFFF1F5F9),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              );
            },
          ),
        ),
      );
    }

    return _DocumentPreviewCard(file: file, expanded: false);
  }

  static bool _isImage(String ext) => const {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'bmp',
    'svg',
    'heic',
  }.contains(ext);
}

class _DocumentPreviewCard extends StatelessWidget {
  const _DocumentPreviewCard({required this.file, required this.expanded});

  final ProjectFileRecord file;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final icon = _FileRow._iconForExt(file.extension);
    final colors = _FileRow._colorsForExt(file.extension);
    final height = expanded ? 260.0 : 150.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8E1EF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: colors.foreground, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              file.name.trim().isEmpty ? 'Untitled document' : file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: ProjectDetailScreen.title,
                fontSize: expanded ? 16 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              file.extension.isEmpty
                  ? 'Document preview'
                  : '${file.extension.toUpperCase()} document',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: ProjectDetailScreen.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        ),
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
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
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

class _UsageColors {
  const _UsageColors({
    required this.background,
    required this.foreground,
    required this.gradient,
  });

  final Color background;
  final Color foreground;
  final List<Color> gradient;
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ProjectDetailScreen.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ProjectDetailScreen.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120F172A),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _UsageSection extends StatefulWidget {
  const _UsageSection({required this.projectId});

  final String projectId;

  @override
  State<_UsageSection> createState() => _UsageSectionState();
}

class _UsageSectionState extends State<_UsageSection> {
  late Future<ProjectUsageModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ProjectUsageModel> _load() async {
    return ApiService.instance.getProjectUsage(widget.projectId);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProjectUsageModel>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StateCard(
            icon: Icons.pie_chart_outline_rounded,
            title: 'Loading usage statistics...',
          );
        }

        if (snapshot.hasError) {
          return _UsageErrorCard(onRetry: _reload);
        }

        final usage = snapshot.data;
        if (usage == null) {
          return const _Card(
            child: _EmptySectionState(
              message: 'No usage statistics available.',
            ),
          );
        }

        final statuses = usage.statuses;
        return _Card(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = constraints.maxWidth < 360 ? 210.0 : 230.0;
              const cardSpacing = 12.0;
              final itemWidth = constraints.maxWidth < 520
                  ? (constraints.maxWidth - cardSpacing) / 2
                  : (constraints.maxWidth - (cardSpacing * 2)) / 3;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Usage Statistics',
                    style: AppTextStyles.style(
                      color: ProjectDetailScreen.title,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Task status distribution',
                    style: AppTextStyles.style(
                      color: ProjectDetailScreen.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: SizedBox(
                      width: chartSize,
                      height: chartSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size.square(chartSize),
                            painter: _UsageDonutPainter(statuses: statuses),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${usage.totalTasks}',
                                style: AppTextStyles.style(
                                  color: ProjectDetailScreen.title,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total tasks',
                                style: AppTextStyles.style(
                                  color: ProjectDetailScreen.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: cardSpacing,
                    runSpacing: cardSpacing,
                    children: statuses
                        .map(
                          (status) => SizedBox(
                            width: itemWidth,
                            child: _UsageLegendCard(stat: status),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _UsageLegendCard extends StatelessWidget {
  const _UsageLegendCard({required this.stat});

  final ProjectUsageStat stat;

  @override
  Widget build(BuildContext context) {
    final colors = _usageColors(stat.key);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.background,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stat.label,
                  style: AppTextStyles.style(
                    color: ProjectDetailScreen.title,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${stat.percentage.toStringAsFixed(1)}%',
            style: AppTextStyles.style(
              color: ProjectDetailScreen.title,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${stat.taskCount} tasks',
            style: AppTextStyles.style(
              color: ProjectDetailScreen.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (stat.percentage / 100).clamp(0, 1),
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(colors.background),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageDonutPainter extends CustomPainter {
  const _UsageDonutPainter({required this.statuses});

  final List<ProjectUsageStat> statuses;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.2;
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFE9EEF5);

    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    final total = statuses.fold<int>(0, (sum, item) => sum + item.taskCount);
    if (total <= 0) {
      return;
    }

    double startAngle = -math.pi / 2;
    for (final status in statuses) {
      if (status.taskCount <= 0) {
        continue;
      }

      final sweepAngle = (status.taskCount / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: _usageColors(status.key).gradient,
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _UsageDonutPainter oldDelegate) {
    return oldDelegate.statuses != statuses;
  }
}

class _UsageErrorCard extends StatelessWidget {
  const _UsageErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          const Icon(
            Icons.pie_chart_outline_rounded,
            size: 34,
            color: Color(0xFFB42318),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load usage statistics',
            style: AppTextStyles.style(
              color: ProjectDetailScreen.title,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Retry the request to fetch project usage data.',
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: ProjectDetailScreen.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: ProjectDetailScreen.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppTextStyles.style(
        color: fg,
        fontSize: 11,
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
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: AppTextStyles.style(
          color: ProjectDetailScreen.title,
          fontSize: 14,
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.16)),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: AppTextStyles.style(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.style(
            color: color,
            fontSize: 10,
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: accent ? const Color(0xFFEAF1FF) : const Color(0xFFF2F5F9),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppTextStyles.style(
        color: accent ? ProjectDetailScreen.blue : const Color(0xFF53657E),
        fontSize: 11,
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
            fontSize: 13,
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
            fontSize: 13,
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
        Icon(icon, size: 28, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 10),
        Text(
          title,
          style: AppTextStyles.style(
            color: ProjectDetailScreen.title,
            fontSize: 14,
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
        const Icon(Icons.cloud_off_rounded, size: 28, color: Color(0xFFB42318)),
        const SizedBox(height: 10),
        Text(
          'Unable to load project details',
          style: AppTextStyles.style(
            color: ProjectDetailScreen.title,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pull to refresh or retry the request.',
          textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: ProjectDetailScreen.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              backgroundColor: const Color(0xFF1D6FEA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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

String _timeAgo(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return 'Just now';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final localTime = parsed.toLocal();
  final diff = DateTime.now().difference(localTime);

  if (diff.inSeconds < 60) {
    return '${diff.inSeconds.clamp(1, 59)} second${diff.inSeconds == 1 ? '' : 's'} ago';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  return '${localTime.day.toString().padLeft(2, '0')}-'
      '${localTime.month.toString().padLeft(2, '0')}-'
      '${localTime.year}';
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
  if (value.contains('resolved') || value.contains('closed')) {
    return const _BadgeColors(Color(0xFFDCFCE7), Color(0xFF16A34A));
  }
  if (value.contains('open')) {
    return const _BadgeColors(Color(0xFFDBEAFE), Color(0xFF2563EB));
  }
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

_UsageColors _usageColors(String key) {
  switch (key) {
    case 'not_started':
      return const _UsageColors(
        background: Color(0xFF6B7280),
        foreground: Colors.white,
        gradient: [Color(0xFF6B7280), Color(0xFF94A3B8)],
      );
    case 'in_progress':
      return const _UsageColors(
        background: Color(0xFF1D8BFF),
        foreground: Colors.white,
        gradient: [Color(0xFF4F6AE0), Color(0xFF2DD4BF)],
      );
    case 'on_hold':
      return const _UsageColors(
        background: Color(0xFFFBBF24),
        foreground: Colors.white,
        gradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      );
    case 'completed':
      return const _UsageColors(
        background: Color(0xFF22C55E),
        foreground: Colors.white,
        gradient: [Color(0xFF4ADE80), Color(0xFF16A34A)],
      );
    case 'cancelled':
      return const _UsageColors(
        background: Color(0xFFF43F5E),
        foreground: Colors.white,
        gradient: [Color(0xFFF87171), Color(0xFFE11D48)],
      );
    default:
      return const _UsageColors(
        background: Color(0xFFCBD5E1),
        foreground: Color(0xFF1E2740),
        gradient: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
      );
  }
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
