import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/vendor_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

import 'vendor_detail_screen.dart';
import 'vendor_form_screen.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class VendorDirectoryScreen extends StatefulWidget {
  const VendorDirectoryScreen({super.key});

  @override
  State<VendorDirectoryScreen> createState() => _VendorDirectoryScreenState();
}

class _VendorDirectoryScreenState extends State<VendorDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _appliedSearchTerm = '';
  late Future<VendorListPageResult> _vendorsFuture;
  int _rowsPerPage = 10;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _vendorsFuture = ApiService.instance.getVendorsListPage(
      page: _currentPage,
      perPage: _rowsPerPage,
      search: _appliedSearchTerm,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload({int? page}) {
    final targetPage = page ?? _currentPage;
    final resolvedPage = targetPage < 1 ? 1 : targetPage;
    setState(() {
      _currentPage = resolvedPage;
      _vendorsFuture = ApiService.instance.getVendorsListPage(
        page: _currentPage,
        perPage: _rowsPerPage,
        search: _appliedSearchTerm,
      );
    });
  }

  void _applySearch() {
    setState(() {
      _appliedSearchTerm = _searchController.text.trim();
      _currentPage = 1;
      _vendorsFuture = ApiService.instance.getVendorsListPage(
        page: _currentPage,
        perPage: _rowsPerPage,
        search: _appliedSearchTerm,
      );
    });
  }

  Future<void> _openCreateVendor() async {
    final created = await Get.to<bool>(() => const VendorFormScreen());
    if (created == true) {
      _reload();
    }
  }

  Future<void> _openEditVendor(VendorModel vendor) async {
    final updated = await Get.to<bool>(
      () => VendorFormScreen(vendorId: vendor.id, vendor: vendor),
    );
    if (updated == true) {
      _reload();
    }
  }

  Future<void> _openVendorDetail(VendorModel vendor) async {
    final updated = await Get.to<bool>(
      () => VendorDetailScreen(vendorId: vendor.id),
    );
    if (updated == true) {
      _reload();
    }
  }

  Future<void> _deleteVendor(VendorModel vendor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete vendor'),
        content: Text(
          'Are you sure you want to delete ${vendor.vendorName.isEmpty ? 'this vendor' : vendor.vendorName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiService.instance.deleteVendor(vendor.id);
      AppSnackbar.show(
        'Vendor deleted',
        'The vendor has been deleted successfully.',
      );
      _reload();
    } on DioException catch (error) {
      final responseData = error.response?.data;
      String message = 'Failed to delete vendor.';

      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }

      AppSnackbar.show('Delete failed', message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 900;
    final useMobileLayout = width < 720;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: FutureBuilder<VendorListPageResult>(
          future: _vendorsFuture,
          builder: (context, snapshot) {
            final pageResult = snapshot.data;
            final vendors = pageResult?.items ?? const <VendorModel>[];
            final pageCount = (pageResult?.lastPage ?? 1).clamp(1, 999999);
            final currentPage = pageResult?.currentPage ?? _currentPage;
            final visibleRows = vendors;
            final totalEntries = pageResult?.total ?? vendors.length;
            final perPage = pageResult?.perPage ?? _rowsPerPage;
            final startEntry = totalEntries == 0
                ? 0
                : ((currentPage - 1) * perPage) + 1;
            final endEntry = totalEntries == 0
                ? 0
                : (startEntry + visibleRows.length - 1).clamp(0, totalEntries);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 24,
                18,
                compact ? 16 : 24,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonTopBar(
                    title: 'Vendor',
                    compact: compact,
                    onBack: Get.back,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(compact ? 16 : 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE1E8F2)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F0F172A),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _VendorToolbar(
                          compact: useMobileLayout,
                          rowsPerPage: _rowsPerPage,
                          searchController: _searchController,
                          onSearchTap: _applySearch,
                          onAddVendor: _openCreateVendor,
                          onRowsChanged: (value) {
                            setState(() {
                              _rowsPerPage = value;
                              _currentPage = 1;
                              _vendorsFuture = ApiService.instance
                                  .getVendorsListPage(
                                    page: _currentPage,
                                    perPage: _rowsPerPage,
                                    search: _appliedSearchTerm,
                                  );
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(),
                          )
                        else if (snapshot.hasError)
                          _VendorLoadError(
                            message: _readVendorError(snapshot.error),
                            onRetry: _reload,
                          )
                        else ...[
                          useMobileLayout
                              ? _VendorMobileList(
                                  rows: visibleRows,
                                  onViewVendor: _openVendorDetail,
                                  onEditVendor: _openEditVendor,
                                  onDeleteVendor: _deleteVendor,
                                )
                              : _VendorTable(
                                  rows: visibleRows,
                                  compact: compact,
                                  onViewVendor: _openVendorDetail,
                                  onEditVendor: _openEditVendor,
                                  onDeleteVendor: _deleteVendor,
                                ),
                          const SizedBox(height: 10),
                          _VendorFooter(
                            startEntry: startEntry,
                            endEntry: endEntry,
                            totalEntries: totalEntries,
                            currentPage: currentPage - 1,
                            pageCount: pageCount,
                            compact: useMobileLayout,
                            onPrevious: (currentPage > 1)
                                ? () => _reload(page: currentPage - 1)
                                : null,
                            onNext: (currentPage < pageCount)
                                ? () => _reload(page: currentPage + 1)
                                : null,
                            onSelectPage: (page) => _reload(page: page + 1),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VendorToolbar extends StatelessWidget {
  const _VendorToolbar({
    required this.compact,
    required this.rowsPerPage,
    required this.searchController,
    required this.onSearchTap,
    required this.onAddVendor,
    required this.onRowsChanged,
  });

  final bool compact;
  final int rowsPerPage;
  final TextEditingController searchController;
  final VoidCallback onSearchTap;
  final VoidCallback onAddVendor;
  final ValueChanged<int> onRowsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: compact ? 40 : 36,
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearchTap(),
                  decoration: InputDecoration(
                    hintText: 'Search vendors...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD9E2EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD9E2EF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1D8BFF)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: compact ? 120 : 135,
              child: _ToolbarButton(
                icon: Icons.search_rounded,
                label: 'Search',
                filled: true,
                onTap: onSearchTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: compact ? 150 : 185,
              child: _ToolbarButton(
                icon: Icons.add_circle_outline_rounded,
                label: compact ? 'Add Vendor' : 'Add New Vendor',
                filled: true,
                onTap: onAddVendor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Row(
        //   children: [
        //     Text(
        //       'Show',
        //       style: AppTextStyles.style(
        //         color: const Color(0xFF334155),
        //         fontSize: 14,
        //         fontWeight: FontWeight.w500,
        //       ),
        //     ),
        //     const SizedBox(width: 8),
        //     Container(
        //       height: compact ? 36 : 34,
        //       padding: const EdgeInsets.symmetric(horizontal: 10),
        //       decoration: BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.circular(8),
        //         border: Border.all(color: const Color(0xFFD9E2EF)),
        //       ),
        //       child: DropdownButtonHideUnderline(
        //         child: DropdownButton<int>(
        //           value: rowsPerPage,
        //           items: const [10, 25, 50]
        //               .map(
        //                 (value) => DropdownMenuItem<int>(
        //                   value: value,
        //                   child: Text('$value'),
        //                 ),
        //               )
        //               .toList(),
        //           onChanged: (value) {
        //             if (value != null) {
        //               onRowsChanged(value);
        //             }
        //           },
        //         ),
        //       ),
        //     ),
        //     const SizedBox(width: 8),
        //     Text(
        //       'entries',
        //       style: AppTextStyles.style(
        //         color: const Color(0xFF334155),
        //         fontSize: 14,
        //         fontWeight: FontWeight.w500,
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}

class _VendorMobileList extends StatelessWidget {
  const _VendorMobileList({
    required this.rows,
    required this.onViewVendor,
    required this.onEditVendor,
    required this.onDeleteVendor,
  });

  final List<VendorModel> rows;
  final ValueChanged<VendorModel> onViewVendor;
  final ValueChanged<VendorModel> onEditVendor;
  final ValueChanged<VendorModel> onDeleteVendor;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1E8F2)),
        ),
        child: Text(
          'No vendors found.',
          style: AppTextStyles.style(
            color: const Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VendorMobileCard(
                row: row,
                onViewVendor: () => onViewVendor(row),
                onEditVendor: () => onEditVendor(row),
                onDeleteVendor: () => onDeleteVendor(row),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _VendorMobileCard extends StatelessWidget {
  const _VendorMobileCard({
    required this.row,
    required this.onViewVendor,
    required this.onEditVendor,
    required this.onDeleteVendor,
  });

  final VendorModel row;
  final VoidCallback onViewVendor;
  final VoidCallback onEditVendor;
  final VoidCallback onDeleteVendor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.vendorName,
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _MobileInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: row.email,
          ),
          const SizedBox(height: 8),
          _MobileInfoRow(
            icon: Icons.call_outlined,
            label: 'Contact',
            value: row.contactNo,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ActionIcon(
                icon: Icons.remove_red_eye_outlined,
                onTap: onViewVendor,
              ),
              const SizedBox(width: 8),
              _ActionIcon(icon: Icons.edit_square, onTap: onEditVendor),
              const SizedBox(width: 8),
              _ActionIcon(
                icon: Icons.delete_outline_rounded,
                danger: true,
                onTap: onDeleteVendor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileInfoRow extends StatelessWidget {
  const _MobileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.style(
                color: const Color(0xFF17213A),
                fontSize: 13,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: AppTextStyles.style(
                    color: const Color(0xFF17213A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VendorTable extends StatelessWidget {
  const _VendorTable({
    required this.rows,
    required this.compact,
    required this.onViewVendor,
    required this.onEditVendor,
    required this.onDeleteVendor,
  });

  final List<VendorModel> rows;
  final bool compact;
  final ValueChanged<VendorModel> onViewVendor;
  final ValueChanged<VendorModel> onEditVendor;
  final ValueChanged<VendorModel> onDeleteVendor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: compact ? 980 : double.infinity,
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FlexColumnWidth(3.4),
              2: FlexColumnWidth(1.8),
              3: FlexColumnWidth(1.3),
              4: FixedColumnWidth(110),
              5: FixedColumnWidth(150),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFD)),
                children: const [
                  _HeaderCell(child: _CheckboxStub()),
                  _HeaderCell(label: 'Vendor Name'),
                  _HeaderCell(label: 'Email ID'),
                  _HeaderCell(label: 'Contact No'),
                  _HeaderCell(label: 'Status'),
                  _HeaderCell(label: 'Actions'),
                ],
              ),
              ...rows.map(
                (row) => TableRow(
                  decoration: BoxDecoration(
                    color: (int.tryParse(row.id) ?? 0).isEven
                        ? const Color(0xFFFAFCFF)
                        : Colors.white,
                  ),
                  children: [
                    const _BodyCell(child: _CheckboxStub()),
                    _BodyCell(
                      child: Text(
                        row.vendorName,
                        style: AppTextStyles.style(
                          color: const Color(0xFF17213A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _BodyCell(
                      child: Text(
                        row.email,
                        style: AppTextStyles.style(
                          color: const Color(0xFF334155),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _BodyCell(
                      child: Text(
                        row.contactNo,
                        style: AppTextStyles.style(
                          color: const Color(0xFF334155),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _BodyCell(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _StatusToggle(active: row.isActive),
                      ),
                    ),
                    _BodyCell(
                      child: Row(
                        children: [
                          _ActionIcon(
                            icon: Icons.remove_red_eye_outlined,
                            onTap: () => onViewVendor(row),
                          ),
                          const SizedBox(width: 8),
                          _ActionIcon(
                            icon: Icons.edit_square,
                            onTap: () => onEditVendor(row),
                          ),
                          const SizedBox(width: 8),
                          _ActionIcon(
                            icon: Icons.delete_outline_rounded,
                            danger: true,
                            onTap: () => onDeleteVendor(row),
                          ),
                        ],
                      ),
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
}

class _VendorFooter extends StatelessWidget {
  const _VendorFooter({
    required this.startEntry,
    required this.endEntry,
    required this.totalEntries,
    required this.currentPage,
    required this.pageCount,
    required this.compact,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectPage,
  });

  final int startEntry;
  final int endEntry;
  final int totalEntries;
  final int currentPage;
  final int pageCount;
  final bool compact;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onSelectPage;

  @override
  Widget build(BuildContext context) {
    List<int?> visiblePages() {
      // 0-based page indices, with `null` representing an ellipsis.
      if (pageCount <= 7) {
        return List<int?>.generate(pageCount, (index) => index);
      }

      final candidates = <int>{
        0,
        pageCount - 1,
        currentPage - 1,
        currentPage,
        currentPage + 1,
      }.where((index) => index >= 0 && index < pageCount).toList()..sort();

      final result = <int?>[];
      for (final index in candidates) {
        if (result.isNotEmpty) {
          final previous = result.last;
          if (previous is int && index - previous > 1) {
            result.add(null);
          }
        }
        result.add(index);
      }
      return result;
    }

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Showing $startEntry to $endEntry of $totalEntries entries',
            style: AppTextStyles.style(
              color: const Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PageNavButton(label: 'Prev', onTap: onPrevious),
                const SizedBox(width: 8),
                ...visiblePages().map((pageIndex) {
                  if (pageIndex == null) {
                    return const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: _EllipsisChip(),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PageNumberButton(
                      label: '${pageIndex + 1}',
                      active: pageIndex == currentPage,
                      onTap: () => onSelectPage(pageIndex),
                    ),
                  );
                }),
                _PageNavButton(label: 'Next', onTap: onNext),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          'Showing $startEntry to $endEntry of $totalEntries entries',
          style: AppTextStyles.style(
            color: const Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        _PageNavButton(label: 'Prev', onTap: onPrevious),
        const SizedBox(width: 8),
        ...visiblePages().map((pageIndex) {
          if (pageIndex == null) {
            return const Padding(
              padding: EdgeInsets.only(right: 8),
              child: _EllipsisChip(),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _PageNumberButton(
              label: '${pageIndex + 1}',
              active: pageIndex == currentPage,
              onTap: () => onSelectPage(pageIndex),
            ),
          );
        }),
        _PageNavButton(label: 'Next', onTap: onNext),
      ],
    );
  }
}

class _EllipsisChip extends StatelessWidget {
  const _EllipsisChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9E2EF)),
      ),
      child: Text(
        '...',
        style: AppTextStyles.style(
          color: const Color(0xFF475569),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.filled,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: filled ? const Color(0xFF1D8BFF) : const Color(0xFF6B7280),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                Icon(trailing, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({this.label, this.child});

  final String? label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5ECF5))),
      ),
      child:
          child ??
          Text(
            label ?? '',
            style: AppTextStyles.style(
              color: const Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F4F9))),
      ),
      child: child,
    );
  }
}

class _CheckboxStub extends StatelessWidget {
  const _CheckboxStub();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD7DEE9)),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 16,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: active ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, this.danger = false, this.onTap});

  final IconData icon;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: danger ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: danger ? const Color(0xFFB91C1C) : const Color(0xFF1D4ED8),
          ),
        ),
      ),
    );
  }
}

class _PageNavButton extends StatelessWidget {
  const _PageNavButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9E2EF)),
        ),
        child: Text(
          label,
          style: AppTextStyles.style(
            color: onTap == null
                ? const Color(0xFF94A3B8)
                : const Color(0xFF475569),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1D8BFF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFF1D8BFF) : const Color(0xFFD9E2EF),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.style(
            color: active ? Colors.white : const Color(0xFF475569),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _VendorLoadError extends StatelessWidget {
  const _VendorLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D8BFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _readVendorError(Object? error) {
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

  final fallback = error?.toString().trim() ?? '';
  return fallback.isEmpty ? 'Failed to load vendors.' : fallback;
}
