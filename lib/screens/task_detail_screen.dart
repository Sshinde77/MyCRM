import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/project_comment_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

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
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailTopBar(
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(height: 12),
                        _TaskHero(detail: detail),
                        const SizedBox(height: 16),
                        wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 8,
                                    child: _TaskInformationCard(detail: detail),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        _PeopleCard(
                                          title: 'Assignees & Followers',
                                          assignees: detail.assignees,
                                          followers: detail.followers,
                                        ),
                                        const SizedBox(height: 16),
                                        _AttachmentsCard(
                                          attachments: detail.attachments,
                                        ),
                                        const SizedBox(height: 16),
                                        _TaskCommentsCard(
                                          taskId: widget.taskId,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _TaskInformationCard(detail: detail),
                                  const SizedBox(height: 14),
                                  _PeopleCard(
                                    title: 'Assignees & Followers',
                                    assignees: detail.assignees,
                                    followers: detail.followers,
                                  ),
                                  const SizedBox(height: 14),
                                  _AttachmentsCard(
                                    attachments: detail.attachments,
                                  ),
                                  const SizedBox(height: 14),
                                  _TaskCommentsCard(taskId: widget.taskId),
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

class _TaskCommentsCard extends StatefulWidget {
  const _TaskCommentsCard({required this.taskId});

  final String taskId;

  @override
  State<_TaskCommentsCard> createState() => _TaskCommentsCardState();
}

class _TaskCommentsCardState extends State<_TaskCommentsCard> {
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
  void didUpdateWidget(covariant _TaskCommentsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId) {
      _future = _load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<ProjectCommentModel>> _load() async {
    final taskId = widget.taskId.trim();
    if (taskId.isEmpty) {
      return const [];
    }
    return ApiService.instance.getTaskComments(taskId);
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
      await ApiService.instance.createTaskComment(
        taskId: widget.taskId.trim(),
        comment: text,
      );
      _controller.clear();
      if (!mounted) return;
      setState(() {
        _future = _load();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (error is DioException &&
            error.response?.data is Map &&
            error.response?.data['message'] != null) {
          _submitError = error.response!.data['message'].toString();
        } else {
          _submitError = 'Unable to post comment. Please try again.';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Comments',
      accent: const Color(0xFF1D8CF8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<List<ProjectCommentModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: _SoftEmpty(
                    icon: Icons.chat_bubble_outline_rounded,
                    message: 'Loading comments...',
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unable to load comments.',
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
                  child: _SoftEmpty(
                    icon: Icons.chat_bubble_outline_rounded,
                    message: 'No comments yet.',
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: comments
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _TaskCommentItem(comment: entry),
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

class _TaskCommentItem extends StatelessWidget {
  const _TaskCommentItem({required this.comment});

  final ProjectCommentModel comment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PersonAvatar(imageUrl: comment.userAvatarUrl, name: comment.userName),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.userName,
                style: AppTextStyles.style(
                  color: const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                comment.comment,
                style: AppTextStyles.style(
                  color: const Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _timeAgo(comment.createdAtRaw),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                          fontSize: 16,
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
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return CommonTopBar(
      title: 'Task Details',
      compact: MediaQuery.of(context).size.width < 360,
      onBack: onBack,
    );
  }
}

class _TaskHero extends StatelessWidget {
  const _TaskHero({required this.detail});

  final _TaskDetailData detail;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 8),
          Text(
            detail.title,
            style: AppTextStyles.style(
              color: const Color(0xFF0F172A),
              fontSize: compact ? 18 : 20,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: compact ? 12 : 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Priority',
                  value: detail.priority,
                  compact: compact,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStat(
                  label: 'Status',
                  value: detail.status,
                  compact: compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Start Date',
                  value: detail.startDateText,
                  compact: compact,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStat(
                  label: 'Due Date',
                  value: detail.deadlineText,
                  compact: compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: const Color(0xFF0F172A),
              fontSize: compact ? 12 : 13,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.style(
                    color: const Color(0xFF0F172A),
                    fontSize: 13,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.style(
              color: const Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.style(
                color: const Color(0xFF64748B),
                fontSize: 12,
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
        radius: 20,
        backgroundColor: const Color(0xFFE2E8F0),
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFE7F0FF),
      child: Text(
        initials,
        style: AppTextStyles.style(
          color: const Color(0xFF1D4ED8),
          fontSize: 12,
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
