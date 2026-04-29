import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../core/constants/app_text_styles.dart';
import '../models/client_model.dart';
import '../models/renewal_model.dart';
import '../models/vendor_model.dart';
import '../providers/renewal_list_provider.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

enum _RenewalFilterOption {
  all('All'),
  upcoming('Up Coming'),
  active('Active'),
  inactive('Inactive'),
  expired('Expired');

  const _RenewalFilterOption(this.label);
  final String label;
}

class _StatusVisual {
  const _StatusVisual({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class ClientRenewalScreen extends StatelessWidget {
  const ClientRenewalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RenewalListProvider>(
      create: (_) =>
          RenewalListProvider(type: RenewalType.client)..loadRenewals(),
      child: const _ClientRenewalBody(),
    );
  }
}

class ClientRenewalFormScreen extends StatelessWidget {
  const ClientRenewalFormScreen({super.key, this.initialRenewal});

  final RenewalModel? initialRenewal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: CommonScreenAppBar(
        title: (initialRenewal?.id.trim().isNotEmpty ?? false)
            ? 'Edit Service'
            : 'Add Service',
      ),
      body: _ClientRenewalFormSheet(initialRenewal: initialRenewal),
    );
  }
}

class _ClientRenewalBody extends StatefulWidget {
  const _ClientRenewalBody();

  @override
  State<_ClientRenewalBody> createState() => _ClientRenewalBodyState();
}

