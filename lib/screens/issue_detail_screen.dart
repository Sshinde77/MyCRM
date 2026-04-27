import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';
import 'package:mycrm/models/client_issue_model.dart';
import 'package:mycrm/models/client_issue_task_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

class IssueDetailScreen extends StatefulWidget {
  const IssueDetailScreen({super.key, this.issueId, this.initialIssue});

  final String? issueId;
  final ClientIssueModel? initialIssue;

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final ApiService _apiService = ApiService.instance;
  late Future<ClientIssueModel> _future;
  bool _isClosingIssue = false;
  bool _canCreateIssueTask = false;
  bool _canEditIssue = false;
  bool _canDeleteIssueTask = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _future = _loadIssue();
  }

  Future<void> _loadPermissions() async {
    final canCreate = await PermissionService.has(AppPermission.createRaiseIssue);
    final canEdit = await PermissionService.has(AppPermission.editRaiseIssue);
    final canDelete = await PermissionService.has(AppPermission.deleteRaiseIssue);
    if (!mounted) return;
    setState(() {
      _canCreateIssueTask = canCreate;
      _canEditIssue = canEdit;
      _canDeleteIssueTask = canDelete;
    });
  }

  Future<ClientIssueModel> _loadIssue() async {
    final id = (widget.issueId ?? widget.initialIssue?.id ?? '').trim();
    if (id.isEmpty) {
      final initial = widget.initialIssue;
      if (initial != null) return initial;
      throw Exception('Issue id is missing.');
    }
    try {
      return await _apiService.getClientIssueDetail(id);
    } on DioException catch (error) {
      final initial = widget.initialIssue;
      if (initial != null && error.response?.statusCode == 404) {
        return initial;
      }
      rethrow;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadIssue();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: const CommonScreenAppBar(title: 'Issue Details'),
      body: SafeArea(
        child: FutureBuilder<ClientIssueModel>(
          future: _future,
          initialData: widget.initialIssue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && !snapshot.hasData) {
              return _DetailState(
                message: _messageFromError(snapshot.error!),
                onRetry: _refresh,
              );
            }

            final issue = snapshot.data;
            if (issue == null) {
              return _DetailState(
                message: 'Issue details are not available.',
                onRetry: _refresh,
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IssueHeaderCard(
                      issue: issue,
                      canEditIssue: _canEditIssue,
                      onAssign: () {
                        _openAssignTeamsDialog(issue.id);
                      },
                      onCloseIssue: () {
                        _closeIssue(issue);
                      },
                      isClosingIssue: _isClosingIssue,
                    ),
                    // const SizedBox(height: 24),
                    // _AssignmentsCard(issue: issue),
                    const SizedBox(height: 24),
                    _DetailsCard(issue: issue),
                    const SizedBox(height: 24),
                    _TaskBoardCard(
                      issue: issue,
                      onTaskCreated: _refresh,
                      canCreateTask: _canCreateIssueTask,
                      canEditTask: _canEditIssue,
                      canDeleteTask: _canDeleteIssueTask,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _messageFromError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw.isEmpty ? 'Unable to load issue details.' : raw;
  }

  Future<void> _openAssignTeamsDialog(String issueId) async {
    if (!_canEditIssue) {
      AppSnackbar.show(
        'Permission denied',
        'You do not have permission to edit issues.',
      );
      return;
    }

    final assigned = await showDialog<bool>(
      context: context,
      builder: (_) => _AssignTeamsDialog(issueId: issueId),
    );
    if (assigned == true && mounted) {
      await _refresh();
      if (!mounted) return;
      AppSnackbar.show('Success', 'Team assigned successfully.');
    }
  }

  Future<void> _closeIssue(ClientIssueModel issue) async {
    if (!_canEditIssue) {
      if (!mounted) return;
      AppSnackbar.show(
        'Permission denied',
        'You do not have permission to edit issues.',
      );
      return;
    }

    final issueId = issue.id.trim();
    if (issueId.isEmpty) {
      if (!mounted) return;
      AppSnackbar.show('Notice', 'Issue id is missing.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Close Issue'),
          content: const Text('Mark this issue as resolved?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1769F3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Close Issue'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClosingIssue = true);
    try {
      await _apiService.updateClientIssueStatus(
        issueId: issueId,
        status: 'closed',
      );

      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      AppSnackbar.show('Success', 'Issue closed successfully.');
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.show('Error', _messageFromError(error));
    } finally {
      if (mounted) {
        setState(() => _isClosingIssue = false);
      }
    }
  }
}

class _IssueHeaderCard extends StatelessWidget {
  const _IssueHeaderCard({
    required this.issue,
    required this.canEditIssue,
    required this.onAssign,
    required this.onCloseIssue,
    required this.isClosingIssue,
  });

  final ClientIssueModel issue;
  final bool canEditIssue;
  final VoidCallback onAssign;
  final VoidCallback onCloseIssue;
  final bool isClosingIssue;

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF141C33);
    const textSec = Color(0xFF74839D);
    const blue = Color(0xFF1769F3);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Badge(
                label: issue.displayId,
                background: const Color(0xFFE0E7FF),
                foreground: blue,
              ),
              _Badge(
                label: '${issue.displayPriority.toUpperCase()} PRIORITY',
                background: _priorityBg(issue.priority),
                foreground: _priorityFg(issue.priority),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  issue.displayProject,
                  style: AppTextStyles.style(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _Badge(
                label: '${issue.displayStatus.toUpperCase()} STATUS',
                background: _statusBg(issue.status),
                foreground: _statusFg(issue.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Client: ',
                  style: AppTextStyles.style(
                    color: textSec,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: issue.displayClient,
                  style: AppTextStyles.style(
                    color: textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            issue.displayDescription,
            style: AppTextStyles.style(
              color: textSec,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canEditIssue ? onAssign : null,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Assign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      canEditIssue && !isClosingIssue ? onCloseIssue : null,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(isClosingIssue ? 'Closing...' : 'Close Issue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: textMain,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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

class _AssignTeamsDialog extends StatefulWidget {
  const _AssignTeamsDialog({required this.issueId});

  final String issueId;

  @override
  State<_AssignTeamsDialog> createState() => _AssignTeamsDialogState();
}

class _AssignTeamsDialogState extends State<_AssignTeamsDialog> {
  final ApiService _apiService = ApiService.instance;
  late Future<List<ClientIssueTeamOption>> _teamsFuture;
  String? _assigningTeamName;

  @override
  void initState() {
    super.initState();
    _teamsFuture = _apiService.getClientIssueTeams();
  }

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF141C33);
    const textSec = Color(0xFF74839D);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: FutureBuilder<List<ClientIssueTeamOption>>(
            future: _teamsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unable to load teams.',
                      style: AppTextStyles.style(
                        color: const Color(0xFFB3261E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              }

              final teams = snapshot.data ?? const <ClientIssueTeamOption>[];

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Assign Team',
                          style: AppTextStyles.style(
                            color: textMain,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: textSec),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (teams.isEmpty)
                    Text(
                      'No teams available.',
                      style: AppTextStyles.style(
                        color: textSec,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final team = teams[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE6ECF5),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _assigningTeamName != null
                                  ? null
                                  : () => _confirmAssign(team),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _TeamAvatar(iconPath: team.iconPath),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            team.displayName,
                                            style: AppTextStyles.style(
                                              color: textMain,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            team.displayDescription,
                                            style: AppTextStyles.style(
                                              color: textSec,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_assigningTeamName == team.displayName)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAssign(ClientIssueTeamOption team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Assign Team'),
          content: Text('Assign "${team.displayName}" to this issue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _assigningTeamName = team.displayName);
    try {
      await _apiService.assignClientIssueTeam(
        issueId: widget.issueId,
        teamName: team.displayName,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show('Error', 'Unable to assign team right now.');
    } finally {
      if (mounted) {
        setState(() => _assigningTeamName = null);
      }
    }
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.iconPath});

  final String iconPath;

  @override
  Widget build(BuildContext context) {
    final normalizedPath = iconPath.trim();
    final hasIcon = normalizedPath.isNotEmpty;
    final iconUrl = hasIcon
        ? (normalizedPath.startsWith('http')
              ? normalizedPath
              : 'https://mycrm.technofra.com/$normalizedPath')
        : '';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: hasIcon
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFF1769F3),
                  size: 20,
                ),
              ),
            )
          : const Icon(
              Icons.groups_rounded,
              color: Color(0xFF1769F3),
              size: 20,
            ),
    );
  }
}

class _AssignmentsCard extends StatelessWidget {
  const _AssignmentsCard({required this.issue});

  final ClientIssueModel issue;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Assignments',
      child: Column(
        children: [
          _InfoRow('Team', _valueOrFallback(issue.assignedTeam, 'Unassigned')),
          const Divider(height: 32),
          _InfoRow(
            'Assigned To',
            _valueOrFallback(issue.assignedTo, 'Unassigned'),
            valueColor: const Color(0xFF1769F3),
          ),
          const Divider(height: 32),
          _InfoRow(
            'Assigned By',
            _valueOrFallback(issue.assignedBy, 'Not available'),
          ),
          const Divider(height: 32),
          _InfoRow('Date', issue.displayDate),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.issue});

  final ClientIssueModel issue;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Issue Information',
      child: Column(
        children: [
          _InfoRow('Title', issue.displayTitle),
          const Divider(height: 32),
          _InfoRow('Project', issue.displayProject),
          const Divider(height: 32),
          _InfoRow('Priority', issue.displayPriority),
          const Divider(height: 32),
          _InfoRow('Status', issue.displayStatus),
        ],
      ),
    );
  }
}

class _TaskBoardCard extends StatelessWidget {
  const _TaskBoardCard({
    required this.issue,
    this.onTaskCreated,
    required this.canCreateTask,
    required this.canEditTask,
    required this.canDeleteTask,
  });

  final ClientIssueModel issue;
  final Future<void> Function()? onTaskCreated;
  final bool canCreateTask;
  final bool canEditTask;
  final bool canDeleteTask;

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF141C33);
    const textSec = Color(0xFF74839D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Task Board',
                style: AppTextStyles.style(
                  color: textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (canCreateTask)
              TextButton.icon(
                onPressed: () async {
                  final created = await showDialog<bool>(
                    context: context,
                    builder: (_) => _AddTaskDialog(issueId: issue.id),
                  );
                  if (created != true || !context.mounted) return;
                  if (onTaskCreated != null) {
                    await onTaskCreated!();
                  }
                  if (!context.mounted) return;
                  AppSnackbar.show('Success', 'Task saved successfully.');
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Task'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: issue.tasks.isEmpty
              ? Text(
                  'No tasks are linked to this issue.',
                  style: AppTextStyles.style(
                    color: textSec,
                    fontSize: 13,
                    height: 1.4,
                  ),
                )
              : Column(
                  children: issue.tasks
                      .map((task) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE6ECF5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title.trim().isEmpty
                                          ? 'Untitled Task'
                                          : task.title.trim(),
                                      style: AppTextStyles.style(
                                        color: textMain,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _Badge(
                                    label: task.status.toUpperCase(),
                                    background: _statusBg(task.status),
                                    foreground: _statusFg(task.status),
                                  ),
                                ],
                              ),
                              if (task.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  task.description.trim(),
                                  style: AppTextStyles.style(
                                    color: textSec,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _Badge(
                                    label: task.priority.toUpperCase(),
                                    background: _priorityBg(task.priority),
                                    foreground: _priorityFg(task.priority),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _taskDateText(
                                        task.startDate,
                                        task.dueDate,
                                      ),
                                      textAlign: TextAlign.right,
                                      style: AppTextStyles.style(
                                        color: textSec,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    task.assignedTo.trim().isEmpty
                                        ? 'Assigned: Unassigned'
                                        : 'Assigned: ${task.assignedTo.trim()}',
                                    style: AppTextStyles.style(
                                      color: textSec,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Files: ${task.attachments.length}',
                                    style: AppTextStyles.style(
                                      color: textSec,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'View',
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (dialogContext) {
                                          return _TaskDetailDialog(
                                            issueId: issue.id,
                                            taskId: task.id,
                                          );
                                        },
                                      );
                                    },
                                    icon: Icon(
                                      Icons.visibility_outlined,
                                      size: 20,
                                      color: textSec.withValues(alpha: 0.75),
                                    ),
                                  ),
                                  if (canEditTask)
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: () async {
                                        final updated = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => _AddTaskDialog(
                                            issueId: issue.id,
                                            initialTask: task,
                                          ),
                                        );
                                        if (updated != true ||
                                            !context.mounted) {
                                          return;
                                        }
                                        if (onTaskCreated != null) {
                                          await onTaskCreated!();
                                        }
                                        if (!context.mounted) return;
                                        AppSnackbar.show(
                                          'Success',
                                          'Task updated successfully.',
                                        );
                                      },
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: textSec.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  if (canDeleteTask)
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              title: const Text('Delete Task'),
                                              content: Text(
                                                'Delete "${task.title.trim().isEmpty ? 'this task' : task.title.trim()}" permanently?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(
                                                        dialogContext,
                                                      ).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.of(
                                                        dialogContext,
                                                      ).pop(true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFB3261E,
                                                            ),
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (confirmed != true ||
                                            !context.mounted) {
                                          return;
                                        }

                                        var deleted = false;
                                        try {
                                          await ApiService.instance
                                              .deleteClientIssueTask(
                                                issueId: issue.id,
                                                taskId: task.id,
                                              );
                                          deleted = true;
                                        } catch (_) {
                                          if (!context.mounted) return;
                                          AppSnackbar.show(
                                            'Error',
                                            'Unable to delete task right now.',
                                          );
                                          return;
                                        }

                                        if (!deleted || !context.mounted) return;

                                        if (onTaskCreated != null) {
                                          try {
                                            await onTaskCreated!();
                                          } catch (_) {
                                            // Keep success state if delete already succeeded.
                                          }
                                        }

                                        if (!context.mounted) return;
                                        AppSnackbar.show(
                                          'Success',
                                          'Task deleted successfully.',
                                        );
                                      },
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: textSec.withValues(alpha: 0.75),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }

  String _taskDateText(String startDate, String dueDate) {
    final start = startDate.trim();
    final due = dueDate.trim();
    if (start.isEmpty && due.isEmpty) return 'No dates';
    if (start.isNotEmpty && due.isNotEmpty) return '$start -> $due';
    if (start.isNotEmpty) return 'Start: $start';
    return 'Due: $due';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.style(
            color: const Color(0xFF141C33),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(radius: 20, shadow: false),
          child: child,
        ),
      ],
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog({required this.issueId, this.initialTask});

  final String issueId;
  final ClientIssueTaskModel? initialTask;

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _TaskDetailDialog extends StatefulWidget {
  const _TaskDetailDialog({required this.issueId, required this.taskId});

  final String issueId;
  final String taskId;

  @override
  State<_TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<_TaskDetailDialog> {
  final ApiService _apiService = ApiService.instance;
  late Future<ClientIssueTaskModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _apiService.getClientIssueTaskDetail(
      issueId: widget.issueId,
      taskId: widget.taskId,
    );
  }

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF141C33);
    const textSec = Color(0xFF74839D);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: FutureBuilder<ClientIssueTaskModel>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                final errorText = _messageFromError(snapshot.error);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unable to load task details.',
                      style: AppTextStyles.style(
                        color: const Color(0xFFB3261E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      errorText,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.style(
                        color: textSec,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              }

              final task = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title.trim().isEmpty
                              ? 'Task Details'
                              : task.title,
                          style: AppTextStyles.style(
                            color: textMain,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: textSec),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        label: task.status.toUpperCase(),
                        background: _statusBg(task.status),
                        foreground: _statusFg(task.status),
                      ),
                      _Badge(
                        label: task.priority.toUpperCase(),
                        background: _priorityBg(task.priority),
                        foreground: _priorityFg(task.priority),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TaskDetailRow('Task ID', task.id, textMain, textSec),
                  _TaskDetailRow(
                    'Issue ID',
                    task.clientIssueId,
                    textMain,
                    textSec,
                  ),
                  _TaskDetailRow(
                    'Description',
                    task.description.trim().isEmpty
                        ? 'No description'
                        : task.description.trim(),
                    textMain,
                    textSec,
                  ),
                  _TaskDetailRow(
                    'Assigned To',
                    task.assignedTo.trim().isEmpty
                        ? 'Unassigned'
                        : task.assignedTo,
                    textMain,
                    textSec,
                  ),
                  _TaskDetailRow(
                    'Start Date',
                    task.startDate.trim().isEmpty ? 'N/A' : task.startDate,
                    textMain,
                    textSec,
                  ),
                  _TaskDetailRow(
                    'Due Date',
                    task.dueDate.trim().isEmpty ? 'N/A' : task.dueDate,
                    textMain,
                    textSec,
                  ),
                  _TaskDetailRow(
                    'Created At',
                    _formatDateTime(task.createdAt),
                    textMain,
                    textSec,
                  ),
                  _TaskDetailRow(
                    'Updated At',
                    _formatDateTime(task.updatedAt),
                    textMain,
                    textSec,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attachments',
                    style: AppTextStyles.style(
                      color: textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (task.attachments.isEmpty)
                    Text(
                      'No attachments',
                      style: AppTextStyles.style(
                        color: textSec,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    ...task.attachments.map((attachment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE6ECF5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attachment.displayName,
                                style: AppTextStyles.style(
                                  color: textMain,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (attachment.path.trim().isNotEmpty &&
                                  attachment.path.trim() !=
                                      attachment.displayName) ...[
                                const SizedBox(height: 2),
                                Text(
                                  attachment.path.trim(),
                                  style: AppTextStyles.style(
                                    color: textSec,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _messageFromError(Object? error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final raw = error?.toString().trim() ?? '';
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw.isEmpty ? 'Please try again.' : raw;
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'N/A';
    final local = value.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd-$mm-$yyyy $hh:$min';
  }
}

class _TaskDetailRow extends StatelessWidget {
  const _TaskDetailRow(
    this.label,
    this.value,
    this.mainColor,
    this.secondaryColor,
  );

  final String label;
  final String value;
  final Color mainColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTextStyles.style(
                color: secondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'N/A' : value,
              style: AppTextStyles.style(
                color: mainColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final ApiService _apiService = ApiService.instance;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assignedToController = TextEditingController();
  final _checklistController = TextEditingController();
  List<PlatformFile> _attachments = const [];
  String _status = 'todo';
  String _priority = 'medium';
  String? _inlineError;
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isSaving = false;
  static const int _maxAttachmentBytes = 10 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    if (initialTask == null) return;

    _titleController.text = initialTask.title;
    _descriptionController.text = initialTask.description;
    _assignedToController.text = initialTask.assignedTo;
    _status = _normalizeDialogStatus(initialTask.status);
    _priority = _normalizeDialogPriority(initialTask.priority);
    _startDate = _tryParseDate(initialTask.startDate);
    _dueDate = _tryParseDate(initialTask.dueDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _inlineError = 'Please enter task title.');
      return;
    }

    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    try {
      final initialTask = widget.initialTask;
      if (initialTask == null) {
        await _apiService.createClientIssueTask(
          issueId: widget.issueId,
          request: CreateClientIssueTaskRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            status: _status,
            priority: _priority,
            assignedTo: _assignedToController.text.trim(),
            startDate: _startDate,
            dueDate: _dueDate,
            attachmentPaths: _attachments
                .map((entry) => entry.path?.trim() ?? '')
                .where((entry) => entry.isNotEmpty)
                .toList(growable: false),
          ),
        );
      } else {
        await _apiService.updateClientIssueTask(
          issueId: widget.issueId,
          taskId: initialTask.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          priority: _priority,
          assignedTo: _assignedToController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _inlineError = _messageFromError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final picked = result.files;
    final valid = picked
        .where((file) => file.size <= _maxAttachmentBytes)
        .toList(growable: false);

    setState(() {
      _attachments = valid;
      _inlineError = valid.length == picked.length
          ? null
          : 'Some files were skipped because they exceed 10MB.';
    });
  }

  Future<void> _pickDate({
    required DateTime? currentValue,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final initialDate = currentValue ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null || !mounted) return;
    onPicked(picked);
  }

  String _displayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  DateTime? _tryParseDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  String _normalizeDialogStatus(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'to do':
      case 'todo':
        return 'todo';
      case 'in progress':
      case 'in_progress':
        return 'in_progress';
      case 'review':
        return 'review';
      case 'done':
      case 'completed':
      case 'complete':
        return 'done';
      default:
        return 'todo';
    }
  }

  String _normalizeDialogPriority(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'low':
      case 'medium':
      case 'high':
      case 'critical':
        return normalized;
      default:
        return 'medium';
    }
  }

  String _messageFromError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw.isEmpty ? 'Unable to save task right now.' : raw;
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 640;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 28,
        vertical: compact ? 16 : 28,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 18 : 22,
                  compact ? 18 : 22,
                  compact ? 12 : 16,
                  compact ? 14 : 18,
                ),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 38 : 42,
                      height: compact ? 38 : 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.check_box_outlined,
                        color: const Color(0xFF1769F3),
                        size: compact ? 20 : 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.initialTask == null
                            ? 'Add New Task'
                            : 'Edit Task',
                        style: AppTextStyles.style(
                          color: const Color(0xFF141C33),
                          fontSize: compact ? 20 : 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF74839D),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE6ECF5)),
              Padding(
                padding: EdgeInsets.all(compact ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TaskFormLabel('Title', required: true),
                    const SizedBox(height: 6),
                    _TaskTextField(
                      controller: _titleController,
                      hint: 'Enter task title',
                    ),
                    SizedBox(height: compact ? 14 : 16),
                    const _TaskFormLabel('Description'),
                    const SizedBox(height: 6),
                    _TaskTextField(
                      controller: _descriptionController,
                      hint: 'Enter task description',
                      minLines: 3,
                      maxLines: 4,
                    ),
                    SizedBox(height: compact ? 14 : 16),
                    _ResponsivePair(
                      compact: compact,
                      left: _TaskSelectField(
                        label: 'Status',
                        value: _status,
                        items: const ['todo', 'in_progress', 'review', 'done'],
                        onChanged: (value) => setState(() => _status = value),
                      ),
                      right: _TaskSelectField(
                        label: 'Priority',
                        value: _priority,
                        items: const ['low', 'medium', 'high', 'critical'],
                        onChanged: (value) => setState(() => _priority = value),
                      ),
                    ),
                    SizedBox(height: compact ? 14 : 16),
                    const _TaskFormLabel('Assigned To'),
                    const SizedBox(height: 6),
                    _TaskTextField(
                      controller: _assignedToController,
                      hint: 'Enter staff id',
                    ),
                    SizedBox(height: compact ? 16 : 18),
                    _TaskPanel(
                      icon: Icons.calendar_today_outlined,
                      title: 'Dates',
                      child: _ResponsiveTriple(
                        compact: compact,
                        children: [
                          _TaskDateInput(
                            label: 'Start Date',
                            hint: _startDate == null
                                ? 'dd-mm-yyyy'
                                : _displayDate(_startDate!),
                            onTap: () {
                              _pickDate(
                                currentValue: _startDate,
                                onPicked: (value) => setState(() {
                                  _startDate = value;
                                }),
                              );
                            },
                          ),
                          _TaskDateInput(
                            label: 'Due Date',
                            hint: _dueDate == null
                                ? 'dd-mm-yyyy'
                                : _displayDate(_dueDate!),
                            onTap: () {
                              _pickDate(
                                currentValue: _dueDate ?? _startDate,
                                onPicked: (value) => setState(() {
                                  _dueDate = value;
                                }),
                              );
                            },
                          ),
                          _TaskDateInput(label: 'Time', hint: '--:--'),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 14),
                    _TaskPanel(
                      icon: Icons.check_box_outlined,
                      title: 'Checklist',
                      child: _TaskInlineAddField(
                        controller: _checklistController,
                        hint: 'Add a checklist item',
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 14),
                    _TaskPanel(
                      icon: Icons.attach_file_rounded,
                      title: 'Attachment',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD8E1EF),
                              ),
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFFF8FAFC),
                            ),
                            child: Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _pickAttachments,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(13),
                                    ),
                                    child: Container(
                                      height: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEAF2FF),
                                        borderRadius: BorderRadius.horizontal(
                                          left: Radius.circular(13),
                                        ),
                                      ),
                                      child: Text(
                                        'Choose Files',
                                        style: AppTextStyles.style(
                                          color: const Color(0xFF1769F3),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _attachments.isEmpty
                                        ? 'No file chosen'
                                        : _attachments
                                              .map((file) => file.name)
                                              .join(', '),
                                    style: AppTextStyles.style(
                                      color: const Color(0xFF74839D),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _attachments.isEmpty
                                ? 'Max file size: 10M'
                                : '${_attachments.length} file(s) selected • Max file size: 10M',
                            style: AppTextStyles.style(
                              color: const Color(0xFF74839D),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_inlineError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _inlineError!,
                        style: AppTextStyles.style(
                          color: const Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE6ECF5)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 20,
                  compact ? 14 : 16,
                  compact ? 16 : 20,
                  compact ? 16 : 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF141C33),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : widget.initialTask == null
                            ? 'Save Task'
                            : 'Update Task',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1769F3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskFormLabel extends StatelessWidget {
  const _TaskFormLabel(this.text, {this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppTextStyles.style(
          color: const Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFDC2626)),
                ),
              ]
            : const [],
      ),
    );
  }
}

class _TaskTextField extends StatelessWidget {
  const _TaskTextField({
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: AppTextStyles.style(
        color: const Color(0xFF141C33),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: _taskInputDecoration(hint),
    );
  }
}

class _TaskSelectField extends StatelessWidget {
  const _TaskSelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TaskFormLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          style: AppTextStyles.style(
            color: const Color(0xFF141C33),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF74839D),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(_taskTitleCase(item)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
          decoration: _taskInputDecoration(''),
        ),
      ],
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({
    required this.compact,
    required this.left,
    required this.right,
  });

  final bool compact;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(children: [left, const SizedBox(height: 10), right]);
    }
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }
}

class _ResponsiveTriple extends StatelessWidget {
  const _ResponsiveTriple({required this.compact, required this.children});

  final bool compact;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }
}

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E1EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF1769F3)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.style(
                  color: const Color(0xFF141C33),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TaskDateInput extends StatelessWidget {
  const _TaskDateInput({required this.label, required this.hint, this.onTap});

  final String label;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TaskFormLabel(label),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          onTap: onTap,
          style: AppTextStyles.style(
            color: const Color(0xFF141C33),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _taskInputDecoration(hint).copyWith(
            suffixIcon: Icon(
              label.toLowerCase().contains('time')
                  ? Icons.access_time_rounded
                  : Icons.calendar_today_rounded,
              size: 18,
              color: const Color(0xFF74839D),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskInlineAddField extends StatelessWidget {
  const _TaskInlineAddField({
    required this.controller,
    required this.hint,
    this.label,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final input = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _TaskTextField(controller: controller, hint: hint),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1769F3),
              side: const BorderSide(color: Color(0xFF1769F3)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );

    if (label == null) {
      return input;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_TaskFormLabel(label!), const SizedBox(height: 6), input],
    );
  }
}

InputDecoration _taskInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.style(
      color: const Color(0xFF94A3B8),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8E1EF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8E1EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF1769F3), width: 1.4),
    ),
  );
}

String _taskTitleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF74839D),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.style(
              color: valueColor ?? const Color(0xFF141C33),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailState extends StatelessWidget {
  const _DetailState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.style(
                color: const Color(0xFF74839D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => onRetry(), child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 24, bool shadow = true}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: shadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
        : null,
  );
}

String _valueOrFallback(String value, String fallback) {
  final normalized = value.trim();
  return normalized.isEmpty ? fallback : normalized;
}

Color _priorityBg(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'high':
    case 'urgent':
      return const Color(0xFFFFEDD5);
    case 'low':
      return const Color(0xFFF1F5F9);
    default:
      return const Color(0xFFFEF3C7);
  }
}

Color _priorityFg(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'high':
    case 'urgent':
      return const Color(0xFFF97316);
    case 'low':
      return const Color(0xFF475569);
    default:
      return const Color(0xFFD97706);
  }
}

Color _statusBg(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.contains('closed') ||
      normalized.contains('complete') ||
      normalized.contains('resolved')) {
    return const Color(0xFFE8F8EE);
  }
  if (normalized.contains('progress')) {
    return const Color(0xFFDCEAFE);
  }
  return const Color(0xFFFEE2E2);
}

Color _statusFg(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.contains('closed') ||
      normalized.contains('complete') ||
      normalized.contains('resolved')) {
    return const Color(0xFF16A34A);
  }
  if (normalized.contains('progress')) {
    return const Color(0xFF2563EB);
  }
  return const Color(0xFFEF4444);
}
