import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

class StaffProjectAnalyticsScreen extends StatefulWidget {
  const StaffProjectAnalyticsScreen({
    super.key,
    required this.staffId,
    this.staffName,
  });

  final String staffId;
  final String? staffName;

  @override
  State<StaffProjectAnalyticsScreen> createState() =>
      _StaffProjectAnalyticsScreenState();
}

class _StaffProjectAnalyticsScreenState
    extends State<StaffProjectAnalyticsScreen> {
  late Future<_StaffProjectAnalyticsData> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _loadAnalytics();
  }

  Future<_StaffProjectAnalyticsData> _loadAnalytics() async {
    _debugAnalyticsLog(
      '[StaffProjectAnalytics] load start staffId=${widget.staffId} name=${widget.staffName ?? '(null)'}',
    );
    final payload = await ApiService.instance.getStaffAnalytics(widget.staffId);
    _debugAnalyticsLog(
      '[StaffProjectAnalytics] raw api payload keys=${payload.keys.toList()}',
    );
    _debugAnalyticsDump('[StaffProjectAnalytics] raw api payload', payload);
    return _StaffProjectAnalyticsData.fromPayload(payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CommonScreenAppBar(
        title: widget.staffName?.trim().isNotEmpty == true
            ? '${widget.staffName!.trim()} Project Analytics'
            : 'Project Analytics',
      ),
      body: FutureBuilder<_StaffProjectAnalyticsData>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            _debugAnalyticsLog(
              '[StaffProjectAnalytics] load error: ${snapshot.error}',
            );
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load project analytics right now.',
                  style: AppTextStyles.style(fontSize: 14),
                ),
              ),
            );
          }

          final data = snapshot.data ?? _StaffProjectAnalyticsData.empty();
          _debugAnalyticsLog(
            '[StaffProjectAnalytics] parsed projectStatus=${data.projectStatusDistribution}',
          );
          _debugAnalyticsLog(
            '[StaffProjectAnalytics] parsed taskStatus=${data.taskStatusDistribution}',
          );
          _debugAnalyticsLog(
            '[StaffProjectAnalytics] parsed timelineCount=${data.timelineEntries.length}',
          );
          _debugAnalyticsLog(
            '[StaffProjectAnalytics] parsed taskOverview=${data.taskStatusOverview}',
          );
          return RefreshIndicator(
            onRefresh: () async {
              _debugAnalyticsLog(
                '[StaffProjectAnalytics] manual refresh start',
              );
              setState(() => _analyticsFuture = _loadAnalytics());
              await _analyticsFuture;
              _debugAnalyticsLog('[StaffProjectAnalytics] manual refresh done');
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                _AnalyticsSectionCard(
                  title: 'Project Status Distribution',
                  child: _DistributionChart(
                    entries: data.projectStatusDistribution,
                    order: const [
                      'Not started',
                      'In progress',
                      'Completed',
                      'On hold',
                      'Cancelled',
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _AnalyticsSectionCard(
                  title: 'Task Status Distribution',
                  child: _DistributionChart(
                    entries: data.taskStatusDistribution,
                    order: const [
                      'Not started',
                      'Pending',
                      'In progress',
                      'Completed',
                      'On hold',
                      'Cancelled',
                      'Overdue',
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _AnalyticsSectionCard(
                  title: 'Monthly Project Timeline',
                  child: _ProjectTimelineChart(entries: data.timelineEntries),
                ),
                const SizedBox(height: 12),
                _AnalyticsSectionCard(
                  title: 'Task Status Overview',
                  child: _TaskOverviewBarChart(
                    entries: data.taskStatusOverview,
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

class _AnalyticsSectionCard extends StatelessWidget {
  const _AnalyticsSectionCard({required this.title, required this.child});

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
            color: Color(0x110F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
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

class _DistributionChart extends StatelessWidget {
  const _DistributionChart({required this.entries, required this.order});

  final Map<String, int> entries;
  final List<String> order;

  @override
  Widget build(BuildContext context) {
    final sortedEntries = _sortEntries(entries, order);
    if (sortedEntries.isEmpty) {
      _debugAnalyticsLog(
        '[StaffProjectAnalytics] distribution chart empty order=$order entries=$entries',
      );
      return const _EmptyChartState();
    }

    final total = sortedEntries.fold<int>(0, (sum, item) => sum + item.value);
    if (total <= 0) {
      _debugAnalyticsLog(
        '[StaffProjectAnalytics] distribution chart zero-total order=$order entries=$entries',
      );
      return const _EmptyChartState();
    }

    _debugAnalyticsLog(
      '[StaffProjectAnalytics] distribution chart render total=$total sorted=$sortedEntries',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        final chartSize = isNarrow ? 220.0 : 280.0;
        final centerSpace = isNarrow ? 48.0 : 64.0;
        final radius = isNarrow ? 62.0 : 78.0;

        final chart = SizedBox(
          width: chartSize,
          height: chartSize,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: centerSpace,
              sectionsSpace: 2,
              sections: [
                for (final entry in sortedEntries)
                  PieChartSectionData(
                    value: entry.value.toDouble(),
                    color: _statusColor(entry.key),
                    radius: radius,
                    title:
                        '${((entry.value / total) * 100).toStringAsFixed(1)}%',
                    titleStyle: AppTextStyles.style(
                      fontSize: isNarrow ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );

        final legend = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in sortedEntries)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: _statusColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: AppTextStyles.style(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: chart),
              const SizedBox(height: 12),
              legend,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Center(child: chart)),
            const SizedBox(width: 12),
            SizedBox(width: 180, child: legend),
          ],
        );
      },
    );
  }
}

class _TaskOverviewBarChart extends StatelessWidget {
  const _TaskOverviewBarChart({required this.entries});

  final Map<String, int> entries;

  @override
  Widget build(BuildContext context) {
    final ordered = _sortEntries(entries, const [
      'Pending',
      'Not started',
      'In progress',
      'Overdue',
      'Completed',
      'On hold',
      'Cancelled',
    ]);
    if (ordered.isEmpty) {
      _debugAnalyticsLog(
        '[StaffProjectAnalytics] task overview empty entries=$entries',
      );
      return const _EmptyChartState();
    }

    var maxY = 0.0;
    for (final entry in ordered) {
      maxY = math.max(maxY, entry.value.toDouble());
    }
    if (maxY <= 0) {
      maxY = 1;
    }

    _debugAnalyticsLog(
      '[StaffProjectAnalytics] task overview render maxY=$maxY ordered=$ordered',
    );

    return SizedBox(
      height: 290,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY + 1,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max(1, (maxY / 4).ceilToDouble()),
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFE2E8F0),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Number of Tasks',
                  style: AppTextStyles.style(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: math.max(1, (maxY / 4).ceilToDouble()),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= ordered.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      ordered[index].key,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.style(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < ordered.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: ordered[i].value.toDouble(),
                    color: _statusColor(ordered[i].key),
                    width: 56,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2),
                    ),
                    rodStackItems: const [],
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY + 1,
                      color: const Color(0xFFF8FAFC),
                    ),
                  ),
                ],
                showingTooltipIndicators: const [],
              ),
          ],
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = ordered[group.x.toInt()];
                return BarTooltipItem(
                  '${entry.key}\n${entry.value}',
                  AppTextStyles.style(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectTimelineChart extends StatelessWidget {
  const _ProjectTimelineChart({required this.entries});

  final List<_ProjectTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      _debugAnalyticsLog('[StaffProjectAnalytics] timeline empty');
      return const _EmptyChartState();
    }

    final sorted = [...entries]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    _debugAnalyticsLog(
      '[StaffProjectAnalytics] timeline render count=${sorted.length} entries=${sorted.map((e) => {'project': e.projectName, 'start': e.startDate.toIso8601String(), 'end': e.endDate.toIso8601String(), 'status': e.statusSnapshot}).toList()}',
    );
    var minDate = sorted.first.startDate;
    var maxDate = sorted.first.endDate;
    for (final entry in sorted) {
      if (entry.startDate.isBefore(minDate)) minDate = entry.startDate;
      if (entry.endDate.isAfter(maxDate)) maxDate = entry.endDate;
    }
    if (!maxDate.isAfter(minDate)) {
      maxDate = minDate.add(const Duration(days: 30));
    }

    final ticks = _buildMonthTicks(minDate, maxDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final veryCompact = constraints.maxWidth < 420;
        final labelWidth = veryCompact ? 96.0 : (compact ? 110.0 : 160.0);
        final rowHeight = compact ? 44.0 : 48.0;
        final chartHeight = sorted.length * rowHeight;
        final chartWidth = math.max(
          veryCompact ? 140.0 : 180.0,
          constraints.maxWidth - labelWidth - 20,
        );
        final visibleTicks = _filterMonthTicks(
          ticks,
          chartWidth,
          minimumSpacing: veryCompact ? 74.0 : 88.0,
        );
        final tickLabels = _buildTickLabels(
          visibleTicks,
          chartWidth,
          minDate,
          maxDate,
          compact: compact,
          veryCompact: veryCompact,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: chartHeight + 34,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: labelWidth,
                    height: chartHeight,
                    child: Column(
                      children: [
                        for (final entry in sorted)
                          SizedBox(
                            height: rowHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                entry.projectName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.style(
                                  fontSize: compact ? 11 : 12,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            for (var i = 0; i <= sorted.length; i++)
                              Container(
                                height: i == sorted.length ? 0 : rowHeight,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        for (final tick in visibleTicks)
                          Positioned(
                            left:
                                _fractionForDate(tick, minDate, maxDate) *
                                chartWidth,
                            top: 0,
                            bottom: 22,
                            child: Container(
                              width: 1,
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                        for (var i = 0; i < sorted.length; i++)
                          Builder(
                            builder: (context) {
                              final entry = sorted[i];
                              final left =
                                  _fractionForDate(
                                    entry.startDate,
                                    minDate,
                                    maxDate,
                                  ) *
                                  chartWidth;
                              final right =
                                  _fractionForDate(
                                    entry.endDate,
                                    minDate,
                                    maxDate,
                                  ) *
                                  chartWidth;
                              final width = math.max(10.0, right - left);

                              return Positioned(
                                left: left.clamp(0.0, chartWidth),
                                top: i * rowHeight + 8,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      _showTimelineEntryPopup(context, entry),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      width: width,
                                      height: rowHeight - 16,
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                          entry.statusSnapshot,
                                        ).withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: SizedBox(
                            height: veryCompact ? 30 : 22,
                            child: Stack(
                              children: [
                                for (final tick in tickLabels)
                                  Positioned(
                                    left: tick.left,
                                    child: Transform.rotate(
                                      angle: veryCompact ? -0.35 : 0,
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        _formatMonthTick(
                                          tick.date,
                                          compact: compact,
                                        ),
                                        style: AppTextStyles.style(
                                          fontSize: veryCompact ? 9 : 11,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _LegendChip(
                  label: 'Not Started / Pending',
                  color: Color(0xFF6B7280),
                ),
                _LegendChip(label: 'In Progress', color: Color(0xFF1D8CF8)),
                _LegendChip(label: 'Overdue', color: Color(0xFFE53950)),
                _LegendChip(label: 'Finished', color: Color(0xFF1F8C54)),
              ],
            ),
            const SizedBox(height: 14),
            _ProjectTimelineTable(entries: sorted),
          ],
        );
      },
    );
  }
}

class _ProjectTimelineTable extends StatelessWidget {
  const _ProjectTimelineTable({required this.entries});

  final List<_ProjectTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in entries) ...[
          _ProjectTimelineInfoCard(entry: entry),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ProjectTimelineInfoCard extends StatelessWidget {
  const _ProjectTimelineInfoCard({required this.entry});

  final _ProjectTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.projectName,
            style: AppTextStyles.style(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ProjectInfoField(
                  label: 'Start Date',
                  value: _formatDisplayDate(entry.startDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProjectInfoField(
                  label: 'End Date',
                  value: _formatDisplayDate(entry.endDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProjectInfoField(
            label: 'Status',
            value: entry.statusSnapshot,
            valueColor: _statusColor(entry.statusSnapshot),
            valueWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

class _ProjectInfoField extends StatelessWidget {
  const _ProjectInfoField({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueWeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.style(
            fontSize: 13,
            fontWeight: valueWeight ?? FontWeight.w500,
            color: valueColor ?? const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

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
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.style(
            fontSize: 11.5,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Text(
          'No analytics data available.',
          style: AppTextStyles.style(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _StaffProjectAnalyticsData {
  const _StaffProjectAnalyticsData({
    required this.projectStatusDistribution,
    required this.taskStatusDistribution,
    required this.timelineEntries,
    required this.taskStatusOverview,
  });

  final Map<String, int> projectStatusDistribution;
  final Map<String, int> taskStatusDistribution;
  final List<_ProjectTimelineEntry> timelineEntries;
  final Map<String, int> taskStatusOverview;

  factory _StaffProjectAnalyticsData.empty() {
    return const _StaffProjectAnalyticsData(
      projectStatusDistribution: <String, int>{},
      taskStatusDistribution: <String, int>{},
      timelineEntries: <_ProjectTimelineEntry>[],
      taskStatusOverview: <String, int>{},
    );
  }

  factory _StaffProjectAnalyticsData.fromPayload(Map<String, dynamic> payload) {
    _debugAnalyticsLog(
      '[StaffProjectAnalytics] parser start payloadKeys=${payload.keys.toList()}',
    );
    final flat = <String, dynamic>{};

    String normalizeKey(String key) =>
        key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    void collect(dynamic source) {
      if (source is Map) {
        source.forEach((key, value) {
          flat[normalizeKey(key.toString())] = value;
          collect(value);
        });
      } else if (source is List) {
        for (final item in source) {
          collect(item);
        }
      }
    }

    collect(payload);
    _debugAnalyticsLog(
      '[StaffProjectAnalytics] flattened key count=${flat.length}',
    );

    dynamic readAny(List<String> keys) {
      for (final key in keys) {
        final direct = payload[key];
        if (direct != null) return direct;
        final flattened = flat[normalizeKey(key)];
        if (flattened != null) return flattened;
      }
      return null;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse((value ?? '').toString().trim()) ?? 0;
    }

    Map<String, int> parseDistribution(dynamic source) {
      final result = <String, int>{};
      _debugAnalyticsDump(
        '[StaffProjectAnalytics] parseDistribution source',
        source,
      );

      int readCount(dynamic value) {
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is Map) {
          final map = value.map((key, nestedValue) {
            return MapEntry(key.toString(), nestedValue);
          });
          for (final key in const [
            'count',
            'total',
            'value',
            'tasks',
            'task_count',
          ]) {
            final parsed = parseInt(map[key]);
            if (parsed != 0 || map.containsKey(key)) {
              return parsed;
            }
          }
        }
        return int.tryParse((value ?? '').toString().trim()) ?? 0;
      }

      if (source is Map) {
        final map = source.map((key, value) => MapEntry(key.toString(), value));
        final labels = map['labels'];
        final series = map['series'] ?? map['data'] ?? map['counts'];
        if (labels is List && series is List) {
          final maxLen = math.min(labels.length, series.length);
          for (var i = 0; i < maxLen; i++) {
            final label = _prettyStatusLabel(labels[i]);
            if (label.isEmpty) continue;
            result[label] = readCount(series[i]);
          }
          _debugAnalyticsLog(
            '[StaffProjectAnalytics] parseDistribution labels/series result=$result',
          );
          return result;
        }

        final nestedList =
            map['data'] ??
            map['items'] ??
            map['statuses'] ??
            map['distribution'];
        if (nestedList is List) {
          return parseDistribution(nestedList);
        }

        var usedStructuredMap = false;
        map.forEach((key, value) {
          final label = _prettyStatusLabel(key);
          if (label.isEmpty) return;
          final count = readCount(value);
          if (count <= 0 && value is! num && value is! String) {
            return;
          }
          usedStructuredMap = true;
          result[label] = count;
        });
        if (usedStructuredMap) {
          _debugAnalyticsLog(
            '[StaffProjectAnalytics] parseDistribution structured map result=$result',
          );
          return result;
        }
      }

      if (source is List) {
        for (final item in source) {
          if (item is! Map) continue;
          final map = item.map((key, value) => MapEntry(key.toString(), value));
          final label = _prettyStatusLabel(
            map['status'] ??
                map['name'] ??
                map['label'] ??
                map['key'] ??
                map['title'],
          );
          if (label.isEmpty) continue;
          result[label] = readCount(
            map['count'] ?? map['value'] ?? map['total'] ?? map['tasks'],
          );
        }
      }
      _debugAnalyticsLog(
        '[StaffProjectAnalytics] parseDistribution list result=$result',
      );
      return result;
    }

    List<_ProjectTimelineEntry> parseTimeline(dynamic source) {
      final result = <_ProjectTimelineEntry>[];
      if (source is List) {
        for (final item in source) {
          if (item is! Map) continue;
          final map = item.map((key, value) => MapEntry(key.toString(), value));
          final projectName = _readFirstString(map, const [
            'project',
            'project_name',
            'name',
            'title',
          ]);
          final startDate = _parseDate(
            _readFirstValue(map, const [
              'start_date',
              'startDate',
              'started_at',
              'from',
            ]),
          );
          final endDate = _parseDate(
            _readFirstValue(map, const [
              'end_date',
              'endDate',
              'deadline',
              'due_date',
              'to',
              'finished_at',
            ]),
          );
          final snapshot = _readFirstString(map, const [
            'difference_label',
            'status_label',
            'status_snapshot',
            'statusSnapshot',
            'snapshot',
            'remarks',
            'note',
            'status',
          ]);
          if (projectName.isEmpty || startDate == null || endDate == null) {
            continue;
          }
          result.add(
            _ProjectTimelineEntry(
              projectName: projectName,
              startDate: startDate,
              endDate: endDate,
              statusSnapshot: _resolveTimelineStatusSnapshot(
                source: map,
                fallback: snapshot,
              ),
            ),
          );
        }
        return result;
      }

      if (source is Map) {
        final map = source.map((key, value) => MapEntry(key.toString(), value));
        final projects =
            map['projects'] ?? map['items'] ?? map['rows'] ?? map['data'];
        if (projects is List) {
          return parseTimeline(projects);
        }

        final names = map['labels'] ?? map['projects'] ?? map['names'];
        final starts = map['start_dates'] ?? map['startDates'];
        final ends = map['end_dates'] ?? map['endDates'];
        final snapshots = map['status_snapshots'] ?? map['statusSnapshots'];
        final statusLabels = map['status_labels'] ?? map['statusLabels'];
        final differenceLabels =
            map['difference_labels'] ?? map['differenceLabels'];
        final overdueFlags = map['is_overdue_list'] ?? map['isOverdueList'];
        if (names is List && starts is List && ends is List) {
          final maxLen = math.min(
            names.length,
            math.min(starts.length, ends.length),
          );
          for (var i = 0; i < maxLen; i++) {
            final startDate = _parseDate(starts[i]);
            final endDate = _parseDate(ends[i]);
            if (startDate == null || endDate == null) continue;
            result.add(
              _ProjectTimelineEntry(
                projectName: names[i].toString().trim(),
                startDate: startDate,
                endDate: endDate,
                statusSnapshot: _resolveTimelineStatusSnapshot(
                  source: <String, dynamic>{
                    'status_snapshot':
                        i < (snapshots is List ? snapshots.length : 0)
                        ? snapshots[i]
                        : null,
                    'status_label':
                        i < (statusLabels is List ? statusLabels.length : 0)
                        ? statusLabels[i]
                        : null,
                    'difference_label':
                        i <
                            (differenceLabels is List
                                ? differenceLabels.length
                                : 0)
                        ? differenceLabels[i]
                        : null,
                    'is_overdue':
                        i < (overdueFlags is List ? overdueFlags.length : 0)
                        ? overdueFlags[i]
                        : null,
                  },
                ),
              ),
            );
          }
        }
      }
      return result;
    }

    final projectStatus = parseDistribution(
      readAny(const [
        'project_status_distribution',
        'projectStatusDistribution',
        'project_status',
        'projectStatus',
        'projects_by_status',
        'project_statuses',
        'projectStatuses',
        'project_status_analytics',
        'projectStatusAnalytics',
        'status_distribution',
        'statusDistribution',
      ]),
    );
    final taskStatus = parseDistribution(
      readAny(const [
        'task_status_distribution',
        'taskStatusDistribution',
        'task_status',
        'taskStatus',
        'tasks_by_status',
      ]),
    );
    final timeline = parseTimeline(
      readAny(const [
        'monthly_project_timeline',
        'monthlyProjectTimeline',
        'project_timeline',
        'projectTimeline',
        'timeline',
        'project_schedule',
      ]),
    );
    final taskOverviewRaw = parseDistribution(
      readAny(const [
        'task_status_overview',
        'taskStatusOverview',
        'task_overview',
        'taskOverview',
        'task_summary',
        'taskSummary',
      ]),
    );

    final taskOverview = <String, int>{};
    if (taskOverviewRaw.isNotEmpty) {
      taskOverview.addAll(taskOverviewRaw);
    } else {
      for (final key in const [
        'Pending',
        'Not started',
        'In progress',
        'Overdue',
        'Completed',
      ]) {
        if (taskStatus.containsKey(key)) {
          taskOverview[key] = taskStatus[key]!;
        }
      }
    }

    _debugAnalyticsLog(
      '[StaffProjectAnalytics] parser result projectStatus=$projectStatus taskStatus=$taskStatus timeline=${timeline.length} taskOverview=$taskOverview',
    );
    return _StaffProjectAnalyticsData(
      projectStatusDistribution: projectStatus,
      taskStatusDistribution: taskStatus,
      timelineEntries: timeline,
      taskStatusOverview: taskOverview,
    );
  }
}

class _ProjectTimelineEntry {
  const _ProjectTimelineEntry({
    required this.projectName,
    required this.startDate,
    required this.endDate,
    required this.statusSnapshot,
  });

  final String projectName;
  final DateTime startDate;
  final DateTime endDate;
  final String statusSnapshot;
}

Future<void> _showTimelineEntryPopup(
  BuildContext context,
  _ProjectTimelineEntry entry,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (dialogContext) {
      return Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD7DFEA)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x220F172A),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.projectName,
                    style: AppTextStyles.style(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start: ${_formatDisplayDate(entry.startDate)}',
                    style: AppTextStyles.style(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'End: ${_formatDisplayDate(entry.endDate)}',
                    style: AppTextStyles.style(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.statusSnapshot,
                    style: AppTextStyles.style(
                      fontSize: 12,
                      color: _statusColor(entry.statusSnapshot),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _debugAnalyticsLog(String message) {
  if (!kDebugMode) return;
  debugPrint(message);
}

void _debugAnalyticsDump(String label, dynamic value) {
  if (!kDebugMode) return;
  _debugAnalyticsLog('$label:');
  late final String text;
  try {
    text = const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    text = value.toString();
  }
  for (var index = 0; index < text.length; index += 800) {
    final end = (index + 800 < text.length) ? index + 800 : text.length;
    debugPrint(text.substring(index, end));
  }
}

String _resolveTimelineStatusSnapshot({
  required Map<String, dynamic> source,
  String fallback = '',
}) {
  final isOverdue =
      source['is_overdue'] == true ||
      source['isOverdue'] == true ||
      source['overdue'] == true;
  if (isOverdue) {
    final differenceLabel =
        (source['difference_label'] ?? source['differenceLabel'] ?? '')
            .toString()
            .trim();
    if (differenceLabel.isNotEmpty) {
      return differenceLabel;
    }

    final statusLabel =
        (source['status_label'] ?? source['statusLabel'] ?? 'Overdue')
            .toString()
            .trim();
    if (statusLabel.isNotEmpty) {
      return statusLabel;
    }
    return 'Overdue';
  }

  for (final key in const [
    'difference_label',
    'differenceLabel',
    'status_label',
    'statusLabel',
    'status_snapshot',
    'statusSnapshot',
    'snapshot',
    'remarks',
    'note',
  ]) {
    final value = source[key];
    final text = value == null ? '' : value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }

  if (fallback.trim().isNotEmpty) {
    return fallback.trim();
  }

  return _prettyStatusLabel(source['status']);
}

List<MapEntry<String, int>> _sortEntries(
  Map<String, int> entries,
  List<String> preferredOrder,
) {
  final normalizedOrder = <String, int>{
    for (var i = 0; i < preferredOrder.length; i++)
      preferredOrder[i].toLowerCase(): i,
  };
  final items = entries.entries.where((entry) => entry.value > 0).toList();
  items.sort((a, b) {
    final aOrder = normalizedOrder[a.key.toLowerCase()] ?? 999;
    final bOrder = normalizedOrder[b.key.toLowerCase()] ?? 999;
    if (aOrder != bOrder) return aOrder.compareTo(bOrder);
    return b.value.compareTo(a.value);
  });
  return items;
}

Color _statusColor(String rawStatus) {
  final value = rawStatus.toLowerCase().trim();
  if (value.contains('cancel')) return const Color(0xFFE53950);
  if (value.contains('overdue')) return const Color(0xFFE53950);
  if (value.contains('complete') || value.contains('finish')) {
    return const Color(0xFF1F8C54);
  }
  if (value.contains('progress')) return const Color(0xFF23A0B8);
  if (value.contains('hold')) return const Color(0xFFF8B400);
  if (value.contains('pending')) return const Color(0xFF6B7280);
  if (value.contains('not') && value.contains('start')) {
    return const Color(0xFF2563EB);
  }
  return const Color(0xFF2563EB);
}

String _prettyStatusLabel(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return '';
  final normalized = text.toLowerCase().replaceAll('_', ' ');
  if (normalized == 'not started' || normalized == 'notstart') {
    return 'Not started';
  }
  if (normalized == 'in progress' || normalized == 'inprogress') {
    return 'In progress';
  }
  if (normalized == 'on hold' || normalized == 'onhold') {
    return 'On hold';
  }
  if (normalized == 'completed' || normalized == 'complete') {
    return 'Completed';
  }
  if (normalized == 'cancelled' || normalized == 'canceled') {
    return 'Cancelled';
  }
  if (normalized == 'pending') {
    return 'Pending';
  }
  if (normalized == 'overdue') {
    return 'Overdue';
  }
  return text
      .split(RegExp(r'[\s_]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

dynamic _readFirstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value != null) return value;
  }
  return null;
}

String _readFirstString(Map<String, dynamic> source, List<String> keys) {
  final value = _readFirstValue(source, keys);
  return value == null ? '' : value.toString().trim();
}

DateTime? _parseDate(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;

  final direct = DateTime.tryParse(text);
  if (direct != null) return DateTime(direct.year, direct.month, direct.day);

  final normalized = text.replaceAll(',', '');
  final tokens = normalized
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (tokens.length >= 3) {
    final monthIndex = _monthIndex(tokens[0]);
    final day = int.tryParse(tokens[1]);
    final year = int.tryParse(tokens[2]);
    if (monthIndex != null && day != null && year != null) {
      return DateTime(year, monthIndex, day);
    }
  }

  final slashMatch = RegExp(
    r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$',
  ).firstMatch(text);
  if (slashMatch != null) {
    final part1 = int.tryParse(slashMatch.group(1)!);
    final part2 = int.tryParse(slashMatch.group(2)!);
    final part3 = int.tryParse(slashMatch.group(3)!);
    if (part1 != null && part2 != null && part3 != null) {
      final year = part3 < 100 ? 2000 + part3 : part3;
      return DateTime(year, part1, part2);
    }
  }

  return null;
}

int? _monthIndex(String token) {
  const months = <String, int>{
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };
  return months[token.toLowerCase()];
}

List<DateTime> _buildMonthTicks(DateTime start, DateTime end) {
  final ticks = <DateTime>[];
  var cursor = DateTime(start.year, start.month, 1);
  final last = DateTime(end.year, end.month, 1);
  while (!cursor.isAfter(last)) {
    ticks.add(cursor);
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }
  if (ticks.isEmpty) {
    ticks.add(DateTime(start.year, start.month, 1));
  }
  return ticks;
}

double _fractionForDate(DateTime date, DateTime start, DateTime end) {
  final total = math.max(1, end.difference(start).inHours);
  final current = date.difference(start).inHours.clamp(0, total);
  return current / total;
}

String _formatMonthTick(DateTime date, {bool compact = false}) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (!compact) {
    return '${months[date.month - 1]} ${date.year}';
  }
  return '${months[date.month - 1]} ${date.year.toString().substring(2)}';
}

String _formatDisplayDate(DateTime date, {bool compact = false}) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (compact) {
    return '${months[date.month - 1]} ${date.day}';
  }
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

List<DateTime> _filterMonthTicks(
  List<DateTime> ticks,
  double chartWidth, {
  required double minimumSpacing,
}) {
  if (ticks.length <= 1) return ticks;
  final maxTicks = math.max(1, (chartWidth / minimumSpacing).floor());
  if (ticks.length <= maxTicks) return ticks;
  final step = math.max(1, (ticks.length / maxTicks).ceil());
  final filtered = <DateTime>[];
  for (var i = 0; i < ticks.length; i += step) {
    filtered.add(ticks[i]);
  }
  if (filtered.last != ticks.last) {
    filtered.add(ticks.last);
  }
  return filtered;
}

List<_TickLabelPosition> _buildTickLabels(
  List<DateTime> ticks,
  double chartWidth,
  DateTime minDate,
  DateTime maxDate, {
  required bool compact,
  required bool veryCompact,
}) {
  if (ticks.isEmpty) return const <_TickLabelPosition>[];

  final result = <_TickLabelPosition>[];
  final estimatedLabelWidth = veryCompact ? 34.0 : (compact ? 42.0 : 54.0);
  final maxLeft = math.max(0.0, chartWidth - estimatedLabelWidth);
  double lastRight = -double.infinity;

  for (var i = 0; i < ticks.length; i++) {
    final tick = ticks[i];
    final rawLeft =
        _fractionForDate(tick, minDate, maxDate) * chartWidth -
        (estimatedLabelWidth / 2);
    final left = rawLeft.clamp(0.0, maxLeft);
    final right = left + estimatedLabelWidth;

    final isLast = i == ticks.length - 1;
    if (!isLast && left < lastRight + 6) {
      continue;
    }

    if (isLast && result.isNotEmpty && left < lastRight + 6) {
      final adjustedLeft = (lastRight + 6).clamp(0.0, maxLeft);
      if (adjustedLeft + estimatedLabelWidth <= chartWidth) {
        result.add(_TickLabelPosition(date: tick, left: adjustedLeft));
      }
      continue;
    }

    result.add(_TickLabelPosition(date: tick, left: left));
    lastRight = right;
  }

  return result;
}

class _TickLabelPosition {
  const _TickLabelPosition({required this.date, required this.left});

  final DateTime date;
  final double left;
}