class _ClientRenewalBodyState extends State<_ClientRenewalBody>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _appliedFromDate;
  DateTime? _appliedToDate;
  _RenewalFilterOption _selectedFilter = _RenewalFilterOption.all;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshRenewals();
    }
  }

  Future<void> _refreshRenewals() async {
    if (!mounted) {
      return;
    }
    await context.read<RenewalListProvider>().loadRenewals(forceRefresh: true);
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }
    setState(() => _currentPage = 1);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialStart = _fromDate ?? _appliedFromDate ?? now;
    final initialEnd = _toDate ?? _appliedToDate ?? initialStart;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: DateTime(
          initialStart.year,
          initialStart.month,
          initialStart.day,
        ),
        end: DateTime(initialEnd.year, initialEnd.month, initialEnd.day),
      ),
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: const Color(0xFF156CF1),
              onPrimary: const Color(0xFF156CF1),
              primaryContainer: const Color(0x1F156CF1),
              onPrimaryContainer: const Color(0xFF156CF1),
            ),
            datePickerTheme: base.datePickerTheme.copyWith(
              rangeSelectionBackgroundColor: const Color(0x1A156CF1),
              rangeSelectionOverlayColor: MaterialStateProperty.all(
                const Color(0x1A156CF1),
              ),
              dayOverlayColor: MaterialStateProperty.all(
                const Color(0x1A156CF1),
              ),
              dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return null;
              }),
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF156CF1);
                }
                return null;
              }),
              dayShape: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const CircleBorder(
                    side: BorderSide(color: Color(0xFF156CF1), width: 1.4),
                  );
                }
                return const CircleBorder();
              }),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    final start = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    final end = DateTime(picked.end.year, picked.end.month, picked.end.day);
    setState(() {
      _fromDate = start;
      _toDate = end;
      _appliedFromDate = start;
      _appliedToDate = end;
      _currentPage = 1;
    });
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _appliedFromDate = null;
      _appliedToDate = null;
      _selectedFilter = _RenewalFilterOption.all;
      _searchController.clear();
      _currentPage = 1;
    });
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'dd-mm-yyyy';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  bool _matchesQuery(RenewalModel renewal, String query) {
    if (query.isEmpty) {
      return true;
    }
    final q = query.toLowerCase();
    final haystack = <String>[
      renewal.title,
      renewal.client,
      renewal.vendor,
      renewal.status,
      renewal.serviceDetails,
      renewal.expiryNote,
      renewal.remarkText,
      renewal.startDate,
      renewal.endDate,
      renewal.billing,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  DateTime? _effectiveRenewalDate(RenewalModel renewal) {
    return renewal.endDateValue ??
        renewal.startDateValue ??
        renewal.billingDateValue;
  }

  bool _isUpcoming(RenewalModel renewal) {
    final status = renewal.status.trim().toLowerCase();
    return status.contains('upcoming');
  }

  bool _isActive(RenewalModel renewal) {
    final status = renewal.status.trim().toLowerCase();
    return status.contains('active') && !status.contains('inactive');
  }

  bool _isInactive(RenewalModel renewal) {
    final status = renewal.status.trim().toLowerCase();
    return status.contains('inactive') ||
        status.contains('deactive') ||
        status.contains('disabled');
  }

  bool _isExpired(RenewalModel renewal) {
    final status = renewal.status.trim().toLowerCase();
    return status.contains('expired') || status.contains('overdue');
  }

  bool _matchesStatusFilter(RenewalModel renewal, _RenewalFilterOption filter) {
    switch (filter) {
      case _RenewalFilterOption.all:
        return true;
      case _RenewalFilterOption.upcoming:
        return _isUpcoming(renewal);
      case _RenewalFilterOption.active:
        return _isActive(renewal);
      case _RenewalFilterOption.inactive:
        return _isInactive(renewal);
      case _RenewalFilterOption.expired:
        return _isExpired(renewal);
    }
  }

  List<RenewalModel> _applyBaseFilters(List<RenewalModel> renewals) {
    final query = _searchController.text.trim().toLowerCase();
    final from = _appliedFromDate == null ? null : _dateOnly(_appliedFromDate!);
    final to = _appliedToDate == null ? null : _dateOnly(_appliedToDate!);
    return renewals
        .where((renewal) {
          if (!_matchesQuery(renewal, query)) {
            return false;
          }
          final date = _effectiveRenewalDate(renewal);
          final normalizedDate = date == null ? null : _dateOnly(date);
          if (from != null &&
              (normalizedDate == null || normalizedDate.isBefore(from))) {
            return false;
          }
          if (to != null &&
              (normalizedDate == null || normalizedDate.isAfter(to))) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Map<_RenewalFilterOption, int> _buildStatusCounts(
    List<RenewalModel> renewals,
  ) {
    final counts = <_RenewalFilterOption, int>{};
    for (final option in _RenewalFilterOption.values) {
      counts[option] = renewals
          .where((item) => _matchesStatusFilter(item, option))
          .length;
    }
    return counts;
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _selectedFilter != _RenewalFilterOption.all ||
        _appliedFromDate != null ||
        _appliedToDate != null;
  }

  Future<void> _openServiceForm({RenewalModel? renewal}) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientRenewalFormScreen(initialRenewal: renewal),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await _refreshRenewals();
    }
  }

  Future<void> _openDetail(RenewalModel renewal) async {
    await Get.toNamed(AppRoutes.clientRenewalDetail, arguments: renewal);
    if (!mounted) {
      return;
    }
    await _refreshRenewals();
  }

  Future<void> _deleteRenewal(RenewalModel renewal) async {
    final renewalId = renewal.id.trim();
    if (renewalId.isEmpty) {
      AppSnackbar.show('Delete failed', 'Invalid service id.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Service'),
          content: Text(
            'Are you sure you want to delete "${renewal.title.trim().isEmpty ? 'this service' : renewal.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _apiService.deleteClientRenewal(renewalId);
      if (!mounted) {
        return;
      }
      await _refreshRenewals();
      if (!mounted) {
        return;
      }
      AppSnackbar.show('Deleted', 'Service deleted successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      String message = 'Failed to delete service.';
      if (error is DioException) {
        final data = error.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else {
          final dioMessage = error.message?.trim() ?? '';
          if (dioMessage.isNotEmpty) {
            message = dioMessage;
          }
        }
      } else {
        final raw = error.toString().trim();
        if (raw.startsWith('Exception: ')) {
          message = raw.substring('Exception: '.length);
        } else if (raw.isNotEmpty) {
          message = raw;
        }
      }

      AppSnackbar.show('Delete failed', message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 380;
    final side = compact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: Consumer<RenewalListProvider>(
        builder: (context, provider, _) {
          final baseRenewals = _applyBaseFilters(provider.renewals);
          final counts = _buildStatusCounts(baseRenewals);
          final filteredRenewals = baseRenewals
              .where((item) => _matchesStatusFilter(item, _selectedFilter))
              .toList(growable: false);
          final pageSize = provider.perPage > 0 ? provider.perPage : 10;
          final totalPages = filteredRenewals.isEmpty
              ? 0
              : ((filteredRenewals.length + pageSize - 1) / pageSize).floor();
          final safeCurrentPage = totalPages == 0
              ? 1
              : (_currentPage > totalPages ? totalPages : _currentPage);
          final startIndex = totalPages == 0
              ? 0
              : (safeCurrentPage - 1) * pageSize;
          final endIndex = totalPages == 0
              ? 0
              : (startIndex + pageSize > filteredRenewals.length
                    ? filteredRenewals.length
                    : startIndex + pageSize);
          final pagedRenewals = filteredRenewals.sublist(startIndex, endIndex);
          return SafeArea(
            child: Column(
              children: [
                _TopBar(compact: compact),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshRenewals,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            side,
                            compact ? 16 : 18,
                            side,
                            18,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                child: Column(
                                  children: [
                                    _FilterCard(
                                      compact: compact,
                                      searchController: _searchController,
                                      selectedFilter: _selectedFilter,
                                      statusCounts: counts,
                                      onDateRangeTap: _pickDateRange,
                                      onClearTap: _clearFilters,
                                      onStatusChanged: (value) {
                                        setState(() {
                                          _selectedFilter = value;
                                          _currentPage = 1;
                                        });
                                      },
                                    ),
                                    SizedBox(height: compact ? 16 : 18),
                                    _AddServiceButton(
                                      compact: compact,
                                      onTap: () => _openServiceForm(),
                                    ),
                                    SizedBox(height: compact ? 16 : 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        _RenewalListSection(
                          compact: compact,
                          sidePadding: side,
                          renewals: pagedRenewals,
                          isLoading: provider.isLoading,
                          errorMessage: provider.errorMessage,
                          hasActiveFilters: _hasActiveFilters,
                          onRetry: () => context
                              .read<RenewalListProvider>()
                              .loadRenewals(forceRefresh: true),
                          onView: (renewal) => _openDetail(renewal),
                          onEdit: (renewal) =>
                              _openServiceForm(renewal: renewal),
                          onDelete: (renewal) => _deleteRenewal(renewal),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            side,
                            0,
                            side,
                            compact ? 18 : 22,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                child: _PaginationBar(
                                  compact: compact,
                                  currentPage: safeCurrentPage,
                                  totalPages: totalPages,
                                  onPageTap: (page) {
                                    setState(() => _currentPage = page);
                                  },
                                ),
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
          );
        },
      ),
    );
  }
}

class _RenewalListSection extends StatelessWidget {
  const _RenewalListSection({
    required this.compact,
    required this.sidePadding,
    required this.renewals,
    required this.isLoading,
    required this.errorMessage,
    required this.hasActiveFilters,
    required this.onRetry,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final bool compact;
  final double sidePadding;
  final List<RenewalModel> renewals;
  final bool isLoading;
  final String? errorMessage;
  final bool hasActiveFilters;
  final VoidCallback onRetry;
  final ValueChanged<RenewalModel> onView;
  final ValueChanged<RenewalModel> onEdit;
  final ValueChanged<RenewalModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (isLoading && renewals.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (errorMessage != null && renewals.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 0),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _ErrorCard(
                compact: compact,
                message: errorMessage!,
                onRetry: onRetry,
              ),
            ),
          ),
        ),
      );
    }

    if (renewals.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 0),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _EmptyCard(
                compact: compact,
                message: hasActiveFilters
                    ? 'No client renewals match the current filters.'
                    : 'No client renewals available.',
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final service = _ServiceItem.fromRenewal(renewals[index]);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: EdgeInsets.only(bottom: compact ? 14 : 16),
                child: _ServiceCard(
                  service: service,
                  compact: compact,
                  onView: () => onView(service.renewal),
                  onEdit: () => onEdit(service.renewal),
                  onDelete: () => onDelete(service.renewal),
                ),
              ),
            ),
          );
        }, childCount: renewals.length),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 68 : 72,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: CommonTopBar(
        title: 'Services',
        compact: compact,
        onBack: Get.back,
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.compact,
    required this.searchController,
    required this.selectedFilter,
    required this.statusCounts,
    required this.onDateRangeTap,
    required this.onClearTap,
    required this.onStatusChanged,
  });

  final bool compact;
  final TextEditingController searchController;
  final _RenewalFilterOption selectedFilter;
  final Map<_RenewalFilterOption, int> statusCounts;
  final VoidCallback onDateRangeTap;
  final VoidCallback onClearTap;
  final ValueChanged<_RenewalFilterOption> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: const Color(0xFFDCE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                color: const Color(0xFF475569),
                size: compact ? 21 : 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Filter Renewal Period',
                style: AppTextStyles.style(
                  color: const Color(0xFF334155),
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: compact ? 46 : 50,
                  padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(compact ? 14 : 16),
                    border: Border.all(color: const Color(0xFFDCE6F2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<_RenewalFilterOption>(
                      value: selectedFilter,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B),
                      ),
                      items: _RenewalFilterOption.values
                          .map((option) {
                            final count = statusCounts[option] ?? 0;
                            final visual = _statusVisualFor(option);
                            return DropdownMenuItem<_RenewalFilterOption>(
                              value: option,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: visual.foreground,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${option.label} ($count)',
                                      style: AppTextStyles.style(
                                        color: visual.foreground,
                                        fontSize: compact ? 13 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(growable: false),
                      selectedItemBuilder: (context) {
                        return _RenewalFilterOption.values
                            .map((option) {
                              final count = statusCounts[option] ?? 0;
                              final visual = _statusVisualFor(option);
                              return Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: visual.foreground,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${option.label} ($count)',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.style(
                                        color: visual.foreground,
                                        fontSize: compact ? 13 : 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            })
                            .toList(growable: false);
                      },
                      onChanged: (value) {
                        if (value != null) {
                          onStatusChanged(value);
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              _DateRangeButton(compact: compact, onTap: onDateRangeTap),
              SizedBox(width: compact ? 8 : 10),
              _ActionButton(
                label: 'Clear',
                icon: Icons.refresh_rounded,
                filled: false,
                compact: compact,
                onTap: onClearTap,
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          _SearchField(controller: searchController, compact: compact),
        ],
      ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: Container(
        width: compact ? 50 : 54,
        height: compact ? 46 : 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          border: Border.all(color: const Color(0xFFDCE6F2)),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.calendar_month_outlined,
          size: 20,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = filled ? const Color(0xFF156CF1) : Colors.white;
    final foreground = filled ? Colors.white : const Color(0xFF334155);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: Container(
        height: compact ? 46 : 50,
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          border: Border.all(
            color: filled ? const Color(0xFF156CF1) : const Color(0xFFDCE6F2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 18 : 19, color: foreground),
            SizedBox(width: compact ? 6 : 8),
            Text(
              label,
              style: AppTextStyles.style(
                color: foreground,
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.compact});

  final TextEditingController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search',
          style: AppTextStyles.style(
            color: const Color(0xFF64748B),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        TextField(
          controller: controller,
          style: AppTextStyles.style(
            color: const Color(0xFF17213A),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search by service, client, vendor or status',
            hintStyle: AppTextStyles.style(
              color: const Color(0xFF94A3B8),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 12 : 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(compact ? 14 : 16),
              borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(compact ? 14 : 16),
              borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(compact ? 14 : 16),
              borderSide: const BorderSide(
                color: Color(0xFF156CF1),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.compact,
    required this.currentPage,
    required this.totalPages,
    required this.onPageTap,
  });

  final bool compact;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageTap;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final tokens = _buildPageTokens(currentPage, totalPages);
    final canGoPrev = currentPage > 1;
    final canGoNext = currentPage < totalPages;

    return Padding(
      padding: EdgeInsets.only(top: compact ? 6 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationArrowButton(
            compact: compact,
            icon: Icons.chevron_left_rounded,
            enabled: canGoPrev,
            onTap: () => onPageTap(currentPage - 1),
          ),
          SizedBox(width: compact ? 10 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tokens
                .map((token) {
                  if (token == null) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2 : 4,
                        vertical: compact ? 8 : 9,
                      ),
                      child: Text(
                        '...',
                        style: AppTextStyles.style(
                          color: const Color(0xFF64748B),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  final selected = token == currentPage;
                  return InkWell(
                    onTap: () => onPageTap(token),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: compact ? 34 : 36,
                      height: compact ? 34 : 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF122B52)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$token',
                        style: AppTextStyles.style(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF334155),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          SizedBox(width: compact ? 10 : 12),
          _PaginationArrowButton(
            compact: compact,
            icon: Icons.chevron_right_rounded,
            enabled: canGoNext,
            onTap: () => onPageTap(currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<int?> _buildPageTokens(int current, int total) {
    if (total <= 7) {
      return List<int?>.generate(total, (index) => index + 1);
    }

    final tokens = <int?>[1];
    var start = current - 1;
    var end = current + 1;

    if (current <= 3) {
      start = 2;
      end = 4;
    } else if (current >= total - 2) {
      start = total - 3;
      end = total - 1;
    } else {
      start = start < 2 ? 2 : start;
      end = end > total - 1 ? total - 1 : end;
    }

    if (start > 2) {
      tokens.add(null);
    }
    for (var page = start; page <= end; page += 1) {
      tokens.add(page);
    }
    if (end < total - 1) {
      tokens.add(null);
    }
    tokens.add(total);
    return tokens;
  }
}

class _PaginationArrowButton extends StatelessWidget {
  const _PaginationArrowButton({
    required this.compact,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final bool compact;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: compact ? 34 : 40,
        height: compact ? 34 : 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE6F2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: compact ? 20 : 22,
          color: enabled ? const Color(0xFF122B52) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _FilterStatusChip extends StatelessWidget {
  const _FilterStatusChip({
    required this.compact,
    required this.label,
    required this.count,
    required this.selected,
    required this.visual,
    required this.onTap,
  });

  final bool compact;
  final String label;
  final int count;
  final bool selected;
  final _StatusVisual visual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? visual.background : Colors.white;
    final borderColor = selected
        ? visual.background
        : visual.foreground.withOpacity(0.45);
    final textColor = selected ? visual.foreground : visual.foreground;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 9,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.style(
                color: textColor,
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.style(
                  color: textColor,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_StatusVisual _statusVisualFor(_RenewalFilterOption option) {
  switch (option) {
    case _RenewalFilterOption.all:
      return const _StatusVisual(
        background: Color(0xFFF1F5F9),
        foreground: Color(0xFF334155),
      );
    case _RenewalFilterOption.upcoming:
      return const _StatusVisual(
        background: Color(0xFFFEF3C7),
        foreground: Color(0xFFB45309),
      );
    case _RenewalFilterOption.active:
      return const _StatusVisual(
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF15803D),
      );
    case _RenewalFilterOption.inactive:
      return const _StatusVisual(
        background: Color(0xFFFEE2E2),
        foreground: Color(0xFFDC2626),
      );
    case _RenewalFilterOption.expired:
      return const _StatusVisual(
        background: Color(0xFFFFEDD5),
        foreground: Color(0xFFC2410C),
      );
  }
}

_StatusVisual _statusVisualForService(String rawStatus) {
  final status = rawStatus.trim().toLowerCase();
  if (status.contains('upcoming')) {
    return const _StatusVisual(
      background: Color(0xFFFEF3C7),
      foreground: Color(0xFFB45309),
    );
  }
  if (status.contains('pending') || status.contains('hold')) {
    return const _StatusVisual(
      background: Color(0xFFE0F2FE),
      foreground: Color(0xFF0369A1),
    );
  }
  if (status.contains('inactive') ||
      status.contains('deactive') ||
      status.contains('disabled')) {
    return const _StatusVisual(
      background: Color(0xFFFEE2E2),
      foreground: Color(0xFFDC2626),
    );
  }
  if (status.contains('expired') || status.contains('overdue')) {
    return const _StatusVisual(
      background: Color(0xFFFFEDD5),
      foreground: Color(0xFFC2410C),
    );
  }
  if (status.contains('active')) {
    return const _StatusVisual(
      background: Color(0xFFDCFCE7),
      foreground: Color(0xFF15803D),
    );
  }
  return const _StatusVisual(
    background: Color(0xFFE2E8F0),
    foreground: Color(0xFF334155),
  );
}

class _AddServiceButton extends StatelessWidget {
  const _AddServiceButton({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: compact ? 14 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFF156CF1),
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22156CF1),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: compact ? 22 : 24,
            ),
            SizedBox(width: compact ? 10 : 12),
            Text(
              'Add New Service'
                  '',
              style: AppTextStyles.style(
                color: Colors.white,
                fontSize: compact ? 15 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.compact,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final _ServiceItem service;
  final bool compact;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusVisual = _statusVisualForService(service.status);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: const Color(0xFFDCE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 18,
              compact ? 16 : 18,
              compact ? 16 : 18,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SERVICE DETAILS',
                            style: AppTextStyles.style(
                              color: const Color(0xFF94A3B8),
                              fontSize: compact ? 11 : 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: compact ? 8 : 10),
                          Text(
                            service.title,
                            style: AppTextStyles.style(
                              color: const Color(0xFF17213A),
                              fontSize: compact ? 17 : 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 12,
                        vertical: compact ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusVisual.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        service.status,
                        style: AppTextStyles.style(
                          color: statusVisual.foreground,
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 14 : 16),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  text: 'Client: ${service.client}',
                  compact: compact,
                ),
                SizedBox(height: compact ? 10 : 12),
                _InfoRow(
                  icon: Icons.storefront_outlined,
                  text: 'Vendor: ${service.vendor}',
                  compact: compact,
                ),
                SizedBox(height: compact ? 16 : 18),
                const Divider(height: 1, color: Color(0xFFEAF0F6)),
                SizedBox(height: compact ? 12 : 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetaColumn(
                        label: 'Start',
                        value: service.startDate,
                        compact: compact,
                      ),
                    ),
                    _VerticalDivider(compact: compact),
                    Expanded(
                      child: _MetaColumn(
                        label: 'End',
                        value: service.endDate,
                        compact: compact,
                      ),
                    ),
                    _VerticalDivider(compact: compact),
                    Expanded(
                      child: _MetaColumn(
                        label: 'Billing',
                        value: service.billing,
                        compact: compact,
                      ),
                    ),
                  ],
                ),
                if (service.showExpiryAlert) ...[
                  SizedBox(height: compact ? 14 : 16),
                  const Divider(height: 1, color: Color(0xFFEAF0F6)),
                  SizedBox(height: compact ? 12 : 14),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFEF4444),
                        size: compact ? 20 : 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service.expiryNote,
                          style: AppTextStyles.style(
                            color: const Color(0xFFEF4444),
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: compact ? 14 : 16),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAF0F6)),
          SizedBox(
            height: compact ? 52 : 56,
            child: Row(
              children: [
                Expanded(
                  child: _CardAction(
                    icon: Icons.remove_red_eye_outlined,
                    onTap: onView,
                  ),
                ),
                _ActionDivider(),
                Expanded(
                  child: _CardAction(icon: Icons.edit_outlined, onTap: onEdit),
                ),
                _ActionDivider(),
                Expanded(
                  child: _CardAction(
                    icon: Icons.delete_outline_rounded,
                    onTap: onDelete,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.compact,
  });

  final IconData icon;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: compact ? 23 : 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.style(
              color: const Color(0xFF334155),
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaColumn extends StatelessWidget {
  const _MetaColumn({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF94A3B8),
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.style(
            color: const Color(0xFF17213A),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 50 : 56,
      width: 1,
      color: const Color(0xFFEAF0F6),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Icon(icon, color: const Color(0xFF64748B), size: 23),
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: const Color(0xFFEAF0F6));
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.compact,
    required this.message,
    required this.onRetry,
  });

  final bool compact;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 22 : 24),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load client renewals',
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            message,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compact ? 12 : 14),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.compact, required this.message});

  final bool compact;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 22 : 24),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Text(
        message,
        style: AppTextStyles.style(
          color: const Color(0xFF64748B),
          fontSize: compact ? 14 : 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ClientRenewalFormSheet extends StatefulWidget {
  const _ClientRenewalFormSheet({this.initialRenewal});

  final RenewalModel? initialRenewal;

  @override
  State<_ClientRenewalFormSheet> createState() =>
      _ClientRenewalFormSheetState();
}

class _ClientRenewalFormSheetState extends State<_ClientRenewalFormSheet> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _serviceDetailsController =
      TextEditingController();

  List<ClientModel> _clients = const <ClientModel>[];
  List<VendorModel> _vendors = const <VendorModel>[];

  String? _renewalId;
  String? _selectedClientId;
  String? _selectedVendorId;
  String _seedClientName = '';
  String _seedVendorName = '';
  String _selectedStatus = 'active';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _billingDate;

  bool _isLoadingOptions = false;
  bool _isLoadingDetail = false;
  bool _isSubmitting = false;

  bool get _isEditMode => (_renewalId ?? '').isNotEmpty;

  static const List<String> _statusValues = <String>['active', 'inactive'];

  @override
  void initState() {
    super.initState();
    _applyRenewalSeed(widget.initialRenewal);
    _loadFormData();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _serviceDetailsController.dispose();
    super.dispose();
  }

  void _applyRenewalSeed(RenewalModel? renewal) {
    if (renewal == null) {
      return;
    }

    _renewalId = renewal.id.trim().isEmpty ? null : renewal.id.trim();
    _selectedClientId = renewal.clientId.trim().isEmpty
        ? null
        : renewal.clientId.trim();
    _selectedVendorId = renewal.vendorId.trim().isEmpty
        ? null
        : renewal.vendorId.trim();
    _seedClientName = renewal.client.trim();
    _seedVendorName = renewal.vendor.trim();

    _serviceNameController.text = renewal.title.trim();
    _serviceDetailsController.text = renewal.serviceDetails.trim();
    _selectedStatus = _normalizeStatusForForm(renewal.status);
    _startDate = renewal.startDateValue;
    _endDate = renewal.endDateValue;
    _billingDate = renewal.billingDateValue;
  }

  String _normalizeStatusForForm(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    if (normalized.contains('inactive') || normalized == '0') {
      return 'inactive';
    }
    return 'active';
  }

  Future<void> _loadFormData() async {
    await _loadLookupData();
    if (_isEditMode) {
      await _loadRenewalDetail();
    }
  }

  Future<void> _loadLookupData() async {
    setState(() => _isLoadingOptions = true);
    try {
      final options = await _apiService.getClientRenewalFormOptions();
      _clients = options.clients;
      _vendors = options.vendors;
      _syncSelectionsWithLookup();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        title: 'Unable to load form options',
        message: _readError(error, fallback: 'Please try again later.'),
        backgroundColor: const Color(0xFFB45309),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
      }
    }
  }

  Future<void> _loadRenewalDetail() async {
    final id = (_renewalId ?? '').trim();
    if (id.isEmpty) {
      return;
    }

    setState(() => _isLoadingDetail = true);
    try {
      final detail = await _apiService.getClientRenewalDetail(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _applyRenewalSeed(detail);
        _syncSelectionsWithLookup();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        title: 'Unable to load service detail',
        message: _readError(error, fallback: 'Please try again later.'),
        backgroundColor: const Color(0xFFB45309),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  String? _validate() {
    if ((_selectedClientId ?? '').trim().isEmpty) {
      return 'Client is required.';
    }
    if ((_selectedVendorId ?? '').trim().isEmpty) {
      return 'Vendor is required.';
    }
    if (_serviceNameController.text.trim().isEmpty) {
      return 'Service name is required.';
    }
    if (_startDate == null) {
      return 'Start date is required.';
    }
    if (_endDate == null) {
      return 'End date is required.';
    }
    if (_billingDate == null) {
      return 'Billing date is required.';
    }
    if (_startDate!.isAfter(_endDate!)) {
      return 'End date must be on or after start date.';
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      _showSnack(
        title: 'Missing details',
        message: validationError,
        backgroundColor: const Color(0xFFB45309),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        await _apiService.updateClientRenewal(
          id: _renewalId!,
          clientId: _selectedClientId!,
          vendorId: _selectedVendorId!,
          serviceName: _serviceNameController.text.trim(),
          serviceDetails: _serviceDetailsController.text.trim(),
          remarkText: '',
          remarkColor: '',
          startDate: _startDate!,
          endDate: _endDate!,
          billingDate: _billingDate!,
          status: _selectedStatus,
        );
      } else {
        await _apiService.createClientRenewal(
          clientId: _selectedClientId!,
          vendorId: _selectedVendorId!,
          serviceName: _serviceNameController.text.trim(),
          serviceDetails: _serviceDetailsController.text.trim(),
          remarkText: '',
          remarkColor: '',
          startDate: _startDate!,
          endDate: _endDate!,
          billingDate: _billingDate!,
          status: _selectedStatus,
        );
      }

      if (!mounted) {
        return;
      }
      _showSnack(
        title: _isEditMode ? 'Service updated' : 'Service created',
        message: _isEditMode
            ? 'Client service has been updated successfully.'
            : 'Client service has been created successfully.',
        backgroundColor: const Color(0xFF153A63),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        title: _isEditMode ? 'Update failed' : 'Create failed',
        message: _readError(
          error,
          fallback: _isEditMode
              ? 'Failed to update service.'
              : 'Failed to create service.',
        ),
        backgroundColor: const Color(0xFFB91C1C),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetServiceFields() {
    setState(() {
      _selectedVendorId = null;
      _serviceNameController.clear();
      _serviceDetailsController.clear();
      _startDate = null;
      _endDate = null;
      _billingDate = null;
      _selectedStatus = 'active';
    });
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) {
      return;
    }
    onPicked(DateTime(picked.year, picked.month, picked.day));
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'dd-mm-yyyy';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  String _normalizeLookupId(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return '';
    }

    final intValue = int.tryParse(normalized);
    if (intValue != null) {
      return intValue.toString();
    }

    final numValue = num.tryParse(normalized);
    if (numValue != null && numValue == numValue.toInt()) {
      return numValue.toInt().toString();
    }

    return normalized.toLowerCase();
  }

  void _syncSelectionsWithLookup() {
    if (_clients.isNotEmpty) {
      final candidateClientId = (_selectedClientId ?? '').trim();
      if (candidateClientId.isNotEmpty) {
        final normalized = _normalizeLookupId(candidateClientId);
        final matched = _clients.where((entry) {
          return _normalizeLookupId(entry.id) == normalized;
        });
        if (matched.isNotEmpty) {
          _selectedClientId = matched.first.id;
        }
      }

      if ((_selectedClientId ?? '').trim().isEmpty &&
          _seedClientName.isNotEmpty) {
        final matchedByName = _clients.where((entry) {
          return _clientDisplayName(entry).trim().toLowerCase() ==
              _seedClientName.toLowerCase();
        });
        if (matchedByName.isNotEmpty) {
          _selectedClientId = matchedByName.first.id;
        }
      }
    }

    if (_vendors.isNotEmpty) {
      final candidateVendorId = (_selectedVendorId ?? '').trim();
      if (candidateVendorId.isNotEmpty) {
        final normalized = _normalizeLookupId(candidateVendorId);
        final matched = _vendors.where((entry) {
          return _normalizeLookupId(entry.id) == normalized;
        });
        if (matched.isNotEmpty) {
          _selectedVendorId = matched.first.id;
        }
      }

      if ((_selectedVendorId ?? '').trim().isEmpty &&
          _seedVendorName.isNotEmpty) {
        final matchedByName = _vendors.where((entry) {
          return entry.vendorName.trim().toLowerCase() ==
              _seedVendorName.toLowerCase();
        });
        if (matchedByName.isNotEmpty) {
          _selectedVendorId = matchedByName.first.id;
        }
      }
    }
  }

  String _clientDisplayName(ClientModel client) {
    final name = client.name.trim();
    if (name.isNotEmpty) {
      return name;
    }

    final contact = client.contactName.trim();
    if (contact.isNotEmpty) {
      return contact;
    }
    return 'Unnamed Client';
  }

  Future<String?> _showSearchableSelectionSheet({
    required String title,
    required List<MapEntry<String, String>> options,
    String? selectedValue,
  }) async {
    final queryController = TextEditingController();
    var filtered = options;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void applyFilter(String query) {
              final q = query.trim().toLowerCase();
              setSheetState(() {
                filtered = q.isEmpty
                    ? options
                    : options
                          .where((entry) => entry.value.toLowerCase().contains(q))
                          .toList(growable: false);
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.style(
                          color: const Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: queryController,
                        autofocus: true,
                        onChanged: applyFilter,
                        decoration: _inputDecoration('Type to search...'),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No results found',
                                  style: AppTextStyles.style(
                                    color: const Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (listContext, index) {
                                  final item = filtered[index];
                                  final isSelected = item.key == selectedValue;
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      item.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: Color(0xFF1D8BFF),
                                          )
                                        : null,
                                    onTap: () =>
                                        Navigator.of(sheetContext).pop(item.key),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _readError(Object error, {required String fallback}) {
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
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? fallback : message;
  }

  void _showSnack({
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    AppSnackbar.show(title, message);
  }

  @override
  Widget build(BuildContext context) {
    final insetBottom = MediaQuery.of(context).viewInsets.bottom;
    final compact = MediaQuery.of(context).size.width <= 440;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: insetBottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            14,
            compact ? 12 : 16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SERVICE FORM',
                style: AppTextStyles.style(
                  color: const Color(0xFF334155),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 12 : 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE6F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isEditMode ? 'Edit Service' : 'Add Services',
                            style: AppTextStyles.style(
                              color: const Color(0xFF1E293B),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_isLoadingOptions || _isLoadingDetail)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormLabel(text: 'Select Client', required: true),
                    const SizedBox(height: 8),
                    _SearchSelectField(
                      text: _clients
                          .where((entry) => entry.id == _selectedClientId)
                          .map(_clientDisplayName)
                          .cast<String?>()
                          .firstWhere(
                            (_) => true,
                            orElse: () => null,
                          ),
                      hint: 'Choose a client...',
                      onTap: _isSubmitting
                          ? null
                          : () async {
                              final selected = await _showSearchableSelectionSheet(
                                title: 'Select Client',
                                selectedValue: _selectedClientId,
                                options: _clients
                                    .map(
                                      (entry) => MapEntry(
                                        entry.id,
                                        _clientDisplayName(entry),
                                      ),
                                    )
                                    .toList(growable: false),
                              );
                              if (selected != null && mounted) {
                                setState(() => _selectedClientId = selected);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Services',
                          style: AppTextStyles.style(
                            color: const Color(0xFF334155),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        // TextButton.icon(
                        //   onPressed: _isSubmitting ? null : _resetServiceFields,
                        //   icon: const Icon(Icons.add, size: 18),
                        //   label: const Text('Add Another Service'),
                        //   style: TextButton.styleFrom(
                        //     foregroundColor: const Color(0xFF16A34A),
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(compact ? 10 : 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDCE6F2)),
                      ),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 760;
                              final itemWidth = isWide
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;

                              return Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Vendor',
                                      required: true,
                                      child: _SearchSelectField(
                                        text: _vendors
                                            .where(
                                              (entry) =>
                                                  entry.id == _selectedVendorId,
                                            )
                                            .map(
                                              (entry) =>
                                                  entry.vendorName.trim().isEmpty
                                                  ? 'Vendor #${entry.id}'
                                                  : entry.vendorName,
                                            )
                                            .cast<String?>()
                                            .firstWhere(
                                              (_) => true,
                                              orElse: () => null,
                                            ),
                                        hint: 'Choose a vendor...',
                                        onTap: _isSubmitting
                                            ? null
                                            : () async {
                                                final selected =
                                                    await _showSearchableSelectionSheet(
                                                      title: 'Select Vendor',
                                                      selectedValue:
                                                          _selectedVendorId,
                                                      options: _vendors
                                                          .map(
                                                            (entry) => MapEntry(
                                                              entry.id,
                                                              entry.vendorName
                                                                      .trim()
                                                                      .isEmpty
                                                                  ? 'Vendor #${entry.id}'
                                                                  : entry.vendorName,
                                                            ),
                                                          )
                                                          .toList(
                                                            growable: false,
                                                          ),
                                                    );
                                                if (selected != null && mounted) {
                                                  setState(
                                                    () =>
                                                        _selectedVendorId = selected,
                                                  );
                                                }
                                              },
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Service Name',
                                      required: true,
                                      child: TextField(
                                        controller: _serviceNameController,
                                        decoration: _inputDecoration(
                                          'Enter service name',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          _LabeledField(
                            label: 'Service Details',
                            child: TextField(
                              controller: _serviceDetailsController,
                              maxLines: 2,
                              decoration: _inputDecoration(
                                'Enter detailed description of the service...',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 900;
                              final itemWidth = isWide
                                  ? (constraints.maxWidth - 36) / 4
                                  : (constraints.maxWidth - 12) / 2;

                              return Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Start Date',
                                      required: true,
                                      child: _DateInputField(
                                        text: _formatDate(_startDate),
                                        onTap: _isSubmitting
                                            ? null
                                            : () => _pickDate(
                                                initialDate: _startDate,
                                                onPicked: (date) => setState(
                                                  () => _startDate = date,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'End Date',
                                      required: true,
                                      child: _DateInputField(
                                        text: _formatDate(_endDate),
                                        onTap: _isSubmitting
                                            ? null
                                            : () => _pickDate(
                                                initialDate: _endDate,
                                                onPicked: (date) => setState(
                                                  () => _endDate = date,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Billing Date',
                                      required: true,
                                      child: _DateInputField(
                                        text: _formatDate(_billingDate),
                                        onTap: _isSubmitting
                                            ? null
                                            : () => _pickDate(
                                                initialDate: _billingDate,
                                                onPicked: (date) => setState(
                                                  () => _billingDate = date,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Status',
                                      required: true,
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        menuMaxHeight: 300,
                                        value: _selectedStatus,
                                        items: _statusValues
                                            .map(
                                              (entry) =>
                                                  DropdownMenuItem<String>(
                                                    value: entry,
                                                    child: Text(
                                                      entry[0].toUpperCase() +
                                                          entry.substring(1),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                            )
                                            .toList(growable: false),
                                        onChanged: _isSubmitting
                                            ? null
                                            : (value) {
                                                if (value == null) return;
                                                setState(
                                                  () => _selectedStatus = value,
                                                );
                                              },
                                        decoration: _inputDecoration('Status'),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D8BFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Save Services'),
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              side: const BorderSide(color: Color(0xFFDCE6F2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
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
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1D8BFF)),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppTextStyles.style(
          color: const Color(0xFF334155),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ]
            : const [],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(text: label, required: required),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DateInputField extends StatelessWidget {
  const _DateInputField({required this.text, required this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE6F2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.style(
                  color: text == 'dd-mm-yyyy'
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSelectField extends StatelessWidget {
  const _SearchSelectField({
    required this.text,
    required this.hint,
    required this.onTap,
  });

  final String? text;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final value = (text ?? '').trim();
    final hasValue = value.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE6F2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.style(
                  color: hasValue
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.renewal,
    required this.title,
    required this.client,
    required this.vendor,
    required this.startDate,
    required this.endDate,
    required this.billing,
    required this.status,
    required this.expiryNote,
    this.showExpiryAlert = false,
  });

  final RenewalModel renewal;
  final String title;
  final String client;
  final String vendor;
  final String startDate;
  final String endDate;
  final String billing;
  final String status;
  final String expiryNote;
  final bool showExpiryAlert;

  factory _ServiceItem.fromRenewal(RenewalModel renewal) {
    return _ServiceItem(
      renewal: renewal,
      title: renewal.title,
      client: renewal.client,
      vendor: renewal.vendor,
      startDate: _orFallback(renewal.startDate, 'N/A'),
      endDate: _orFallback(renewal.endDate, 'N/A'),
      billing: _orFallback(renewal.billing, 'N/A'),
      status: _orFallback(renewal.status, 'Unknown'),
      expiryNote: _orFallback(renewal.expiryNote, 'Renewal due soon'),
      showExpiryAlert: renewal.showExpiryAlert,
    );
  }

  static String _orFallback(String value, String fallback) {
    final normalized = value.trim();
    return normalized.isEmpty ? fallback : normalized;
  }
}
