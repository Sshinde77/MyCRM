import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  String _selectedFormId = '';
  List<MetaLeadRecord> _records = const <MetaLeadRecord>[];

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
    final canViewMeta = await PermissionService.has(AppPermission.viewMetaLead);
    final canViewMarketing = await PermissionService.has(
      AppPermission.viewDigitalMarketingLeads,
    );
    final canView = canViewMeta || canViewMarketing;
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
      final result = await _apiService.getMetaLeadsPage(
        page: page,
        perPage: _entriesPerPage,
        search: normalizedSearch,
        dateFrom: _selectedDateFrom == null
            ? null
            : _formatDate(_selectedDateFrom!),
        dateTo: _selectedDateTo == null ? null : _formatDate(_selectedDateTo!),
        formId: _selectedFormId,
      );
      final mapped = result.items.map(MetaLeadRecord.fromJson).toList();
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
    var tempDateFrom = _selectedDateFrom;
    var tempDateTo = _selectedDateTo;
    var tempFormId = _selectedFormId;
    final formController = TextEditingController(text: tempFormId);

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
                      controller: formController,
                      onChanged: (value) => tempFormId = value.trim(),
                      decoration: InputDecoration(
                        hintText: 'Form ID',
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
                                _selectedFormId = '';
                              });
                              Navigator.of(sheetContext).pop();
                              _loadMetaLeads(page: 1, search: _appliedSearch);
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
                                _selectedFormId = tempFormId.trim();
                              });
                              Navigator.of(sheetContext).pop();
                              _loadMetaLeads(page: 1, search: _appliedSearch);
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

  @override
  Widget build(BuildContext context) {
    final totalPages = _lastPage < 1 ? 1 : _lastPage;
    final currentPage = _currentPage > totalPages ? totalPages : _currentPage;
    final showingCount = _records.length;
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
                else if (_records.isEmpty)
                  _MetaEmptyCard(
                    message: _appliedSearch.isEmpty
                        ? 'No Meta leads found.'
                        : 'No Meta leads matched your search/filter.',
                  )
                else
                  ..._records.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MetaLeadCard(
                        record: record,
                        onTap: () => _openLeadDetails(record),
                      ),
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

  Future<void> _openLeadDetails(MetaLeadRecord record) async {
    final deleted = await Get.to<bool>(
      () => MetaLeadDetailsScreen(record: record),
    );
    if (deleted == true && mounted) {
      await _loadMetaLeads(page: 1, search: _appliedSearch);
    }
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
  const _MetaLeadCard({required this.record, required this.onTap});

  final MetaLeadRecord record;
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
              _detailLine('Form ID', record.formId),
              _detailLine('City/State', record.cityState),
              _detailLine('Lead Date', record.leadDate),
            ],
          ),
        ),
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

class MetaLeadRecord {
  const MetaLeadRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.formId,
    required this.city,
    required this.state,
    required this.leadDate,
    required this.pageId,
    required this.adId,
    required this.storedAt,
    required this.raw,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String formId;
  final String city;
  final String state;
  final String leadDate;
  final String pageId;
  final String adId;
  final String storedAt;
  final Map<String, dynamic> raw;

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

