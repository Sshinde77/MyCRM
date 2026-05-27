import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_text_styles.dart';
import '../models/lead_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_card.dart';
import '../widgets/common_screen_app_bar.dart';
import '../widgets/skeletons/app_skeletons.dart';
import 'add_lead_screen.dart';

class AllLeadsScreen extends StatefulWidget {
  const AllLeadsScreen({super.key});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _searchController = TextEditingController();

  static const List<int> _entryOptions = <int>[10, 25, 50, 100];

  bool _isLoading = true;
  String? _error;
  List<LeadModel> _items = const <LeadModel>[];
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _perPage = 10;

  String _appliedSearch = '';
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLeads({int page = 1, String? search}) async {
    final normalizedSearch = (search ?? _appliedSearch).trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getLeadsListPage(
        page: page,
        perPage: _perPage,
        search: normalizedSearch,
        status: _selectedStatus,
      );

      if (!mounted) return;
      setState(() {
        _items = result.items;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage < 1 ? 1 : result.lastPage;
        _total = result.total;
        _perPage = result.perPage > 0 ? result.perPage : _perPage;
        _appliedSearch = normalizedSearch;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load leads.';
      });
    }
  }

  List<String> _statusOptions() {
    final statuses = _items
        .map((lead) => (lead.status ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return statuses;
  }

  Map<String, int> _sourceCounts() {
    final counts = <String, int>{};
    for (final lead in _items) {
      final source = (lead.source ?? '').trim();
      if (source.isEmpty) continue;
      counts[source] = (counts[source] ?? 0) + 1;
    }
    return counts;
  }

  int get _startEntry {
    if (_items.isEmpty) return 0;
    return ((_currentPage - 1) * _perPage) + 1;
  }

  int get _endEntry {
    if (_items.isEmpty) return 0;
    final end = _startEntry + _items.length - 1;
    return end > _total ? _total : end;
  }

  @override
  Widget build(BuildContext context) {
    final sourceCounts = _sourceCounts();
    final statusOptions = _statusOptions();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadLeads(page: _currentPage),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            children: [
              const CommonTopBar(title: 'Lead Management', showBackButton: false),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Lead Management',
                          style: AppTextStyles.style(
                            color: const Color(0xFF0F172A),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.addLead),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add New Lead'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D7CE8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CountChip(
                          label: 'All',
                          value: _total,
                          foreground: Colors.white,
                          background: const Color(0xFF111827),
                        ),
                        _CountChip(
                          label: 'Leads',
                          value: _total,
                          foreground: const Color(0xFFCA8A04),
                          background: const Color(0xFFFFFBEB),
                          border: const Color(0xFFFACC15),
                        ),
                        ...sourceCounts.entries.map(
                          (entry) => _CountChip(
                            label: entry.key,
                            value: entry.value,
                            foreground: const Color(0xFF2563EB),
                            background: const Color(0xFFF8FAFC),
                            border: const Color(0xFF60A5FA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Showing $_startEntry to $_endEntry of $_total leads',
                      style: AppTextStyles.style(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Show',
                          style: AppTextStyles.style(
                            color: const Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<int>(
                            value: _entryOptions.contains(_perPage)
                                ? _perPage
                                : _entryOptions.first,
                            underline: const SizedBox.shrink(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _perPage = value);
                              _loadLeads(page: 1, search: _appliedSearch);
                            },
                            items: _entryOptions
                                .map(
                                  (value) => DropdownMenuItem<int>(
                                    value: value,
                                    child: Text('$value'),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'entries',
                          style: AppTextStyles.style(
                            color: const Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 170,
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus.isEmpty ? null : _selectedStatus,
                            decoration: InputDecoration(
                              hintText: 'All Statuses',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                            items: statusOptions
                                .map(
                                  (status) => DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedStatus = value ?? '');
                              _loadLeads(page: 1, search: _appliedSearch);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Search:',
                          style: AppTextStyles.style(
                            color: const Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (_) =>
                                _loadLeads(page: 1, search: _searchController.text),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _loadLeads(page: 1, search: _searchController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D7CE8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: const Text('Go'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: ScreenSkeleton(),
                      )
                    else if (_error != null)
                      _ErrorBox(message: _error!, onRetry: () => _loadLeads(page: 1))
                    else
                      _buildTable(),
                    const SizedBox(height: 8),
                    Text(
                      'Showing $_startEntry to $_endEntry of $_total entries',
                      style: AppTextStyles.style(
                        color: const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _Pagination(
                        currentPage: _currentPage,
                        lastPage: _lastPage,
                        onPageTap: (page) => _loadLeads(page: page),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.leads,
      ),
    );
  }

  Widget _buildTable() {
    if (_items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'No leads found.',
          style: AppTextStyles.style(
            color: const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 62,
        columns: const [
          DataColumn(label: Text('Sr No')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Number')),
          DataColumn(label: Text('Company')),
          DataColumn(label: Text('Source')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Assigned To')),
          DataColumn(label: Text('Created Date')),
          DataColumn(label: Text('Actions')),
        ],
        rows: List<DataRow>.generate(_items.length, (index) {
          final lead = _items[index];
          final serialNumber = ((_currentPage - 1) * _perPage) + index + 1;
          return DataRow(
            cells: [
              DataCell(Text('$serialNumber')),
              DataCell(
                SizedBox(
                  width: 160,
                  child: Text(lead.displayName, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 210,
                  child: Text(lead.displayEmail, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 130,
                  child: Text(lead.displayPhone, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 140,
                  child:
                      Text(lead.displayCompany, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 140,
                  child: Text(lead.displaySource, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(_StatusBadge(status: lead.displayStatus)),
              DataCell(
                SizedBox(
                  width: 130,
                  child:
                      Text(lead.displayAssignedTo, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    _formatDateTime(lead.createdAt),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                      color: const Color(0xFF1D7CE8),
                      onPressed: () =>
                          Get.toNamed(AppRoutes.leadDetail, arguments: lead.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: const Color(0xFF0EA5E9),
                      onPressed: () =>
                          Get.to(() => AddLeadScreen(leadId: lead.id)),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';

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

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hourRaw = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = hourRaw >= 12 ? 'PM' : 'AM';
    final hour = (hourRaw % 12 == 0 ? 12 : hourRaw % 12).toString().padLeft(
      2,
      '0',
    );

    return '$day $month $year $hour:$minute $amPm';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final isNew = normalized.contains('new');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFF64748B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.style(
          color: isNew ? Colors.white : const Color(0xFF334155),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
    required this.foreground,
    required this.background,
    this.border,
  });

  final String label;
  final int value;
  final Color foreground;
  final Color background;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border ?? background),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.style(
              color: foreground,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: foreground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$value',
              style: AppTextStyles.style(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.onPageTap,
  });

  final int currentPage;
  final int lastPage;
  final ValueChanged<int> onPageTap;

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) {
      return const SizedBox.shrink();
    }

    final pages = <int>{
      1,
      lastPage,
      currentPage - 1,
      currentPage,
      currentPage + 1,
    }.where((page) => page >= 1 && page <= lastPage).toList()
      ..sort();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: currentPage > 1 ? () => onPageTap(currentPage - 1) : null,
          child: const Text('Prev'),
        ),
        ...pages.map((page) {
          final selected = page == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => onPageTap(page),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1D7CE8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  '$page',
                  style: AppTextStyles.style(
                    color: selected ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
        TextButton(
          onPressed: currentPage < lastPage
              ? () => onPageTap(currentPage + 1)
              : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTextStyles.style(
              color: const Color(0xFF9A3412),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
