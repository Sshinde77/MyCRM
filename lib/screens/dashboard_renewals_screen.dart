import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';

class DashboardRenewalsScreen extends StatefulWidget {
  const DashboardRenewalsScreen({super.key});

  @override
  State<DashboardRenewalsScreen> createState() =>
      _DashboardRenewalsScreenState();
}

class _DashboardRenewalsScreenState extends State<DashboardRenewalsScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _filters = [
    'All',
    'Due in 7 days',
    'Due this month',
    'Overdue',
  ];

  static const List<_RenewalRecord> _clientRecords = [
    _RenewalRecord(
      name: 'Acme Corporation',
      service: 'Domain Renewal',
      amount: 'Rs 12,500',
      renewalDate: '15 Apr 2026',
      status: 'Due in 7 days',
      badgeColor: Color(0xFFF59E0B),
      initials: 'AC',
    ),
    _RenewalRecord(
      name: 'Northwind Labs',
      service: 'SSL Certificate',
      amount: 'Rs 8,400',
      renewalDate: '22 Apr 2026',
      status: 'Due this month',
      badgeColor: Color(0xFF2563EB),
      initials: 'NL',
    ),
    _RenewalRecord(
      name: 'Pixel Studio',
      service: 'Hosting Plan',
      amount: 'Rs 15,000',
      renewalDate: '18 Mar 2026',
      status: 'Overdue',
      badgeColor: Color(0xFFDC2626),
      initials: 'PS',
    ),
  ];

  static const List<_RenewalRecord> _vendorRecords = [
    _RenewalRecord(
      name: 'Hostinger India',
      service: 'Cloud Server Contract',
      amount: 'Rs 25,000',
      renewalDate: '12 Apr 2026',
      status: 'Due in 7 days',
      badgeColor: Color(0xFFF59E0B),
      initials: 'HI',
    ),
    _RenewalRecord(
      name: 'Google Workspace',
      service: 'Email Suite License',
      amount: 'Rs 19,999',
      renewalDate: '28 Apr 2026',
      status: 'Due this month',
      badgeColor: Color(0xFF2563EB),
      initials: 'GW',
    ),
    _RenewalRecord(
      name: 'Amazon Web Services',
      service: 'Reserved Instances',
      amount: 'Rs 31,200',
      renewalDate: '20 Mar 2026',
      status: 'Overdue',
      badgeColor: Color(0xFFDC2626),
      initials: 'AW',
    ),
  ];

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = _filters.first;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChange);
    _searchController.addListener(_handleSearchChange);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    _searchController
      ..removeListener(_handleSearchChange)
      ..dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _handleSearchChange() {
    setState(() {});
  }

  List<_RenewalRecord> get _visibleRecords {
    final records =
        _tabController.index == 0 ? _clientRecords : _vendorRecords;
    final query = _searchController.text.trim().toLowerCase();

    return records.where((record) {
      final matchesFilter =
          _selectedFilter == 'All' || record.status == _selectedFilter;
      final matchesSearch =
          query.isEmpty ||
          record.name.toLowerCase().contains(query) ||
          record.service.toLowerCase().contains(query) ||
          record.renewalDate.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 360;
    final horizontalPadding = compact ? 14.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(compact: compact, controller: _tabController),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 12 : 14,
                  horizontalPadding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FilterAndSearchCard(
                          compact: compact,
                          selectedFilter: _selectedFilter,
                          filters: _filters,
                          searchController: _searchController,
                          onFilterChanged: (filter) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        ),
                        SizedBox(height: compact ? 14 : 16),
                        Text(
                          '${_tabController.index == 0 ? 'Client' : 'Vendor'} Renewals',
                          style: AppTextStyles.style(
                            color: const Color(0xFF17213A),
                            fontSize: compact ? 16 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        Text(
                          'Dummy data for the list view. Hook this screen to API data next.',
                          style: AppTextStyles.style(
                            color: const Color(0xFF64748B),
                            fontSize: compact ? 12 : 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 14),
                        if (_visibleRecords.isEmpty)
                          _EmptyState(compact: compact)
                        else
                          ..._visibleRecords.map(
                            (record) => Padding(
                              padding:
                                  EdgeInsets.only(bottom: compact ? 10 : 12),
                              child: _RenewalRecordCard(
                                record: record,
                                compact: compact,
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
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.compact,
    required this.controller,
  });

  final bool compact;
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 12,
        compact ? 8 : 10,
        compact ? 10 : 12,
        0,
      ),
      child: Column(
        children: [
          SizedBox(
              height: compact ? 50 : 54,
            child: Row(
              children: [
                IconButton(
                  onPressed: Get.back,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: const Color(0xFF334155),
                    size: compact ? 24 : 26,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Upcoming Renewals',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(
                      color: const Color(0xFF17213A),
                      fontSize: compact ? 18 : 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: controller,
              isScrollable: true,
              labelPadding: const EdgeInsets.only(right: 10),
              indicatorColor: const Color(0xFF1769F3),
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: AppTextStyles.style(
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTextStyles.style(
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w600,
              ),
              labelColor: const Color(0xFF1769F3),
              unselectedLabelColor: const Color(0xFF64748B),
              tabs: const [
                Tab(text: 'Client'),
                Tab(text: 'Vendor'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterAndSearchCard extends StatelessWidget {
  const _FilterAndSearchCard({
    required this.compact,
    required this.selectedFilter,
    required this.filters,
    required this.searchController,
    required this.onFilterChanged,
  });

  final bool compact;
  final String selectedFilter;
  final List<String> filters;
  final TextEditingController searchController;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter',
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
           SizedBox(height: compact ? 10 : 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
               borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE6F2)),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 12 : 13,
                ),
              ),
              style: AppTextStyles.style(
                color: const Color(0xFF17213A),
                 fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
              items: filters
                  .map(
                    (filter) => DropdownMenuItem<String>(
                      value: filter,
                      child: Text(filter),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onFilterChanged(value);
                }
              },
            ),
          ),
           SizedBox(height: compact ? 12 : 14),
          Text(
            'Search',
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
               fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
           SizedBox(height: compact ? 10 : 12),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search name, service, or date',
              hintStyle: AppTextStyles.style(
                color: const Color(0xFF94A3B8),
                 fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF64748B),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 12 : 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1769F3),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalRecordCard extends StatelessWidget {
  const _RenewalRecordCard({
    required this.record,
    required this.compact,
  });

  final _RenewalRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 40 : 42,
                height: compact ? 40 : 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F1FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  record.initials,
                  style: AppTextStyles.style(
                    color: const Color(0xFF1769F3),
                     fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            record.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.style(
                              color: const Color(0xFF17213A),
                              fontSize: compact ? 14 : 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 10),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 8 : 10,
                            vertical: compact ? 4 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: record.badgeColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            record.status,
                            style: AppTextStyles.style(
                              color: record.badgeColor,
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 3 : 4),
                    Text(
                      record.service,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.style(
                        color: const Color(0xFF64748B),
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          Wrap(
            spacing: compact ? 8 : 10,
            runSpacing: compact ? 8 : 10,
            children: [
              _InfoChip(
                label: 'Amount',
                value: record.amount,
                compact: compact,
              ),
              _InfoChip(
                label: 'Renewal Date',
                value: record.renewalDate,
                compact: compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF94A3B8),
                fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 3 : 4),
          Text(
            value,
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
                fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 18,
        vertical: compact ? 20 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: const Color(0xFF94A3B8),
            size: compact ? 30 : 34,
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            'No renewals match the current search or filter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
                fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalRecord {
  const _RenewalRecord({
    required this.name,
    required this.service,
    required this.amount,
    required this.renewalDate,
    required this.status,
    required this.badgeColor,
    required this.initials,
  });

  final String name;
  final String service;
  final String amount;
  final String renewalDate;
  final String status;
  final Color badgeColor;
  final String initials;
}