  Map<String, String> get formFields {
    final candidates = <dynamic>[
      raw['all_form_fields'],
      raw['allFormFields'],
      raw['form_fields'],
      raw['formFields'],
      raw['field_data'],
      raw['fieldData'],
      raw['data'],
      raw['payload'],
    ];

    for (final candidate in candidates) {
      final extracted = _extractFormFields(candidate);
      if (extracted.isNotEmpty) {
        return extracted;
      }
    }

    const excludedKeys = <String>{
      'id',
      'lead_id',
      'meta_lead_id',
      'name',
      'full_name',
      'lead_name',
      'email',
      'email_address',
      'phone',
      'mobile',
      'phone_number',
      'form_id',
      'formId',
      'meta_form_id',
      'city',
      'state',
      'lead_date',
      'created_at',
      'date',
      'submitted_at',
      'stored_at',
      'page_id',
      'ad_id',
      'status',
      'all_form_fields',
      'allFormFields',
      'form_fields',
      'formFields',
      'field_data',
      'fieldData',
      'data',
      'payload',
    };
    final fallback = <String, String>{};
    raw.forEach((key, value) {
      final normalizedKey = key.trim();
      if (normalizedKey.isEmpty || excludedKeys.contains(normalizedKey)) {
        return;
      }
      if (value is Map || value is List || value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return;
      fallback[_humanizeKey(normalizedKey)] = text;
    });
    return fallback;
  }

  factory MetaLeadRecord.fromJson(Map<String, dynamic> source) {
    final payload = _extractMetaLeadSource(source);

    String readString(List<String> keys, {String fallback = '-'}) {
      for (final key in keys) {
        final value = payload[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return fallback;
    }

    final submittedAt = readString(const [
      'created_time',
      'lead_date',
      'submitted_at',
      'created_at',
      'date',
    ]);
    return MetaLeadRecord(
      id: readString(const ['lead_id', 'id', 'meta_lead_id'], fallback: ''),
      name: readString(const ['full_name', 'name', 'lead_name']),
      email: readString(const ['email', 'email_address']),
      phone: readString(const ['phone', 'mobile', 'phone_number']),
      formId: readString(const ['form_id', 'formId', 'meta_form_id']),
      city: readString(const ['city'], fallback: ''),
      state: readString(const ['state'], fallback: ''),
      leadDate: _normalizeLeadDate(submittedAt),
      pageId: readString(const ['page_id', 'pageId']),
      adId: readString(const ['ad_id', 'adId']),
      storedAt: _normalizeLeadDate(
        readString(const ['created_at', 'stored_at', 'storedAt']),
      ),
      raw: Map<String, dynamic>.from(payload),
    );
  }
}

class MetaLeadDetailsScreen extends StatefulWidget {
  const MetaLeadDetailsScreen({super.key, required this.record});

  final MetaLeadRecord record;

  @override
  State<MetaLeadDetailsScreen> createState() => _MetaLeadDetailsScreenState();
}

class _MetaLeadDetailsScreenState extends State<MetaLeadDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  late MetaLeadRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _loadLeadDetail();
  }

  Future<void> _loadLeadDetail() async {
    final id = _resolveDetailId(widget.record);
    if (id.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Meta lead id is missing.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await ApiService.instance.getMetaLeadDetail(id);
      if (!mounted) return;
      setState(() {
        _record = MetaLeadRecord.fromJson(detail);
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final responseData = error.response?.data;
      var message = 'Failed to load lead details.';
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
        _error = 'Failed to load lead details.';
      });
    }
  }

  String _resolveDetailId(MetaLeadRecord record) {
    final rawIdValue = record.raw['id'];
    final rawId = rawIdValue == null ? '' : rawIdValue.toString().trim();
    if (rawId.isNotEmpty) {
      return rawId;
    }

    final fallbackId = record.id.trim();
    if (fallbackId.isEmpty) {
      return '';
    }

    // Block likely external lead_id values from being used on /meta-leads/{id}.
    if (_looksLikeExternalLeadId(fallbackId)) {
      return '';
    }

    return fallbackId;
  }

  bool _looksLikeExternalLeadId(String value) {
    return RegExp(r'^\d{13,}$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    final formFields = record.formFields;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Meta Lead Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.style(
                          color: const Color(0xFFB42318),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _loadLeadDetail,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetaTopHeader(record: record),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 900;
                        if (compact) {
                          return Column(
                            children: [
                              _ContactInformationCard(record: record),
                              const SizedBox(height: 10),
                              _MetaInformationCard(record: record),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ContactInformationCard(record: record),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetaInformationCard(record: record),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _AllFormFieldsCard(fields: formFields),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MetaTopHeader extends StatelessWidget {
  const _MetaTopHeader({required this.record});

  final MetaLeadRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF6F9FF)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1D8CF8),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.ads_click, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                  'Lead ID: ${record.id}',
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Submitted on ${record.leadDate}',
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF19C943),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Complete',
              style: AppTextStyles.style(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInformationCard extends StatelessWidget {
  const _ContactInformationCard({required this.record});

  final MetaLeadRecord record;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Contact Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailLine('Full Name', record.name),
          _detailLine('Email', record.email),
          _detailLine('Phone', record.phone),
          _detailLine('City', record.city.isEmpty ? '-' : record.city),
          _detailLine('State', record.state.isEmpty ? '-' : record.state),
        ],
      ),
    );
  }
}

class _MetaInformationCard extends StatelessWidget {
  const _MetaInformationCard({required this.record});

  final MetaLeadRecord record;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Meta Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _detailLine('Lead ID', record.id)),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: record.id));
                  AppSnackbar.show('Copied', 'Lead ID copied.');
                },
                child: const Text('Copy'),
              ),
            ],
          ),
          _detailLine('Form ID', record.formId),
          _detailLine('Page ID', record.pageId),
          _detailLine('Ad ID', record.adId),
          _detailLine('Submitted At', record.leadDate),
          _detailLine('Stored At', record.storedAt),
        ],
      ),
    );
  }
}

