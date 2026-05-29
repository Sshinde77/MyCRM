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
  State<LeadManagementDetailScreen> createState() =>
      _LeadManagementDetailScreenState();
}

class _LeadManagementDetailScreenState extends State<LeadManagementDetailScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _fixedStatusOptions = <String>[
    'new',
    'attempted_contact',
    'contacted',
    'qualified',
    'demo_scheduled',
    'proposal_sent',
    'negotiation',
    'converted',
    'lost',
    'junk',
  ];

  final ApiService _apiService = ApiService.instance;
  late TabController _tabController;
  int _selectedLeadTab = 0;
  List<Map<String, dynamic>> _timelineItems = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _followupItems = const <Map<String, dynamic>>[];
  bool _isTimelineLoading = false;
  bool _isFollowupsLoading = false;
  String _loadedTimelineKey = '';
  String _loadedFollowupsKey = '';
  String _activeLeadKey = '';
  String _activeSourceType = '';
  String _activeSourceId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_selectedLeadTab != _tabController.index) {
        setState(() => _selectedLeadTab = _tabController.index);
        _triggerTabLoad();
      }
    });
  }

  void _triggerTabLoad() {
    if (!mounted || _activeSourceType.isEmpty || _activeSourceId.isEmpty) return;
    if (_selectedLeadTab == 0) {
      _loadTimelineByKey(
        sourceType: _activeSourceType,
        sourceId: _activeSourceId,
      );
    } else if (_selectedLeadTab == 1) {
      _loadFollowupsByKey(
        sourceType: _activeSourceType,
        sourceId: _activeSourceId,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const Color background = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFF3F51B5);

  Future<void> _loadTimelineByKey({
    required String sourceType,
    required String sourceId,
  }) async {
    final requestKey = '$sourceType::$sourceId';
    if (_isTimelineLoading || _loadedTimelineKey == requestKey) return;

    setState(() => _isTimelineLoading = true);
    try {
      final results = await _apiService.getLeadTimeline(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (!mounted) return;
      setState(() {
        _timelineItems = results;
        _loadedTimelineKey = requestKey;
        _isTimelineLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isTimelineLoading = false);
    }
  }

  Future<void> _loadFollowupsByKey({
    required String sourceType,
    required String sourceId,
  }) async {
    final requestKey = '$sourceType::$sourceId';
    if (_isFollowupsLoading || _loadedFollowupsKey == requestKey) return;

    setState(() => _isFollowupsLoading = true);
    try {
      final results = await _apiService.getLeadFollowups(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (!mounted) return;
      setState(() {
        _followupItems = results;
        _loadedFollowupsKey = requestKey;
        _isFollowupsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFollowupsLoading = false);
    }
  }

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
            final currentLeadKey =
                '${_buildLeadAssignSource(lead)}::${_resolveLeadSourceId(lead)}';
            if (_activeLeadKey != currentLeadKey) {
              _activeLeadKey = currentLeadKey;
              _activeSourceType = _buildLeadAssignSource(lead);
              _activeSourceId = _resolveLeadSourceId(lead);
              _loadedTimelineKey = '';
              _loadedFollowupsKey = '';
              _timelineItems = const <Map<String, dynamic>>[];
              _followupItems = const <Map<String, dynamic>>[];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_selectedLeadTab == 0) {
                  _loadTimelineByKey(
                    sourceType: _activeSourceType,
                    sourceId: _activeSourceId,
                  );
                } else if (_selectedLeadTab == 1) {
                  _loadFollowupsByKey(
                    sourceType: _activeSourceType,
                    sourceId: _activeSourceId,
                  );
                }
              });
            }

            return Column(
              children: [
                const CommonTopBar(title: 'Lead Profile', showBackButton: true),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.loadLead(forceRefresh: true),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderSection(lead: lead),
                          const SizedBox(height: 16),
                          _ActionButtons(
                            onAddFollowup: () => _openAddFollowupDialog(lead),
                            onUpdateStatus: () => _openStatusUpdateDialog(lead),
                          ),
                          const SizedBox(height: 16),
                          _LeadInformationCard(lead: lead),
                          // const SizedBox(height: 16),
                          // _UpdateStatusCard(lead: lead),
                          const SizedBox(height: 20),
                          _TimelineTabs(tabController: _tabController),
                          const SizedBox(height: 12),
                          _LeadTabContent(
                            tabIndex: _selectedLeadTab,
                            timelineItems: _timelineItems,
                            followupItems: _followupItems,
                            isTimelineLoading: _isTimelineLoading,
                            isFollowupsLoading: _isFollowupsLoading,
                            onAddNote: (note, isPrivate) async {
                              await _apiService.createLeadNote(
                                sourceType: _buildLeadAssignSource(lead),
                                sourceId: _resolveLeadSourceId(lead),
                                note: note,
                                isPrivate: isPrivate,
                              );
                              if (_selectedLeadTab == 0) {
                                _loadedTimelineKey = '';
                                await _loadTimelineByKey(
                                  sourceType: _buildLeadAssignSource(lead),
                                  sourceId: _resolveLeadSourceId(lead),
                                );
                              }
                            },
                            onAddReminder: (remindAt, reminderType) async {
                              await _apiService.createLeadReminder(
                                sourceType: _buildLeadAssignSource(lead),
                                sourceId: _resolveLeadSourceId(lead),
                                remindAt: remindAt,
                                reminderType: reminderType,
                              );
                              if (_selectedLeadTab == 1) {
                                _loadedFollowupsKey = '';
                                await _loadFollowupsByKey(
                                  sourceType: _buildLeadAssignSource(lead),
                                  sourceId: _resolveLeadSourceId(lead),
                                );
                              }
                            },
                          ),
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
    final raw = (lead.sourceType ?? lead.source ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
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

  String _statusLabel(String status) {
    final normalized = _normalizeStatusForApi(status);
    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
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
                  const SnackBar(
                    content: Text('Lost reason is required for lost status.'),
                  ),
                );
                return;
              }
              if (isConverted && wonValueController.text.trim().isNotEmpty) {
                final parsed = double.tryParse(wonValueController.text.trim());
                if (parsed == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Converted value must be a valid number.'),
                    ),
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
                  wonValue:
                      isConverted && wonValueController.text.trim().isNotEmpty
                      ? double.tryParse(wonValueController.text.trim())
                      : null,
                );
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Lead status updated successfully.'),
                  ),
                );
                await context.read<LeadDetailProvider>().loadLead(
                  forceRefresh: true,
                );
              } catch (_) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Failed to update lead status. Please try again.',
                    ),
                  ),
                );
                setLocalState(() => isSubmitting = false);
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              _statusLabel(lead.displayStatus),
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
                                    child: Text(_statusLabel(status)),
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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: wonValueController,
                            enabled: !isSubmitting,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
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
                              errorText:
                                  isLost &&
                                      lostReasonController.text.trim().isEmpty
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
                            child: Text(
                              isSubmitting ? 'Updating...' : 'Update',
                            ),
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

  Future<void> _openAddFollowupDialog(LeadModel lead) async {
    final messenger = ScaffoldMessenger.of(context);
    final notesController = TextEditingController();
    String followupType = 'call';
    String outcome = '';
    String leadStatus = 'no_change';
    String reminderType = 'Dashboard';
    bool createReminder = false;
    bool isSubmitting = false;
    DateTime? followupDate;
    DateTime? nextFollowupDate;

    String formatDate(DateTime? date) {
      if (date == null) return 'dd-mm-yyyy --:--';
      return DateFormat('dd-MM-yyyy hh:mm a').format(date);
    }

    Future<void> pickDate(
      BuildContext context,
      DateTime? currentValue,
      ValueChanged<DateTime> onPicked,
    ) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: currentValue ?? now,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) onPicked(picked);
    }

    Future<void> pickDateTime(
      BuildContext context,
      DateTime? currentValue,
      ValueChanged<DateTime> onPicked,
    ) async {
      await pickDate(context, currentValue, (pickedDate) async {
        if (!context.mounted) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: currentValue == null
              ? const TimeOfDay(hour: 0, minute: 0)
              : TimeOfDay.fromDateTime(currentValue),
        );
        if (pickedTime == null) return;
        onPicked(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
      });
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isNarrow = screenWidth < 560;
            String toApiDateTime(DateTime date) {
              return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
            }

            InputDecoration inputDecoration({Widget? suffixIcon}) {
              return InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                suffixIcon: suffixIcon,
              );
            }

            Widget buildLabel(String text) {
              return Text(
                text,
                style: AppTextStyles.style(
                  fontSize: isNarrow ? 12 : 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4B5563),
                ),
              );
            }

            String dropdownLabel(String value) {
              return value
                  .split('_')
                  .where((part) => part.isNotEmpty)
                  .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
                  .join(' ');
            }

            Widget buildDateField({
              required DateTime? value,
              required VoidCallback onTap,
            }) {
              return TextFormField(
                readOnly: true,
                controller: TextEditingController(text: formatDate(value)),
                onTap: onTap,
                decoration: inputDecoration(
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
              );
            }

            Widget buildPair({
              required Widget left,
              required Widget right,
            }) {
              if (isNarrow) {
                return Column(
                  children: [
                    left,
                    const SizedBox(height: 8),
                    right,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 8),
                  Expanded(child: right),
                ],
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.88,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Add Followup',
                                style: AppTextStyles.style(
                                  fontSize: isNarrow ? 20 : 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close, size: 24),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                          child: Column(
                            children: [
                              buildPair(
                                left: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Followup Type'),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<String>(
                                      value: followupType,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'call',
                                          child: Text('Call'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'whatsapp',
                                          child: Text('Whatsapp'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'email',
                                          child: Text('Email'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'meeting',
                                          child: Text('Meeting'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'demo',
                                          child: Text('Demo'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'video_call',
                                          child: Text('Video Call'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'site_visit',
                                          child: Text('Site Visit'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'proposal_sent',
                                          child: Text('Proposal Sent'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'quotation_sent',
                                          child: Text('Quotation Sent'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setLocalState(() => followupType = value);
                                      },
                                      selectedItemBuilder: (context) => const [
                                        'call',
                                        'whatsapp',
                                        'email',
                                        'meeting',
                                        'demo',
                                        'video_call',
                                        'site_visit',
                                        'proposal_sent',
                                        'quotation_sent',
                                      ]
                                          .map((value) => Text(dropdownLabel(value)))
                                          .toList(),
                                      decoration: inputDecoration(),
                                    ),
                                  ],
                                ),
                                right: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Outcome'),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<String>(
                                      value: outcome,
                                      items: const [
                                        DropdownMenuItem(
                                          value: '',
                                          child: Text('Select'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'interested',
                                          child: Text('Interested'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'not_interested',
                                          child: Text('Not Interested'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'callback_later',
                                          child: Text('Callback Later'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'converted',
                                          child: Text('Converted'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'no_response',
                                          child: Text('No Response'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'meeting_scheduled',
                                          child: Text('Meeting Scheduled'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'proposal_requested',
                                          child: Text('Proposal Requested'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'negotiation',
                                          child: Text('Negotiation'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'lost',
                                          child: Text('Lost'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setLocalState(() => outcome = value);
                                      },
                                      selectedItemBuilder: (context) => const [
                                        '',
                                        'interested',
                                        'not_interested',
                                        'callback_later',
                                        'converted',
                                        'no_response',
                                        'meeting_scheduled',
                                        'proposal_requested',
                                        'negotiation',
                                        'lost',
                                      ]
                                          .map(
                                            (value) => Text(
                                              value.isEmpty
                                                  ? 'Select'
                                                  : dropdownLabel(value),
                                            ),
                                          )
                                          .toList(),
                                      decoration: inputDecoration(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              buildPair(
                                left: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Followup Date'),
                                    const SizedBox(height: 4),
                                    buildDateField(
                                      value: followupDate,
                                      onTap: () => pickDateTime(
                                        context,
                                        followupDate,
                                        (picked) => setLocalState(
                                          () => followupDate = picked,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                right: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Next Followup'),
                                    const SizedBox(height: 4),
                                    buildDateField(
                                      value: nextFollowupDate,
                                      onTap: () => pickDateTime(
                                        context,
                                        nextFollowupDate,
                                        (picked) => setLocalState(
                                          () => nextFollowupDate = picked,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              buildPair(
                                left: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Lead Status'),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<String>(
                                      value: leadStatus,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'no_change',
                                          child: Text('No Change'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'new',
                                          child: Text('New'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'attempted_contact',
                                          child: Text('Attempted Contact'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'contacted',
                                          child: Text('Contacted'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'qualified',
                                          child: Text('Qualified'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'demo_scheduled',
                                          child: Text('Demo Scheduled'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'proposal_sent',
                                          child: Text('Proposal Sent'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'negotiation',
                                          child: Text('Negotiation'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'converted',
                                          child: Text('Converted'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'lost',
                                          child: Text('Lost'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'junk',
                                          child: Text('Junk'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setLocalState(() => leadStatus = value);
                                      },
                                      decoration: inputDecoration(),
                                    ),
                                  ],
                                ),
                                right: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildLabel('Reminder Type'),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<String>(
                                      value: reminderType,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Dashboard',
                                          child: Text('Dashboard'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Email',
                                          child: Text('Email'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'WhatsApp',
                                          child: Text('WhatsApp'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setLocalState(() => reminderType = value);
                                      },
                                      decoration: inputDecoration(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: createReminder,
                                      onChanged: (value) => setLocalState(
                                        () => createReminder = value ?? false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Create Reminder',
                                    style: AppTextStyles.style(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF4B5563),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: buildLabel('Discussion Notes'),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: notesController,
                                minLines: isNarrow ? 3 : 4,
                                maxLines: isNarrow ? 3 : 4,
                                decoration: inputDecoration(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B7280),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(80, 38),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.style(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      debugPrint(
                                        '[followup] Save tapped: followupType=$followupType, outcome=$outcome',
                                      );
                                      if (followupDate == null) {
                                        debugPrint(
                                          '[followup] Validation failed: followup_date missing',
                                        );
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Followup date is required.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      if (outcome.isEmpty) {
                                        debugPrint(
                                          '[followup] Validation failed: outcome not selected',
                                        );
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please select outcome.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final normalizedLeadStatus = leadStatus
                                                  .trim()
                                                  .toLowerCase() ==
                                              'no_change'
                                          ? ''
                                          : _normalizeStatusForApi(leadStatus);
                                      final normalizedReminderType = createReminder
                                          ? reminderType.trim()
                                          : '';
                                      debugPrint(
                                        '[followup] Prepared payload values: followup_date=${toApiDateTime(followupDate!)}, next_followup_date=${nextFollowupDate == null ? 'null' : toApiDateTime(nextFollowupDate!)}, lead_status_after_followup=$normalizedLeadStatus, create_reminder=$createReminder, reminder_type=$normalizedReminderType',
                                      );

                                      setLocalState(() => isSubmitting = true);
                                      try {
                                        debugPrint(
                                          '[followup] API call start for leadId=${_resolveLeadSourceId(lead)} sourceType=${_buildLeadAssignSource(lead)}',
                                        );
                                        await _apiService.createLeadFollowup(
                                          sourceType: _buildLeadAssignSource(
                                            lead,
                                          ),
                                          leadId: _resolveLeadSourceId(lead),
                                          followupDate: toApiDateTime(
                                            followupDate!,
                                          ),
                                          followupType: followupType,
                                          outcome: outcome,
                                          discussionNotes: notesController.text,
                                          nextFollowupDate: nextFollowupDate == null
                                              ? null
                                              : toApiDateTime(nextFollowupDate!),
                                          leadStatusAfterFollowup:
                                              normalizedLeadStatus,
                                          createReminder: createReminder,
                                          reminderType: normalizedReminderType,
                                        );
                                        debugPrint(
                                          '[followup] API call success',
                                        );
                                        if (!mounted) return;
                                        Navigator.of(dialogContext).pop();
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Followup saved successfully.',
                                            ),
                                          ),
                                        );
                                        await context
                                            .read<LeadDetailProvider>()
                                            .loadLead(forceRefresh: true);
                                      } catch (_) {
                                        debugPrint(
                                          '[followup] API call failed',
                                        );
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to save followup. Please try again.',
                                            ),
                                          ),
                                        );
                                        setLocalState(() => isSubmitting = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(118, 38),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(
                                isSubmitting
                                    ? 'Saving...'
                                    : 'Save Followup',
                                style: AppTextStyles.style(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
        _statusLabel(status),
        style: AppTextStyles.style(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF15803D),
        ),
      ),
    );
  }

  String _statusLabel(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onAddFollowup,
    required this.onUpdateStatus,
  });

  final VoidCallback onAddFollowup;
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
            onTap: onAddFollowup,
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
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
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
              const Icon(
                Icons.info_outline,
                size: 20,
                color: Color(0xFF64748B),
              ),
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
                    _InfoItem(
                      label: 'CREATED DATE',
                      value: _formatDate(lead.createdAt),
                    ),
                    const SizedBox(height: 16),
                    _InfoItem(
                      label: 'CONVERTED AT',
                      value: _formatDate(lead.convertedAt),
                    ),
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
                    _InfoItem(
                      label: 'PREVIOUS STATUS',
                      value: lead.previousStatus ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _InfoItem(
                      label: 'LOST REASON',
                      value: lead.lostReason ?? '-',
                    ),
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
            items: [
              lead.displayStatus,
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {},
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 16),
          _InputFieldLabel(label: 'Conversion Value'),
          const SizedBox(height: 8),
          TextFormField(decoration: _inputDecoration(hint: 'Optional')),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
      tabAlignment: TabAlignment.start,
      labelColor: const Color(0xFF3F51B5),
      unselectedLabelColor: const Color(0xFF64748B),
      indicatorColor: const Color(0xFF3F51B5),
      labelStyle: AppTextStyles.style(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: AppTextStyles.style(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      tabs: const [
        Tab(text: 'Timeline'),
        Tab(text: 'Followups'),
        Tab(text: 'Notes'),
        Tab(text: 'Reminders'),
        Tab(text: 'Assignments'),
        Tab(text: 'Status History'),
      ],
    );
  }
}

class _LeadTabContent extends StatelessWidget {
  const _LeadTabContent({
    required this.tabIndex,
    required this.timelineItems,
    required this.followupItems,
    required this.isTimelineLoading,
    required this.isFollowupsLoading,
    required this.onAddNote,
    required this.onAddReminder,
  });
  final int tabIndex;
  final List<Map<String, dynamic>> timelineItems;
  final List<Map<String, dynamic>> followupItems;
  final bool isTimelineLoading;
  final bool isFollowupsLoading;
  final Future<void> Function(String note, bool isPrivate) onAddNote;
  final Future<void> Function(String remindAt, String reminderType)
  onAddReminder;

  @override
  Widget build(BuildContext context) {
    switch (tabIndex) {
      case 0:
        return _TimelineList(items: timelineItems, isLoading: isTimelineLoading);
      case 1:
        return _FollowupList(items: followupItems, isLoading: isFollowupsLoading);
      case 2:
        return _NotesSection(onAddNote: onAddNote);
      case 3:
        return _ReminderSection(onAddReminder: onAddReminder);
      case 4:
        return _AssignmentList();
      case 5:
      default:
        return _StatusHistoryList();
    }
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.items, required this.isLoading});
  final List<Map<String, dynamic>> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ));
    }
    final timelineItems = items
        .map(
          (item) => _TimelineItemData(
            title: (item['title'] ??
                    item['event'] ??
                    item['type'] ??
                    item['action'] ??
                    'Activity')
                .toString(),
            description: (item['description'] ??
                    item['message'] ??
                    item['notes'] ??
                    item['details'] ??
                    '-')
                .toString(),
            time: (item['created_at'] ??
                    item['date'] ??
                    item['time'] ??
                    item['updated_at'] ??
                    '-')
                .toString(),
          ),
        )
        .toList(growable: false);

    if (timelineItems.isEmpty) {
      return const _SimpleInfoCard(
        title: 'No Timeline Found',
        subtitle: '',
        description: 'No activity available for this lead.',
      );
    }

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
  });
  final String title;
  final String description;
  final String time;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.data});
  final _TimelineItemData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: AppTextStyles.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  style: AppTextStyles.style(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            data.time,
            style: AppTextStyles.style(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowupList extends StatelessWidget {
  const _FollowupList({required this.items, required this.isLoading});
  final List<Map<String, dynamic>> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ));
    }
    if (items.isEmpty) {
      return const _SimpleInfoCard(
        title: 'No Followups Found',
        subtitle: '',
        description: 'No followups available for this lead.',
      );
    }
    return Column(
      children: items.map((item) {
        final type = (item['followup_type'] ?? item['type'] ?? '-').toString();
        final outcome = (item['outcome'] ?? '-').toString();
        final time = (item['followup_date'] ??
                item['created_at'] ??
                item['date'] ??
                '-')
            .toString();
        final notes = (item['discussion_notes'] ??
                item['notes'] ??
                item['description'] ??
                '-')
            .toString();
        return _SimpleInfoCard(
          title: type,
          subtitle: '$time | Outcome: $outcome',
          description: notes,
        );
      }).toList(growable: false),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.onAddNote});
  final Future<void> Function(String note, bool isPrivate) onAddNote;

  @override
  Widget build(BuildContext context) {
    final noteController = TextEditingController();
    bool isPrivate = false;
    return Column(
      children: [
        StatefulBuilder(
          builder: (context, setLocalState) => Column(
            children: [
              TextField(
                controller: noteController,
                minLines: 3,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add note',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: isPrivate,
                      onChanged: (value) =>
                          setLocalState(() => isPrivate = value ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Private',
                    style: AppTextStyles.style(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      final note = noteController.text.trim();
                      if (note.isEmpty) return;
                      await onAddNote(note, isPrivate);
                      if (!context.mounted) return;
                      noteController.clear();
                      setLocalState(() => isPrivate = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Note added successfully.')),
                      );
                    },
                    child: const Text('Add Note'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReminderSection extends StatelessWidget {
  const _ReminderSection({required this.onAddReminder});
  final Future<void> Function(String remindAt, String reminderType)
  onAddReminder;

  @override
  Widget build(BuildContext context) {
    DateTime? remindAt;
    String reminderType = 'dashboard';

    Future<void> pickReminderDateTime(
      BuildContext context,
      ValueChanged<DateTime> onPicked,
    ) async {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (time == null) return;
      onPicked(
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      );
    }

    return Column(
      children: [
        StatefulBuilder(
          builder: (context, setLocalState) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: remindAt == null
                            ? 'dd-mm-yyyy --:--'
                            : DateFormat(
                                'dd-MM-yyyy hh:mm a',
                              ).format(remindAt!),
                      ),
                      onTap: () => pickReminderDateTime(
                        context,
                        (picked) => setLocalState(() => remindAt = picked),
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: reminderType,
                      items: const [
                        DropdownMenuItem(
                          value: 'dashboard',
                          child: Text('Dashboard'),
                        ),
                        DropdownMenuItem(value: 'email', child: Text('Email')),
                        DropdownMenuItem(
                          value: 'whatsapp',
                          child: Text('WhatsApp'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setLocalState(() => reminderType = value);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (remindAt == null) return;
                    await onAddReminder(
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(remindAt!),
                      reminderType,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reminder added successfully.'),
                      ),
                    );
                  },
                  child: const Text('Add Reminder'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssignmentList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SimpleInfoCard(
          title: 'Saurabh Damale',
          subtitle: 'Assigned at: 27 May 2026 05:45 PM',
          description: 'Bulk assignment',
        ),
        _SimpleInfoCard(
          title: 'Saurabh Damale',
          subtitle: 'Assigned at: 26 May 2026 05:58 PM',
          description: '-',
        ),
      ],
    );
  }
}

class _StatusHistoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SimpleInfoCard(
          title: 'converted -> new',
          subtitle: '29 May 2026 03:10 PM',
          description: 'Updated via followup',
        ),
        _SimpleInfoCard(
          title: 'converted -> converted',
          subtitle: '28 May 2026 03:58 PM',
          description: '-',
        ),
        _SimpleInfoCard(
          title: 'new -> won',
          subtitle: '28 May 2026 02:56 PM',
          description: '-',
        ),
      ],
    );
  }
}

class _SimpleInfoCard extends StatelessWidget {
  const _SimpleInfoCard({
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final String title;
  final String subtitle;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.style(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.style(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF334155),
              ),
            ),
          ],
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
