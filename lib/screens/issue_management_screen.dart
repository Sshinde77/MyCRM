import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import '../routes/app_routes.dart';

class IssueManagementScreen extends StatefulWidget {
  const IssueManagementScreen({super.key});

  @override
  State<IssueManagementScreen> createState() => _IssueManagementScreenState();
}

class _IssueManagementScreenState extends State<IssueManagementScreen> {
  final _searchController = TextEditingController();
  int _page = 1;
  static const _pageSize = 3;

  static const List<_IssueItem> _allIssues = [
    _IssueItem(
      '#ISS-2034',
      'Project: Laith Barrera',
      'Database migration failure on staging',
      'Arnav',
      'Oct 24, 2023',
      'Low',
      Color(0xFFF1F5F9),
      Color(0xFF475569),
      'Open',
      Color(0xFFFCE7E7),
      Color(0xFFEF4444),
    ),
    _IssueItem(
      '#ISS-2035',
      'Project: Evelyn Fox',
      'Login API timeout during peak hours',
      'Zara Sheikh',
      'Oct 25, 2023',
      'High',
      Color(0xFFFFEDD5),
      Color(0xFFF97316),
      'In Progress',
      Color(0xFFDCEAFE),
      Color(0xFF2563EB),
    ),
    _IssueItem(
      '#ISS-2036',
      'Project: Project Delta',
      'UI responsiveness on iPhone 15',
      'John Doe',
      'Oct 26, 2023',
      'Medium',
      Color(0xFFF1F5F9),
      Color(0xFF475569),
      'Open',
      Color(0xFFFCE7E7),
      Color(0xFFEF4444),
    ),
    _IssueItem(
      '#ISS-2037',
      'Project: Nova Retail',
      'Invoice export generates blank PDF attachments',
      'Ayesha Khan',
      'Oct 27, 2023',
      'High',
      Color(0xFFFFEDD5),
      Color(0xFFF97316),
      'Open',
      Color(0xFFFCE7E7),
      Color(0xFFEF4444),
    ),
    _IssueItem(
      '#ISS-2038',
      'Project: Atlas Group',
      'Lead activity timeline not refreshing automatically',
      'Riya Patel',
      'Oct 28, 2023',
      'Low',
      Color(0xFFF1F5F9),
      Color(0xFF475569),
      'Closed',
      Color(0xFFE8F8EE),
      Color(0xFF16A34A),
    ),
  ];

