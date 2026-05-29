import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_text_styles.dart';
import '../models/lead_model.dart';
import '../providers/lead_detail_provider.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';
import '../widgets/app_bottom_navigation.dart';

class LeadManagementDetailScreen extends StatefulWidget {
  const LeadManagementDetailScreen({super.key});

  @override
  State<LeadManagementDetailScreen> createState() => _LeadManagementDetailScreenState();
}

class _LeadManagementDetailScreenState extends State<LeadManagementDetailScreen> with SingleTickerProviderStateMixin {
  static const List<String> _fixedStatusOptions = <String>[
    'New',
    'Attempted Contact',
    'Contacted',
    'Qualified',
    'Demo Scheduled',
    'Proposal Sent',
    'Negotiation',
    'Converted',
    'Lost',
    'Junk',
  ];

  final ApiService _apiService = ApiService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const Color background = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFF3F51B5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Consumer<LeadDetailProvider>(
          builder: (context, provider, _) {
            final lead = provider.lead;

            if (provider.isLoading && lead == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && lead == null) {
              return _ErrorView(
                message: provider.errorMessage!,
                onRetry: () => provider.loadLead(forceRefresh: true),
              );
            }

            if (lead == null) {
              return _ErrorView(
                message: 'Lead details are not available.',
                onRetry: () => provider.loadLead(forceRefresh: true),
              );
            }

            return Column(
              children: [
                const CommonTopBar(
                  title: 'Lead Profile',
                  showBackButton: true,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.loadLead(forceRefresh: true),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderSection(lead: lead),
                          const SizedBox(height: 16),
                          _ActionButtons(
                            onUpdateStatus: () => _openStatusUpdateDialog(lead),
                          ),
                          const SizedBox(height: 16),
                          _LeadInformationCard(lead: lead),
                          const SizedBox(height: 16),
                          _UpdateStatusCard(lead: lead),
                          const SizedBox(height: 20),
                          _TimelineTabs(tabController: _tabController),
                          const SizedBox(height: 12),
                          _TimelineList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.leads,
      ),
    );
  }
  String _buildLeadAssignSource(LeadModel lead) {
    final raw =
        (lead.sourceType ?? lead.source ?? '').trim().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
    switch (raw) {
      case 'lead':
      case 'leads':
        return 'lead';
      case 'digitalmarketing':
        return 'digital_marketing';
      case 'webapp':
      case 'webapps':
      case 'webapplication':
        return 'webapp';
      case 'meta':
      case 'facebook':
        return 'meta';
      case 'google':
      case 'googleads':
        return 'google';
      case 'indiamart':
        return 'indiamart';
      case 'justdial':
        return 'justdial';
      default:
        return raw.isEmpty ? 'lead' : raw;
    }
  }

  String _resolveLeadSourceId(LeadModel lead) {
    final sourceId = (lead.sourceId ?? '').trim();
    if (sourceId.isNotEmpty) return sourceId;
    return lead.id.trim();
  }

  String _normalizeStatusForApi(String status) {
    return status.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _resolveCurrentStatusOption(String currentStatus) {
    final normalizedCurrent = _normalizeStatusForApi(currentStatus);
    for (final option in _fixedStatusOptions) {
      final normalizedOption = _normalizeStatusForApi(option);
      if (normalizedOption == normalizedCurrent) {
        return option;
      }
      if (normalizedCurrent == 'won' && normalizedOption == 'converted') {
        return option;
      }
    }
    return _fixedStatusOptions.first;
  }

  Future<void> _openStatusUpdateDialog(LeadModel lead) async {
    final messenger = ScaffoldMessenger.of(context);
    final remarksController = TextEditingController();
    final lostReasonController = TextEditingController();
    final wonValueController = TextEditingController();
    String selectedStatus = _resolveCurrentStatusOption(lead.displayStatus);
    bool isSubmitting = false;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final isLost = selectedStatus.toLowerCase() == 'lost';
            final isConverted = selectedStatus.toLowerCase() == 'converted';

            Future<void> onUpdate() async {
              if (isSubmitting) return;
              if (isLost && lostReasonController.text.trim().isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Lost reason is required for lost status.')),
                );
                return;
              }
              if (isConverted && wonValueController.text.trim().isNotEmpty) {
                final parsed = double.tryParse(wonValueController.text.trim());
                if (parsed == null) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Converted value must be a valid number.')),
                  );
                  return;
                }
              }

              setLocalState(() => isSubmitting = true);
              try {
                await _apiService.updateLeadStatus(
                  sourceType: _buildLeadAssignSource(lead),
                  leadId: _resolveLeadSourceId(lead),
                  status: _normalizeStatusForApi(selectedStatus),
                  remarks: remarksController.text.trim(),
                  lostReason: isLost ? lostReasonController.text.trim() : null,
                  wonValue: isConverted && wonValueController.text.trim().isNotEmpty
                      ? double.tryParse(wonValueController.text.trim())
                      : null,
                );
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Lead status updated successfully.')),
                );
                await context.read<LeadDetailProvider>().loadLead(forceRefresh: true);
              } catch (_) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Failed to update lead status. Please try again.')),
                );
                setLocalState(() => isSubmitting = false);
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Change Lead Status',
                              style: AppTextStyles.style(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.displayName,
                            style: AppTextStyles.style(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Current Status',
                            style: AppTextStyles.style(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              lead.displayStatus,
                              style: AppTextStyles.style(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Status',
                            style: AppTextStyles.style(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            items: _fixedStatusOptions
                                .map(
                                  (status) => DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                            onChanged: isSubmitting
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setLocalState(() => selectedStatus = value);
                                  },
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: wonValueController,
                            enabled: !isSubmitting,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Converted Value (if converted)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: lostReasonController,
                            enabled: !isSubmitting,
                            minLines: 2,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Lost Reason (required if lost)',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              errorText: isLost && lostReasonController.text.trim().isEmpty
                                  ? 'Required for Lost status'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: remarksController,
                            enabled: !isSubmitting,
                            minLines: 2,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Remarks',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: isSubmitting ? null : onUpdate,
                            child: Text(isSubmitting ? 'Updating...' : 'Update'),
                          ),
                        ],
                      ),
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
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.lead});
  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CUSTOMER NAME',
          style: AppTextStyles.style(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                lead.displayName,
                style: AppTextStyles.style(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            _StatusBadge(status: lead.displayStatus),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: AppTextStyles.style(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF15803D),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onUpdateStatus});

