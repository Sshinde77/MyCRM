import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/project_comment_model.dart';
import 'package:mycrm/models/project_detail_model.dart';
import 'package:mycrm/models/project_issue_model.dart';
import 'package:mycrm/models/project_milestone_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

class ProjectReportsScreen extends StatefulWidget {
  const ProjectReportsScreen({super.key, required this.project});

  final ProjectDetailModel project;

  @override
  State<ProjectReportsScreen> createState() => _ProjectReportsScreenState();
}

class _ProjectReportsScreenState extends State<ProjectReportsScreen> {
  late Future<_ProjectReportsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProjectReportsData> _load() async {
    final projectId = widget.project.id.trim();
    if (projectId.isEmpty) {
      throw Exception('Project id is missing.');
    }

    final payload = await ApiService.instance.getProjectReportDetails(
      projectId,
    );
    return _ProjectReportsData.fromPayload(payload);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: const CommonScreenAppBar(
        title: 'Project Reports',
        showDateBadge: false,
        showTodoButton: false,
        showNotificationButton: false,
      ),
      body: FutureBuilder<_ProjectReportsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                children: const [
                  _StateCard(
                    icon: Icons.hourglass_top_rounded,
                    title: 'Loading reports...',
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                children: [
                  _ErrorCard(
                    title: 'Unable to load reports',
                    message: 'Pull to refresh or retry the request.',
                    onRetry: _reload,
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
              children: [
                // _SectionCard(
                //   title: 'Time Tracking Stats',
                //   child: _TimeTrackingStatsCard(stats: data.timeTrackingStats),
                // ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Task Status Distribution',
                  child: _TaskStatusChartCard(entries: data.taskStatusEntries),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Workload Distribution',
                  child: _WorkloadChartCard(entries: data.workloadEntries),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Overdue Tasks Trend',
                  child: _OverdueTasksTrendCard(
                    points: data.overdueTrendPoints,
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Milestone Completion',
                  child: _MilestoneCompletionCard(
                    completed: data.completedMilestones,
                    total: data.totalMilestones,
                    progress: data.milestoneProgress,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProjectReportsData {
  const _ProjectReportsData({
    required this.project,
    required this.projectProgressOverall,
    required this.projectProgressEntries,
    required this.projectDashboardEntries,
    required this.projectDashboardSummary,
    required this.milestoneStatEntries,
    required this.issueStatEntries,
    required this.timeTrackingStats,
    required this.taskStatusEntries,
    required this.workloadEntries,
    required this.overdueTrendPoints,
    required this.completedMilestones,
    required this.totalMilestones,
    required this.milestoneProgress,
    required this.deploymentEntries,
    required this.memberMetricEntries,
    required this.tasks,
    required this.files,
    required this.milestones,
    required this.issues,
    required this.pendingIssues,
    required this.activityFeedEntries,
    required this.recentActivities,
    required this.statusLogs,
    required this.kanbanColumns,
  });

  final ProjectDetailModel project;
  final double projectProgressOverall;
  final List<_KeyValueEntry> projectProgressEntries;
  final List<_KeyValueEntry> projectDashboardEntries;
  final Map<String, dynamic> projectDashboardSummary;
  final List<_KeyValueEntry> milestoneStatEntries;
  final List<_KeyValueEntry> issueStatEntries;
  final _TimeTrackingStats timeTrackingStats;
  final List<_StatusEntry> taskStatusEntries;
  final List<_WorkloadEntry> workloadEntries;
  final List<_TrendPoint> overdueTrendPoints;
  final int completedMilestones;
  final int totalMilestones;
  final double milestoneProgress;
  final List<_KeyValueEntry> deploymentEntries;
  final List<_MemberMetricEntry> memberMetricEntries;
  final List<ProjectTaskRecord> tasks;
  final List<ProjectFileRecord> files;
  final List<ProjectMilestoneModel> milestones;
  final List<ProjectIssueModel> issues;
  final List<ProjectIssueModel> pendingIssues;
  final List<_ActivityFeedEntry> activityFeedEntries;
  final List<_ActivityFeedEntry> recentActivities;
  final List<_StatusLogEntry> statusLogs;
  final List<_KanbanColumnEntry> kanbanColumns;

  factory _ProjectReportsData.fromPayload(Map<String, dynamic> payload) {
    final projectMap = _findMap(payload, const ['project']);
    final progressMap = _findMap(payload, const ['project_progress']);
    final projectDashboardSummary = _findMap(
      _findMap(payload, const ['project_dashboard']),
      const ['summary'],
    );
    final milestoneStats = _findMap(payload, const ['milestone_stats']);
    final issueStats = _findMap(payload, const ['issue_stats']);
    final deploymentSummary = _findMap(payload, const ['deployment_summary']);
    final charts = _findMap(payload, const ['charts']);
    final chartsTaskStatus = _findMap(charts, const ['task_status']);
    final chartsSummary = _findMap(charts, const ['summary']);
    final milestoneCompletion = _findMap(payload, const [
      'milestone_completion_analytics',
    ]);
    final memberMetricsMap = _findMap(payload, const ['member_metrics']);

    final mergedProject = <String, dynamic>{}
      ..addAll(projectMap)
      ..['progress'] =
          progressMap['overall'] ??
          chartsSummary['overall_progress'] ??
          projectDashboardSummary['overall_progress'] ??
          _coerceDoubleValue(projectMap['progress'])
      ..['tasks'] = _extractTaskStats(progressMap, chartsSummary, payload)
      ..['customer'] = projectMap['customer'] ?? projectMap['client'];

    final project = ProjectDetailModel.fromJson(mergedProject);

    final milestoneMaps = _extractListOfMaps(payload, const ['milestones']);
    final issueMaps = _extractListOfMaps(payload, const ['issues']);
    final pendingIssueMaps = _extractListOfMaps(payload, const [
      'pending_issues',
    ]);
    final taskMaps = _extractListOfMaps(payload, const ['tasks']);
    final fileMaps = _extractListOfMaps(payload, const ['project_files']);
    final activityFeedMaps = _extractListOfMaps(payload, const [
      'activity_feed',
    ]);
    final recentActivityMaps = _extractListOfMaps(payload, const [
      'recent_activities',
    ]);
    final statusLogMaps = _extractListOfMaps(payload, const ['status_logs']);
    final kanbanColumnsMaps = _extractListOfMaps(
      _findMap(payload, const ['kanban']),
      const ['columns'],
    );

    final totalMilestones = _readInt(milestoneStats, const [
      'total',
    ], fallback: milestoneMaps.length);
    final completedMilestones = _readInt(milestoneStats, const [
      'completed',
    ], fallback: milestoneMaps.where(_isCompletedMilestone).length);
    final milestoneProgress =
        _readDouble(
          milestoneCompletion,
          const ['rate', 'percentage', 'percent'],
          fallback: totalMilestones == 0
              ? 0
              : (completedMilestones / totalMilestones) * 100,
        ) /
        100;

    final projectProgressOverall = _readDouble(
      progressMap,
      const ['overall'],
      fallback: _readDouble(
        chartsSummary,
        const ['overall_progress'],
        fallback: _readDouble(projectDashboardSummary, const [
          'overall_progress',
        ]),
      ),
    );

    return _ProjectReportsData(
      project: project,
      projectProgressOverall: projectProgressOverall,
      projectProgressEntries: _mapEntriesFromPayload(
        progressMap,
        fallback: const [
          'overall',
          'completed_tasks',
          'in_progress_tasks',
          'overdue_tasks',
          'remaining_tasks',
          'not_started_tasks',
          'total_tasks',
        ],
      ),
      projectDashboardEntries: _mapEntriesFromPayload(
        projectDashboardSummary,
        fallback: const [
          'elapsed_hours',
          'overall_progress',
          'tasks_total',
          'issues_total',
          'milestones_total',
        ],
      ),
      projectDashboardSummary: projectDashboardSummary,
      milestoneStatEntries: _mapEntriesFromPayload(
        milestoneStats,
        fallback: const ['total', 'completed', 'in_progress', 'pending'],
      ),
      issueStatEntries: _mapEntriesFromPayload(
        issueStats,
        fallback: const ['total', 'open', 'in_progress', 'resolved', 'closed'],
      ),
      timeTrackingStats: _TimeTrackingStats.fromPayload(payload),
      taskStatusEntries: _parseTaskStatusEntries(payload, chartsTaskStatus),
      workloadEntries: _parseWorkloadEntries(payload),
      overdueTrendPoints: _parseOverdueTrendPoints(payload),
      completedMilestones: completedMilestones,
      totalMilestones: totalMilestones,
      milestoneProgress: milestoneProgress,
      deploymentEntries: _mapEntriesFromPayload(
        deploymentSummary,
        fallback: const [
          'status',
          'environment',
          'version',
          'deployed_at',
          'maintenance_expiry',
        ],
      ),
      memberMetricEntries: _memberMetricEntries(memberMetricsMap),
      tasks: taskMaps.map(ProjectTaskRecord.fromJson).toList(),
      files: fileMaps.map(ProjectFileRecord.fromJson).toList(),
      milestones: milestoneMaps.map(ProjectMilestoneModel.fromJson).toList(),
      issues: issueMaps.map(ProjectIssueModel.fromJson).toList(),
      pendingIssues: pendingIssueMaps.map(ProjectIssueModel.fromJson).toList(),
      activityFeedEntries: activityFeedMaps
          .map(_ActivityFeedEntry.fromJson)
          .where(
            (entry) => entry.title.isNotEmpty || entry.description.isNotEmpty,
          )
          .toList(),
      recentActivities: recentActivityMaps
          .map(_ActivityFeedEntry.fromJson)
          .where(
            (entry) => entry.title.isNotEmpty || entry.description.isNotEmpty,
          )
          .toList(),
      statusLogs: _statusLogs(statusLogMaps),
      kanbanColumns: _kanbanColumns(kanbanColumnsMaps),
    );
  }
}

class _TimeTrackingStats {
  const _TimeTrackingStats({
    required this.totalHours,
    required this.timerHours,
    required this.manualHours,
    required this.entriesLogged,
  });

  final double totalHours;
  final double timerHours;
  final double manualHours;
  final int entriesLogged;

  factory _TimeTrackingStats.fromPayload(Map<String, dynamic> payload) {
    final source = _findMap(payload, const [
      'time_tracking_stats',
      'timeTrackingStats',
      'time_tracking',
      'timeTracking',
      'tracking_stats',
      'trackingStats',
      'stats',
    ]);

    return _TimeTrackingStats(
      totalHours: _readDouble(source.isNotEmpty ? source : payload, const [
        'total_hours',
        'totalHours',
        'total',
        'sum',
        'logged_hours',
        'project_elapsed_hours',
      ]),
      timerHours: _readDouble(source.isNotEmpty ? source : payload, const [
        'timer_hours',
        'timerHours',
        'timer',
        'auto',
        'automatic_hours',
      ]),
      manualHours: _readDouble(source.isNotEmpty ? source : payload, const [
        'manual_hours',
        'manualHours',
        'manual',
      ]),
      entriesLogged: _readInt(source.isNotEmpty ? source : payload, const [
        'entries_logged',
        'entriesLogged',
        'entries_count',
        'entries',
        'count',
        'total_entries',
      ]),
    );
  }
}

class _StatusEntry {
  const _StatusEntry({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  double get percent => 0;
}

class _TrendPoint {
  const _TrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class _WorkloadEntry {
  const _WorkloadEntry({required this.label, required this.count});

  final String label;
  final int count;
}

class _ActivityFeedEntry {
  const _ActivityFeedEntry({
    required this.title,
    required this.description,
    required this.actor,
    required this.createdAt,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String actor;
  final String createdAt;
  final IconData icon;
  final Color color;

  factory _ActivityFeedEntry.fromJson(Map<String, dynamic> json) {
    final type = _readString(json, const [
      'type',
      'activity_type',
      'event_type',
      'action',
      'module',
      'name',
    ]);
    final title = _readString(json, const [
      'title',
      'message',
      'subject',
      'activity',
      'event',
      'action',
    ], fallback: type.isEmpty ? 'Activity' : _pretty(type));
    final description = _readString(json, const [
      'description',
      'details',
      'body',
      'text',
      'comment',
      'summary',
      'message',
    ]);
    final actorMap = _findMap(json, const [
      'user',
      'actor',
      'author',
      'created_by',
      'createdBy',
      'staff',
      'member',
    ]);
    final actorSource = actorMap.isNotEmpty ? actorMap : json;
    final firstName = _readString(actorSource, const [
      'first_name',
      'firstName',
    ]);
    final lastName = _readString(actorSource, const ['last_name', 'lastName']);
    final fullName = [
      firstName,
      lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    final actor = fullName.isNotEmpty
        ? fullName
        : _readString(actorSource, const [
            'name',
            'full_name',
            'fullName',
            'user_name',
            'author_name',
            'created_by_name',
          ], fallback: 'System');
    final createdAt = _readString(json, const [
      'created_at',
      'createdAt',
      'activity_at',
      'date',
      'time',
      'timestamp',
      'created_on',
    ]);

    return _ActivityFeedEntry(
      title: title,
      description: description,
      actor: actor,
      createdAt: createdAt,
      icon: _activityIcon(type, title, description),
      color: _activityColor(type, title, description),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B1E2740),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              title,
              style: AppTextStyles.style(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

class _TimeTrackingStatsCard extends StatelessWidget {
  const _TimeTrackingStatsCard({required this.stats});

  final _TimeTrackingStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final metrics = [
              _MetricTile(
                label: 'Total',
                value: _formatHours(stats.totalHours),
              ),
              _MetricTile(
                label: 'Timer',
                value: _formatHours(stats.timerHours),
              ),
              _MetricTile(
                label: 'Manual',
                value: _formatHours(stats.manualHours),
              ),
            ];

            return Row(
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  Expanded(child: metrics[i]),
                  if (i != metrics.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Entries Logged: ${stats.entriesLogged}',
          style: AppTextStyles.style(
            color: const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.style(
              color: const Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskStatusChartCard extends StatelessWidget {
  const _TaskStatusChartCard({required this.entries});

  final List<_StatusEntry> entries;

  @override
  Widget build(BuildContext context) {
    final visible = entries.where((entry) => entry.count > 0).toList();
    if (visible.isEmpty) {
      return const _EmptyState(message: 'No task status data available.');
    }

    final total = visible.fold<int>(0, (sum, entry) => sum + entry.count);
    final sections = visible
        .map(
          (entry) => PieChartSectionData(
            value: entry.count.toDouble(),
            color: entry.color,
            radius: 44,
            title: total == 0
                ? ''
                : '${((entry.count / total) * 100).toStringAsFixed(1)}%',
            titleStyle: AppTextStyles.style(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        )
        .toList();

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 58,
              sections: sections,
              pieTouchData: PieTouchData(enabled: false),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: entries
              .map(
                (entry) => _LegendItem(color: entry.color, label: entry.label),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _WorkloadChartCard extends StatelessWidget {
  const _WorkloadChartCard({required this.entries});

  final List<_WorkloadEntry> entries;

  @override
  Widget build(BuildContext context) {
    final visible = entries.where((entry) => entry.count > 0).toList();
    if (visible.isEmpty) {
      return const _EmptyState(message: 'No workload data available.');
    }

    final maxY = math
        .max(
          1,
          visible
              .map((entry) => entry.count)
              .fold<int>(0, math.max)
              .toDouble()
              .ceil(),
        )
        .toDouble();
    final barGroups = <BarChartGroupData>[
      for (var i = 0; i < visible.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: visible[i].count.toDouble(),
              width: 26,
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
    ];

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visible.length) {
                    return const SizedBox.shrink();
                  }
                  final label = visible[index].label;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: SizedBox(
                      width: 78,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.style(
                          color: const Color(0xFF0F172A),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverdueTasksTrendCard extends StatelessWidget {
  const _OverdueTasksTrendCard({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.isEmpty
        ? const <_TrendPoint>[
            _TrendPoint(label: 'Sun', value: 0),
            _TrendPoint(label: 'Mon', value: 0),
            _TrendPoint(label: 'Tue', value: 0),
          ]
        : points;

    final maxY = math
        .max(1.0, visible.map((point) => point.value).fold<double>(0, math.max))
        .toDouble();
    final spots = [
      for (var i = 0; i < visible.length; i++)
        FlSpot(i.toDouble(), visible[i].value),
    ];

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY,
          minX: 0,
          maxX: (visible.length - 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 4 ? 0.5 : (maxY / 4).ceilToDouble(),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: const Color(0xFFEF4444),
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxY <= 4 ? 0.5 : (maxY / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visible.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      visible[index].label,
                      style: AppTextStyles.style(
                        color: const Color(0xFF0F172A),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MilestoneCompletionCard extends StatelessWidget {
  const _MilestoneCompletionCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final percent = (safeProgress * 100).toStringAsFixed(2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;
        const completedColor = Color(0xFF00A86F);
        const remainingColor = Color(0xFFF59E0B);
        final remainingPercent = ((1 - safeProgress).clamp(0.0, 1.0) * 100)
            .toStringAsFixed(0);
        final completedValue = completed.toDouble().clamp(0.0, double.infinity);
        final remainingValue = total <= 0
            ? 0.0
            : math.max(0.0, total.toDouble() - completedValue);

        final chart = SizedBox(
          width: 210,
          height: 210,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 62,
              sections: [
                PieChartSectionData(
                  value: completedValue,
                  color: completedColor,
                  radius: 48,
                  title: total <= 0 ? '' : '$percent%',
                  titleStyle: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                PieChartSectionData(
                  value: remainingValue <= 0 ? 0.001 : remainingValue,
                  color: remainingColor,
                  radius: 48,
                  title: '',
                ),
              ],
              pieTouchData: PieTouchData(enabled: false),
            ),
          ),
        );

        final summary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CompletionMetric(label: 'Completed', accent: completedColor),
            const SizedBox(height: 10),
            _CompletionMetric(label: 'Remaining', accent: remainingColor),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: completedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Milestone Completion',
                    style: AppTextStyles.style(
                      color: const Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (compact)
                Column(children: [chart, const SizedBox(height: 18), summary])
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    chart,
                    const SizedBox(width: 22),
                    Expanded(child: summary),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CompletionMetric extends StatelessWidget {
  const _CompletionMetric({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.style(
                color: const Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectOverviewCard extends StatelessWidget {
  const _ProjectOverviewCard({
    required this.project,
    required this.progressValue,
    required this.summary,
  });

  final ProjectDetailModel project;
  final double progressValue;
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progressValue.clamp(0.0, 1.0) * 100)
        .toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Tag(
              label: project.priority.toUpperCase(),
              color: _priorityColor(project.priority),
            ),
            _Tag(
              label: project.status.toUpperCase(),
              color: _accent(project.status),
            ),
            _Tag(label: '$progressPercent%', color: const Color(0xFF1D6FEA)),
          ],
        ),
        const SizedBox(height: 14),
        _KeyValueGrid(
          entries: [
            _KeyValueEntry(label: 'Project', value: project.title),
            _KeyValueEntry(label: 'Customer ID', value: project.customerId),
            _KeyValueEntry(label: 'Client', value: project.client),
            _KeyValueEntry(label: 'Client Email', value: project.clientEmail),
            _KeyValueEntry(label: 'Client Phone', value: project.clientPhone),
            _KeyValueEntry(
              label: 'Client Address',
              value: project.clientAddress,
            ),
            _KeyValueEntry(label: 'Start Date', value: project.startDate),
            _KeyValueEntry(label: 'Deadline', value: project.deadline),
            _KeyValueEntry(label: 'Billing Type', value: project.billingType),
            _KeyValueEntry(
              label: 'Estimated Hours',
              value: project.estimatedHours,
            ),
            _KeyValueEntry(
              label: 'Progress',
              value: '${(progressValue * 100).toStringAsFixed(0)}%',
            ),
            _KeyValueEntry(
              label: 'Elapsed Hours',
              value: _formatHours(
                _readDouble(summary, const ['elapsed_hours'], fallback: 0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyValueGrid extends StatelessWidget {
  const _KeyValueGrid({required this.entries});

  final List<_KeyValueEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState(message: 'No data available.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final children = entries
            .map(
              (entry) => Container(
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
                      entry.label,
                      style: AppTextStyles.style(
                        color: const Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value,
                      style: AppTextStyles.style(
                        color: const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList();

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

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final child in children)
              SizedBox(width: (constraints.maxWidth - 10) / 2, child: child),
          ],
        );
      },
    );
  }
}

class _MemberMetricsCard extends StatelessWidget {
  const _MemberMetricsCard({required this.entries});

  final List<_MemberMetricEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState(message: 'No member metrics available.');
    }

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entries[i].label,
                    style: AppTextStyles.style(
                      color: const Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  entries[i].value,
                  style: AppTextStyles.style(
                    color: const Color(0xFF1D6FEA),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (i != entries.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _IssueListCard extends StatelessWidget {
  const _IssueListCard({required this.issues});

  final List<ProjectIssueModel> issues;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return const _EmptyState(message: 'No issues available.');
    }

    return Column(
      children: [
        for (var i = 0; i < issues.length; i++) ...[
          _ListCard(
            title: issues[i].issueDescription,
            subtitle: issues[i].status,
            meta: [
              issues[i].priority.toUpperCase(),
              issues[i].status.toUpperCase(),
            ],
          ),
          if (i != issues.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MilestoneListCard extends StatelessWidget {
  const _MilestoneListCard({required this.milestones});

  final List<ProjectMilestoneModel> milestones;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const _EmptyState(message: 'No milestones available.');
    }

    return Column(
      children: [
        for (var i = 0; i < milestones.length; i++) ...[
          _ListCard(
            title: milestones[i].title,
            subtitle: milestones[i].description,
            meta: [
              milestones[i].status.toUpperCase(),
              if (milestones[i].dueDate.isNotEmpty) milestones[i].dueDate,
            ],
          ),
          if (i != milestones.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FileListCard extends StatelessWidget {
  const _FileListCard({required this.files});

  final List<ProjectFileRecord> files;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const _EmptyState(message: 'No files uploaded.');
    }

    return Column(
      children: [
        for (var i = 0; i < files.length; i++) ...[
          _ListCard(
            title: files[i].name,
            subtitle: files[i].formattedSize.isNotEmpty
                ? files[i].formattedSize
                : (files[i].sizeBytes != null
                      ? _readableSize(files[i].sizeBytes!)
                      : 'File'),
            meta: [
              if (files[i].extension.isNotEmpty)
                files[i].extension.toUpperCase(),
              if (files[i].uploadedOn.isNotEmpty) files[i].uploadedOn,
            ],
          ),
          if (i != files.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TaskListCard extends StatelessWidget {
  const _TaskListCard({required this.tasks});

  final List<ProjectTaskRecord> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const _EmptyState(message: 'No tasks available.');
    }

    return Column(
      children: [
        for (var i = 0; i < tasks.length; i++) ...[
          _ListCard(
            title: tasks[i].title,
            subtitle: tasks[i].assigneeName,
            meta: [
              tasks[i].priority.toUpperCase(),
              tasks[i].status.toUpperCase(),
              tasks[i].createdOn,
            ],
          ),
          if (i != tasks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({required this.columns});

  final List<_KanbanColumnEntry> columns;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) {
      return const _EmptyState(message: 'No kanban data available.');
    }

    return Column(
      children: [
        for (var i = 0; i < columns.length; i++) ...[
          _ListCard(
            title: columns[i].label,
            subtitle: '${columns[i].count} tasks',
            meta: const [],
          ),
          if (i != columns.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StatusLogCard extends StatelessWidget {
  const _StatusLogCard({required this.logs});

  final List<_StatusLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _EmptyState(message: 'No status logs available.');
    }

    return Column(
      children: [
        for (var i = 0; i < logs.length; i++) ...[
          _ListCard(
            title: logs[i].status,
            subtitle: logs[i].endedAt.isEmpty
                ? 'Started: ${logs[i].startedAt}'
                : 'Started: ${logs[i].startedAt}',
            meta: [if (logs[i].endedAt.isNotEmpty) 'Ended: ${logs[i].endedAt}'],
          ),
          if (i != logs.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  final String title;
  final String subtitle;
  final List<String> meta;

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
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.style(
              color: const Color(0xFF475569),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (meta.any((item) => item.trim().isNotEmpty)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meta
                  .where((item) => item.trim().isNotEmpty)
                  .map(
                    (item) =>
                        _MiniChip(label: item, color: const Color(0xFF1D6FEA)),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final background = color.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _KeyValueEntry {
  const _KeyValueEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _MemberMetricEntry {
  const _MemberMetricEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _StatusLogEntry {
  const _StatusLogEntry({
    required this.status,
    required this.startedAt,
    required this.endedAt,
  });

  final String status;
  final String startedAt;
  final String endedAt;
}

class _KanbanColumnEntry {
  const _KanbanColumnEntry({required this.label, required this.count});

  final String label;
  final int count;
}

List<Map<String, dynamic>> _extractListOfMaps(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) => item.map((nestedKey, nestedValue) {
              return MapEntry(nestedKey.toString(), nestedValue);
            }),
          )
          .toList();
    }
    if (value is Map) {
      final normalized = value.map((nestedKey, nestedValue) {
        return MapEntry(nestedKey.toString(), nestedValue);
      });
      final nested = normalized['data'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map(
              (item) => item.map((nestedKey, nestedValue) {
                return MapEntry(nestedKey.toString(), nestedValue);
              }),
            )
            .toList();
      }
    }
  }
  return const <Map<String, dynamic>>[];
}

List<_KeyValueEntry> _mapEntriesFromPayload(
  Map<String, dynamic> source, {
  List<String> fallback = const [],
}) {
  final entries = <_KeyValueEntry>[];
  if (source.isNotEmpty) {
    for (final entry in source.entries) {
      if (entry.value is Map || entry.value is List) {
        entries.add(
          _KeyValueEntry(
            label: _pretty(entry.key),
            value: _stringifyNested(entry.value),
          ),
        );
      } else {
        entries.add(
          _KeyValueEntry(
            label: _pretty(entry.key),
            value: _readString(source, [entry.key], fallback: '-'),
          ),
        );
      }
    }
    return entries;
  }

  for (final key in fallback) {
    final value = source[key];
    if (value == null) continue;
    entries.add(
      _KeyValueEntry(label: _pretty(key), value: _stringifyNested(value)),
    );
  }
  return entries;
}

List<_MemberMetricEntry> _memberMetricEntries(Map<String, dynamic> source) {
  if (source.isEmpty) return const <_MemberMetricEntry>[];

  return source.entries.map((entry) {
    final member = _asMap(entry.value);
    final hours = _readDouble(member, const ['total_hours', 'totalHours']);
    final started = _readString(member, const [
      'assignment_started_at',
      'assignmentStartedAt',
      'started_at',
    ]);
    final label = _readString(member, const [
      'member_name',
      'memberName',
      'name',
      'title',
    ], fallback: 'Member ${entry.key}');
    final value = started.isEmpty
        ? _formatHours(hours)
        : '${_formatHours(hours)}  $started';
    return _MemberMetricEntry(label: label, value: value);
  }).toList();
}

List<_StatusLogEntry> _statusLogs(List<Map<String, dynamic>> source) {
  return source.map((entry) {
    return _StatusLogEntry(
      status: _pretty(
        _readString(entry, const ['status'], fallback: 'Unknown'),
      ),
      startedAt: _readString(entry, const [
        'started_at',
        'startedAt',
      ], fallback: '-'),
      endedAt: _readString(entry, const ['ended_at', 'endedAt']),
    );
  }).toList();
}

List<_KanbanColumnEntry> _kanbanColumns(List<Map<String, dynamic>> source) {
  return source.map((entry) {
    return _KanbanColumnEntry(
      label: _readString(entry, const [
        'label',
        'name',
        'key',
      ], fallback: 'Column'),
      count: _readInt(entry, const ['count']),
    );
  }).toList();
}

Map<String, dynamic> _extractTaskStats(
  Map<String, dynamic> progressMap,
  Map<String, dynamic> chartsSummary,
  Map<String, dynamic> payload,
) {
  final result = <String, dynamic>{};
  final total = _readInt(
    progressMap,
    const ['total_tasks'],
    fallback: _readInt(payload, const [
      'total_tasks',
    ], fallback: _readInt(chartsSummary, const ['total_tasks'])),
  );
  result['total'] = total;
  result['completed'] = _readInt(progressMap, const [
    'completed_tasks',
  ], fallback: _readInt(payload, const ['completed_tasks']));
  result['in_progress'] = _readInt(progressMap, const [
    'in_progress_tasks',
  ], fallback: _readInt(payload, const ['in_progress_tasks']));
  result['overdue'] = _readInt(
    progressMap,
    const ['overdue_tasks'],
    fallback: _readInt(payload, const [
      'overdue_tasks',
    ], fallback: _readInt(chartsSummary, const ['overdue_tasks'])),
  );
  result['remaining'] = _readInt(progressMap, const [
    'remaining_tasks',
  ], fallback: _readInt(payload, const ['remaining_tasks']));
  result['not_started'] = _readInt(progressMap, const [
    'not_started_tasks',
  ], fallback: _readInt(payload, const ['not_started_tasks']));
  return result;
}

double _coerceDoubleValue(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

String _stringifyNested(dynamic value) {
  if (value is Map) {
    final normalized = _asMap(value);
    final buffer = <String>[];
    for (final entry in normalized.entries) {
      if (entry.value == null || entry.value.toString().trim().isEmpty)
        continue;
      buffer.add('${_pretty(entry.key)}: ${entry.value}');
    }
    return buffer.isEmpty ? '-' : buffer.join(' | ');
  }
  if (value is List) {
    return value.map((item) => item.toString()).join(', ');
  }
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? '-' : text;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, nestedValue) {
      return MapEntry(key.toString(), nestedValue);
    });
  }
  return const <String, dynamic>{};
}

class _ActivityFeedCard extends StatelessWidget {
  const _ActivityFeedCard({required this.entries});

  final List<_ActivityFeedEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState(message: 'No activity feed items available.');
    }

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _ActivityFeedItem(entry: entries[i]),
          if (i != entries.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

List<_TrendPoint> _parseOverdueTrendPoints(Map<String, dynamic> payload) {
  final raw = _findValue(payload, const [
    'overdue_tasks_trend',
    'overdueTasksTrend',
    'overdue_trend',
    'overdueTrend',
    'overdue_tasks',
    'overdueTasks',
    'trend',
    'overdue_trend_counts',
  ]);

  if (raw is List) {
    final points = <_TrendPoint>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      final map = item is Map
          ? item.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{'value': item};
      final label = _readString(map, const [
        'label',
        'day',
        'name',
        'date',
        'month',
        'key',
      ], fallback: _defaultTrendLabel(i));
      final value = _readDouble(map, const [
        'value',
        'count',
        'total',
        'tasks',
        'overdue',
        'overdue_count',
      ]);
      points.add(_TrendPoint(label: label, value: value));
    }
    return points;
  }

  final labels = _findValue(payload, const [
    'overdue_trend_labels',
    'overdueTrendLabels',
    'weekly_activity_labels',
    'weeklyActivityLabels',
  ]);
  final counts = _findValue(payload, const [
    'overdue_trend_counts',
    'overdueTrendCounts',
    'weekly_activity_data',
    'weeklyActivityData',
  ]);
  if (labels is List && counts is List) {
    final total = math.min(labels.length, counts.length);
    return [
      for (var i = 0; i < total; i++)
        _TrendPoint(
          label: labels[i].toString(),
          value: _coerceDoubleValue(counts[i]),
        ),
    ];
  }

  if (raw is Map) {
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final points = <_TrendPoint>[];
    for (final entry in map.entries) {
      final value = _readDouble({'value': entry.value}, const ['value']);
      points.add(_TrendPoint(label: _pretty(entry.key), value: value));
    }
    if (points.isNotEmpty) {
      return points;
    }
  }

  final fallbackKeys = const ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
  return [
    for (var i = 0; i < fallbackKeys.length; i++)
      _TrendPoint(
        label: fallbackKeys[i][0].toUpperCase() + fallbackKeys[i].substring(1),
        value: _readDouble(payload, [_toSnakeCase(fallbackKeys[i])]),
      ),
  ];
}

String _defaultTrendLabel(int index) {
  const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  if (index < 0 || index >= labels.length) {
    return 'Day ${index + 1}';
  }
  return labels[index];
}

class _ActivityFeedItem extends StatelessWidget {
  const _ActivityFeedItem({required this.entry});

  final _ActivityFeedEntry entry;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: entry.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(entry.icon, color: entry.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: AppTextStyles.style(
                    color: const Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (entry.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.description,
                    style: AppTextStyles.style(
                      color: const Color(0xFF475569),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MiniChip(
                      label: entry.actor,
                      color: const Color(0xFF1D6FEA),
                    ),
                    if (entry.createdAt.isNotEmpty)
                      _MiniChip(
                        label: entry.createdAt,
                        color: const Color(0xFF64748B),
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

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF334155),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

bool _isCompletedMilestone(Map<String, dynamic> milestone) {
  final status = _readString(milestone, const [
    'status',
    'milestone_status',
    'state',
  ]).toLowerCase();
  return status.contains('complete') ||
      status.contains('done') ||
      status.contains('closed');
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.style(
              color: const Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 28,
            color: Color(0xFFB42318),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
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
                minimumSize: const Size.fromHeight(42),
                backgroundColor: const Color(0xFF1D6FEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

List<_StatusEntry> _parseTaskStatusEntries(
  Map<String, dynamic> payload,
  Map<String, dynamic> chartsTaskStatus,
) {
  final raw =
      _findValue(payload, const [
        'task_status_distribution',
        'taskStatusDistribution',
        'status_distribution',
        'statusDistribution',
        'task_statuses',
        'statuses',
      ]) ??
      chartsTaskStatus;

  final normalized = <_StatusEntry>[];
  if (raw is List) {
    for (final item in raw) {
      final map = item is Map
          ? item.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{'label': item.toString()};
      final label = _readString(map, const [
        'label',
        'status',
        'name',
        'title',
        'key',
      ], fallback: 'Unknown');
      final count = _readInt(map, const [
        'count',
        'total',
        'value',
        'tasks',
        'task_count',
      ]);
      normalized.add(
        _StatusEntry(label: label, count: count, color: _statusColor(label)),
      );
    }
  } else if (raw is Map) {
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final nestedList = _findValue(map, const [
      'data',
      'items',
      'statuses',
      'distribution',
    ]);
    if (nestedList is List) {
      return _parseTaskStatusEntries({
        'statuses': nestedList,
      }, const <String, dynamic>{});
    }
    for (final entry in map.entries) {
      final count = _readInt({'count': entry.value}, const ['count']);
      normalized.add(
        _StatusEntry(
          label: _pretty(entry.key),
          count: count,
          color: _statusColor(entry.key),
        ),
      );
    }
  }

  final seriesSource =
      _findValue(chartsTaskStatus, const ['labels']) is List &&
          _findValue(chartsTaskStatus, const ['series']) is List
      ? chartsTaskStatus
      : _findMap(payload, const ['task_status_analytics']);
  final labels = _findValue(seriesSource, const ['labels']);
  final counts = _findValue(seriesSource, const ['series', 'counts']);
  if (labels is List && counts is List) {
    final total = math.min(labels.length, counts.length);
    return [
      for (var i = 0; i < total; i++)
        _StatusEntry(
          label: labels[i].toString(),
          count: _coerceDoubleValue(counts[i]).round(),
          color: _statusColor(labels[i].toString()),
        ),
    ];
  }

  if (normalized.isNotEmpty) {
    return normalized;
  }

  final fallback = <String>[
    'Not Started',
    'In Progress',
    'On Hold',
    'Completed',
    'Cancelled',
  ];
  return fallback
      .map(
        (label) => _StatusEntry(
          label: label,
          count: _readInt(payload, [_toSnakeCase(label)]),
          color: _statusColor(label),
        ),
      )
      .toList();
}

List<_WorkloadEntry> _parseWorkloadEntries(Map<String, dynamic> payload) {
  final raw = _findValue(payload, const [
    'workload_distribution',
    'workloadDistribution',
    'workload',
    'assignees',
    'members',
    'staff',
    'employees',
  ]);

  final entries = <_WorkloadEntry>[];
  if (raw is List) {
    for (final item in raw) {
      final map = item is Map
          ? item.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{'label': item.toString()};
      final label = _readString(map, const [
        'label',
        'name',
        'assignee',
        'user',
        'title',
      ], fallback: 'Unknown');
      final count = _readInt(map, const [
        'count',
        'total',
        'value',
        'tasks',
        'task_count',
      ]);
      entries.add(_WorkloadEntry(label: label, count: count));
    }
  } else if (raw is Map) {
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    for (final entry in map.entries) {
      final count = _readInt({'count': entry.value}, const ['count']);
      entries.add(_WorkloadEntry(label: _pretty(entry.key), count: count));
    }
  }

  final analytics = _findMap(payload, const ['workload_analytics']);
  final labels = _findValue(analytics, const ['labels']);
  final counts = _findValue(analytics, const ['counts']);
  if (labels is List && counts is List) {
    final total = math.min(labels.length, counts.length);
    return [
      for (var i = 0; i < total; i++)
        _WorkloadEntry(
          label: labels[i].toString(),
          count: _coerceDoubleValue(counts[i]).round(),
        ),
    ];
  }

  return entries;
}

Map<String, dynamic> _findMap(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((nestedKey, nestedValue) {
        return MapEntry(nestedKey.toString(), nestedValue);
      });
    }
  }
  return const <String, dynamic>{};
}

dynamic _findValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (source.containsKey(key)) {
      return source[key];
    }
  }
  return null;
}

String _readString(
  Map<String, dynamic> source,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
  }
  return fallback;
}

int _readInt(
  Map<String, dynamic> source,
  List<String> keys, {
  int fallback = 0,
}) {
  for (final key in keys) {
    final value = source[key];
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

Color _priorityColor(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'low':
      return const Color(0xFF16A34A);
    case 'medium':
      return const Color(0xFFF59E0B);
    case 'high':
      return const Color(0xFFEF4444);
    case 'urgent':
    case 'critical':
      return const Color(0xFFB91C1C);
    default:
      return const Color(0xFF1D6FEA);
  }
}

Color _accent(String status) {
  switch (status.trim().toLowerCase()) {
    case 'completed':
    case 'done':
    case 'closed':
      return const Color(0xFF16A34A);
    case 'in progress':
    case 'active':
      return const Color(0xFF1D6FEA);
    case 'pending':
    case 'on hold':
      return const Color(0xFFF59E0B);
    case 'cancelled':
    case 'rejected':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF64748B);
  }
}

String _readableSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  const units = ['KB', 'MB', 'GB', 'TB'];
  double value = bytes / 1024;
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unitIndex]}';
}

Color _milestoneProgressColor(double progress) {
  if (progress >= 0.75) {
    return const Color(0xFF16A34A);
  }
  if (progress >= 0.4) {
    return const Color(0xFF1D6FEA);
  }
  return const Color(0xFFF59E0B);
}

double _readDouble(
  Map<String, dynamic> source,
  List<String> keys, {
  double fallback = 0,
}) {
  for (final key in keys) {
    final value = source[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll('%', '').trim());
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

String _formatHours(double value) {
  if (value == value.roundToDouble()) {
    return '${value.toInt()}h';
  }
  return '${value.toStringAsFixed(2)}h';
}

String _pretty(String value) {
  final text = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (text.isEmpty) return 'Unknown';
  return text
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _toSnakeCase(String value) {
  return value
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .toLowerCase();
}

Color _statusColor(String label) {
  final normalized = label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  switch (normalized) {
    case 'not started':
    case 'todo':
    case 'to do':
    case 'pending':
      return const Color(0xFF0EA5E9);
    case 'in progress':
    case 'progress':
    case 'running':
      return const Color(0xFF00A86F);
    case 'on hold':
    case 'hold':
    case 'paused':
      return const Color(0xFFCA8501);
    case 'completed':
    case 'complete':
    case 'done':
      return const Color(0xFFFF4560);
    case 'cancelled':
    case 'canceled':
    case 'rejected':
      return const Color(0xFF846DD5);
    default:
      return const Color(0xFF3B82F6);
  }
}

Color _activityColor(String type, String title, String description) {
  final source = '$type $title $description'.toLowerCase();
  if (source.contains('comment')) return const Color(0xFF8B5CF6);
  if (source.contains('issue')) return const Color(0xFFEF4444);
  if (source.contains('file') || source.contains('upload')) {
    return const Color(0xFF0EA5E9);
  }
  if (source.contains('milestone')) return const Color(0xFFF59E0B);
  if (source.contains('task')) return const Color(0xFF10B981);
  return const Color(0xFF3B82F6);
}

IconData _activityIcon(String type, String title, String description) {
  final source = '$type $title $description'.toLowerCase();
  if (source.contains('comment')) return Icons.chat_bubble_outline_rounded;
  if (source.contains('issue')) return Icons.report_gmailerrorred_rounded;
  if (source.contains('file') || source.contains('upload')) {
    return Icons.attach_file_rounded;
  }
  if (source.contains('milestone')) return Icons.flag_rounded;
  if (source.contains('task')) return Icons.task_alt_rounded;
  return Icons.circle_notifications_rounded;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: AppTextStyles.style(
          color: const Color(0xFF64748B),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
