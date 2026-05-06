import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_text_styles.dart';
import '../core/services/permission_service.dart';
import '../core/utils/app_snackbar.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';

class MetaLeadsScreen extends StatefulWidget {
  const MetaLeadsScreen({super.key});

  @override
  State<MetaLeadsScreen> createState() => _MetaLeadsScreenState();
}

class _MetaLeadsScreenState extends State<MetaLeadsScreen> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _searchController = TextEditingController();

  int _entriesPerPage = 10;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRecords = 0;
  bool _isLoading = false;
  String? _error;
  String _appliedSearch = '';
  DateTime? _selectedDate;
  String _cityStateFilter = '';
  List<_MetaLeadRecord> _records = const <_MetaLeadRecord>[];

  @override
  void initState() {
    super.initState();
    _ensureAccessAndLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureAccessAndLoad() async {
    final canView = await PermissionService.has(
      AppPermission.viewDigitalMarketingLeads,
    );
    if (!mounted) return;
    if (!canView) {
      AppSnackbar.show(
        'Access denied',
        'You do not have permission to view Meta leads.',
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Get.back();
      }
      return;
    }
    await _loadMetaLeads();
  }

  Future<void> _loadMetaLeads({int page = 1, String? search}) async {
    if (!mounted) return;
    final normalizedSearch = (search ?? _appliedSearch).trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getDigitalMarketingLeadsPage(
        page: page,
        perPage: _entriesPerPage,
        search: normalizedSearch,
      );
      final mapped = result.items.map(_MetaLeadRecord.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _records = mapped;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _totalRecords = result.total;
        _entriesPerPage = result.perPage > 0 ? result.perPage : 10;
        _appliedSearch = normalizedSearch;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final responseData = error.response?.data;
      var message = 'Failed to load Meta leads.';
      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }
      setState(() {
        _isLoading = false;
        _error = message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load Meta leads.';
      });
    }
  }

  Future<void> _openFilterPopup() async {
    var tempDate = _selectedDate;
    var tempCityState = _cityStateFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Meta Leads',
                      style: AppTextStyles.style(
                        color: const Color(0xFF1E2A3B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => setSheetState(() {
                        tempCityState = value.trim();
                      }),
                      controller: TextEditingController(text: tempCityState),
                      decoration: InputDecoration(
                        hintText: 'City or State',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setSheetState(() => tempDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        tempDate == null
                            ? 'Select Lead Date'
                            : _formatDate(tempDate!),
                      ),
                    ),
                    if (tempDate != null)
                      TextButton(
                        onPressed: () => setSheetState(() => tempDate = null),
                        child: const Text('Clear Date'),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                                _cityStateFilter = '';
                              });
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDate = tempDate;
                                _cityStateFilter = tempCityState;
                              });
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_MetaLeadRecord> _applyFilters(List<_MetaLeadRecord> base) {
    return base
        .where((record) {
          if (_cityStateFilter.isNotEmpty) {
            final needle = _cityStateFilter.toLowerCase();
            final hay = '${record.city} ${record.state}'.toLowerCase();
            if (!hay.contains(needle)) {
              return false;
            }
          }
          if (_selectedDate != null) {
            final date = record.leadDateParsed;
            if (date == null ||
                date.year != _selectedDate!.year ||
                date.month != _selectedDate!.month ||
                date.day != _selectedDate!.day) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _lastPage < 1 ? 1 : _lastPage;
    final currentPage = _currentPage > totalPages ? totalPages : _currentPage;
    final filteredRecords = _applyFilters(_records);
    final showingCount = filteredRecords.length;
    final startEntry = showingCount == 0
        ? 0
        : ((currentPage - 1) * _entriesPerPage) + 1;
    final endEntry = showingCount == 0 ? 0 : startEntry + showingCount - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.leads,
      ),
      appBar: AppBar(
        title: const Text('Meta Leads'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadMetaLeads(page: currentPage),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaLeadsToolbar(
                  controller: _searchController,
                  onSearchTap: () => _loadMetaLeads(
                    page: 1,
                    search: _searchController.text.trim(),
                  ),
                  onFilterTap: _openFilterPopup,
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _MetaErrorCard(message: _error!, onRetry: _loadMetaLeads)
                else if (filteredRecords.isEmpty)
                  _MetaEmptyCard(
                    message: _appliedSearch.isEmpty
                        ? 'No Meta leads found.'
                        : 'No Meta leads matched your search/filter.',
                  )
                else
                  ...filteredRecords.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MetaLeadCard(record: record),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Showing $startEntry to $endEntry of $_totalRecords entries',
                  style: AppTextStyles.style(
                    color: const Color(0xFF475569),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLeadsToolbar extends StatelessWidget {
  const _MetaLeadsToolbar({
    required this.controller,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD2DDEA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSearchTap(),
                    decoration: InputDecoration(
                      hintText: 'Search Meta leads...',
                      hintStyle: AppTextStyles.style(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onSearchTap,
                  child: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD2DDEA)),
            ),
            child: const Icon(Icons.filter_alt_outlined, size: 20),
          ),
        ),
      ],
    );
  }
}

class _MetaLeadCard extends StatelessWidget {
  const _MetaLeadCard({required this.record});

  final _MetaLeadRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E9F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '# ${record.id}',
                  style: AppTextStyles.style(
                    color: const Color(0xFF1D6FEA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showLeadDetails(context, record),
                child: const Text('View'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.name,
            style: AppTextStyles.style(
              color: const Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _MetaInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: record.email,
          ),
          _MetaInfoRow(
            icon: Icons.call_outlined,
            label: 'Phone',
            value: record.phone,
          ),
          _MetaInfoRow(
            icon: Icons.badge_outlined,
            label: 'Form ID',
            value: record.formId,
          ),
          _MetaInfoRow(
            icon: Icons.location_on_outlined,
            label: 'City/State',
            value: record.cityState,
          ),
          _MetaInfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Lead Date',
            value: record.leadDate,
          ),
        ],
      ),
    );
  }

  void _showLeadDetails(BuildContext context, _MetaLeadRecord record) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Meta Lead Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ID: ${record.id}'),
                Text('Name: ${record.name}'),
                Text('Email: ${record.email}'),
                Text('Phone: ${record.phone}'),
                Text('Form ID: ${record.formId}'),
                Text('City/State: ${record.cityState}'),
                Text('Lead Date: ${record.leadDate}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _MetaInfoRow extends StatelessWidget {
  const _MetaInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 11.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.style(
                color: const Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaErrorCard extends StatelessWidget {
  const _MetaErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3D0D0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.style(
                color: const Color(0xFFB42318),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MetaEmptyCard extends StatelessWidget {
  const _MetaEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: AppTextStyles.style(
          color: const Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MetaLeadRecord {
  const _MetaLeadRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.formId,
    required this.city,
    required this.state,
    required this.leadDate,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String formId;
  final String city;
  final String state;
  final String leadDate;

  String get cityState {
    final cityValue = city.trim();
    final stateValue = state.trim();
    if (cityValue.isEmpty && stateValue.isEmpty) {
      return '-';
    }
    if (cityValue.isEmpty) return stateValue;
    if (stateValue.isEmpty) return cityValue;
    return '$cityValue, $stateValue';
  }

  DateTime? get leadDateParsed {
    final raw = leadDate.trim();
    if (raw.isEmpty || raw == '-') return null;
    return DateTime.tryParse(raw);
  }

  factory _MetaLeadRecord.fromJson(Map<String, dynamic> source) {
    String readString(List<String> keys, {String fallback = '-'}) {
      for (final key in keys) {
        final value = source[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return fallback;
    }

    return _MetaLeadRecord(
      id: readString(const ['id', 'lead_id', 'meta_lead_id'], fallback: ''),
      name: readString(const ['name', 'full_name', 'lead_name']),
      email: readString(const ['email', 'email_address']),
      phone: readString(const ['phone', 'mobile', 'phone_number']),
      formId: readString(const ['form_id', 'formId', 'meta_form_id']),
      city: readString(const ['city'], fallback: ''),
      state: readString(const ['state'], fallback: ''),
      leadDate: _normalizeLeadDate(
        readString(const ['lead_date', 'created_at', 'date']),
      ),
    );
  }
}

String _normalizeLeadDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '-') return '-';
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return trimmed;
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
  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = months[local.month - 1];
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month $year, $hour:$minute';
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