  final VoidCallback onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionButton(
            label: 'Add Followup',
            icon: Icons.add_circle_outline,
            backgroundColor: const Color(0xFF3F51B5),
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Update Status',
            icon: Icons.sync_alt_rounded,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF3F51B5),
            borderColor: const Color(0xFF3F51B5),
            onTap: onUpdateStatus,
          ),
        ],
      ),
    );
  }

}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadInformationCard extends StatelessWidget {
  const _LeadInformationCard({required this.lead});
  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lead Information',
                style: AppTextStyles.style(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Icon(Icons.info_outline, size: 20, color: Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoItem(label: 'EMAIL', value: lead.displayEmail),
                    const SizedBox(height: 16),
                    _InfoItem(label: 'COMPANY', value: lead.displayCompany),
                    const SizedBox(height: 16),
                    _InfoItem(label: 'CREATED DATE', value: _formatDate(lead.createdAt)),
                    const SizedBox(height: 16),
                    _InfoItem(label: 'CONVERTED AT', value: _formatDate(lead.convertedAt)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoItem(label: 'PHONE', value: lead.displayPhone),
                    const SizedBox(height: 16),
                    _InfoItem(label: 'SOURCE', value: lead.displaySource),
                    const SizedBox(height: 16),
                    _InfoItem(label: 'PREVIOUS STATUS', value: lead.previousStatus ?? 'N/A'),
                    const SizedBox(height: 16),
                    _InfoItem(label: 'LOST REASON', value: lead.lostReason ?? '-'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy hh:mm a').format(date);
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.style(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _UpdateStatusCard extends StatelessWidget {
  const _UpdateStatusCard({required this.lead});
  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Status',
            style: AppTextStyles.style(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _InputFieldLabel(label: 'Status'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: lead.displayStatus,
            items: [lead.displayStatus].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {},
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 16),
          _InputFieldLabel(label: 'Conversion Value'),
          const SizedBox(height: 8),
          TextFormField(
            decoration: _inputDecoration(hint: 'Optional'),
          ),
          const SizedBox(height: 16),
          _InputFieldLabel(label: 'Remarks'),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: 3,
            decoration: _inputDecoration(hint: 'Optional notes'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Save Status',
                style: AppTextStyles.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}

class _InputFieldLabel extends StatelessWidget {
  const _InputFieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.style(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
      ),
    );
  }
}

class _TimelineTabs extends StatelessWidget {
  const _TimelineTabs({required this.tabController});
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      labelColor: const Color(0xFF3F51B5),
      unselectedLabelColor: const Color(0xFF64748B),
      indicatorColor: const Color(0xFF3F51B5),
      labelStyle: AppTextStyles.style(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: AppTextStyles.style(fontSize: 13, fontWeight: FontWeight.w500),
      tabs: const [
        Tab(text: 'Timeline'),
        Tab(text: 'Followups'),
        Tab(text: 'Notes'),
        Tab(text: 'Reminders'),
      ],
    );
  }
}

class _TimelineList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final timelineItems = [
      _TimelineItemData(
        title: 'Status Changed',
        description: 'Lead status changed from converted to converted',
        time: '28 May 2026 03:58 PM',
        icon: Icons.sync,
      ),
      _TimelineItemData(
        title: 'Lead Assigned',
        description: 'Lead successfully assigned to Sales Representative.',
        time: '27 May 2026 05:45 PM',
        icon: Icons.person_add_alt_1,
      ),
      _TimelineItemData(
        title: 'Note Added',
        description: 'Customer requested a call back regarding enterprise pricing.',
        time: '26 May 2026 05:56 PM',
        icon: Icons.note_add_outlined,
      ),
    ];

    return Column(
      children: timelineItems.map((item) => _TimelineTile(data: item)).toList(),
    );
  }
}

class _TimelineItemData {
  const _TimelineItemData({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
  });
  final String title;
  final String description;
  final String time;
  final IconData icon;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.data});
  final _TimelineItemData data;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, size: 20, color: const Color(0xFF3F51B5)),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.title,
                        style: AppTextStyles.style(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        data.time,
                        style: AppTextStyles.style(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.description,
                    style: AppTextStyles.style(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.style(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
