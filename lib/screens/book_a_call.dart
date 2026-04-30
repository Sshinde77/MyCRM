import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';
import 'package:mycrm/services/api_service.dart';

class BookACallScreen extends StatefulWidget {
  const BookACallScreen({super.key});

  @override
  State<BookACallScreen> createState() => _BookACallScreenState();
}

class _BookACallScreenState extends State<BookACallScreen> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _searchController = TextEditingController();
  int _bookCallEntriesPerPage = 10;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRecords = 0;
  String _appliedSearch = '';
  bool _isLoading = false;
  String? _loadError;
  final List<_BookCallRecord> _bookCallRecords = [];

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
    final canView = await PermissionService.has(AppPermission.viewBookCalls);
    if (!mounted) return;
    if (!canView) {
      AppSnackbar.show(
        'Access denied',
        'You do not have permission to view Book A Call.',
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Get.back();
      }
      return;
    }
    await _loadBookACalls();
  }

  Future<void> _loadBookACalls({int page = 1, String? search}) async {
    if (!mounted) return;
    final normalizedSearch = (search ?? _appliedSearch).trim();
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final result = await _apiService.getBookACallListPage(
        page: page,
        perPage: _bookCallEntriesPerPage,
        search: normalizedSearch,
      );
      final mapped = result.items.map(_BookCallRecord.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _bookCallRecords
          ..clear()
          ..addAll(mapped);
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _totalRecords = result.total;
        _bookCallEntriesPerPage = result.perPage > 0 ? result.perPage : 10;
        _appliedSearch = normalizedSearch;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final responseData = error.response?.data;
      String message = 'Failed to load book-a-call records.';
      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }
      setState(() {
        _isLoading = false;
        _loadError = message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load book-a-call records.';
      });
    }
  }

  Future<void> _deleteBookACall(_BookCallRecord record) async {
    final id = record.id.trim();
    if (id.isEmpty) {
      AppSnackbar.show('Delete failed', 'Record id is missing.');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book A Call'),
        content: Text('Delete booking for "${record.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _apiService.deleteBookACall(id);
      if (!mounted) return;
      AppSnackbar.show('Deleted', 'Book-a-call record removed.');
      await _loadBookACalls(page: _currentPage, search: _appliedSearch);
    } on DioException catch (error) {
      if (!mounted) return;
      final responseData = error.response?.data;
      String message = 'Failed to delete book-a-call record.';
      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }
      AppSnackbar.show('Delete failed', message);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show('Delete failed', 'Failed to delete book-a-call record.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _lastPage < 1 ? 1 : _lastPage;
    final safeCurrentPage = _currentPage > totalPages
        ? totalPages
        : _currentPage;
    final pagedRecords = _bookCallRecords;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEEF5FB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _BookCallBackButton(onTap: Get.back),
                        const SizedBox(width: 12),
                        Text(
                          'Book A Call',
                          style: AppTextStyles.style(
                            color: const Color(0xFF162033),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _BookACallSection(
                      records: pagedRecords,
                      totalRecords: _totalRecords,
                      totalCount: _totalRecords,
                      currentPage: safeCurrentPage,
                      totalPages: totalPages,
                      entriesPerPage: _bookCallEntriesPerPage,
                      isLoading: _isLoading,
                      loadError: _loadError,
                      onRetry: _loadBookACalls,
                      onDelete: _deleteBookACall,
                      onPageTap: (page) {
                        _loadBookACalls(page: page, search: _appliedSearch);
                      },
                      onSearch: () {
                        _loadBookACalls(
                          page: 1,
                          search: _searchController.text.trim(),
                        );
                      },
                      searchController: _searchController,
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
}

class _BookACallSection extends StatelessWidget {
  const _BookACallSection({
    required this.records,
    required this.totalRecords,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.entriesPerPage,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
    required this.onDelete,
    required this.onPageTap,
    required this.onSearch,
    required this.searchController,
  });

  final List<_BookCallRecord> records;
  final int totalRecords;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final int entriesPerPage;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onRetry;
  final ValueChanged<_BookCallRecord> onDelete;
  final ValueChanged<int> onPageTap;
  final VoidCallback onSearch;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final showingRecords = records;
    final showingCount = showingRecords.length;
    final startEntry = showingCount == 0
        ? 0
        : ((currentPage - 1) * entriesPerPage) + 1;
    final endEntry = showingCount == 0 ? 0 : startEntry + showingCount - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCE7F5)),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'All booked call records',
                  style: AppTextStyles.style(
                    color: const Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _BookCallStatChip(
                  label: 'Total',
                  value: '$totalCount',
                  color: const Color(0xFF1D6FEA),
                ),
                _BookCallStatChip(
                  label: 'Showing',
                  value: '$showingCount',
                  color: const Color(0xFF0F766E),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BookCallSearchField(
                      controller: searchController,
                      onSearch: onSearch,
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _BookCallSearchField(
                      controller: searchController,
                      onSearch: onSearch,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (loadError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3D0D0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      loadError!,
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
            )
          else if (showingRecords.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'No booking records found for this search.',
                style: AppTextStyles.style(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final showCards = constraints.maxWidth < 860;
                if (showCards) {
                  return Column(
                    children: showingRecords
                        .map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _BookCallRecordCard(
                              record: record,
                              onDelete: () => onDelete(record),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 42,
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 52,
                      horizontalMargin: 10,
                      columnSpacing: 18,
                      dividerThickness: 0.6,
                      headingRowColor: MaterialStateProperty.all(
                        const Color(0xFFF8FAFC),
                      ),
                      columns: const [
                        DataColumn(label: _BookCallHeaderCell(label: 'ID')),
                        DataColumn(label: _BookCallHeaderCell(label: 'Name')),
                        DataColumn(label: _BookCallHeaderCell(label: 'Email')),
                        DataColumn(label: _BookCallHeaderCell(label: 'Phone')),
                        DataColumn(label: _BookCallHeaderCell(label: 'Agenda')),
                        DataColumn(label: _BookCallHeaderCell(label: 'Booked')),
                        DataColumn(
                          label: _BookCallHeaderCell(label: 'Created'),
                        ),
                        DataColumn(label: _BookCallHeaderCell(label: 'Action')),
                      ],
                      rows: showingRecords
                          .map(
                            (record) => DataRow(
                              cells: [
                                DataCell(Text(record.id)),
                                DataCell(Text(record.name)),
                                DataCell(Text(record.email)),
                                DataCell(Text(record.phone)),
                                DataCell(Text(record.meetingAgenda)),
                                DataCell(
                                  Text(
                                    '${record.bookingDate} ${record.bookingTime}',
                                  ),
                                ),
                                DataCell(Text(record.createdAt)),
                                DataCell(
                                  InkWell(
                                    onTap: () => onDelete(record),
                                    borderRadius: BorderRadius.circular(999),
                                    child: const Padding(
                                      padding: EdgeInsets.all(3),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 20,
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
              },
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Showing $startEntry to $endEntry of $totalRecords entries',
                  style: AppTextStyles.style(
                    color: const Color(0xFF334155),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (totalRecords > 0) ...[
            const SizedBox(height: 8),
            _BookCallPaginationBar(
              currentPage: currentPage,
              totalPages: totalPages,
              onPageTap: onPageTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _BookCallPaginationBar extends StatelessWidget {
  const _BookCallPaginationBar({
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PageArrow(
          icon: Icons.chevron_left_rounded,
          enabled: canGoPrev,
          onTap: () => onPageTap(currentPage - 1),
        ),
        const SizedBox(width: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tokens
              .map((token) {
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
                    width: 34,
                    height: 34,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(width: 10),
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
          width: 34,
          height: 34,
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

class _BookCallEntriesControl extends StatelessWidget {
  const _BookCallEntriesControl({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rows',
            style: AppTextStyles.style(
              color: const Color(0xFF162033),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isDense: true,
              borderRadius: BorderRadius.circular(10),
              items: const [10, 25, 50]
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry,
                      child: Text('$entry'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (selected) {
                if (selected != null) {
                  onChanged(selected);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCallSearchField extends StatelessWidget {
  const _BookCallSearchField({
    required this.controller,
    required this.onSearch,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search by name, phone, date or agenda',
              hintStyle: AppTextStyles.style(
                color: const Color(0xFF94A3B8),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD4DCE7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD4DCE7)),
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
  }
}

class _BookCallHeaderCell extends StatelessWidget {
  const _BookCallHeaderCell({required this.label});

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
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.unfold_more_rounded,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
      ],
    );
  }
}

class _BookCallRecordCard extends StatelessWidget {
  const _BookCallRecordCard({required this.record, required this.onDelete});

  final _BookCallRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ID ${record.id}',
                  style: AppTextStyles.style(
                    color: const Color(0xFF1D6FEA),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                ),
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
          const SizedBox(height: 2),
          Text(
            record.email,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _BookCallMetaLine(
            icon: Icons.call_outlined,
            label: 'Phone',
            value: record.phone,
          ),
          _BookCallMetaLine(
            icon: Icons.text_snippet_outlined,
            label: 'Agenda',
            value: record.meetingAgenda,
          ),
          _BookCallMetaLine(
            icon: Icons.event_outlined,
            label: 'Booked',
            value: '${record.bookingDate} • ${record.bookingTime}',
          ),
          _BookCallMetaLine(
            icon: Icons.schedule_outlined,
            label: 'Created',
            value: record.createdAt,
          ),
        ],
      ),
    );
  }
}

class _BookCallMetaLine extends StatelessWidget {
  const _BookCallMetaLine({
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
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.style(
                color: const Color(0xFF1E293B),
                fontSize: 11.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCallStatChip extends StatelessWidget {
  const _BookCallStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.style(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BookCallBackButton extends StatelessWidget {
  const _BookCallBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _BookCallRecord {
  const _BookCallRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.meetingAgenda,
    required this.bookingDate,
    required this.bookingTime,
    required this.bookingDateTime,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String meetingAgenda;
  final String bookingDate;
  final String bookingTime;
  final String bookingDateTime;
  final String createdAt;

  factory _BookCallRecord.fromJson(Map<String, dynamic> source) {
    String readString(List<String> keys, {String fallback = ''}) {
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

    String readId(List<String> keys) {
      for (final key in keys) {
        final value = source[key];
        if (value != null) {
          final normalized = value.toString().trim();
          if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
            return normalized;
          }
        }
      }
      return '';
    }

    final bookingDate = readString(const [
      'booking_date',
      'call_date',
      'date',
      'book_date',
    ]);
    final bookingTime = readString(const [
      'booking_time',
      'call_time',
      'time',
      'book_time',
    ]);

    return _BookCallRecord(
      id: readId(const ['id', 'book_call_id', 'book_a_call_id']),
      name: readString(const [
        'name',
        'full_name',
        'client_name',
      ], fallback: 'Unknown'),
      email: readString(const ['email', 'email_id']),
      phone: readString(const ['phone', 'mobile', 'phone_number']),
      meetingAgenda: readString(const [
        'meeting_agenda',
        'agenda',
        'subject',
        'description',
      ]),
      bookingDate: bookingDate,
      bookingTime: bookingTime,
      bookingDateTime: readString(
        const ['booking_datetime', 'booking_date_time', 'call_datetime'],
        fallback: [
          bookingDate,
          bookingTime,
        ].where((e) => e.isNotEmpty).join(' '),
      ),
      createdAt: readString(const ['created_at', 'createdAt', 'created']),
    );
  }
}
