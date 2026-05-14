import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_text_styles.dart';
import '../core/services/permission_service.dart';
import '../core/utils/app_snackbar.dart';
import '../services/api_service.dart';


class GoogleLeadsScreen extends StatefulWidget {
  const GoogleLeadsScreen({super.key});

  @override
  State<GoogleLeadsScreen> createState() => _GoogleLeadsScreenState();
}

class _GoogleLeadsScreenState extends State<GoogleLeadsScreen> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _searchController = TextEditingController();

  int _entriesPerPage = 10;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRecords = 0;
  bool _isLoading = false;
  String? _error;
  String _appliedSearch = '';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  String _selectedType = '';
  String _selectedCampaignId = '';
  String _selectedLeadStage = '';
  List<GoogleLeadRecord> _records = const <GoogleLeadRecord>[];

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
        'You do not have permission to view Google leads.',
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Get.back();
      }
      return;
    }
    await _loadGoogleLeads();
  }

  Future<void> _loadGoogleLeads({int page = 1, String? search}) async {
    if (!mounted) return;
    final normalizedSearch = (search ?? _appliedSearch).trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getGoogleAdsLeadsPage(
        page: page,
        perPage: _entriesPerPage,
        search: normalizedSearch,
        type: _selectedType,
        campaignId: _selectedCampaignId,
        leadStage: _selectedLeadStage,
      );
      final mapped = result.items.map(GoogleLeadRecord.fromJson).toList();
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
      setState(() {
        _isLoading = false;
        _error = _extractErrorMessage(
          error,
          fallback: 'Failed to load Google leads.',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load Google leads.';
      });
    }
  }

  Future<void> _openLeadDetails(GoogleLeadRecord record) async {
    try {
      final id = record.id.trim();
      if (id.isEmpty) {
        await Get.to<void>(() => GoogleLeadDetailsScreen(record: record));
        return;
      }
      final detail = await _apiService.getGoogleAdsLeadDetail(id);
      final fullRecord = GoogleLeadRecord.fromJson(detail);
      await Get.to<void>(() => GoogleLeadDetailsScreen(record: fullRecord));
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        _extractErrorMessage(error, fallback: 'Failed to load lead details.'),
      );
      await Get.to<void>(() => GoogleLeadDetailsScreen(record: record));
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show('Load failed', 'Failed to load lead details.');
      await Get.to<void>(() => GoogleLeadDetailsScreen(record: record));
    }
  }

  Future<void> _openFilterPopup() async {
    var tempDateFrom = _selectedDateFrom;
    var tempDateTo = _selectedDateTo;
    var tempType = _selectedType;
    var tempCampaignId = _selectedCampaignId;
    var tempLeadStage = _selectedLeadStage;
    final typeController = TextEditingController(text: tempType);
    final campaignIdController = TextEditingController(text: tempCampaignId);
    final leadStageController = TextEditingController(text: tempLeadStage);

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
                      'Filter Google Leads',
                      style: AppTextStyles.style(
                        color: const Color(0xFF1E2A3B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempDateFrom ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setSheetState(() => tempDateFrom = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        tempDateFrom == null
                            ? 'Date From'
                            : 'Date From: ${_formatDate(tempDateFrom!)}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempDateTo ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setSheetState(() => tempDateTo = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        tempDateTo == null
                            ? 'Date To'
                            : 'Date To: ${_formatDate(tempDateTo!)}',
                      ),
                    ),
                    if (tempDateFrom != null || tempDateTo != null)
                      TextButton(
                        onPressed: () => setSheetState(() {
                          tempDateFrom = null;
                          tempDateTo = null;
                        }),
                        child: const Text('Clear Date Range'),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: typeController,
                      onChanged: (value) => tempType = value.trim(),
                      decoration: InputDecoration(
                        hintText: 'Type (e.g. real)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: campaignIdController,
                      onChanged: (value) => tempCampaignId = value.trim(),
                      decoration: InputDecoration(
                        hintText: 'Campaign ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: leadStageController,
                      onChanged: (value) => tempLeadStage = value.trim(),
                      decoration: InputDecoration(
                        hintText: 'Lead Stage (e.g. NEW)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDateFrom = null;
                                _selectedDateTo = null;
                                _selectedType = '';
                                _selectedCampaignId = '';
                                _selectedLeadStage = '';
                              });
                              Navigator.of(sheetContext).pop();
                              _loadGoogleLeads(page: 1, search: _appliedSearch);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDateFrom = tempDateFrom;
                                _selectedDateTo = tempDateTo;
                                _selectedType = tempType.trim();
                                _selectedCampaignId = tempCampaignId.trim();
                                _selectedLeadStage = tempLeadStage.trim();
                              });
                              Navigator.of(sheetContext).pop();
                              _loadGoogleLeads(page: 1, search: _appliedSearch);
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

    typeController.dispose();
    campaignIdController.dispose();
    leadStageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeLastPage = _lastPage < 1 ? 1 : _lastPage;
    final currentPage = _currentPage.clamp(1, safeLastPage);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Google Leads'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadGoogleLeads(page: currentPage, search: _appliedSearch),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
            children: [
              _GoogleLeadsToolbar(
                controller: _searchController,
                onSearchTap: () => _loadGoogleLeads(
                  page: 1,
                  search: _searchController.text.trim(),
                ),
                onFilterTap: _openFilterPopup,
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _GoogleErrorCard(message: _error!, onRetry: _loadGoogleLeads)
              else if (_records.isEmpty)
                const _GoogleEmptyCard(message: 'No Google leads found.')
              else
                ..._records.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _GoogleLeadCard(
                      record: record,
                      onTap: () => _openLeadDetails(record),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: currentPage > 1
                          ? () => _loadGoogleLeads(
                                page: currentPage - 1,
                                search: _appliedSearch,
                              )
                          : null,
                      child: const Text('Previous'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Page $currentPage of $safeLastPage'),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: currentPage < safeLastPage
                          ? () => _loadGoogleLeads(
                                page: currentPage + 1,
                                search: _appliedSearch,
                              )
                          : null,
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLeadsToolbar extends StatelessWidget {
  const _GoogleLeadsToolbar({
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
                      hintText: 'Search Google leads...',
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

class _GoogleLeadCard extends StatelessWidget {
  const _GoogleLeadCard({required this.record, required this.onTap});

  final GoogleLeadRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E9F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.name,
                style: AppTextStyles.style(
                  color: const Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _detailLine('Email', record.email),
              _detailLine('Phone', record.phone),
              _detailLine('Company', record.company),
              _detailLine('Website', record.website),
              _detailLine('Source', record.sourcePage),
              _detailLine('Lead Date', record.createdAt),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleErrorCard extends StatelessWidget {
  const _GoogleErrorCard({required this.message, required this.onRetry});

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

class _GoogleEmptyCard extends StatelessWidget {
  const _GoogleEmptyCard({required this.message});

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

class GoogleLeadDetailsScreen extends StatelessWidget {
  const GoogleLeadDetailsScreen({super.key, required this.record});

  final GoogleLeadRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Google Lead Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF6F9FF)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3E8F4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.name,
                    style: AppTextStyles.style(
                      color: const Color(0xFF1A2A41),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted on ${record.createdAt}',
                    style: AppTextStyles.style(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Contact Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailLine('Full Name', record.name),
                  _detailLine('Email', record.email),
                  _detailLine('Phone', record.phone),
                  _detailLine('Company', record.company),
                  _detailLine('Website', record.website),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Lead Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailLine('Source', record.sourcePage),
                  _detailLine('Lead Date', record.createdAt),
                  _detailLine('Lead ID', record.id),
                ],
              ),
            ),
          ],
        ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class GoogleLeadRecord {
  const GoogleLeadRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.website,
    required this.sourcePage,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String website;
  final String sourcePage;
  final String createdAt;

  factory GoogleLeadRecord.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys, {String fallback = '-'}) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return fallback;
    }

    return GoogleLeadRecord(
      id: read(const ['id'], fallback: ''),
      name: read(const ['name', 'full_name', 'client_name']),
      email: read(const ['email', 'email_address']),
      phone: read(const ['phone', 'mobile', 'contact_number']),
      company: read(const ['company', 'company_name']),
      website: read(const ['website', 'website_url', 'url']),
      sourcePage: read(const ['source_page', 'sourcePage', 'source']),
      createdAt: _normalizeLeadDate(
        read(const ['created_at', 'createdAt', 'created']),
      ),
    );
  }
}

Widget _detailLine(String label, String value) {
  final normalized = value.trim().isEmpty ? '-' : value.trim();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: RichText(
      text: TextSpan(
        style: AppTextStyles.style(
          color: const Color(0xFF475569),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: AppTextStyles.style(
              color: const Color(0xFF334155),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: normalized),
        ],
      ),
    ),
  );
}

String _extractErrorMessage(DioException error, {required String fallback}) {
  final responseData = error.response?.data;
  if (responseData is Map && responseData['message'] != null) {
    final message = responseData['message'].toString().trim();
    if (message.isNotEmpty) return message;
  }
  final message = error.message?.trim() ?? '';
  if (message.isNotEmpty) return message;
  return fallback;
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
