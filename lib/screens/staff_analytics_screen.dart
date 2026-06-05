import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

class StaffAnalyticsScreen extends StatefulWidget {
  const StaffAnalyticsScreen({
    super.key,
    required this.staffId,
    this.staffName,
  });

  final String staffId;
  final String? staffName;

  @override
  State<StaffAnalyticsScreen> createState() => _StaffAnalyticsScreenState();
}

class _StaffAnalyticsScreenState extends State<StaffAnalyticsScreen> {
  late Future<_StaffAnalyticsViewData> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _loadAnalytics();
  }

  Future<_StaffAnalyticsViewData> _loadAnalytics() async {
    final responses = await Future.wait<Map<String, dynamic>>([
      ApiService.instance.getStaffAnalytics(widget.staffId),
      ApiService.instance.getStaffLeadChart(widget.staffId),
      ApiService.instance.getStaffFollowupChart(widget.staffId),
    ]);
    return _StaffAnalyticsViewData.fromPayload(
      responses[0],
      leadChartPayload: responses[1],
      followupChartPayload: responses[2],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CommonScreenAppBar(
        title: widget.staffName?.trim().isNotEmpty == true
            ? '${widget.staffName!.trim()} Analytics'
            : 'Staff Analytics',
      ),
      body: FutureBuilder<_StaffAnalyticsViewData>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load analytics right now.',
                  style: AppTextStyles.style(fontSize: 14),
                ),
              ),
            );
          }

          final data = snapshot.data ?? _StaffAnalyticsViewData.empty();
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _analyticsFuture = _loadAnalytics());
              await _analyticsFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                _SectionCard(
                  title: 'Monthly Lead Conversion',
                  child: _LeadConversionChart(points: data.leadConversion),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Monthly Followup Activity',
                  child: _FollowupActivityChart(
                    months: data.followupMonths,
                    activity: data.followupByType,
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Lead Status Distribution',
                  child: _LeadStatusChart(entries: data.leadStatusDistribution),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Followup Outcome Distribution',
                  child: _LeadStatusChart(
                    entries: data.followupOutcomeDistribution,
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Daily Activity Timeline (30d)',
                  child: _DailyActivityTimelineChart(
                    points: data.dailyTimeline,
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Assigned vs Converted (Monthly)',
                  child: _AssignedConvertedBarChart(
                    points: data.leadConversion,
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

class _LeadConversionChart extends StatelessWidget {
  const _LeadConversionChart({required this.points});

  final List<_LeadConversionPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _EmptyChartState();
    }

    final assignedSpots = <FlSpot>[];
    final convertedSpots = <FlSpot>[];
    double maxY = 0;

    for (var i = 0; i < points.length; i++) {
      assignedSpots.add(FlSpot(i.toDouble(), points[i].assigned.toDouble()));
      convertedSpots.add(FlSpot(i.toDouble(), points[i].converted.toDouble()));
      maxY = math.max(
        maxY,
        math.max(points[i].assigned.toDouble(), points[i].converted.toDouble()),
      );
    }
    if (maxY <= 0) maxY = 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _safeChartWidth(context, constraints);
        final compact = width < 380;
        final chartHeight = compact ? 220.0 : 240.0;
        final labelStep = _labelStep(
          points.length,
          width,
          minimumPixelsPerLabel: 68,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: chartHeight,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY + 1,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: math.max(1, (maxY / 3).ceilToDouble()),
                    drawVerticalLine: false,
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
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: compact ? 24 : 28,
                        interval: math.max(1, (maxY / 3).ceilToDouble()),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: compact ? 40 : 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 ||
                              idx >= points.length ||
                              idx % labelStep != 0) {
                            return const SizedBox.shrink();
                          }
                          final child = Text(
                            points[idx].monthLabel,
                            style: AppTextStyles.style(
                              fontSize: compact ? 9 : 10,
                            ),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: compact
                                ? Transform.rotate(angle: -0.45, child: child)
                                : child,
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: assignedSpots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: const Color(0xFF2563EB),
                      barWidth: compact ? 2.1 : 2.5,
                      dotData: FlDotData(show: !compact),
                    ),
                    LineChartBarData(
                      spots: convertedSpots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: const Color(0xFF16A34A),
                      barWidth: compact ? 2.1 : 2.5,
                      dotData: FlDotData(show: !compact),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _LegendRow(
              items: [
                _LegendItem('Assigned', Color(0xFF2563EB)),
                _LegendItem('Converted', Color(0xFF16A34A)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FollowupActivityChart extends StatelessWidget {
  const _FollowupActivityChart({required this.months, required this.activity});

  final List<String> months;
  final Map<String, List<int>> activity;

  static const List<Color> _palette = <Color>[
    Color(0xFF0284C7),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFF43F5E),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF97316),
    Color(0xFFE11D48),
  ];

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty || activity.isEmpty) {
      return const _EmptyChartState();
    }

    final types = activity.keys.toList(growable: false);
    final monthCount = months.length;
    double maxY = 0;

    for (var monthIndex = 0; monthIndex < monthCount; monthIndex++) {
      for (var typeIndex = 0; typeIndex < types.length; typeIndex++) {
        final values = activity[types[typeIndex]] ?? const <int>[];
        final double y = monthIndex < values.length
            ? values[monthIndex].toDouble()
            : 0.0;
        maxY = math.max(maxY, y);
      }
    }
    if (maxY <= 0) maxY = 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _safeChartWidth(context, constraints);
        final compact = width < 380;
        final labelStep = _labelStep(
          months.length,
          width,
          minimumPixelsPerLabel: 72,
        );
        final rodWidth = compact ? 5.0 : 7.0;
        final barGroups = <BarChartGroupData>[
          for (var monthIndex = 0; monthIndex < monthCount; monthIndex++)
            BarChartGroupData(
              x: monthIndex,
              barsSpace: compact ? 1.5 : 2,
              barRods: [
                for (var typeIndex = 0; typeIndex < types.length; typeIndex++)
                  BarChartRodData(
                    toY:
                        monthIndex <
                            (activity[types[typeIndex]] ?? const <int>[]).length
                        ? (activity[types[typeIndex]] ??
                                  const <int>[])[monthIndex]
                              .toDouble()
                        : 0.0,
                    width: rodWidth,
                    color: _palette[typeIndex % _palette.length],
                    borderRadius: BorderRadius.circular(2),
                    rodStackItems: const [],
                    backDrawRodData: BackgroundBarChartRodData(show: false),
                  ),
              ],
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: compact ? 230 : 250,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  minY: 0,
                  maxY: maxY + 1,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: math.max(1, (maxY / 3).ceilToDouble()),
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
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: compact ? 24 : 28,
                        interval: math.max(1, (maxY / 3).ceilToDouble()),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: compact ? 40 : 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= months.length ||
                              index % labelStep != 0) {
                            return const SizedBox.shrink();
                          }
                          final child = Text(
                            months[index],
                            style: AppTextStyles.style(
                              fontSize: compact ? 9 : 10,
                            ),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: compact
                                ? Transform.rotate(angle: -0.45, child: child)
                                : child,
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(enabled: true),
                ),
                swapAnimationDuration: const Duration(milliseconds: 250),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: compact ? 10 : 12,
              runSpacing: 8,
              children: [
                for (var i = 0; i < types.length; i++)
                  _LegendChip(
                    label: types[i],
                    color: _palette[i % _palette.length],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LeadStatusChart extends StatelessWidget {
  const _LeadStatusChart({required this.entries});

  final Map<String, int> entries;

  static const List<Color> _colors = <Color>[
    Color(0xFF2563EB),
    Color(0xFF6B7280),
    Color(0xFF0EA5A4),
    Color(0xFF16A34A),
    Color(0xFFEAB308),
    Color(0xFF111827),
    Color(0xFFF97316),
    Color(0xFF22C55E),
    Color(0xFFEF4444),
    Color(0xFF9CA3AF),
  ];

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyChartState();
    }

    final total = entries.values.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return const _EmptyChartState();
    }

    final labels = entries.keys.toList(growable: false);
    final values = entries.values.toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _safeChartWidth(context, constraints);
        final isNarrow = width < 460;
        final isVeryNarrow = width < 340;
        final chartSize = isVeryNarrow ? 160.0 : (isNarrow ? 180.0 : 220.0);
        final centerSpace = isVeryNarrow ? 34.0 : (isNarrow ? 40.0 : 48.0);
        final sectionRadius = isVeryNarrow ? 44.0 : (isNarrow ? 50.0 : 58.0);
        final labelFont = isVeryNarrow ? 10.0 : (isNarrow ? 11.0 : 11.5);

        final chart = SizedBox(
          width: chartSize,
          height: chartSize,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: centerSpace,
              sectionsSpace: 2,
              sections: [
                for (var i = 0; i < labels.length; i++)
                  PieChartSectionData(
                    value: values[i].toDouble(),
                    color: _colors[i % _colors.length],
                    radius: sectionRadius,
                    title: '${((values[i] / total) * 100).toStringAsFixed(1)}%',
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
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colors[i % _colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${labels[i]} (${values[i]})',
                        style: AppTextStyles.style(fontSize: labelFont),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            chart,
            const SizedBox(width: 12),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _DailyActivityTimelineChart extends StatelessWidget {
  const _DailyActivityTimelineChart({required this.points});

  final List<_DailyTimelinePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const _EmptyChartState();

    final followupSpots = <FlSpot>[];
    final activitySpots = <FlSpot>[];
    double maxY = 0;

    for (var i = 0; i < points.length; i++) {
      final followups = points[i].followups.toDouble();
      final activities = points[i].activities.toDouble();
      followupSpots.add(FlSpot(i.toDouble(), followups));
      activitySpots.add(FlSpot(i.toDouble(), activities));
      maxY = math.max(maxY, math.max(followups, activities));
    }
    if (maxY <= 0) maxY = 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _safeChartWidth(context, constraints);
        final compact = width < 380;
        final labelStep = _labelStep(
          points.length,
          width,
          minimumPixelsPerLabel: 58,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: compact ? 230 : 250,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY + 1,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: math.max(1, (maxY / 3).ceilToDouble()),
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
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: compact ? 24 : 28,
                        interval: math.max(1, (maxY / 3).ceilToDouble()),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: compact ? 44 : 40,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= points.length ||
                              index % labelStep != 0) {
                            return const SizedBox.shrink();
                          }
                          return Transform.rotate(
                            angle: compact ? -0.75 : -0.6,
                            child: Text(
                              points[index].dayLabel,
                              style: AppTextStyles.style(
                                fontSize: compact ? 9 : 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: followupSpots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: const Color(0xFF0F8A5F),
                      barWidth: compact ? 2.2 : 2.8,
                      dotData: FlDotData(show: !compact),
                    ),
                    LineChartBarData(
                      spots: activitySpots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: const Color(0xFF06B6D4),
                      barWidth: compact ? 2.2 : 2.8,
                      dotData: FlDotData(show: !compact),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _LegendRow(
              items: [
                _LegendItem('Followups', Color(0xFF0F8A5F)),
                _LegendItem('Activities', Color(0xFF06B6D4)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AssignedConvertedBarChart extends StatelessWidget {
  const _AssignedConvertedBarChart({required this.points});

  final List<_LeadConversionPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const _EmptyChartState();

    final groups = <BarChartGroupData>[];
    double maxY = 0;

    for (var i = 0; i < points.length; i++) {
      final assigned = points[i].assigned.toDouble();
      final converted = points[i].converted.toDouble();
      maxY = math.max(maxY, math.max(assigned, converted));
      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: assigned,
              width: 10,
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(2),
            ),
            BarChartRodData(
              toY: converted,
              width: 10,
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    if (maxY <= 0) maxY = 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _safeChartWidth(context, constraints);
        final compact = width < 380;
        final labelStep = _labelStep(
          points.length,
          width,
          minimumPixelsPerLabel: 72,
        );
        final rodWidth = compact ? 8.0 : 10.0;
        final responsiveGroups = <BarChartGroupData>[
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: compact ? 3 : 4,
              barRods: [
                BarChartRodData(
                  toY: points[i].assigned.toDouble(),
                  width: rodWidth,
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: points[i].converted.toDouble(),
                  width: rodWidth,
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: compact ? 230 : 250,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY + 1,
                  barGroups: responsiveGroups,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: math.max(1, (maxY / 3).ceilToDouble()),
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
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: compact ? 24 : 28,
                        interval: math.max(1, (maxY / 3).ceilToDouble()),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: compact ? 40 : 34,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 ||
                              i >= points.length ||
                              i % labelStep != 0) {
                            return const SizedBox.shrink();
                          }
                          final child = Text(
                            points[i].monthLabel,
                            style: AppTextStyles.style(
                              fontSize: compact ? 9 : 10,
                            ),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: compact
                                ? Transform.rotate(angle: -0.45, child: child)
                                : child,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _LegendRow(
              items: [
                _LegendItem('Assigned', Color(0xFF2563EB)),
                _LegendItem('Converted', Color(0xFF16A34A)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final item in items)
          _LegendChip(label: item.label, color: item.color),
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
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: narrow ? 8 : 10,
          height: narrow ? 8 : 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: narrow ? 3 : 4),
        Text(label, style: AppTextStyles.style(fontSize: narrow ? 10.5 : 11.5)),
      ],
    );
  }
}

double _safeChartWidth(BuildContext context, BoxConstraints constraints) {
  if (constraints.maxWidth.isFinite) {
    return constraints.maxWidth;
  }
  return MediaQuery.sizeOf(context).width;
}

int _labelStep(
  int itemCount,
  double width, {
  required double minimumPixelsPerLabel,
}) {
  if (itemCount <= 1) return 1;
  final slots = math.max(1, (width / minimumPixelsPerLabel).floor());
  return math.max(1, (itemCount / slots).ceil());
}

class _LegendItem {
  const _LegendItem(this.label, this.color);
  final String label;
  final Color color;
}

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
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

class _StaffAnalyticsViewData {
  const _StaffAnalyticsViewData({
    required this.leadConversion,
    required this.followupMonths,
    required this.followupByType,
    required this.leadStatusDistribution,
    required this.followupOutcomeDistribution,
    required this.dailyTimeline,
  });

  final List<_LeadConversionPoint> leadConversion;
  final List<String> followupMonths;
  final Map<String, List<int>> followupByType;
  final Map<String, int> leadStatusDistribution;
  final Map<String, int> followupOutcomeDistribution;
  final List<_DailyTimelinePoint> dailyTimeline;

  factory _StaffAnalyticsViewData.empty() {
    return const _StaffAnalyticsViewData(
      leadConversion: <_LeadConversionPoint>[],
      followupMonths: <String>[],
      followupByType: <String, List<int>>{},
      leadStatusDistribution: <String, int>{},
      followupOutcomeDistribution: <String, int>{},
      dailyTimeline: <_DailyTimelinePoint>[],
    );
  }

  factory _StaffAnalyticsViewData.fromPayload(
    Map<String, dynamic> payload, {
    Map<String, dynamic>? leadChartPayload,
    Map<String, dynamic>? followupChartPayload,
  }) {
    final flattened = <String, dynamic>{};

    String normalizeKey(String key) =>
        key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    void collect(dynamic source) {
      if (source is Map) {
        source.forEach((key, value) {
          flattened[normalizeKey(key.toString())] = value;
          collect(value);
        });
      } else if (source is List) {
        for (final item in source) {
          collect(item);
        }
      }
    }

    collect(payload);

    dynamic readAny(List<String> keys) {
      for (final key in keys) {
        final direct = payload[key];
        if (direct != null) return direct;
        final normalized = flattened[normalizeKey(key)];
        if (normalized != null) return normalized;
      }
      return null;
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse((value ?? '').toString().trim()) ?? 0;
    }

    List<dynamic> asList(dynamic value) {
      if (value is List) return value;
      return const <dynamic>[];
    }

    List<int> toSeriesValues(dynamic raw, List<String> orderedLabels) {
      if (raw is List) {
        return List<int>.generate(
          orderedLabels.length,
          (i) => parseInt(i < raw.length ? raw[i] : 0),
        );
      }

      if (raw is Map) {
        final mapped = raw.map((key, value) => MapEntry(key.toString(), value));
        final normalizedValueByLabel = <String, int>{};
        mapped.forEach((key, value) {
          normalizedValueByLabel[key.toString().trim().toLowerCase()] =
              parseInt(value);
        });
        return orderedLabels
            .map((label) => normalizedValueByLabel[label.toLowerCase()] ?? 0)
            .toList(growable: false);
      }

      return List<int>.filled(orderedLabels.length, 0, growable: false);
    }

    String normalizeMonth(dynamic value) {
      final text = (value ?? '').toString().trim();
      if (text.isEmpty) return '';
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        const names = <String>[
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
        return '${names[parsed.month - 1]} ${parsed.year}';
      }
      return text;
    }

    dynamic readFrom(
      Map<String, dynamic> source,
      Map<String, dynamic> flat,
      List<String> keys,
    ) {
      for (final key in keys) {
        final direct = source[key];
        if (direct != null) return direct;
        final normalized = flat[normalizeKey(key)];
        if (normalized != null) return normalized;
      }
      return null;
    }

    final leadPayload = leadChartPayload ?? const <String, dynamic>{};
    final followupPayload = followupChartPayload ?? const <String, dynamic>{};

    final leadFlat = <String, dynamic>{};
    final followupFlat = <String, dynamic>{};
    collectTo(Map<String, dynamic> out, dynamic source) {
      if (source is Map) {
        source.forEach((key, value) {
          out[normalizeKey(key.toString())] = value;
          collectTo(out, value);
        });
      } else if (source is List) {
        for (final item in source) {
          collectTo(out, item);
        }
      }
    }

    collectTo(leadFlat, leadPayload);
    collectTo(followupFlat, followupPayload);

    final hasRootLeadArrays =
        leadPayload['labels'] is List &&
        leadPayload['assigned'] is List &&
        leadPayload['converted'] is List;
    final hasRootFollowupSeries =
        followupPayload['labels'] is List && followupPayload['series'] is List;

    final conversionSource = hasRootLeadArrays
        ? leadPayload
        : readFrom(leadPayload, leadFlat, const [
                'monthly_lead_conversion',
                'lead_conversion_monthly',
                'lead_conversion_trend',
                'lead_conversion',
                'conversion_monthly',
                'assigned_vs_converted_monthly',
                'monthly',
                'chart',
                'data',
              ]) ??
              readAny(const [
                'monthly_lead_conversion',
                'lead_conversion_monthly',
                'lead_conversion_trend',
                'lead_conversion',
                'conversion_monthly',
              ]);

    final conversion = <_LeadConversionPoint>[];
    if (conversionSource is List) {
      for (final row in conversionSource) {
        if (row is! Map) continue;
        final map = row.map((key, value) => MapEntry(key.toString(), value));
        final month = normalizeMonth(
          map['month'] ?? map['label'] ?? map['date'],
        );
        final assigned = parseInt(
          map['assigned'] ?? map['total_assigned'] ?? map['leads_assigned'],
        );
        final converted = parseInt(
          map['converted'] ?? map['total_converted'] ?? map['leads_converted'],
        );
        if (month.isEmpty) continue;
        conversion.add(
          _LeadConversionPoint(
            monthLabel: month,
            assigned: assigned,
            converted: converted,
          ),
        );
      }
    } else if (conversionSource is Map) {
      final map = conversionSource.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final labels = asList(map['labels']);
      final assignedList = asList(map['assigned']);
      final convertedList = asList(map['converted']);
      final maxLen = math.max(
        labels.length,
        math.max(assignedList.length, convertedList.length),
      );
      for (var i = 0; i < maxLen; i++) {
        final month = normalizeMonth(i < labels.length ? labels[i] : '');
        if (month.isEmpty) continue;
        conversion.add(
          _LeadConversionPoint(
            monthLabel: month,
            assigned: parseInt(i < assignedList.length ? assignedList[i] : 0),
            converted: parseInt(
              i < convertedList.length ? convertedList[i] : 0,
            ),
          ),
        );
      }
    }

    final followupSource = hasRootFollowupSeries
        ? followupPayload
        : readFrom(followupPayload, followupFlat, const [
                'monthly_followup_activity',
                'followup_activity_monthly',
                'followup_monthly',
                'followups_by_month',
                'monthly',
                'chart',
                'data',
              ]) ??
              readAny(const [
                'monthly_followup_activity',
                'followup_activity_monthly',
                'followup_monthly',
                'followups_by_month',
              ]);

    final followupMonths = <String>[];
    final followupByType = <String, List<int>>{};
    if (followupSource is List) {
      for (
        var monthIndex = 0;
        monthIndex < followupSource.length;
        monthIndex++
      ) {
        final row = followupSource[monthIndex];
        if (row is! Map) continue;
        final map = row.map((key, value) => MapEntry(key.toString(), value));
        final month = normalizeMonth(
          map['month'] ?? map['label'] ?? map['date'],
        );
        if (month.isEmpty) continue;
        followupMonths.add(month);

        final typeMapSource =
            map['types'] ??
            map['followup_types'] ??
            map['activity'] ??
            map['counts'];
        if (typeMapSource is Map) {
          typeMapSource.forEach((key, value) {
            final name = key.toString().trim();
            if (name.isEmpty) return;
            followupByType.putIfAbsent(name, () => <int>[]);
            final bucket = followupByType[name]!;
            while (bucket.length < followupMonths.length - 1) {
              bucket.add(0);
            }
            bucket.add(parseInt(value));
          });
        }
      }
      for (final bucket in followupByType.values) {
        while (bucket.length < followupMonths.length) {
          bucket.add(0);
        }
      }
    } else if (followupSource is Map) {
      final map = followupSource.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final labels = asList(map['labels']);
      final rawSeries = map['series'];
      for (final label in labels) {
        final month = normalizeMonth(label);
        if (month.isNotEmpty) {
          followupMonths.add(month);
        }
      }
      if (rawSeries is List) {
        var unnamedIndex = 1;
        for (final entry in rawSeries) {
          if (entry is! Map) continue;
          final s = entry.map((key, value) => MapEntry(key.toString(), value));
          final rawName = (s['name'] ?? s['label'] ?? s['type'] ?? '')
              .toString()
              .trim();
          final name = rawName.isEmpty ? 'Series $unnamedIndex' : rawName;
          unnamedIndex++;
          if (name.isEmpty) continue;
          final rawData =
              s['data'] ??
              s['series'] ??
              s['values'] ??
              s['counts'] ??
              s['value'];
          if (rawData != null) {
            followupByType[name] = toSeriesValues(rawData, followupMonths);
            continue;
          }

          // Fallback: some APIs provide month keys directly on the series item.
          final monthKeyMap = <String, dynamic>{};
          s.forEach((key, value) {
            final lower = key.toLowerCase();
            if (lower == 'name' ||
                lower == 'label' ||
                lower == 'type' ||
                lower == 'id') {
              return;
            }
            monthKeyMap[key] = value;
          });
          followupByType[name] = toSeriesValues(monthKeyMap, followupMonths);
        }
      } else if (rawSeries is Map) {
        rawSeries.forEach((key, value) {
          final name = key.toString().trim();
          if (name.isEmpty) return;
          followupByType[name] = toSeriesValues(value, followupMonths);
        });
      }
    }

    final statusSource = readAny(const [
      'lead_status_distribution',
      'status_distribution',
      'lead_status_counts',
      'lead_status',
    ]);
    final statusDistribution = <String, int>{};
    if (statusSource is Map) {
      final map = statusSource.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final labels = asList(map['labels']);
      final series = asList(map['series']);
      if (labels.isNotEmpty && series.isNotEmpty) {
        final maxLen = math.min(labels.length, series.length);
        for (var i = 0; i < maxLen; i++) {
          final name = labels[i].toString().trim();
          if (name.isEmpty) continue;
          statusDistribution[name] = parseInt(series[i]);
        }
      } else {
        map.forEach((key, value) {
          final name = key.toString().trim();
          if (name.isEmpty) return;
          statusDistribution[name] = parseInt(value);
        });
      }
    } else if (statusSource is List) {
      for (final row in statusSource) {
        if (row is! Map) continue;
        final map = row.map((key, value) => MapEntry(key.toString(), value));
        final name = (map['status'] ?? map['name'] ?? map['label'] ?? '')
            .toString()
            .trim();
        if (name.isEmpty) continue;
        statusDistribution[name] = parseInt(map['count'] ?? map['value']);
      }
    }

    final followupOutcomeSource =
        readFrom(followupPayload, followupFlat, const [
          'followup_outcome_distribution',
          'followup_outcomes',
          'outcome_distribution',
          'followup_status_distribution',
          'outcomes',
        ]) ??
        readAny(const [
          'followup_outcome_distribution',
          'followup_outcomes',
          'outcome_distribution',
          'followup_status_distribution',
        ]);
    final followupOutcomeDistribution = <String, int>{};
    if (followupOutcomeSource is Map) {
      final map = followupOutcomeSource.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final labels = asList(map['labels']);
      final series = asList(map['series']);
      if (labels.isNotEmpty && series.isNotEmpty) {
        final maxLen = math.min(labels.length, series.length);
        for (var i = 0; i < maxLen; i++) {
          final name = labels[i].toString().trim();
          if (name.isEmpty) continue;
          followupOutcomeDistribution[name] = parseInt(series[i]);
        }
      } else {
        map.forEach((key, value) {
          final name = key.toString().trim();
          if (name.isEmpty) return;
          followupOutcomeDistribution[name] = parseInt(value);
        });
      }
    } else if (followupOutcomeSource is List) {
      for (final row in followupOutcomeSource) {
        if (row is! Map) continue;
        final map = row.map((key, value) => MapEntry(key.toString(), value));
        final name = (map['outcome'] ?? map['status'] ?? map['name'] ?? '')
            .toString()
            .trim();
        if (name.isEmpty) continue;
        followupOutcomeDistribution[name] = parseInt(
          map['count'] ?? map['value'],
        );
      }
    }

    final timelineSource =
        readFrom(followupPayload, followupFlat, const [
          'daily_activity_timeline',
          'daily_timeline',
          'activity_timeline',
          'timeline_30d',
          'daily',
          'timeline',
        ]) ??
        readAny(const [
          'daily_activity_timeline',
          'daily_timeline',
          'activity_timeline',
          'timeline_30d',
        ]);
    final dailyTimeline = <_DailyTimelinePoint>[];
    if (timelineSource is List) {
      for (final row in timelineSource) {
        if (row is! Map) continue;
        final map = row.map((key, value) => MapEntry(key.toString(), value));
        final rawDate =
            map['date'] ?? map['day'] ?? map['label'] ?? map['timeline_date'];
        final label = (rawDate ?? '').toString().trim();
        if (label.isEmpty) continue;
        final followups = parseInt(
          map['followups'] ?? map['followup_count'] ?? map['total_followups'],
        );
        final activities = parseInt(
          map['activities'] ?? map['activity_count'] ?? map['total_activities'],
        );
        dailyTimeline.add(
          _DailyTimelinePoint(
            dayLabel: label,
            followups: followups,
            activities: activities,
          ),
        );
      }
    } else if (timelineSource is Map) {
      final map = timelineSource.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final labels = asList(map['labels']);
      final followups = asList(map['followups']);
      final activities = asList(map['activities']);
      final maxLen = math.max(
        labels.length,
        math.max(followups.length, activities.length),
      );
      for (var i = 0; i < maxLen; i++) {
        final label = (i < labels.length ? labels[i] : '').toString().trim();
        if (label.isEmpty) continue;
        dailyTimeline.add(
          _DailyTimelinePoint(
            dayLabel: label,
            followups: parseInt(i < followups.length ? followups[i] : 0),
            activities: parseInt(i < activities.length ? activities[i] : 0),
          ),
        );
      }
    }

    final trimmedLeadConversion = conversion.length <= 6
        ? conversion
        : conversion.sublist(conversion.length - 6);

    final monthStart = followupMonths.length <= 6
        ? 0
        : followupMonths.length - 6;
    final trimmedFollowupMonths = followupMonths.sublist(monthStart);
    final trimmedFollowupByType = <String, List<int>>{};
    followupByType.forEach((key, values) {
      if (values.length <= monthStart) {
        trimmedFollowupByType[key] = <int>[];
      } else {
        trimmedFollowupByType[key] = values.sublist(monthStart);
      }
    });

    final trimmedDailyTimeline = dailyTimeline.length <= 7
        ? dailyTimeline
        : dailyTimeline.sublist(dailyTimeline.length - 7);

    return _StaffAnalyticsViewData(
      leadConversion: trimmedLeadConversion,
      followupMonths: trimmedFollowupMonths,
      followupByType: trimmedFollowupByType,
      leadStatusDistribution: statusDistribution,
      followupOutcomeDistribution: followupOutcomeDistribution,
      dailyTimeline: trimmedDailyTimeline,
    );
  }
}

class _LeadConversionPoint {
  const _LeadConversionPoint({
    required this.monthLabel,
    required this.assigned,
    required this.converted,
  });

  final String monthLabel;
  final int assigned;
  final int converted;
}

class _DailyTimelinePoint {
  const _DailyTimelinePoint({
    required this.dayLabel,
    required this.followups,
    required this.activities,
  });

  final String dayLabel;
  final int followups;
  final int activities;
}
