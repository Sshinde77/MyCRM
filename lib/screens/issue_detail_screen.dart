import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/client_issue_model.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _loadIssue();
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
    setState(() => _future = _loadIssue());
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
                    _IssueHeaderCard(issue: issue),
                    const SizedBox(height: 24),
                    _AssignmentsCard(issue: issue),
                    const SizedBox(height: 24),
                    _DetailsCard(issue: issue),
                    const SizedBox(height: 24),
                    const _TaskBoardCard(),
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
}

class _IssueHeaderCard extends StatelessWidget {
  const _IssueHeaderCard({required this.issue});

  final ClientIssueModel issue;

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
                  onPressed: () {},
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
                  onPressed: () {},
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Close Issue'),
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
  const _TaskBoardCard();

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
            TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _AddTaskDialog(),
              ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Task is empty',
                      style: AppTextStyles.style(
                        color: textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'EMPTY',
                      style: AppTextStyles.style(
                        color: Colors.orange,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'No tasks are linked to this issue.',
                style: AppTextStyles.style(
                  color: textSec,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: textSec,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TODO',
                    style: AppTextStyles.style(
                      color: textSec,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '0',
                      style: AppTextStyles.style(
                        color: textSec,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '--',
                      style: AppTextStyles.style(
                        color: textSec,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: textSec.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: textSec.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: textSec.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _labelController = TextEditingController();
  final _checklistController = TextEditingController();
  String _status = 'todo';
  String _priority = 'medium';
  String? _inlineError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _labelController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _inlineError = 'Please enter task title.');
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 640;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 28,
        vertical: compact ? 16 : 28,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: const Color(0xFF0D8BFF),
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_box_outlined,
                      color: Color(0xFF1E293B),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add New Task',
                        style: AppTextStyles.style(
                          color: const Color(0xFF1E293B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF93C5FD),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TaskFormLabel('Title', required: true),
                    const SizedBox(height: 6),
                    _TaskTextField(
                      controller: _titleController,
                      hint: 'Enter task title',
                    ),
                    const SizedBox(height: 12),
                    const _TaskFormLabel('Description'),
                    const SizedBox(height: 6),
                    _TaskTextField(
                      controller: _descriptionController,
                      hint: 'Enter task description',
                      minLines: 3,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _ResponsivePair(
                      compact: compact,
                      left: _TaskSelectField(
                        label: 'Status',
                        value: _status,
                        items: const ['todo', 'in_progress', 'completed'],
                        onChanged: (value) => setState(() => _status = value),
                      ),
                      right: _TaskSelectField(
                        label: 'Priority',
                        value: _priority,
                        items: const ['low', 'medium', 'high'],
                        onChanged: (value) => setState(() => _priority = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TaskPanel(
                      icon: Icons.calendar_today_outlined,
                      title: 'Dates',
                      child: _ResponsiveTriple(
                        compact: compact,
                        children: const [
                          _TaskDateInput(label: 'Start Date', hint: 'dd-mm-yyyy'),
                          _TaskDateInput(label: 'Due Date', hint: 'dd-mm-yyyy'),
                          _TaskDateInput(label: 'Time', hint: '--:--'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TaskPanel(
                      icon: Icons.label_outline_rounded,
                      title: 'Labels',
                      child: _ResponsivePair(
                        compact: compact,
                        left: const _TaskColorInput(),
                        right: _TaskInlineAddField(
                          label: 'Label Text',
                          controller: _labelController,
                          hint: 'Enter label',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TaskPanel(
                      icon: Icons.check_box_outlined,
                      title: 'Checklist',
                      child: _TaskInlineAddField(
                        controller: _checklistController,
                        hint: 'Add a checklist item',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TaskPanel(
                      icon: Icons.notifications_none_rounded,
                      title: 'Reminder',
                      child: _ResponsivePair(
                        compact: compact,
                        left: const _TaskDateInput(
                          label: 'Reminder Date',
                          hint: 'dd-mm-yyyy',
                        ),
                        right: const _TaskDateInput(
                          label: 'Reminder Time',
                          hint: '--:--',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TaskPanel(
                      icon: Icons.attach_file_rounded,
                      title: 'Attachment',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  alignment: Alignment.center,
                                  color: const Color(0xFFF3F4F6),
                                  child: Text(
                                    'Choose Files',
                                    style: AppTextStyles.style(
                                      color: const Color(0xFF111827),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'No file chosen',
                                  style: AppTextStyles.style(
                                    color: const Color(0xFF374151),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Max file size: 10M',
                            style: AppTextStyles.style(
                              color: const Color(0xFF6B7280),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
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
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7280),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_outlined, size: 14),
                      label: const Text('Save Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D8BFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
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
          color: const Color(0xFF4B5563),
          fontSize: 11,
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
        color: const Color(0xFF111827),
        fontSize: 12,
        fontWeight: FontWeight.w400,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: const Color(0xFF374151)),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.style(
                  color: const Color(0xFF374151),
                  fontSize: 12,
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
  const _TaskDateInput({required this.label, required this.hint});

  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TaskFormLabel(label),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          style: AppTextStyles.style(
            color: const Color(0xFF111827),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          decoration: _taskInputDecoration(hint).copyWith(
            suffixIcon: Icon(
              label.toLowerCase().contains('time')
                  ? Icons.access_time_rounded
                  : Icons.calendar_today_rounded,
              size: 14,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskColorInput extends StatelessWidget {
  const _TaskColorInput();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TaskFormLabel('Color'),
        const SizedBox(height: 6),
        Container(
          height: 24,
          width: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF1E90FF),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFFD1D5DB)),
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
      children: [
        Expanded(child: _TaskTextField(controller: controller, hint: hint)),
        SizedBox(
          height: 24,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('Add'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0D8BFF),
              side: const BorderSide(color: Color(0xFF0D8BFF)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
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
      color: const Color(0xFF9CA3AF),
      fontSize: 11,
      fontWeight: FontWeight.w400,
    ),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: const BorderSide(color: Color(0xFF0D8BFF)),
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