class _AllFormFieldsCard extends StatelessWidget {
  const _AllFormFieldsCard({required this.fields});

  final Map<String, String> fields;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'All Form Fields',
      child: fields.isEmpty
          ? const Text('No form field data available.')
          : Table(
              border: TableBorder.all(color: const Color(0xFFD7DCE7)),
              columnWidths: const {
                0: FlexColumnWidth(1.3),
                1: FlexColumnWidth(1.9),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFF5F7FC)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Field Name',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Value',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                ...fields.entries.toList().asMap().entries.map(
                  (row) => TableRow(
                    decoration: BoxDecoration(
                      color: row.key.isEven
                          ? Colors.white
                          : const Color(0xFFFBFDFF),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(row.value.key),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(row.value.value),
                      ),
                    ],
                  ),
                ),
              ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.style(
              color: const Color(0xFF1A2A41),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

Widget _detailLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: RichText(
      text: TextSpan(
        text: '$label: ',
        style: const TextStyle(
          color: Color(0xFF101928),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        children: [
          TextSpan(
            text: value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF23364D),
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  );
}

Map<String, String> _extractFormFields(dynamic source) {
  if (source is Map) {
    final map = source.map((key, value) => MapEntry(key.toString(), value));
    final result = <String, String>{};
    map.forEach((key, value) {
      if (value is Map || value is List || value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return;
      result[_humanizeKey(key)] = text;
    });
    return result;
  }
  if (source is List) {
    final result = <String, String>{};
    for (final item in source) {
      if (item is! Map) continue;
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      final key =
          map['field_name'] ??
          map['name'] ??
          map['label'] ??
          map['key'] ??
          map['question'];
      final values = map['values'];
      String? valuesJoined;
      if (values is List) {
        final normalized = values
            .map((entry) => entry?.toString().trim() ?? '')
            .where((entry) => entry.isNotEmpty && entry.toLowerCase() != 'null')
            .toList(growable: false);
        if (normalized.isNotEmpty) {
          valuesJoined = normalized.join(', ');
        }
      }
      final value =
          valuesJoined ??
          map['value'] ??
          map['field_value'] ??
          map['answer'] ??
          map['text'];
      if (key == null || value == null) continue;
      final keyText = key.toString().trim();
      final valueText = value.toString().trim();
      if (keyText.isEmpty || valueText.isEmpty) continue;
      result[_humanizeKey(keyText)] = valueText;
    }
    return result;
  }
  return const <String, String>{};
}

Map<String, dynamic> _extractMetaLeadSource(Map<String, dynamic> source) {
  final nested = source['data'];
  if (nested is Map<String, dynamic>) {
    return nested;
  }
  if (nested is Map) {
    return nested.map((key, value) => MapEntry(key.toString(), value));
  }
  return source;
}

String _humanizeKey(String key) {
  final cleaned = key
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return key;
  return cleaned
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
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