  List<_IssueItem> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _allIssues;
    return _allIssues.where((issue) {
      return issue.code.toLowerCase().contains(q) ||
          issue.project.toLowerCase().contains(q) ||
          issue.title.toLowerCase().contains(q) ||
          issue.client.toLowerCase().contains(q) ||
          issue.priority.toLowerCase().contains(q) ||
          issue.status.toLowerCase().contains(q);
    }).toList();
  }

  int get _pageCount =>
      _filtered.isEmpty ? 1 : (_filtered.length / _pageSize).ceil();

  List<_IssueItem> get _visible {
    final start = (_page - 1) * _pageSize;
    if (start >= _filtered.length) return const [];
    final end = start + _pageSize > _filtered.length
        ? _filtered.length
        : start + _pageSize;
    return _filtered.sublist(start, end);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setPage(int value) {
    if (value < 1 || value > _pageCount) return;
    setState(() => _page = value);
  }

  @override
  Widget build(BuildContext context) {
    final startEntry = _filtered.isEmpty ? 0 : ((_page - 1) * _pageSize) + 1;
    final endEntry = _filtered.isEmpty
        ? 0
        : ((_page - 1) * _pageSize) + _visible.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;
            final side = compact ? 14.0 : 18.0;
            final inner = compact ? 16.0 : 20.0;

            return Column(
              children: [
                _MobileAppBar(compact: compact),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      compact ? 6 : 10,
                      0,
                      compact ? 12 : 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    compact ? 24 : 28,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFD8E1EF),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0x120F172A),
                                      blurRadius: compact ? 16 : 22,
                                      offset: Offset(0, compact ? 8 : 12),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        inner,
                                        inner,
                                        inner,
                                        compact ? 12 : 14,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Show',
                                                style: _ts(
                                                  const Color(0xFF64748B),
                                                  compact ? 14 : 15,
                                                  FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(width: compact ? 8 : 10),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: compact ? 12 : 14,
                                                  vertical: compact ? 8 : 9,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF8FAFC,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        compact ? 16 : 18,
                                                      ),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFD8E1EF,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '10',
                                                      style: _ts(
                                                        const Color(0xFF334155),
                                                        compact ? 14 : 15,
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      color: const Color(
                                                        0xFF64748B,
                                                      ),
                                                      size: compact ? 18 : 20,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: compact ? 8 : 10),
                                              Text(
                                                'entries',
                                                style: _ts(
                                                  const Color(0xFF64748B),
                                                  compact ? 14 : 15,
                                                  FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: compact ? 12 : 14),
                                          TextField(
                                            controller: _searchController,
                                            onChanged: (_) =>
                                                setState(() => _page = 1),
                                            style: _ts(
                                              const Color(0xFF334155),
                                              compact ? 14 : 15,
                                              FontWeight.w500,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Search issues...',
                                              hintStyle: _ts(
                                                const Color(0xFF94A3B8),
                                                compact ? 14 : 15,
                                                FontWeight.w500,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.search_rounded,
                                                color: const Color(0xFF94A3B8),
                                                size: compact ? 20 : 22,
                                              ),
                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF8FAFC,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: compact ? 13 : 15,
                                                  ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      compact ? 18 : 20,
                                                    ),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD8E1EF),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      compact ? 18 : 20,
                                                    ),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF3B82F6),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFD8E1EF),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        compact ? 12 : 14,
                                        compact ? 12 : 14,
                                        compact ? 12 : 14,
                                        compact ? 10 : 12,
                                      ),
                                      child: Column(
                                        children: _visible.isEmpty
                                            ? [
                                                Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.all(
                                                    compact ? 20 : 24,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFFBFDFF,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          compact ? 20 : 24,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFE6ECF5,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'No issues match your search.',
                                                    textAlign: TextAlign.center,
                                                    style: _ts(
                                                      const Color(0xFF64748B),
                                                      compact ? 14 : 15,
                                                      FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ]
                                            : _visible.map((issue) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: compact ? 12 : 14,
                                                  ),
                                                  child: _IssueCard(
                                                    issue: issue,
                                                    compact: compact,
                                                  ),
                                                );
                                              }).toList(),
                                      ),
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFD8E1EF),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        compact ? 12 : 16,
                                        compact ? 14 : 16,
                                        compact ? 12 : 16,
                                        compact ? 16 : 18,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Showing $startEntry to $endEntry of ${_filtered.length} entries',
                                            textAlign: TextAlign.center,
                                            style: _ts(
                                              const Color(0xFF64748B),
                                              compact ? 13 : 14,
                                              FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: compact ? 12 : 14),
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: compact ? 6 : 8,
                                            runSpacing: compact ? 8 : 10,
                                            children: [
                                              _PageAction(
                                                'Previous',
                                                _page > 1,
                                                () => _setPage(_page - 1),
                                                compact: compact,
                                              ),
                                              ...List.generate(
                                                _pageCount > 3 ? 3 : _pageCount,
                                                (i) {
                                                  final p = i + 1;
                                                  return _PageChip(
                                                    label: '$p',
                                                    selected: p == _page,
                                                    compact: compact,
                                                    onTap: () => _setPage(p),
                                                  );
                                                },
                                              ),
                                              _PageAction(
                                                'Next',
                                                _page < _pageCount,
                                                () => _setPage(_page + 1),
                                                compact: compact,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MobileAppBar extends StatelessWidget {
  const _MobileAppBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 64 : 68,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFD8E1EF))),
      ),
      child: CommonTopBar(
        title: 'Issue Management',
        compact: compact,
        onBack: Get.back,
      ),
    );
  }
}



