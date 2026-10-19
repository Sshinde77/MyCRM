import '../models/lead_flow.dart';
import '../widgets/lead_activity_dialog.dart';
import '../core/services/in_app_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:url_launcher/url_launcher.dart';

class AllLeadsScreen extends StatefulWidget {
  const AllLeadsScreen({super.key});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen> {
  Map<String, String> _statusOptions = {
    for (final s in LeadFlow.statuses) s: LeadFlow.label(s),
  };
  Map<String, String> _sources = {
    for (final s in LeadFlow.sources) s: LeadFlow.label(s),
  };
  Map<String, dynamic> _tabCounts = {};
  List<StaffMemberModel> _staff = [];
  int _requestVersion = 0;
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<LeadModel> _items = const <LeadModel>[];
  final Map<String, LeadModel> _priorityDetails = {};
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
    final version = ++_requestVersion;
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
        source: _selectedSource,
      );

      if (!mounted || version != _requestVersion) return;
      setState(() {
        _items = result.items;
        _priorityDetails.clear();
        if (result.statusOptions.isNotEmpty)
          _statusOptions = result.statusOptions;
        if (result.sources.isNotEmpty) _sources = result.sources;
        _tabCounts = result.tabCounts;
        _staff = result.staff.map(StaffMemberModel.fromJson).toList();
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
      _hydrateMissingPriorities(_items, version);
    } catch (error) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _isLoading = false;
        _error = AppErrorHandler.messageFromError(error);
      });
    }
  }

  Future<void> _hydrateMissingPriorities(
    List<LeadModel> leads,
    int version,
  ) async {
    // Imported profiles can report a default priority that differs from their
    // pipeline. Verify them even when the list already supplied a priority.
    final missing = leads.where((lead) {
      return lead.managementSource != 'lead' ||
          (lead.priority?.trim().isEmpty ?? true);
    }).toList();

    if (missing.isEmpty) return;

    await Future.wait(
      missing.map((lead) async {
        try {
          if (!mounted || version != _requestVersion) return;
          final detail = await _apiService.getLeadManagementDetailView(
            sourceType: _buildLeadAssignSource(lead),
            sourceId: _resolveLeadSourceId(lead),
          );
          if (!mounted || version != _requestVersion) return;
          setState(() {
            _priorityDetails[_leadSelectionKey(lead)] = detail;
          });
        } catch (error) {
          debugPrint('Unable to verify lead priority: $error');
        }
      }),
    );
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
      await _apiService.deleteManagedLead(
        source: lead.managementSource,
        id: lead.managementId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead deleted successfully.')),
      );
      await _loadLeads(page: _currentPage, search: _appliedSearch);
      InAppNotifications.instance.refresh();
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

  Future<void> _callLead(String phoneNumber) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    if (normalizedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available.')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: normalizedPhone);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the dialer.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the dialer.')),
      );
    }
  }

  Future<void> _copyLeadPhone(String phoneNumber) async {
    final normalizedPhone = phoneNumber.trim();
    if (normalizedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available.')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: normalizedPhone));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied to clipboard.')),
    );
  }

  List<LeadModel> _visibleItems() => _items;

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

  String _buildLeadAssignSource(LeadModel lead) => lead.managementSource;
  String _resolveLeadSourceId(LeadModel lead) => lead.managementId;

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
      staffList = _staff.isNotEmpty
          ? _staff
          : await _apiService.getStaffList(forceRefresh: true);
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
                InAppNotifications.instance.refresh();
              } catch (error) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(AppErrorHandler.messageFromError(error)),
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
                width: MediaQuery.of(context).size.width < 456
                    ? MediaQuery.of(context).size.width - 32
                    : 420,
                child: staffList.isEmpty
                    ? const Text('No staff members found.')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select staff to add to the assigned team. Existing assignments remain.',
                          ),
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
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeadActivityDialog(
        lead: lead,
        conversation: false,
        statusOptions: _statusOptions,
      ),
    );
    if (saved == true && mounted) {
      await _loadLeads(page: _currentPage);
      InAppNotifications.instance.refresh();
    }
  }

  Future<void> _openPriorityDialog(LeadModel lead) async {
    String selectedPriority =
        (_priorityDetails[_leadSelectionKey(lead)] ?? lead).displayPriority;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Change Priority',
                style: AppTextStyles.style(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: LeadFlow.priorities.map((p) {
                  final isSelected = selectedPriority == p;
                  return RadioListTile<String>(
                    title: Row(
                      children: [
                        if (p == 'high')
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.flag_rounded,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        Text(
                          LeadFlow.label(p),
                          style: AppTextStyles.style(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: p == 'high'
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    value: p,
                    groupValue: selectedPriority,
                    activeColor: p == 'high'
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF1D6FEA),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedPriority = val);
                      }
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.style(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D6FEA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await _apiService.updateLeadPriority(
                        sourceType: _buildLeadAssignSource(lead),
                        leadId: _resolveLeadSourceId(lead),
                        priority: selectedPriority,
                      );
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop(true);
                      }
                    } catch (error) {
                      if (dialogCtx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update priority: $error'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved == true && mounted) {
      await _loadLeads(page: _currentPage);
      InAppNotifications.instance.refresh();
    }
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

  String _normalizePhoneNumber(String phoneNumber) {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) return '';

    final hasLeadingPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '';

    return hasLeadingPlus ? '+$digitsOnly' : digitsOnly;
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = ['all', ..._statusOptions.keys];
    final sourceOptions = [
      const _SourceOption(label: 'All', iconData: Icons.apps_rounded),
      for (final s in _sources.entries)
        _SourceOption(label: s.key, iconData: Icons.source_outlined),
    ];
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
                  final stackedActions = constraints.maxWidth < 520;
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
                      if (stackedActions)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSearchField(isCompact: isNarrow),
                            SizedBox(height: isNarrow ? 6 : 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGoButton(isCompact: isNarrow),
                                ),
                                SizedBox(width: isNarrow ? 6 : 8),
                                Expanded(
                                  child: _buildBulkAssignButton(
                                    isCompact: isNarrow,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isNarrow ? 6 : 8),
                            _buildAddLeadButton(
                              compact: true,
                              isCompact: isNarrow,
                              iconOnly: isVeryNarrow,
                            ),
                          ],
                        )
                      else
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
        // Apply the same priority styling to every management source.
        final isHighPriority =
            (_priorityDetails[_leadSelectionKey(lead)] ?? lead).isHighPriority;

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
                : () async {
                    await Get.toNamed(
                      AppRoutes.leadManagementDetail,
                      arguments: <String, dynamic>{
                        'leadId': _resolveLeadSourceId(lead),
                        'sourceType': _buildLeadAssignSource(lead),
                        'sourceId': _resolveLeadSourceId(lead),
                        'source_id': _resolveLeadSourceId(lead),
                      },
                    );
                    _loadLeads(page: _currentPage);
                  },
            child: AppCard(
              padding: const EdgeInsets.all(12),
              color: isHighPriority ? const Color(0xFFFEF2F2) : Colors.white,
              border: Border.all(
                color: isHighPriority
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE2E8F0),
                width: isHighPriority ? 1.5 : 1.0,
              ),
              boxShadow: isHighPriority
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
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
                                        if (isHighPriority) ...[
                                          _PriorityBadge(
                                            compact: compact,
                                            veryCompact: veryCompact,
                                            onTap: () =>
                                                _openPriorityDialog(lead),
                                          ),
                                          SizedBox(width: veryCompact ? 4 : 6),
                                        ],
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
                          trailing: lead.phone?.trim().isNotEmpty == true
                              ? _ActionCircleButton(
                                  icon: Icons.copy_outlined,
                                  iconColor: const Color(0xFF334155),
                                  background: const Color(0xFFE2E8F0),
                                  onTap: () =>
                                      _copyLeadPhone(lead.phone!.trim()),
                                )
                              : null,
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
                          onReturn: () => _loadLeads(page: _currentPage),
                          phoneNumber: lead.phone,
                          onCall: () => _callLead(lead.phone?.trim() ?? ''),
                          leadId: _resolveLeadSourceId(lead),
                          sourceType: _buildLeadAssignSource(lead),
                          sourceId: _resolveLeadSourceId(lead),
                          onAssign: () => _openAssignSingleLead(lead),
                          onEditStatus: () => _openStatusUpdateDialog(lead),
                          onEditPriority: () => _openPriorityDialog(lead),
                          isHighPriority: isHighPriority,
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
              child: Text(
                status == 'all'
                    ? 'All'
                    : _statusOptions[status] ?? _statusLabel(status),
              ),
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
                  Expanded(
                    child: Text(
                      source.label == 'All'
                          ? 'All'
                          : '${_sources[source.label] ?? LeadFlow.label(source.label)}${_tabCounts[source.label] == null ? '' : ' (${_tabCounts[source.label]})'}',
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() => _selectedSource = value ?? '');
        _loadLeads(page: 1);
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
              onPressed: () async {
                await Get.toNamed(AppRoutes.addLead);
                if (mounted) {
                  await _loadLeads(page: 1);
                  InAppNotifications.instance.refresh();
                }
              },
              style: buttonStyle,
              child: Icon(Icons.add, size: isCompact ? 14 : 16),
            )
          : ElevatedButton.icon(
              onPressed: () async {
                await Get.toNamed(AppRoutes.addLead);
                if (mounted) {
                  await _loadLeads(page: 1);
                  InAppNotifications.instance.refresh();
                }
              },
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
    required this.phoneNumber,
    required this.onCall,
    required this.leadId,
    required this.sourceType,
    required this.sourceId,
    required this.onAssign,
    required this.onEditStatus,
    required this.onDelete,
    this.onEditPriority,
    this.isHighPriority = false,
    this.onReturn,
  });

  final String? phoneNumber;
  final VoidCallback onCall;
  final String leadId;
  final String sourceType;
  final String sourceId;
  final VoidCallback onAssign;
  final VoidCallback onEditStatus;
  final VoidCallback onDelete;
  final VoidCallback? onEditPriority;
  final bool isHighPriority;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final hasPhoneNumber = phoneNumber?.trim().isNotEmpty == true;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPhoneNumber) ...[
          _ActionIconButton(
            icon: Icons.phone_outlined,
            color: const Color(0xFF16A34A),
            onTap: onCall,
          ),
          const SizedBox(width: 8),
        ],
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            await Get.toNamed(
              AppRoutes.leadManagementDetail,
              arguments: <String, dynamic>{
                'leadId': leadId,
                'sourceType': sourceType,
                'sourceId': sourceId,
                'source_id': sourceId,
              },
            );
            onReturn?.call();
          },
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
        if (onEditPriority != null) ...[
          _ActionIconButton(
            icon: isHighPriority ? Icons.flag_rounded : Icons.flag_outlined,
            color: isHighPriority
                ? const Color(0xFFDC2626)
                : const Color(0xFFD97706),
            onTap: onEditPriority!,
          ),
          const SizedBox(width: 8),
        ],
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

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({
    this.compact = false,
    this.veryCompact = false,
    this.onTap,
  });

  final bool compact;
  final bool veryCompact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: veryCompact ? 5 : (compact ? 6 : 8),
          vertical: veryCompact ? 2 : (compact ? 3 : 4),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_rounded, size: 11, color: Color(0xFFDC2626)),
            if (!veryCompact) ...[
              const SizedBox(width: 3),
              Text(
                'HIGH',
                maxLines: 1,
                style: AppTextStyles.style(
                  color: const Color(0xFFDC2626),
                  fontSize: veryCompact ? 9 : (compact ? 9.5 : 10.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
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
