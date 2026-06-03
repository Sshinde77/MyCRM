import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../core/constants/app_text_styles.dart';
import '../core/utils/app_error_handler.dart';
import '../models/lead_model.dart';
import '../models/staff_member_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_card.dart';
import '../widgets/common_screen_app_bar.dart';
import '../widgets/skeletons/app_skeletons.dart';

class AllLeadsScreen extends StatefulWidget {
  const AllLeadsScreen({super.key});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen> {
  static const List<String> _fixedStatusOptions = <String>[
    'all',
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

  static const List<_SourceOption> _fixedSourceOptions = <_SourceOption>[
    _SourceOption(label: 'All', iconData: Icons.apps_rounded),
    _SourceOption(label: 'Leads', iconData: Icons.leaderboard_outlined),
    _SourceOption(
      label: 'Digital Marketing',
      iconData: Icons.campaign_outlined,
    ),
    _SourceOption(label: 'Web App', iconData: Icons.language_outlined),
    _SourceOption(
      label: 'Meta',
      iconData: FontAwesomeIcons.meta,
      useFaIcon: true,
    ),
    _SourceOption(
      label: 'Google',
      iconData: FontAwesomeIcons.google,
      useFaIcon: true,
    ),
    _SourceOption(label: 'IndiaMart', iconData: Icons.storefront_outlined),
    _SourceOption(label: 'JustDial', iconData: Icons.phone_in_talk_outlined),
  ];

  final ApiService _apiService = ApiService.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<LeadModel> _items = const <LeadModel>[];
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _perPage = 10;

  String _appliedSearch = '';
  String _selectedStatus = '';
  String _selectedSource = '';
  final Set<String> _selectedLeadKeys = <String>{};
  bool _isBulkSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLeads({int page = 1, String? search}) async {
    final normalizedSearch = (search ?? _appliedSearch).trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getLeadsListPage(
        page: page,
        perPage: _perPage,
        search: normalizedSearch,
        status: _selectedStatus,
      );

      if (!mounted) return;
      setState(() {
        _items = result.items;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage < 1 ? 1 : result.lastPage;
        _total = result.total;
        _perPage = result.perPage > 0 ? result.perPage : _perPage;
        _appliedSearch = normalizedSearch;
        _selectedLeadKeys.removeWhere(
          (key) => !_items.any((lead) => _leadSelectionKey(lead) == key),
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load leads.';
      });
    }
  }

  Future<void> _deleteLead(LeadModel lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete lead?'),
          content: Text('Delete lead ${lead.displayName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteLead(lead.id.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead deleted successfully.')),
      );
      await _loadLeads(page: _currentPage, search: _appliedSearch);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorHandler.messageFromError(
              error,
              fallback: 'Failed to delete lead.',
            ),
          ),
        ),
      );
    }
  }

  List<LeadModel> _visibleItems() {
    if (_selectedSource.isEmpty) return _items;
    return _items
        .where(
          (lead) =>
              _normalizeSourceLabel((lead.source ?? '').trim()) ==
              _selectedSource,
        )
        .toList(growable: false);
  }

  String _leadSelectionKey(LeadModel lead) {
    return '${_buildLeadAssignSource(lead)}::${_resolveLeadSourceId(lead)}';
  }

  bool _isLeadSelected(LeadModel lead) =>
      _selectedLeadKeys.contains(_leadSelectionKey(lead));

  void _toggleLeadSelection(LeadModel lead, bool selected) {
    final key = _leadSelectionKey(lead);
    setState(() {
      if (selected) {
        _selectedLeadKeys.add(key);
      } else {
        _selectedLeadKeys.remove(key);
      }
    });
  }

  List<Map<String, dynamic>> _selectedLeadPayload() {
    final selected = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final key in _selectedLeadKeys) {
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);
      final separatorIndex = key.indexOf('::');
      if (separatorIndex <= 0 || separatorIndex >= key.length - 2) {
        continue;
      }
      final sourceType = key.substring(0, separatorIndex).trim();
      final leadId = key.substring(separatorIndex + 2).trim();
      if (sourceType.isEmpty || leadId.isEmpty) {
        continue;
      }
      selected.add(<String, dynamic>{
        'source_type': sourceType,
        'source_id': leadId,
        'id': leadId,
      });
    }
    return selected;
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

  Future<void> _showAssignDialog({
    required List<Map<String, dynamic>> selectedLeads,
    String? singleLeadId,
    String? singleLeadSourceType,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final noteController = TextEditingController();
    final selectedStaffIds = <String>{};
    bool submitting = false;

    List<StaffMemberModel> staffList = const <StaffMemberModel>[];
    try {
      staffList = await _apiService.getStaffList(forceRefresh: true);
    } catch (_) {}

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> submitAssign() async {
              if (submitting) return;
              if (selectedStaffIds.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Please select at least one staff member.'),
                  ),
                );
                return;
              }
              setLocalState(() => submitting = true);
              try {
                debugPrint(
                  '[AllLeads.submitAssign] singleLeadId=$singleLeadId sourceType=${singleLeadSourceType ?? 'lead'} selectedStaffIds=${selectedStaffIds.toList()} selectedLeadsCount=${selectedLeads.length}',
                );
                if (singleLeadId != null) {
                  await _apiService.assignLead(
                    sourceType: singleLeadSourceType ?? 'lead',
                    leadId: singleLeadId,
                    assignedUserIds: selectedStaffIds.toList(growable: false),
                    assignmentNote: noteController.text,
                  );
                } else {
                  await _apiService.bulkAssignLeads(
                    assignedUserIds: selectedStaffIds.toList(growable: false),
                    selectedLeads: selectedLeads,
                  );
                }
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      singleLeadId != null
                          ? 'Lead assigned successfully.'
                          : 'Selected leads assigned successfully.',
                    ),
                  ),
                );
                setState(() => _selectedLeadKeys.clear());
                setState(() => _isBulkSelectionMode = false);
                await _loadLeads(page: _currentPage, search: _appliedSearch);
              } catch (_) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Failed to assign lead(s). Please try again.',
                    ),
                  ),
                );
                setLocalState(() => submitting = false);
              }
            }

            return AlertDialog(
              scrollable: true,
              title: Text(
                singleLeadId != null ? 'Assign Lead' : 'Bulk Assign Leads',
              ),
              content: SizedBox(
                width: 420,
                child: staffList.isEmpty
                    ? const Text('No staff members found.')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Staff'),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: staffList
                                    .map((staff) {
                                      final checked = selectedStaffIds.contains(
                                        staff.id,
                                      );
                                      return CheckboxListTile(
                                        dense: true,
                                        value: checked,
                                        title: Text(
                                          staff.name.isEmpty
                                              ? staff.email
                                              : staff.name,
                                        ),
                                        subtitle: staff.email.isEmpty
                                            ? null
                                            : Text(staff.email),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        onChanged: (value) {
                                          setLocalState(() {
                                            if (value == true) {
                                              selectedStaffIds.add(staff.id);
                                            } else {
                                              selectedStaffIds.remove(staff.id);
                                            }
                                          });
                                        },
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                          if (singleLeadId != null) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: noteController,
                              minLines: 2,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Assignment Note (optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting || staffList.isEmpty
                      ? null
                      : submitAssign,
                  child: Text(submitting ? 'Assigning...' : 'Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openAssignSingleLead(LeadModel lead) async {
    await _showAssignDialog(
      selectedLeads: const <Map<String, dynamic>>[],
      singleLeadId: _resolveLeadSourceId(lead),
      singleLeadSourceType: _buildLeadAssignSource(lead),
    );
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
                await _loadLeads(page: _currentPage, search: _appliedSearch);
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

  Future<void> _openBulkAssign() async {
    if (!_isBulkSelectionMode) {
      setState(() {
        _isBulkSelectionMode = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selection mode enabled. Select leads, then tap Bulk Assign again.',
          ),
        ),
      );
      return;
    }

    final selectedLeads = _selectedLeadPayload();
    if (selectedLeads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one lead for bulk assign.'),
        ),
      );
      return;
    }
    await _showAssignDialog(selectedLeads: selectedLeads);
  }

  String _normalizeStatusForApi(String status) {
    return status.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _statusLabel(String status) {
    final normalized = _normalizeStatusForApi(status);
    if (normalized == 'all') {
      return 'All';
    }
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

  String _normalizeSourceLabel(String source) {
    final normalized = source.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    switch (normalized) {
      case 'lead':
      case 'leads':
        return 'Leads';
      case 'digitalmarketing':
        return 'Digital Marketing';
      case 'webapp':
      case 'webapps':
      case 'webapplication':
        return 'Web App';
      case 'meta':
      case 'facebook':
        return 'Meta';
      case 'google':
      case 'googleads':
        return 'Google';
      case 'indiamart':
        return 'IndiaMart';
      case 'justdial':
        return 'JustDial';
      default:
        return source;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = _fixedStatusOptions;
    final sourceOptions = _fixedSourceOptions;
    final visibleItems = _visibleItems();
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 420;
    final isVeryNarrow = screenWidth <= 380;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadLeads(page: _currentPage),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            children: [
              const CommonTopBar(
                title: 'Lead Management',
                showBackButton: false,
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusDropdown(
                              statusOptions,
                              isCompact: isNarrow,
                            ),
                          ),
                          SizedBox(width: isNarrow ? 6 : 8),
                          Expanded(
                            child: _buildSourceDropdown(
                              sourceOptions,
                              isCompact: isNarrow,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isNarrow ? 6 : 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSearchField(isCompact: isNarrow),
                          ),
                          SizedBox(width: isNarrow ? 6 : 8),
                          _buildGoButton(isCompact: isNarrow),
                          SizedBox(width: isNarrow ? 6 : 8),
                          _buildBulkAssignButton(isCompact: isNarrow),
                          SizedBox(width: isNarrow ? 6 : 8),
                          _buildAddLeadButton(
                            compact: true,
                            isCompact: isNarrow,
                            iconOnly: isVeryNarrow,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: ScreenSkeleton(),
                        )
                      else if (_error != null)
                        _ErrorBox(
                          message: _error!,
                          onRetry: () => _loadLeads(page: 1),
                        )
                      else
                        _buildLeadCards(visibleItems),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _Pagination(
                          currentPage: _currentPage,
                          lastPage: _lastPage,
                          onPageTap: (page) => _loadLeads(page: page),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.leads,
      ),
    );
  }

  Widget _buildLeadCards(List<LeadModel> leads) {
    if (leads.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'No leads found.',
          style: AppTextStyles.style(
            color: const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: List<Widget>.generate(leads.length, (index) {
        final lead = leads[index];
        final serialNumber = ((_currentPage - 1) * _perPage) + index + 1;

        return Padding(
          padding: EdgeInsets.only(bottom: index == leads.length - 1 ? 0 : 10),
          child: GestureDetector(
            onLongPress: () {
              setState(() {
                _isBulkSelectionMode = true;
              });
              _toggleLeadSelection(lead, true);
            },
            onTap: _isBulkSelectionMode
                ? () => _toggleLeadSelection(lead, !_isLeadSelected(lead))
                : null,
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isBulkSelectionMode)
                        Checkbox(
                          value: _isLeadSelected(lead),
                          onChanged: (value) =>
                              _toggleLeadSelection(lead, value ?? false),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final veryCompact = constraints.maxWidth < 220;
                                final compact = constraints.maxWidth < 280;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '#$serialNumber ${lead.displayName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.style(
                                          color: const Color(0xFF0F172A),
                                          fontSize: veryCompact ? 12 : 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: veryCompact ? 4 : 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: veryCompact ? 72 : 96,
                                          ),
                                          child: _TypeBadge(
                                            type: lead.displaySourceType,
                                            compact: compact,
                                            veryCompact: veryCompact,
                                          ),
                                        ),
                                        SizedBox(width: veryCompact ? 4 : 6),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: veryCompact ? 84 : 112,
                                          ),
                                          child: _StatusBadge(
                                            status: lead.displayStatus,
                                            compact: compact,
                                            veryCompact: veryCompact,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lead.displayCompany == '-'
                        ? 'Unknown Client'
                        : lead.displayCompany,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      _buildLeadFieldRow(
                        left: _LeadApiField(
                          label: 'source_id',
                          value: lead.displaySourceId,
                        ),
                        right: _LeadApiField(
                          label: 'email',
                          value: lead.displayEmail,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildLeadFieldRow(
                        left: _LeadApiField(
                          label: 'number',
                          value: lead.displayPhone,
                        ),
                        right: _LeadApiField(
                          label: 'source',
                          value: lead.displaySource,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _LeadApiField(
                        label: 'assigned_to',
                        value: lead.displayAssignedTo,
                        trailing: _LeadActions(
                          leadId: _resolveLeadSourceId(lead),
                          sourceType: _buildLeadAssignSource(lead),
                          sourceId: _resolveLeadSourceId(lead),
                          onAssign: () => _openAssignSingleLead(lead),
                          onEditStatus: () => _openStatusUpdateDialog(lead),
                          onDelete: () => _deleteLead(lead),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLeadFieldRow({required Widget left, required Widget right}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildStatusDropdown(
    List<String> statusOptions, {
    bool isCompact = false,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedStatus.isEmpty ? null : _selectedStatus,
      decoration: InputDecoration(
        hintText: 'All Statuses',
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 10,
          vertical: isCompact ? 6 : 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
      style: AppTextStyles.style(
        color: const Color(0xFF334155),
        fontSize: isCompact ? 11 : 12,
        fontWeight: FontWeight.w600,
      ),
      items: statusOptions
          .map(
            (status) => DropdownMenuItem<String>(
              value: status,
              child: Text(_statusLabel(status)),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() => _selectedStatus = value == 'all' ? '' : value ?? '');
        _loadLeads(page: 1, search: _appliedSearch);
      },
    );
  }

  Widget _buildSourceDropdown(
    List<_SourceOption> sourceOptions, {
    bool isCompact = false,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedSource.isEmpty ? null : _selectedSource,
      decoration: InputDecoration(
        hintText: 'All Sources',
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 10,
          vertical: isCompact ? 6 : 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
      style: AppTextStyles.style(
        color: const Color(0xFF334155),
        fontSize: isCompact ? 11 : 12,
        fontWeight: FontWeight.w600,
      ),
      items: sourceOptions
          .map(
            (source) => DropdownMenuItem<String>(
              value: source.label == 'All' ? '' : source.label,
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(
                      size: isCompact ? 14 : 16,
                      color: const Color(0xFF334155),
                    ),
                    child: source.buildIcon(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(source.label)),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() => _selectedSource = value ?? '');
      },
    );
  }

  Widget _buildSearchField({bool isCompact = false}) {
    return TextField(
      controller: _searchController,
      onSubmitted: (_) => _loadLeads(page: 1, search: _searchController.text),
      decoration: InputDecoration(
        hintText: 'Search',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 10,
          vertical: isCompact ? 8 : 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
    );
  }

  Widget _buildAddLeadButton({
    bool compact = false,
    bool isCompact = false,
    bool iconOnly = false,
  }) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1D7CE8),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : (compact ? 12 : 14),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    return SizedBox(
      height: isCompact ? 34 : 38,
      width: iconOnly ? (isCompact ? 36 : 40) : null,
      child: iconOnly
          ? ElevatedButton(
              onPressed: () => Get.toNamed(AppRoutes.addLead),
              style: buttonStyle,
              child: Icon(Icons.add, size: isCompact ? 14 : 16),
            )
          : ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.addLead),
              icon: Icon(Icons.add, size: isCompact ? 14 : 16),
              label: Text(
                compact ? 'Add Lead' : 'Add New Lead',
                style: AppTextStyles.style(
                  color: Colors.white,
                  fontSize: isCompact ? 12 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: buttonStyle,
            ),
    );
  }

  Widget _buildGoButton({bool isCompact = false}) {
    return SizedBox(
      height: isCompact ? 34 : 38,
      child: ElevatedButton(
        onPressed: () => _loadLeads(page: 1, search: _searchController.text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D7CE8),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Go',
          style: AppTextStyles.style(
            color: Colors.white,
            fontSize: isCompact ? 13 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBulkAssignButton({bool isCompact = false}) {
    final hasSelectedVisibleLeads = _selectedLeadPayload().isNotEmpty;
    return SizedBox(
      height: isCompact ? 34 : 38,
      child: OutlinedButton.icon(
        onPressed: _openBulkAssign,
        icon: Icon(Icons.group_add_outlined, size: isCompact ? 14 : 16),
        label: Text(
          _isBulkSelectionMode
              ? (hasSelectedVisibleLeads
                    ? 'Bulk Assign (${_selectedLeadKeys.length})'
                    : 'Select Leads')
              : 'Bulk Assign',
          style: AppTextStyles.style(
            fontSize: isCompact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D4ED8),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF93C5FD)),
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _SourceOption {
  const _SourceOption({
    required this.label,
    required this.iconData,
    this.useFaIcon = false,
  });

  final String label;
  final Object iconData;
  final bool useFaIcon;

  Widget buildIcon() {
    if (useFaIcon && iconData is FaIconData) {
      return FaIcon(iconData as FaIconData);
    }
    if (iconData is IconData) {
      return Icon(iconData as IconData);
    }
    return const Icon(Icons.help_outline);
  }
}

class _LeadApiField extends StatelessWidget {
  const _LeadApiField({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$label: ',
              style: AppTextStyles.style(
                color: const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.style(
                    color: const Color(0xFF334155),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    this.compact = false,
    this.veryCompact = false,
  });

  final String status;
  final bool compact;
  final bool veryCompact;

  @override
  Widget build(BuildContext context) {
    final displayStatus = _statusLabel(status);
    final isCompact = compact || displayStatus.length > 12;
    final isVeryCompact = veryCompact || displayStatus.length > 18;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVeryCompact ? 4 : (isCompact ? 6 : 8),
        vertical: isVeryCompact ? 2 : (isCompact ? 3 : 4),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        displayStatus,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.style(
          color: const Color(0xFF2563EB),
          fontSize: isVeryCompact ? 10 : (isCompact ? 11 : 12),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _statusLabel(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.type,
    this.compact = false,
    this.veryCompact = false,
  });

  final String type;
  final bool compact;
  final bool veryCompact;

  @override
  Widget build(BuildContext context) {
    final isCompact = compact || type.length > 12;
    final isVeryCompact = veryCompact || type.length > 18;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVeryCompact ? 4 : (isCompact ? 6 : 8),
        vertical: isVeryCompact ? 2 : (isCompact ? 3 : 4),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.style(
          color: const Color(0xFF334155),
          fontSize: isVeryCompact ? 9 : (isCompact ? 10 : 11),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LeadActions extends StatelessWidget {
  const _LeadActions({
    required this.leadId,
    required this.sourceType,
    required this.sourceId,
    required this.onAssign,
    required this.onEditStatus,
    required this.onDelete,
  });

  final String leadId;
  final String sourceType;
  final String sourceId;
  final VoidCallback onAssign;
  final VoidCallback onEditStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Get.toNamed(
            AppRoutes.leadManagementDetail,
            arguments: <String, dynamic>{
              'leadId': leadId,
              'sourceType': sourceType,
              'sourceId': sourceId,
              'source_id': sourceId,
            },
          ),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.remove_red_eye_outlined,
              size: 16,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ActionIconButton(
          icon: Icons.person_add_alt_1_outlined,
          color: Color(0xFFF59E0B),
          onTap: onAssign,
        ),
        const SizedBox(width: 8),
        _ActionIconButton(
          icon: Icons.edit_outlined,
          color: Color(0xFF0EA5E9),
          onTap: onEditStatus,
        ),
        const SizedBox(width: 8),
        _ActionIconButton(
          icon: Icons.delete_outline,
          color: Color(0xFFEF4444),
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.onPageTap,
  });

  final int currentPage;
  final int lastPage;
  final ValueChanged<int> onPageTap;

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: currentPage > 1 ? () => onPageTap(currentPage - 1) : null,
          child: const Text('Prev'),
        ),
        TextButton(
          onPressed: currentPage < lastPage
              ? () => onPageTap(currentPage + 1)
              : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTextStyles.style(
              color: const Color(0xFF9A3412),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
