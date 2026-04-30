import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:dio/dio.dart';

class GoogleAdsScreen extends StatefulWidget {
  const GoogleAdsScreen({super.key});

  @override
  State<GoogleAdsScreen> createState() => _GoogleAdsScreenState();
}

class _GoogleAdsScreenState extends State<GoogleAdsScreen> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0;
  int _entriesPerPage = 10;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRecords = 0;
  String _appliedSearch = '';
  bool _isLoading = false;
  String? _loadError;

  final List<_LeadRecord> _digital = [];
  final List<_LeadRecord> _webApp = [];
  int _digitalTotal = 0;
  int _webAppTotal = 0;

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
      AppSnackbar.show('Access denied', 'You do not have permission to view Google Ads leads.');
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Get.back();
      }
      return;
    }
    await _loadLeads();
  }

  List<_LeadRecord> get _activeList => _selectedTab == 0 ? _digital : _webApp;

  Future<void> _loadLeads({
    int? tabIndex,
    int page = 1,
    String? search,
  }) async {
    if (!mounted) return;
    final tab = tabIndex ?? _selectedTab;
    final normalizedSearch = (search ?? _appliedSearch).trim();
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final result = tab == 0
          ? await _apiService.getDigitalMarketingLeadsPage(
              page: page,
              perPage: _entriesPerPage,
              search: normalizedSearch,
            )
          : await _apiService.getWebAppsLeadsPage(
              page: page,
              perPage: _entriesPerPage,
              search: normalizedSearch,
            );
      final mapped = result.items.map(_LeadRecord.fromJson).toList();

      if (!mounted) return;
      setState(() {
        if (tab == 0) {
          _digital
            ..clear()
            ..addAll(mapped);
          _digitalTotal = result.total;
        } else {
          _webApp
            ..clear()
            ..addAll(mapped);
          _webAppTotal = result.total;
        }
        _selectedTab = tab;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _entriesPerPage = result.perPage > 0 ? result.perPage : 10;
        _totalRecords = result.total;
        _appliedSearch = normalizedSearch;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = _extractErrorMessage(
          error,
          fallback: 'Failed to load Google Ads leads.',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load Google Ads leads.';
      });
    }
  }

  Future<void> _remove(_LeadRecord item) async {
    final leadId = item.id.trim();
    if (leadId.isEmpty) {
      AppSnackbar.show('Delete failed', 'Lead id is missing.');
      return;
    }

    try {
      if (_selectedTab == 0) {
        await _apiService.deleteDigitalMarketingLead(leadId);
      } else {
        await _apiService.deleteWebAppsLead(leadId);
      }

      if (!mounted) return;
      final target = _selectedTab == 0 ? _digital : _webApp;
      setState(() {
        target.removeWhere((x) => x.id == item.id);
      });
      AppSnackbar.show('Deleted', 'Lead removed successfully.');
      await _loadLeads(
        tabIndex: _selectedTab,
        page: _currentPage,
        search: _appliedSearch,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Delete failed',
        _extractErrorMessage(error, fallback: 'Failed to delete lead.'),
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show('Delete failed', 'Failed to delete lead.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRecords = _totalRecords;
    final totalPages = _lastPage < 1 ? 1 : _lastPage;
    final safeCurrentPage = _currentPage > totalPages ? totalPages : _currentPage;
    final page = _activeList;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FBFF), Color(0xFFECF4FB)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(
                      digitalCount: _digitalTotal,
                      webCount: _webAppTotal,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFDDE8F3)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HeroStrip(),
                          const SizedBox(height: 12),
                          _SegmentTabs(
                            selected: _selectedTab,
                            digitalCount: _digital.length,
                            webCount: _webApp.length,
                            onChange: (idx) {
                              setState(() {
                                _selectedTab = idx;
                              });
                              _loadLeads(tabIndex: idx, page: 1, search: _appliedSearch);
                            },
                          ),
                          const SizedBox(height: 12),
                          _Toolbar(
                            entries: _entriesPerPage,
                            onEntries: (v) {
                              setState(() {
                                _entriesPerPage = v;
                              });
                              _loadLeads(
                                tabIndex: _selectedTab,
                                page: 1,
                                search: _appliedSearch,
                              );
                            },
                            searchController: _searchController,
                            onSearch: () {
                              _loadLeads(
                                tabIndex: _selectedTab,
                                page: 1,
                                search: _searchController.text.trim(),
                              );
                            },
                          ),
                          if (_isLoading) ...[
                            const SizedBox(height: 8),
                            const LinearProgressIndicator(
                              minHeight: 3,
                              color: Color(0xFF2563EB),
                              backgroundColor: Color(0xFFD8E7FB),
                            ),
                          ],
                          if (_loadError != null) ...[
                            const SizedBox(height: 10),
                            _ErrorPanel(
                              message: _loadError!,
                              onRetry: _loadLeads,
                            ),
                          ],
                          const SizedBox(height: 12),
                          isMobile
                              ? _LeadCards(
                                  rows: page,
                                  onDelete: _remove,
                                )
                              : _LeadTable(
                                  rows: page,
                                  onDelete: _remove,
                                ),
                          const SizedBox(height: 10),
                          _Footer(
                            currentPage: safeCurrentPage,
                            pageSize: _entriesPerPage,
                            showing: page.length,
                            total: totalRecords,
                            totalPages: totalPages,
                            onPageTap: (pageNumber) {
                              _loadLeads(
                                tabIndex: _selectedTab,
                                page: pageNumber,
                                search: _appliedSearch,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _extractErrorMessage(DioException error, {required String fallback}) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'].toString().trim();
      if (message.isNotEmpty) {
        return message;
      }
    }
    final message = error.message?.trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }
    return fallback;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.digitalCount, required this.webCount});

  final int digitalCount;
  final int webCount;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 560;
    final title = Text(
      'Google Ads Leads',
      style: AppTextStyles.style(
        color: const Color(0xFF102A43),
        fontSize: compact ? 20 : 22,
        fontWeight: FontWeight.w700,
      ),
    );

    final badges = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pill(text: 'Digital: $digitalCount', color: const Color(0xFF1D6FEA)),
        _Pill(text: 'Web App: $webCount', color: const Color(0xFF0891B2)),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BackButton(onTap: Get.back),
              const SizedBox(width: 10),
              Expanded(child: title),
            ],
          ),
          const SizedBox(height: 10),
          badges,
        ],
      );
    }

    return Row(
      children: [
        _BackButton(onTap: Get.back),
        const SizedBox(width: 10),
        Expanded(child: title),
        badges,
      ],
    );
  }
}