class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue, required this.compact});

  final _IssueItem issue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.issueDetail),
      borderRadius: BorderRadius.circular(compact ? 20 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 16,
          compact ? 14 : 16,
          compact ? 14 : 16,
          compact ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(compact ? 20 : 24),
          border: Border.all(color: const Color(0xFFE6ECF5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0D0F172A),
              blurRadius: compact ? 10 : 14,
              offset: Offset(0, compact ? 5 : 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: _Pill(
                    issue.code,
                    const Color(0xFFF1F5F9),
                    const Color(0xFF64748B),
                    compact: compact,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: compact ? 15 : 16,
                  color: const Color(0xFF94A3B8),
                ),
                SizedBox(width: compact ? 5 : 6),
                Text(
                  issue.date,
                  style: _ts(
                    const Color(0xFF94A3B8),
                    compact ? 12 : 13,
                    FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 14 : 18),
            Text(
              issue.project.toUpperCase(),
              style: _ts(
                const Color(0xFF3B82F6),
                compact ? 11 : 12,
                FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            Text(
              issue.title,
              style: _ts(
                const Color(0xFF17213A),
                compact ? 18 : 19,
                FontWeight.w700,
                height: 1.22,
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            Text(
              'Client: ${issue.client}',
              style: _ts(
                const Color(0xFF64748B),
                compact ? 14 : 15,
                FontWeight.w500,
              ),
            ),
            SizedBox(height: compact ? 14 : 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            SizedBox(height: compact ? 12 : 14),
            Wrap(
              spacing: compact ? 8 : 10,
              runSpacing: compact ? 8 : 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Pill(
                  issue.priority,
                  issue.priorityBg,
                  issue.priorityFg,
                  compact: compact,
                ),
                _Pill(
                  issue.status,
                  issue.statusBg,
                  issue.statusFg,
                  compact: compact,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye_outlined,
                        color: const Color(0xFF94A3B8),
                        size: compact ? 20 : 22,
                      ),
                      onPressed: () => Get.toNamed(AppRoutes.issueDetail),
                    ),
                    SizedBox(width: compact ? 12 : 14),
                    Icon(
                      Icons.edit_outlined,
                      color: const Color(0xFF94A3B8),
                      size: compact ? 18 : 20,
                    ),
                    SizedBox(width: compact ? 12 : 14),
                    Icon(
                      Icons.delete_outline_rounded,
                      color: const Color(0xFF94A3B8),
                      size: compact ? 20 : 22,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.bg, this.fg, {required this.compact});

  final String label;
  final Color bg;
  final Color fg;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: _ts(fg, compact ? 11 : 12, FontWeight.w700),
      ),
    );
  }
}

class _PageAction extends StatelessWidget {
  const _PageAction(
    this.label,
    this.enabled,
    this.onTap, {
    required this.compact,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
          border: Border.all(color: const Color(0xFFD8E1EF)),
        ),
        child: Text(
          label,
          style: _ts(
            enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
            compact ? 13 : 14,
            FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: Container(
        height: compact ? 40 : 44,
        width: compact ? 40 : 44,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3E82F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: _ts(
            selected ? Colors.white : const Color(0xFF334155),
            compact ? 14 : 15,
            FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _IssueItem {
  const _IssueItem(
    this.code,
    this.project,
    this.title,
    this.client,
    this.date,
    this.priority,
    this.priorityBg,
    this.priorityFg,
    this.status,
    this.statusBg,
    this.statusFg,
  );

  final String code;
  final String project;
  final String title;
  final String client;
  final String date;
  final String priority;
  final Color priorityBg;
  final Color priorityFg;
  final String status;
  final Color statusBg;
  final Color statusFg;
}

TextStyle _ts(
  Color color,
  double size,
  FontWeight weight, {
  double? height,
  double? letterSpacing,
}) {
  return AppTextStyles.style(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
  );
}
