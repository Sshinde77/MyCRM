import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/vendor_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

import 'vendor_form_screen.dart';

class VendorDetailScreen extends StatefulWidget {
  const VendorDetailScreen({super.key, this.vendorId, this.vendor});

  final String? vendorId;
  final Map<String, dynamic>? vendor;

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final TextEditingController _serviceSearchController =
      TextEditingController();
  late Future<VendorModel> _detailFuture;
  String? _vendorId;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _vendorId =
        widget.vendorId ?? _extractVendorId(widget.vendor ?? Get.arguments);
    _detailFuture = _loadVendorDetail();
    _serviceSearchController.addListener(() => setState(() {}));
  }

  Future<VendorModel> _loadVendorDetail() async {
    final id = (_vendorId ?? '').trim();
    if (id.isEmpty) {
      throw Exception('Vendor id missing');
    }
    return ApiService.instance.getVendorDetail(id);
  }

  void _reload() {
    setState(() {
      _detailFuture = _loadVendorDetail();
    });
  }

  void _closeScreen() {
    Navigator.of(context).pop(_hasChanges);
  }

  Future<void> _openEditVendor(VendorModel detail) async {
    final updated = await Get.to<bool>(
      () => VendorFormScreen(vendorId: detail.id, vendor: detail),
    );
    if (updated == true) {
      _hasChanges = true;
      _reload();
    }
  }

  @override
  void dispose() {
    _serviceSearchController.dispose();
    super.dispose();
  }

  List<_VendorServiceRow> _servicesFor(VendorModel detail) {
    return detail.services
        .map(
          (service) => _VendorServiceRow(
            serviceId: service.id,
            clientName: service.clientName.isEmpty
                ? 'Unknown client'
                : service.clientName,
            serviceName: service.serviceName.isEmpty
                ? 'Untitled service'
                : service.serviceName,
            startDate: service.startDate,
            endDate: service.endDate,
            billingDate: service.billingDate,
            status: service.status.isEmpty ? 'Unknown' : service.status,
          ),
        )
        .toList(growable: false);
  }

  List<_VendorServiceRow> _filteredServices(VendorModel detail) {
    final query = _serviceSearchController.text.trim().toLowerCase();
    final services = _servicesFor(detail);
    if (query.isEmpty) return services;
    return services.where((row) {
      return row.serviceId.contains(query) ||
          row.clientName.toLowerCase().contains(query) ||
          row.serviceName.toLowerCase().contains(query) ||
          row.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 720;
    final sidePadding = isMobile ? 16.0 : 24.0;

    return WillPopScope(
      onWillPop: () async {
        _closeScreen();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F6FB),
        body: SafeArea(
          child: FutureBuilder<VendorModel>(
            future: _detailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 10),
                        Text(
                          _readVendorError(snapshot.error),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.style(
                            color: const Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _reload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D8BFF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final detail = snapshot.data;
              if (detail == null) {
                return const Center(child: Text('Vendor not found'));
              }

              final filteredServices = _filteredServices(detail);

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(sidePadding, 18, sidePadding, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(title: 'Vendor details', onBack: _closeScreen),
                        const SizedBox(height: 18),
                        _SectionHeader(
                          title: 'Vendor Details',
                          actions: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _PrimaryActionButton(
                                label: 'Edit',
                                icon: Icons.edit_outlined,
                                onTap: () => _openEditVendor(detail),
                              ),
                              _SecondaryActionButton(
                                label: 'Back to List',
                                icon: Icons.arrow_back_rounded,
                                onTap: _closeScreen,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Card(
                          child: isMobile
                              ? _VendorDetailMobile(detail: detail)
                              : _VendorDetailTable(detail: detail),
                        ),
                        const SizedBox(height: 18),
                        _SectionHeader(
                          title: 'Vendor Services',
                          actions: _PrimaryActionButton(
                            label: 'Add New Service',
                            icon: Icons.add_rounded,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ServiceToolbar(
                                controller: _serviceSearchController,
                                isMobile: isMobile,
                              ),
                              const SizedBox(height: 14),
                              if (filteredServices.isEmpty)
                                const _EmptyState(
                                  message: 'No services found for this vendor.',
                                )
                              else
                                isMobile
                                    ? _ServiceMobileList(rows: filteredServices)
                                    : _ServiceTable(rows: filteredServices),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 720;
    return CommonTopBar(title: title, compact: isMobile, onBack: onBack);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actions});

  final String title;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 720;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        actions,
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1D8BFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF64748B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _VendorDetailTable extends StatelessWidget {
  const _VendorDetailTable({required this.detail});

  final VendorModel detail;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value})>[
      (label: 'Vendor ID', value: '${detail.id}'),
      (label: 'Vendor Name', value: detail.vendorName),
      (label: 'Email ID', value: detail.email),
      (label: 'Contact No', value: detail.contactNo),
      (label: 'Created At', value: detail.createdAt),
      (label: 'Last Updated', value: detail.updatedAt),
    ];

    return _VendorInfoBox(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(1.1), 1: FlexColumnWidth(2)},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows
              .map(
                (row) => TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE8EEF6)),
                    ),
                  ),
                  children: [
                    _DetailCellLabel(text: '${row.label}:'),
                    _DetailCellValue(text: row.value),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _VendorDetailMobile extends StatelessWidget {
  const _VendorDetailMobile({required this.detail});

  final VendorModel detail;

  @override
  Widget build(BuildContext context) {
    final fields = <({IconData icon, String label, String value})>[
      (icon: Icons.tag_outlined, label: 'Vendor ID', value: '${detail.id}'),
      (
        icon: Icons.store_outlined,
        label: 'Vendor Name',
        value: detail.vendorName,
      ),
      (icon: Icons.email_outlined, label: 'Email ID', value: detail.email),
      (icon: Icons.call_outlined, label: 'Contact No', value: detail.contactNo),
      (
        icon: Icons.access_time_rounded,
        label: 'Created At',
        value: detail.createdAt,
      ),
      (
        icon: Icons.update_rounded,
        label: 'Last Updated',
        value: detail.updatedAt,
      ),
    ];

    return _VendorInfoBox(
      child: Column(
        children: fields
            .map(
              (field) => _MobileDetailTile(
                icon: field.icon,
                label: field.label,
                value: field.value,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _VendorInfoBox extends StatelessWidget {
  const _VendorInfoBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: child,
    );
  }
}

class _MobileDetailTile extends StatelessWidget {
  const _MobileDetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: label == 'Last Updated'
                ? Colors.transparent
                : const Color(0xFFE3EAF5),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1D8BFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTextStyles.style(
                    color: const Color(0xFF17213A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _DetailCellLabel extends StatelessWidget {
  const _DetailCellLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: AppTextStyles.style(
          color: const Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailCellValue extends StatelessWidget {
  const _DetailCellValue({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: AppTextStyles.style(
          color: const Color(0xFF17213A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ServiceToolbar extends StatelessWidget {
  const _ServiceToolbar({required this.controller, required this.isMobile});

  final TextEditingController controller;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search services...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE3EAF5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE3EAF5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1D8BFF)),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search Services',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFD),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE3EAF5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE3EAF5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1D8BFF)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceTable extends StatelessWidget {
  const _ServiceTable({required this.rows});

  final List<_VendorServiceRow> rows;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(110),
            1: FixedColumnWidth(180),
            2: FixedColumnWidth(220),
            3: FixedColumnWidth(140),
            4: FixedColumnWidth(140),
            5: FixedColumnWidth(150),
            6: FixedColumnWidth(120),
            7: FixedColumnWidth(150),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFF8FAFD)),
              children: [
                _ServiceHeaderCell(label: 'Service ID'),
                _ServiceHeaderCell(label: 'Client Name'),
                _ServiceHeaderCell(label: 'Service Name'),
                _ServiceHeaderCell(label: 'Start Date'),
                _ServiceHeaderCell(label: 'End Date'),
                _ServiceHeaderCell(label: 'Billing Date'),
                _ServiceHeaderCell(label: 'Status'),
                _ServiceHeaderCell(label: 'Actions'),
              ],
            ),
            ...rows.map(
              (row) => TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F4F9))),
                ),
                children: [
                  _ServiceBodyCell(text: row.serviceId),
                  _ServiceBodyCell(text: row.clientName),
                  _ServiceBodyCell(text: row.serviceName),
                  _ServiceBodyCell(text: row.startDate),
                  _ServiceBodyCell(text: row.endDate),
                  _ServiceBodyCell(text: row.billingDate),
                  _ServiceStatusCell(status: row.status),
                  const _ServiceActionsCell(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceMobileList extends StatelessWidget {
  const _ServiceMobileList({required this.rows});

  final List<_VendorServiceRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServiceMobileCard(row: row),
            ),
          )
          .toList(),
    );
  }
}

class _ServiceMobileCard extends StatelessWidget {
  const _ServiceMobileCard({required this.row});

  final _VendorServiceRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Service ID ${row.serviceId}',
                  style: AppTextStyles.style(
                    color: const Color(0xFF1D4ED8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _MiniStatusPill(status: row.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            row.serviceName,
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Client: ${row.clientName}',
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _MetaChip(icon: Icons.play_circle_outline, text: row.startDate),
              _MetaChip(icon: Icons.event_outlined, text: row.endDate),
              _MetaChip(
                icon: Icons.calendar_month_outlined,
                text: row.billingDate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ServiceActionsRow(),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.style(
              color: const Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceHeaderCell extends StatelessWidget {
  const _ServiceHeaderCell({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5ECF5))),
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: const Color(0xFF111827),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ServiceBodyCell extends StatelessWidget {
  const _ServiceBodyCell({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        text,
        style: AppTextStyles.style(
          color: const Color(0xFF334155),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ServiceStatusCell extends StatelessWidget {
  const _ServiceStatusCell({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: _MiniStatusPill(status: status),
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  const _MiniStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final active =
        normalized.contains('active') ||
        normalized.contains('in progress') ||
        normalized.contains('progress');
    final bg = active ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9);
    final fg = active ? const Color(0xFF16A34A) : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: AppTextStyles.style(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ServiceActionsCell extends StatelessWidget {
  const _ServiceActionsCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: const [
          _ActionIcon(icon: Icons.remove_red_eye_outlined),
          SizedBox(width: 8),
          _ActionIcon(icon: Icons.edit_square),
          SizedBox(width: 8),
          _ActionIcon(icon: Icons.delete_outline_rounded, danger: true),
        ],
      ),
    );
  }
}

class _ServiceActionsRow extends StatelessWidget {
  const _ServiceActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _ActionIcon(icon: Icons.remove_red_eye_outlined),
        SizedBox(width: 8),
        _ActionIcon(icon: Icons.edit_square),
        SizedBox(width: 8),
        _ActionIcon(icon: Icons.delete_outline_rounded, danger: true),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Text(
        message,
        style: AppTextStyles.style(
          color: const Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _VendorServiceRow {
  const _VendorServiceRow({
    required this.serviceId,
    required this.clientName,
    required this.serviceName,
    required this.startDate,
    required this.endDate,
    required this.billingDate,
    required this.status,
  });

  final String serviceId;
  final String clientName;
  final String serviceName;
  final String startDate;
  final String endDate;
  final String billingDate;
  final String status;
}

String? _extractVendorId(dynamic args) {
  if (args == null) return null;
  if (args is String) return args;
  if (args is int) return args.toString();
  if (args is Map) {
    final raw = args['id'] ?? args['vendorId'] ?? args['vendor_id'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString();
    }
  }
  return null;
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
  return fallback.isEmpty ? 'Failed to load vendor details.' : fallback;
}
