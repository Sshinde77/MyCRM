import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/services/api_service.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    this.initialTaskData,
  });

  final String taskId;
  final Map<String, dynamic>? initialTaskData;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    try {
      return await ApiService.instance.getTaskDetail(widget.taskId);
    } catch (_) {
      if (widget.initialTaskData != null) {
        return widget.initialTaskData!;
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              widget.initialTaskData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && widget.initialTaskData == null) {
            final message = snapshot.error is DioException
                ? (((snapshot.error as DioException).response?.data is Map &&
                          (snapshot.error as DioException)
                                  .response
                                  ?.data['message'] !=
                              null)
                      ? (snapshot.error as DioException)
                            .response!
                            .data['message']
                            .toString()
                      : (snapshot.error as DioException).message ??
                            'Unable to load task details.')
                : 'Unable to load task details.';
            return _TaskDetailError(
              message: message,
              onRetry: () {
                setState(() {
                  _future = _load();
                });
              },
            );
          }

          final source = snapshot.data ?? widget.initialTaskData ?? const {};
          final detail = _TaskDetailData.fromMap(source);

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailTopBar(
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(height: 18),
                        _TaskHero(detail: detail),
                        const SizedBox(height: 24),
                        wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 8,
                                    child: _TaskInformationCard(detail: detail),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        _PeopleCard(
                                          title: 'Assignees & Followers',
                                          assignees: detail.assignees,
                                          followers: detail.followers,
                                        ),
                                        const SizedBox(height: 24),
                                        _AttachmentsCard(
                                          attachments: detail.attachments,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _TaskInformationCard(detail: detail),
                                  const SizedBox(height: 20),
                                  _PeopleCard(
                                    title: 'Assignees & Followers',
                                    assignees: detail.assignees,
                                    followers: detail.followers,
                                  ),
                                  const SizedBox(height: 20),
                                  _AttachmentsCard(
                                    attachments: detail.attachments,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TaskInformationCard extends StatelessWidget {
  const _TaskInformationCard({required this.detail});

  final _TaskDetailData detail;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Task Information',
      accent: const Color(0xFF1677FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth >= 620;
              final children = [
                _MetricCard(
                  icon: Icons.work_outline_rounded,
                  label: 'Project',
                  value: detail.projectName,
                  accent: const Color(0xFF1677FF),
                ),
              ];

              if (!twoColumn) {
                return Column(
                  children: [
                    for (final child in children) ...[child],
                  ],
                );
              }

              return Wrap(
                spacing: 32,
                runSpacing: 28,
                children: children
                    .map(
                      (child) => SizedBox(
                        width: (constraints.maxWidth - 32) / 2,
                        child: child,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          _ContentBlock(
            title: 'Description',
            child: Text(
              detail.description,
              style: AppTextStyles.style(
                color: const Color(0xFF334155),
                fontSize: 14,
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _ContentBlock(
            title: 'Tags',
            child: detail.tags.isEmpty
                ? const _SoftEmpty(
                    icon: Icons.sell_outlined,
                    message: 'No tags added to this task',
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: detail.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5B6778), Color(0xFF7A879A)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A334155),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              tag,
                              style: AppTextStyles.style(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({
    required this.title,
    required this.assignees,
    required this.followers,
  });

  final String title;
  final List<_PersonData> assignees;
  final List<_PersonData> followers;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: title,
      accent: const Color(0xFF0F9D7A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeopleSection(label: 'Assignees', people: assignees),
          const SizedBox(height: 20),
          _PeopleSection(label: 'Followers', people: followers),
        ],
      ),
    );
  }
}

class _AttachmentsCard extends StatelessWidget {
  const _AttachmentsCard({required this.attachments});

  final List<_AttachmentData> attachments;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Attachments',
      accent: const Color(0xFF7C3AED),
      child: attachments.isEmpty
          ? const _SoftEmpty(
              icon: Icons.attach_file_rounded,
              message: 'No attachments uploaded yet',
            )
          : Column(
              children: attachments
                  .map(
                    (attachment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.attach_file_rounded,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              attachment.name,
                              style: AppTextStyles.style(
                                color: const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _PeopleSection extends StatelessWidget {
  const _PeopleSection({required this.label, required this.people});

  final String label;
  final List<_PersonData> people;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        if (people.isEmpty)
          _SoftEmpty(
            icon: Icons.people_outline_rounded,
            message: 'No ${label.toLowerCase()} added',
          )
        else
          Column(
            children: people
                .map(
                  (person) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          _PersonAvatar(
                            imageUrl: person.imageUrl,
                            name: person.name,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person.name,
                                  style: AppTextStyles.style(
                                    color: const Color(0xFF0F172A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if ((person.role ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    person.role!,
                                    style: AppTextStyles.style(
                                      color: const Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.child,
    this.accent = const Color(0xFF1677FF),
  });

  final String title;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 24,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.style(
                          color: const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Details',
                style: AppTextStyles.style(
                  color: const Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Review task information, people, and attachments.',
                style: AppTextStyles.style(
                  color: const Color(0xFF64748B),
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

class _TaskHero extends StatelessWidget {
  const _TaskHero({required this.detail});

  final _TaskDetailData detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(
            detail.title,
            style: AppTextStyles.style(
              color: const Color(0xFF0F172A),
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroStat(label: 'Priority', value: detail.priority),
              _HeroStat(label: 'Status', value: detail.status),
              _HeroStat(label: 'start Date', value: detail.startDateText),
              _HeroStat(label: 'Due Date', value: detail.deadlineText),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF1677FF)),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.style(
              color: const Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.style(
                    color: const Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _ContentBlock extends StatelessWidget {
  const _ContentBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.style(
              color: const Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SoftEmpty extends StatelessWidget {
  const _SoftEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.style(
                color: const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFE2E8F0),
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE7F0FF),
      child: Text(
        initials,
        style: AppTextStyles.style(
          color: const Color(0xFF1D4ED8),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TaskDetailError extends StatelessWidget {
  const _TaskDetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFBE123C)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.style(
                color: const Color(0xFF9F1239),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _TaskDetailData {
  const _TaskDetailData({
    required this.id,
    required this.title,
    required this.projectName,
    required this.priority,
    required this.status,
    required this.description,
    required this.startDate,
    required this.deadline,
    required this.totalHours,
    required this.tags,
    required this.assignees,
    required this.followers,
    required this.attachments,
  });

  final String id;
  final String title;
  final String projectName;
  final String priority;
  final String status;
  final String description;
  final DateTime? startDate;
  final DateTime? deadline;
  final String totalHours;
  final List<String> tags;
  final List<_PersonData> assignees;
  final List<_PersonData> followers;
  final List<_AttachmentData> attachments;

  String get displayId => id.isEmpty ? '--' : '#$id';
  String get startDateText => _formatDisplayDate(startDate);
  String get deadlineText => _formatDisplayDate(deadline);

  factory _TaskDetailData.fromMap(Map<String, dynamic> source) {
    return _TaskDetailData(
      id: _readString(source, const ['id', 'task_id']) ?? '',
      title:
          _readString(source, const ['title', 'name', 'task_title']) ??
          'Untitled Task',
      projectName: _readProjectName(source),
      priority:
          _readString(source, const ['priority', 'priority_level']) ?? 'Normal',
      status: _readString(source, const ['status', 'task_status']) ?? 'Pending',
      description:
          _readString(source, const ['description', 'details']) ??
          'No description available.',
      startDate: _tryParseDate(
        _readString(source, const ['start_date', 'starts_on', 'created_at']),
      ),
      deadline: _tryParseDate(
        _readString(source, const ['deadline', 'due_date', 'end_date']),
      ),
      totalHours:
          _readString(source, const ['total_hours', 'hours', 'worked_hours']) ??
          'N/A',
      tags: _readStringList(source['tags']),
      assignees: _readPeople(source, const [
        'assignees',
        'assigned_to',
        'assigned',
      ]),
      followers: _readPeople(source, const ['followers', 'watchers']),
      attachments: _readAttachments(source),
    );
  }
}

class _PersonData {
  const _PersonData({required this.name, this.role, this.imageUrl});

  final String name;
  final String? role;
  final String? imageUrl;
}

class _AttachmentData {
  const _AttachmentData({required this.name, this.url});

  final String name;
  final String? url;
}

List<_PersonData> _readPeople(Map<String, dynamic> source, List<String> keys) {
  dynamic raw;
  for (final key in keys) {
    if (source[key] != null) {
      raw = source[key];
      break;
    }
  }

  if (raw is! List) {
    return const [];
  }

  return raw.map((entry) {
    final item = _normalizeMap(entry);
    return _PersonData(
      name:
          _readString(item, const ['name', 'full_name', 'first_name']) ??
          'Unknown',
      role: _readString(item, const ['role', 'type', 'designation']),
      imageUrl: _readString(item, const [
        'profile_image',
        'avatar',
        'image',
        'photo',
      ]),
    );
  }).toList();
}

List<_AttachmentData> _readAttachments(Map<String, dynamic> source) {
  final raw = source['attachments'];
  if (raw is! List) {
    return const [];
  }

  return raw.map((entry) {
    if (entry is String) {
      return _AttachmentData(name: entry, url: entry);
    }

    final item = _normalizeMap(entry);
    return _AttachmentData(
      name:
          _readString(item, const ['name', 'file_name', 'filename', 'title']) ??
          'Attachment',
      url: _readString(item, const ['url', 'file', 'path']),
    );
  }).toList();
}

List<String> _readStringList(dynamic value) {
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
        return '';
      })
      .where((entry) => entry.isNotEmpty)
      .toList();
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
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

(Color, Color) _statusPalette(String status) {
  final value = status.trim().toLowerCase();
  if (value == 'completed' || value == 'done' || value == 'closed') {
    return (const Color(0xFFE8F8EE), const Color(0xFF15803D));
  }
  if (value == 'in progress' || value == 'running' || value == 'active') {
    return (const Color(0xFFE7F0FF), const Color(0xFF1D4ED8));
  }
  if (value == 'on hold') {
    return (const Color(0xFFE2E8F0), const Color(0xFF475569));
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
    return (const Color(0xFFFFF0B3), const Color(0xFF8A6200));
  }
  if (value == 'low') {
    return (const Color(0xFFE8F8EE), const Color(0xFF16A34A));
  }
  return (const Color(0xFFF1F5F9), const Color(0xFF475569));
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((entry) => entry.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