class _HeroStrip extends StatelessWidget {
  const _HeroStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF3FF), Color(0xFFF7FBFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5E5FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digital Marketing Leads',
            style: AppTextStyles.style(
              color: const Color(0xFF143B69),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track, filter, and manage leads from ads campaigns in one place.',
            style: AppTextStyles.style(
              color: const Color(0xFF5B728A),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({
    required this.selected,
    required this.digitalCount,
    required this.webCount,
    required this.onChange,
  });

  final int selected;
  final int digitalCount;
  final int webCount;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              active: selected == 0,
              label: 'Digital ($digitalCount)',
              onTap: () => onChange(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegmentButton(
              active: selected == 1,
              label: 'Web & App ($webCount)',
              onTap: () => onChange(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.entries,
    required this.onEntries,
    required this.searchController,
    required this.onSearch,
  });

  final int entries;
  final ValueChanged<int> onEntries;
  final TextEditingController searchController;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 700;
    final entriesWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8E2EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rows',
            style: AppTextStyles.style(
              color: const Color(0xFF12263A),
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: entries,
              isDense: true,
              borderRadius: BorderRadius.circular(10),
              items: const [10, 25, 50]
                  .map(
                    (e) => DropdownMenuItem<int>(value: e, child: Text('$e')),
                  )
                  .toList(growable: false),
              onChanged: (v) {
                if (v != null) onEntries(v);
              },
            ),
          ),
        ],
      ),
    );

    final searchWidget = Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search by name, email, phone...',
              hintStyle: AppTextStyles.style(
                color: const Color(0xFF94A3B8),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF64748B),
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD8E2EE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD8E2EE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1D6FEA)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D6FEA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Search'),
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchWidget,
          const SizedBox(height: 10),
          entriesWidget,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchWidget),
        const SizedBox(width: 12),
        entriesWidget,
      ],
    );
  }
}

class _LeadTable extends StatelessWidget {
  const _LeadTable({required this.rows, required this.onDelete});

