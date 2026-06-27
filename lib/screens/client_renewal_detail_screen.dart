import '../widgets/skeletons/app_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/app_error_handler.dart';
import '../core/services/permission_service.dart';
import '../core/utils/app_snackbar.dart';
import '../models/renewal_model.dart';
import '../screens/client_renewal_screen.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class ClientRenewalDetailScreen extends StatefulWidget {
  const ClientRenewalDetailScreen({super.key, this.renewal});
  final RenewalModel? renewal;
  @override
  State<ClientRenewalDetailScreen> createState() =>
      _ClientRenewalDetailScreenState();
}

class _ClientRenewalDetailScreenState extends State<ClientRenewalDetailScreen> {
  final ApiService _apiService = ApiService.instance;
  late Future<RenewalModel?> _detailFuture;
  RenewalModel? _seed;
  bool _canEditService = false;
  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _seed = _resolveRenewal();
    _detailFuture = _loadDetail();
  }

  Future<void> _loadPermissions() async {
    final values = await Future.wait<bool>([
      PermissionService.has(AppPermission.viewServicesDetail),
      PermissionService.has(AppPermission.viewServices),
      PermissionService.has(AppPermission.editServices),
    ]);
    if (!mounted) return;
    _canEditService = values[2];
    if (!(values[0] || values[1])) {
      AppSnackbar.show(
        'Access denied',
        'You do not have permission to view service details.',
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(false);
      } else {
        Get.back();
      }
      return;
    }
    setState(() {});
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
      return await _apiService.getClientRenewalDetail(id);
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
      return;
    }
    if (!_canEditService) {
      AppSnackbar.show(
        'Access denied',
        'You do not have permission to edit services.',
      );
      return;
    }
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientRenewalFormScreen(initialRenewal: renewal),
      ),
    );
    if (shouldRefresh == true && mounted) {
      setState(() {
        _seed = renewal;
        _detailFuture = _loadDetail();
      });
    }
  }

  Future<void> _openAmcVisitUpdateDialog(
    RenewalModel renewal,
    AmcVisitModel visit,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _AmcVisitUpdateDialog(
          renewalId: renewal.id,
          visit: visit,
          apiService: _apiService,
        );
      },
    );
    if (updated == true && mounted) {
      setState(() {
        _detailFuture = _loadDetail();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width <= 420;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: const CommonScreenAppBar(title: 'Service Details'),
      body: FutureBuilder<RenewalModel?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          final current = snapshot.data ?? _seed;
          final hasError = snapshot.hasError && current == null;
          if (snapshot.connectionState == ConnectionState.waiting &&
              current == null) {
            return const ScreenSkeleton();
          }
          if (hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unable to load client renewal details.',
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
              padding: EdgeInsets.all(compact ? 12 : 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    children: [
                      _DetailCard(
                        title: 'Service Details',
                        compact: compact,
                        rows: _buildRows(current),
                        onEdit: _canEditService
                            ? () => _openEditForm(current)
                            : null,
                      ),
                      if (current?.hasAmcDetails ?? false) ...[
                        SizedBox(height: compact ? 12 : 14),
                        _AmcDetailsCard(
                          item: current!,
                          compact: compact,
                          onVisitUpdate: (visit) =>
                              _openAmcVisitUpdateDialog(current, visit),
                        ),
                      ],
                    ],
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

    String richTextValue(String raw) {
      final normalized = raw
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll('&nbsp;', ' ')
          .replaceAll(RegExp(r'\s+\n'), '\n')
          .replaceAll(RegExp(r'\n\s+'), '\n')
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .trim();
      return normalized.isEmpty ? 'N/A' : normalized;
    }

    final status = value(item?.status ?? '');
    final duration = value(item?.durationText ?? '');
    final billing = value(item?.billing ?? '');
    final planType = value(item?.planType ?? '');
    return <_DetailRowData>[
      _DetailRowData(label: 'Client Name', value: value(item?.client ?? '')),
      _DetailRowData(
        label: 'Company Name',
        value: value(item?.companyName ?? ''),
      ),
      _DetailRowData(
        label: 'Client Email',
        value: value(item?.clientEmail ?? ''),
      ),
      _DetailRowData(label: 'Vendor Name', value: value(item?.vendor ?? '')),
      _DetailRowData(
        label: 'Vendor Email',
        value: value(item?.vendorEmail ?? ''),
      ),
      _DetailRowData(label: 'Service Name', value: value(item?.title ?? '')),
      _DetailRowData(label: 'Plan Type', value: planType),
      _DetailRowData(
        label: 'Service Details',
        value: richTextValue(item?.serviceDetails ?? ''),
        multiline: true,
      ),
      _DetailRowData(
        label: 'Remark',
        value: richTextValue(item?.remark ?? ''),
        multiline: true,
      ),
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
    this.onEdit,
  });
  final String title;
  final bool compact;
  final List<_DetailRowData> rows;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE2EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 14,
              compact ? 10 : 12,
              compact ? 12 : 14,
              compact ? 8 : 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.style(
                      color: const Color(0xFF1F2937),
                      fontSize: compact ? 16 : 18,
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
            padding: EdgeInsets.all(compact ? 8 : 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
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

class _AmcDetailsCard extends StatelessWidget {
  const _AmcDetailsCard({
    required this.item,
    required this.compact,
    required this.onVisitUpdate,
  });

  final RenewalModel item;
  final bool compact;
  final ValueChanged<AmcVisitModel> onVisitUpdate;

  String _value(String raw) {
    final normalized = raw.trim();
    return normalized.isEmpty ? 'N/A' : normalized;
  }

  String _count(int? value) {
    return value == null ? 'N/A' : '$value';
  }

  @override
  Widget build(BuildContext context) {
    final totalVisits = item.amcTotalVisits ?? item.amcService?.totalVisits;
    final completedVisits =
        item.amcCompletedVisits ?? item.amcService?.completedVisits;
    final pendingVisits = item.amcPendingVisits ?? item.amcService?.pendingVisits;
    final startDate = _value(item.amcStartDate);
    final endDate = _value(item.amcEndDate);
    final visits = item.amcVisits;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE2EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 14,
              compact ? 12 : 14,
              compact ? 12 : 14,
              compact ? 10 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AMC Details',
                        style: AppTextStyles.style(
                          color: const Color(0xFF1F2937),
                          fontSize: compact ? 16 : 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visits are generated automatically and start in pending state.',
                        style: AppTextStyles.style(
                          color: const Color(0xFF64748B),
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const _AmcEnabledBadge(),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDCE2EC)),
          Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _AmcStatTile(
                        compact: compact,
                        label: 'Total Visits',
                        value: _count(totalVisits),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AmcStatTile(
                        compact: compact,
                        label: 'Completed Visits',
                        value: _count(completedVisits),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AmcStatTile(
                        compact: compact,
                        label: 'Pending Visits',
                        value: _count(pendingVisits),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _AmcStatTile(
                        compact: compact,
                        label: 'AMC Start Date',
                        value: startDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AmcStatTile(
                        compact: compact,
                        label: 'AMC End Date',
                        value: endDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (visits.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDCE2EC)),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: Text(
                      'No AMC visits available.',
                      style: AppTextStyles.style(
                        color: const Color(0xFF64748B),
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Column(
                    children: visits
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key == visits.length - 1 ? 0 : 10,
                            ),
                            child: _AmcVisitCard(
                              visit: entry.value,
                              compact: compact,
                              onUpdate: () => onVisitUpdate(entry.value),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
              ],
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
            textAlign: row.multiline ? TextAlign.start : TextAlign.end,
            style: AppTextStyles.style(
              color: const Color(0xFF334155),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 9 : 11,
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
            width: compact ? 108 : 136,
            child: Text(
              '${row.label}:',
              style: AppTextStyles.style(
                color: const Color(0xFF111827),
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: row.multiline
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: valueWidget,
            ),
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
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF1389F3) : const Color(0xFF64748B),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.style(
                color: Colors.white,
                fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.style(
          color: Colors.white,
          fontSize: 12,
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
    this.multiline = false,
    this.isLast = false,
  });
  final String label;
  final String value;
  final bool asStatus;
  final bool multiline;
  final bool isLast;
}

class _AmcEnabledBadge extends StatelessWidget {
  const _AmcEnabledBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFACC15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'AMC Enabled',
        style: AppTextStyles.style(
          color: const Color(0xFF111827),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AmcStatTile extends StatelessWidget {
  const _AmcStatTile({
    required this.compact,
    required this.label,
    required this.value,
  });

  final bool compact;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.style(
                color: const Color(0xFF111827),
                fontSize: compact ? 15 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmcVisitCard extends StatelessWidget {
  const _AmcVisitCard({
    required this.visit,
    required this.compact,
    required this.onUpdate,
  });

  final AmcVisitModel visit;
  final bool compact;
  final VoidCallback onUpdate;

  String _value(String raw) {
    final normalized = raw.trim();
    return normalized.isEmpty ? 'N/A' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final visitTitle = visit.visitNumber == null
        ? 'Visit'
        : 'Visit ${visit.visitNumber}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE2EC)),
        color: const Color(0xFFFDFEFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  visitTitle,
                  style: AppTextStyles.style(
                    color: const Color(0xFF111827),
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _VisitStatusBadge(text: _value(visit.status)),
                  const SizedBox(width: 8),
                  _VisitUpdateIconButton(onUpdate: onUpdate),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              _VisitInlineRow(
                label: 'Visit Date',
                value: _value(visit.visitDate),
                compact: compact,
              ),
              const SizedBox(height: 8),
              _VisitInlineRow(
                label: 'Details',
                value: _value(visit.details),
                compact: compact,
              ),
              if (visit.completedAt.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _VisitInlineRow(
                  label: 'Completed At',
                  value: _value(visit.completedAt),
                  compact: compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _VisitStatusBadge extends StatelessWidget {
  const _VisitStatusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final normalized = text.trim().toLowerCase();
    final isCompleted = normalized.contains('complete');
    final background = isCompleted
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFACC15);
    final foreground = isCompleted
        ? const Color(0xFF166534)
        : const Color(0xFF111827);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.style(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VisitInfoChip extends StatelessWidget {
  const _VisitInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: const Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitInlineRow extends StatelessWidget {
  const _VisitInlineRow({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.style(
            color: const Color(0xFF64748B),
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.style(
            color: const Color(0xFF111827),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _VisitUpdateIconButton extends StatelessWidget {
  const _VisitUpdateIconButton({required this.onUpdate});

  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onUpdate,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF1D8BFF)),
        ),
        child: const Icon(
          Icons.edit_outlined,
          size: 16,
          color: Color(0xFF1D8BFF),
        ),
      ),
    );
  }
}

class _AmcVisitUpdateDialog extends StatefulWidget {
  const _AmcVisitUpdateDialog({
    required this.renewalId,
    required this.visit,
    required this.apiService,
  });

  final String renewalId;
  final AmcVisitModel visit;
  final ApiService apiService;

  @override
  State<_AmcVisitUpdateDialog> createState() => _AmcVisitUpdateDialogState();
}

class _AmcVisitUpdateDialogState extends State<_AmcVisitUpdateDialog> {
  final TextEditingController _detailsController = TextEditingController();
  bool _isSaving = false;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _detailsController.text = widget.visit.details == 'N/A'
        ? ''
        : widget.visit.details;
    final status = widget.visit.status.trim().toLowerCase();
    _selectedStatus = status == 'completed' || status == 'pending'
        ? status
        : 'pending';
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  String _formatDate(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? 'N/A' : normalized;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.apiService.updateClientRenewalAmcVisit(
        renewalId: widget.renewalId,
        visitId: widget.visit.id,
        status: _selectedStatus,
        details: _detailsController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Update failed',
        AppErrorHandler.messageFromError(
          error,
          fallback: 'Failed to update AMC visit.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width <= 480 ? width - 24 : 520.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Update Visit ${widget.visit.visitNumber ?? ''}'.trim(),
                        style: AppTextStyles.style(
                          color: const Color(0xFF1F2937),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Text(
                  'Status',
                  style: AppTextStyles.style(
                    color: const Color(0xFF334155),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _selectedStatus = value);
                        },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDCE2EC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDCE2EC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1D8BFF)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Details',
                  style: AppTextStyles.style(
                    color: const Color(0xFF334155),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add visit remarks...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDCE2EC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDCE2EC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1D8BFF)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8F3FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8EDCFA)),
                  ),
                  child: Text(
                    'Visit date: ${_formatDate(widget.visit.visitDate)}',
                    style: AppTextStyles.style(
                      color: const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1282F5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
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
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
