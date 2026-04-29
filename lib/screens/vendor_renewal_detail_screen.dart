import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_text_styles.dart';
import '../models/renewal_model.dart';
import '../services/api_service.dart';
import 'vendor_renewal_form_screen.dart';
import '../widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class VendorRenewalDetailScreen extends StatefulWidget {
  const VendorRenewalDetailScreen({super.key, this.renewal});

  final RenewalModel? renewal;

  @override
  State<VendorRenewalDetailScreen> createState() =>
      _VendorRenewalDetailScreenState();
}

class _VendorRenewalDetailScreenState extends State<VendorRenewalDetailScreen> {
  final ApiService _apiService = ApiService.instance;
  late Future<RenewalModel?> _detailFuture;
  RenewalModel? _seed;

  @override
  void initState() {
    super.initState();
    _seed = _resolveRenewal();
    _detailFuture = _loadDetail();
  }

  RenewalModel? _resolveRenewal() {
    if (widget.renewal != null) return widget.renewal;
    final args = Get.arguments;
    if (args is RenewalModel) return args;
    if (args is Map<String, dynamic>) return RenewalModel.fromJson(args);
    if (args is Map) {
      return RenewalModel.fromJson(
        args.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  Future<RenewalModel?> _loadDetail() async {
    final current = _seed;
    final id = (current?.id ?? '').trim();
    if (id.isEmpty) {
      return current;
    }

    try {
      return await _apiService.getVendorRenewalDetail(id);
    } catch (_) {
      if (current != null) return current;
      rethrow;
    }
  }

  void _retry() {
    setState(() {
      _detailFuture = _loadDetail();
    });
  }

  Future<void> _openEditForm(RenewalModel? renewal) async {
    if (renewal == null) {
      AppSnackbar.show(
        'Edit unavailable',
        'Vendor service details are not available yet.',
      );
      return;
    }

    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VendorRenewalFormScreen(initialRenewal: renewal),
      ),
    );

    if (shouldRefresh == true && mounted) {
      setState(() {
        _seed = renewal;
        _detailFuture = _loadDetail();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width <= 380;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: const CommonScreenAppBar(title: 'Vendor Service Details'),
      body: FutureBuilder<RenewalModel?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          final current = snapshot.data ?? _seed;
          final hasError = snapshot.hasError && current == null;

          if (snapshot.connectionState == ConnectionState.waiting &&
              current == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unable to load vendor renewal details.',
                      style: AppTextStyles.style(
                        color: const Color(0xFF334155),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 14 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: _DetailCard(
                    title: 'Vendor Service Details',
                    compact: compact,
                    rows: _buildRows(current),
                    onEdit: () => _openEditForm(current),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<_DetailRowData> _buildRows(RenewalModel? item) {
    String value(String raw) {
      final normalized = raw.trim();
      return normalized.isEmpty ? 'N/A' : normalized;
    }

    final status = value(item?.status ?? '');
    final duration = value(item?.durationText ?? '');
    final billing = value(item?.billing ?? '');
    final planType = value(item?.planType ?? '');

    return <_DetailRowData>[
      _DetailRowData(label: 'Vendor Name', value: value(item?.vendor ?? '')),
      _DetailRowData(
        label: 'Vendor Email',
        value: value(item?.vendorEmail ?? ''),
      ),
      _DetailRowData(label: 'Service Name', value: value(item?.title ?? '')),
      _DetailRowData(label: 'Plan Type', value: planType),
      _DetailRowData(label: 'Start Date', value: value(item?.startDate ?? '')),
      _DetailRowData(label: 'End Date', value: value(item?.endDate ?? '')),
      _DetailRowData(label: 'Duration', value: duration),
      _DetailRowData(label: 'Billing Date', value: billing),
      _DetailRowData(label: 'Status', value: status, asStatus: true),
      _DetailRowData(label: 'Created At', value: value(item?.createdAt ?? '')),
      _DetailRowData(
        label: 'Last Updated',
        value: value(item?.updatedAt ?? ''),
        isLast: true,
      ),
    ];
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.compact,
    required this.rows,
    required this.onEdit,
  });

  final String title;
  final bool compact;
  final List<_DetailRowData> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE2EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 18,
              compact ? 12 : 14,
              compact ? 14 : 18,
              compact ? 10 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.style(
                      color: const Color(0xFF1F2937),
                      fontSize: compact ? 18 : 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeaderButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          filled: true,
                          onTap: onEdit,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDCE2EC)),
          Padding(
            padding: EdgeInsets.all(compact ? 10 : 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDCE2EC)),
              ),
              child: Column(
                children: rows
                    .map((row) => _DetailRow(row: row, compact: compact))
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row, required this.compact});

  final _DetailRowData row;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final valueWidget = row.asStatus
        ? _StatusBadge(text: row.value)
        : Text(
            row.value,
            textAlign: TextAlign.end,
            style: AppTextStyles.style(
              color: const Color(0xFF334155),
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w500,
            ),
          );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 11 : 13,
      ),
      decoration: BoxDecoration(
        border: row.isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE3E8F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 120 : 156,
            child: Text(
              '${row.label}:',
              style: AppTextStyles.style(
                color: const Color(0xFF111827),
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: valueWidget),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF1389F3) : const Color(0xFF64748B),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTextStyles.style(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final normalized = text.toLowerCase();
    final active =
        normalized.contains('active') && !normalized.contains('inactive');
    final bg = active ? const Color(0xFF22C55E) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.style(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailRowData {
  const _DetailRowData({
    required this.label,
    required this.value,
    this.asStatus = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool asStatus;
  final bool isLast;
}
