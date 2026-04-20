import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/project_model.dart';

import '../models/client_detail_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, this.clientId});

  final String? clientId;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late Future<_ClientDetailBundle> _detailFuture;
  String? _clientId;

  @override
  void initState() {
    super.initState();
    _clientId = widget.clientId ?? _extractClientId(Get.arguments);
    _detailFuture = _loadClientBundle();
  }

  Future<_ClientDetailBundle> _loadClientBundle() async {
    final clientId = (_clientId ?? '').trim();
    if (clientId.isEmpty) {
      throw Exception('Client id missing');
    }

    final responses = await Future.wait<dynamic>([
      ApiService.instance.getClientDetail(clientId),
      ApiService.instance.getClientProjectsList(clientId),
      ApiService.instance.getClientTasksList(clientId),
    ]);

    final client = responses[0] as ClientDetailModel;
    final projects = responses[1] as List<ProjectModel>;
    final rawTasks = responses[2] as List<Map<String, dynamic>>;

    return _ClientDetailBundle(
      client: client,
      projects: projects,
      tasks: rawTasks.map(_ClientTaskSummary.fromJson).toList(),
    );
  }

  void _reload() {
    setState(() {
      _detailFuture = _loadClientBundle();
    });
  }

  String? _extractClientId(dynamic args) {
    if (args == null) return null;
    if (args is String) return args;
    if (args is int) return args.toString();
    if (args is Map) {
      final raw = args['id'] ?? args['clientId'] ?? args['client_id'];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        return raw.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF7FAFF);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: const CommonScreenAppBar(title: 'Client Details'),
      body: FutureBuilder<_ClientDetailBundle>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    Text(
                      _readErrorMessage(snapshot.error),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.style(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D6FEA),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final bundle = snapshot.data;
          if (bundle == null) {
            return const Center(child: Text('Client not found'));
          }

          final client = bundle.client;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                _ProfileHeader(client: client),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        icon: Icons.folder_open_rounded,
                        value: '${bundle.projects.length}',
                        label: 'Projects',
                        color: const Color(0xFFE0E7FF),
                        iconColor: const Color(0xFF1769F3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        icon: Icons.assignment_outlined,
                        value: '${bundle.tasks.length}',
                        label: 'Tasks',
                        color: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        icon: client.isActive
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                        value: client.isActive ? 'Active' : 'Inactive',
                        label: 'Status',
                        color: client.isActive
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFE2E8F0),
                        iconColor: client.isActive
                            ? const Color(0xFF059669)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ClientInfoCard(client: client),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Projects',
                  count: bundle.projects.length,
                ),
                const SizedBox(height: 12),
                if (bundle.projects.isEmpty)
                  const _EmptyRelatedState(
                    message: 'No projects found for this client.',
                  )
                else
                  Column(
                    children: bundle.projects
                        .map((project) => _ProjectListCard(project: project))
                        .toList(),
                  ),
                const SizedBox(height: 20),
                _SectionHeader(title: 'Tasks', count: bundle.tasks.length),
                const SizedBox(height: 12),
                if (bundle.tasks.isEmpty)
                  const _EmptyRelatedState(
                    message: 'No tasks found for this client.',
                  )
                else
                  Column(
                    children: bundle.tasks
                        .map((task) => _TaskListCard(task: task))
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClientDetailBundle {
  const _ClientDetailBundle({
    required this.client,
    required this.projects,
    required this.tasks,
  });

  final ClientDetailModel client;
  final List<ProjectModel> projects;
  final List<_ClientTaskSummary> tasks;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.client});

  final ClientDetailModel client;

  @override
  Widget build(BuildContext context) {
    final displayName = client.name.isNotEmpty ? client.name : 'Client';
    final company = client.companyName.isNotEmpty
        ? client.companyName
        : 'No company';
    final email = client.email.isNotEmpty ? client.email : 'No email';
    final phone = client.phone.isNotEmpty ? client.phone : 'No phone';
    final website = client.website.isNotEmpty ? client.website : 'No website';
    final manager = client.managerName.isNotEmpty
        ? client.managerName
        : 'Unassigned Manager';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: AppTextStyles.style(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF141C33),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: client.isActive
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            client.isActive
                                ? 'ACTIVE CLIENT'
                                : 'INACTIVE CLIENT',
                            style: AppTextStyles.style(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: client.isActive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      company,
                      style: AppTextStyles.style(
                        fontSize: 14,
                        color: const Color(0xFF74839D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.email_outlined, email),
          _infoRow(Icons.phone_outlined, phone),
          _infoRow(Icons.language_outlined, website, isLink: true),
          _infoRow(Icons.person_outline, manager),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF74839D)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.style(
                fontSize: 13,
                color: isLink
                    ? const Color(0xFF1769F3)
                    : const Color(0xFF141C33),
                fontWeight: isLink ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141C33),
            ),
          ),
          Text(
            label,
            style: AppTextStyles.style(
              fontSize: 10,
              color: const Color(0xFF74839D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientInfoCard extends StatelessWidget {
  const _ClientInfoCard({required this.client});

  final ClientDetailModel client;

  @override
  Widget build(BuildContext context) {
    final contactPerson = client.contactPerson.isNotEmpty
        ? client.contactPerson
        : 'Not specified';
    final clientType = client.clientType.isNotEmpty
        ? client.clientType
        : 'Not specified';
    final industry = client.industry.isNotEmpty
        ? client.industry
        : 'Not specified';
    final priority = client.priorityLevel.isNotEmpty
        ? client.priorityLevel
        : 'Not specified';
    final billingType = client.billingType.isNotEmpty
        ? client.billingType
        : 'Not specified';
    final dueDays = client.dueDays.isNotEmpty
        ? client.dueDays
        : 'Not specified';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Client Information',
                style: AppTextStyles.style(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141C33),
                ),
              ),
              const Icon(
                Icons.info_outline,
                color: Color(0xFF74839D),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoField(
                  label: 'CONTACT PERSON',
                  value: contactPerson,
                ),
              ),
              Expanded(
                child: _InfoField(label: 'CLIENT TYPE', value: clientType),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoField(label: 'INDUSTRY', value: industry),
              ),
              Expanded(
                child: _InfoField(
                  label: 'PRIORITY LEVEL',
                  value: priority,
                  valueColor: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _InfoField(label: 'ADDRESS DETAILS', value: client.addressSummary),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: _InfoField(label: 'BILLING TYPE', value: billingType),
              ),
              Expanded(
                child: _InfoField(label: 'DUE DAYS', value: dueDays),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF74839D),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.style(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF141C33),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.style(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF141C33),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.style(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1769F3),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectListCard extends StatelessWidget {
  const _ProjectListCard({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
                  project.title.isNotEmpty ? project.title : 'Untitled Project',
                  style: AppTextStyles.style(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF141C33),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(label: project.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.client.isNotEmpty ? project.client : 'No client name',
            style: AppTextStyles.style(
              fontSize: 13,
              color: const Color(0xFF74839D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetaText(
                icon: Icons.play_circle_outline_rounded,
                text: 'Start: ${project.startDate}',
              ),
              _MetaText(
                icon: Icons.event_outlined,
                text: 'Deadline: ${project.deadline}',
              ),
              _MetaText(
                icon: Icons.group_outlined,
                text: '${project.members.length} members',
              ),
              _MetaText(
                icon: Icons.show_chart_rounded,
                text: '${(project.progress * 100).round()}% progress',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskListCard extends StatelessWidget {
  const _TaskListCard({required this.task});

  final _ClientTaskSummary task;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
                  task.title,
                  style: AppTextStyles.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF141C33),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(label: task.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Project: ${task.projectName}',
            style: AppTextStyles.style(
              fontSize: 12,
              color: const Color(0xFF1769F3),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description,
              style: AppTextStyles.style(
                fontSize: 12,
                color: const Color(0xFF74839D),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetaText(
                icon: Icons.flag_outlined,
                text: 'Priority: ${task.priority}',
              ),
              _MetaText(
                icon: Icons.calendar_month_outlined,
                text: 'Due: ${task.deadlineLabel}',
              ),
              if (task.id.isNotEmpty)
                _MetaText(icon: Icons.tag_outlined, text: 'ID: ${task.id}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF74839D)),
        const SizedBox(width: 5),
        Text(
          text,
          style: AppTextStyles.style(
            fontSize: 11,
            color: const Color(0xFF74839D),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().toLowerCase();
    final background =
        normalized.contains('complete') ||
            normalized.contains('done') ||
            normalized.contains('active')
        ? const Color(0xFFD1FAE5)
        : normalized.contains('progress') || normalized.contains('running')
        ? const Color(0xFFDBEAFE)
        : normalized.contains('pending') || normalized.contains('start')
        ? const Color(0xFFF1F5F9)
        : const Color(0xFFFEF3C7);
    final foreground =
        normalized.contains('complete') ||
            normalized.contains('done') ||
            normalized.contains('active')
        ? const Color(0xFF059669)
        : normalized.contains('progress') || normalized.contains('running')
        ? const Color(0xFF1769F3)
        : normalized.contains('pending') || normalized.contains('start')
        ? const Color(0xFF64748B)
        : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.isNotEmpty ? label : 'Unknown',
        style: AppTextStyles.style(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _EmptyRelatedState extends StatelessWidget {
  const _EmptyRelatedState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined, color: Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.style(
                fontSize: 13,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientTaskSummary {
  const _ClientTaskSummary({
    required this.id,
    required this.title,
    required this.projectName,
    required this.description,
    required this.status,
    required this.priority,
    required this.deadlineLabel,
  });

  final String id;
  final String title;
  final String projectName;
  final String description;
  final String status;
  final String priority;
  final String deadlineLabel;

  factory _ClientTaskSummary.fromJson(Map<String, dynamic> json) {
    final project = _readMap(json['project']);
    final deadline = _readString(json, const [
      'deadline',
      'due_date',
      'dueDate',
      'end_date',
    ]);

    return _ClientTaskSummary(
      id: _readString(json, const ['id', 'task_id']) ?? '',
      title:
          _readString(json, const ['title', 'name', 'task_title', 'subject']) ??
          'Untitled Task',
      projectName:
          _readString(project, const ['name', 'title']) ??
          _readString(json, const ['project_name', 'project']) ??
          'Unassigned Project',
      description:
          _readString(json, const ['description', 'details', 'summary']) ?? '',
      status:
          _readString(json, const ['status', 'task_status']) ?? 'Not Started',
      priority:
          _readString(json, const ['priority', 'priority_level']) ?? 'Normal',
      deadlineLabel: _formatDate(deadline),
    );
  }
}

Map<String, dynamic> _readMap(dynamic value) {
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

String _formatDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Not set';
  }

  final date = DateTime.tryParse(value.trim());
  if (date == null) {
    return value.trim();
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

String _readErrorMessage(Object? error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    final message = error.message?.trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }
  }

  final fallback = error?.toString().trim() ?? '';
  return fallback.isEmpty ? 'Failed to load client details.' : fallback;
}