  final List<_LeadRecord> rows;
  final ValueChanged<_LeadRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const _EmptyBox();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 42,
          dataRowMaxHeight: 50,
          horizontalMargin: 8,
          columnSpacing: 16,
          dividerThickness: 0.5,
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: _Th('ID')),
            DataColumn(label: _Th('Name')),
            DataColumn(label: _Th('Email')),
            DataColumn(label: _Th('Phone')),
            DataColumn(label: _Th('Company')),
            DataColumn(label: _Th('Website')),
            DataColumn(label: _Th('Source Page')),
            DataColumn(label: _Th('Created At')),
            DataColumn(label: _Th('Action')),
          ],
          rows: rows
              .map(
                (r) => DataRow(
                  cells: [
                    DataCell(Text(r.id)),
                    DataCell(Text(r.name)),
                    DataCell(Text(r.email)),
                    DataCell(Text(r.phone)),
                    DataCell(Text(r.company)),
                    DataCell(Text(r.website)),
                    DataCell(Text(r.sourcePage)),
                    DataCell(Text(r.createdAt)),
                    DataCell(
                      InkWell(
                        onTap: () => onDelete(r),
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(3),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _LeadCards extends StatelessWidget {
  const _LeadCards({required this.rows, required this.onDelete});

  final List<_LeadRecord> rows;
  final ValueChanged<_LeadRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const _EmptyBox();

    return Column(
      children: rows
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFEFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#${r.id} ${r.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.style(
                              color: const Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => onDelete(r),
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.style(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Kv(label: 'Phone', value: r.phone),
                    _Kv(label: 'Company', value: r.company),
                    _Kv(label: 'Website', value: r.website),
                    _Kv(label: 'Source', value: r.sourcePage),
                    _Kv(label: 'Created', value: r.createdAt),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.currentPage,
    required this.pageSize,
    required this.showing,
    required this.total,
    required this.totalPages,
    required this.onPageTap,
  });

  final int currentPage;
  final int pageSize;
  final int showing;
  final int total;
  final int totalPages;
  final ValueChanged<int> onPageTap;

  @override
  Widget build(BuildContext context) {
    final startEntry = showing == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final endEntry = showing == 0 ? 0 : startEntry + showing - 1;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Showing $startEntry to $endEntry of $total entries',
          style: AppTextStyles.style(
            color: const Color(0xFF334155),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (total > 0)
          _PaginationBar(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageTap: onPageTap,
          ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF475569),
          size: 17,
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.active,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEAF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: active ? Border.all(color: const Color(0xFFCFE0FB)) : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.style(
            color: active ? const Color(0xFF114B9A) : const Color(0xFF536780),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: AppTextStyles.style(
          color: Colors.white,
          fontSize: 10.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageTap,
  });

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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PageArrow(
          icon: Icons.chevron_left_rounded,
          enabled: canGoPrev,
          onTap: () => onPageTap(currentPage - 1),
        ),
        const SizedBox(width: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tokens.map((token) {
            if (token == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Text('...'),
              );
            }
            final selected = token == currentPage;
            return InkWell(
              onTap: () => onPageTap(token),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF122B52) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$token',
                  style: AppTextStyles.style(
                    color: selected ? Colors.white : const Color(0xFF334155),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(width: 8),
        _PageArrow(
          icon: Icons.chevron_right_rounded,
          enabled: canGoNext,
          onTap: () => onPageTap(currentPage + 1),
        ),
      ],
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
    if (start > 2) tokens.add(null);
    for (var page = start; page <= end; page += 1) {
      tokens.add(page);
    }
    if (end < total - 1) tokens.add(null);
    tokens.add(total);
    return tokens;
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: const Color(0xFF475569), size: 18),
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF0F172A),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.unfold_more_rounded,
          color: Color(0xFF94A3B8),
          size: 14,
        ),
      ],
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 11.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.style(
                color: const Color(0xFF1E293B),
                fontSize: 11.7,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        'No leads found.',
        style: AppTextStyles.style(
          color: const Color(0xFF64748B),
          fontSize: 12.8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(12),
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

class _LeadRecord {
  const _LeadRecord({
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

  factory _LeadRecord.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys, {String fallback = 'N/A'}) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return fallback;
    }

    return _LeadRecord(
      id: read(const ['id', 'lead_id'], fallback: ''),
      name: read(const ['name', 'full_name', 'client_name']),
      email: read(const ['email', 'email_address']),
      phone: read(const ['phone', 'mobile', 'contact_number']),
      company: read(const ['company', 'company_name']),
      website: read(const ['website', 'website_url', 'url']),
      sourcePage: read(const ['source_page', 'sourcePage', 'source']),
      createdAt: read(const ['created_at', 'createdAt', 'created']),
    );
  }
}
