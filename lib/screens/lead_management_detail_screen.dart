import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/lead_flow.dart';
import '../widgets/lead_activity_dialog.dart';
import '../core/services/in_app_notifications.dart';
import '../core/utils/app_error_handler.dart';
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
  final ApiService _apiService = ApiService.instance;
  late TabController _tabController;
  int _selectedLeadTab = 0;
  List<Map<String, dynamic>> _timelineItems = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _followupItems = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _noteItems = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reminderItems = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _assignmentItems = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _statusHistoryItems =
      const <Map<String, dynamic>>[];
  bool _isTimelineLoading = false;
  bool _isFollowupsLoading = false;
  bool _isNotesLoading = false;
  bool _isRemindersLoading = false;
  bool _isAssignmentsLoading = false;
  bool _isStatusHistoryLoading = false;
  String _loadedTimelineKey = '';
  String _loadedFollowupsKey = '';
  String _loadedNotesKey = '';
  String _loadedRemindersKey = '';
  String _loadedAssignmentsKey = '';
  String _loadedStatusHistoryKey = '';
  final Map<int, String> _tabErrors = {};
  int _dataRevision = 0;
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
    if (!mounted || _activeSourceType.isEmpty || _activeSourceId.isEmpty)
      return;
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
    } else if (_selectedLeadTab == 2) {
      _loadNotesByKey(sourceType: _activeSourceType, sourceId: _activeSourceId);
    } else if (_selectedLeadTab == 3) {
      _loadRemindersByKey(
        sourceType: _activeSourceType,
        sourceId: _activeSourceId,
      );
    } else if (_selectedLeadTab == 4) {
      _loadAssignmentsByKey(
        sourceType: _activeSourceType,
        sourceId: _activeSourceId,
      );
    } else if (_selectedLeadTab == 5) {
      _loadStatusHistoryByKey(
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

    final revision = _dataRevision;
    setState(() {
      _isTimelineLoading = true;
      _tabErrors.remove(0);
    });
    try {
      final results = await _apiService.getLeadTimeline(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isTimelineLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _timelineItems = results;
        _loadedTimelineKey = requestKey;
        _isTimelineLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isTimelineLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _isTimelineLoading = false;
        _tabErrors[0] = AppErrorHandler.messageFromError(error);
      });
    }
  }

  Future<void> _loadFollowupsByKey({
    required String sourceType,
    required String sourceId,
  }) async {
    final requestKey = '$sourceType::$sourceId';
    if (_isFollowupsLoading || _loadedFollowupsKey == requestKey) return;

    final revision = _dataRevision;
    setState(() {
      _isFollowupsLoading = true;
      _tabErrors.remove(1);
    });
    try {
      final results = await _apiService.getLeadFollowups(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isFollowupsLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _followupItems = results;
        _loadedFollowupsKey = requestKey;
        _isFollowupsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isFollowupsLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _isFollowupsLoading = false;
        _tabErrors[1] = AppErrorHandler.messageFromError(error);
      });
    }
  }

  Future<void> _loadNotesByKey({
    required String sourceType,
    required String sourceId,
  }) async {
    final requestKey = '$sourceType::$sourceId';
    if (_isNotesLoading || _loadedNotesKey == requestKey) return;

    final revision = _dataRevision;
    setState(() {
      _isNotesLoading = true;
      _tabErrors.remove(2);
    });
    try {
      final results = await _apiService.getLeadNotes(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isNotesLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _noteItems = results;
        _loadedNotesKey = requestKey;
        _isNotesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isNotesLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _isNotesLoading = false;
        _tabErrors[2] = AppErrorHandler.messageFromError(error);
      });
    }
  }

  Future<void> _loadRemindersByKey({
    required String sourceType,
    required String sourceId,
  }) async {
    final requestKey = '$sourceType::$sourceId';
    if (_isRemindersLoading || _loadedRemindersKey == requestKey) return;

    final revision = _dataRevision;
    setState(() {
      _isRemindersLoading = true;
      _tabErrors.remove(3);
    });
    try {
      final results = await _apiService.getLeadReminders(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isRemindersLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _reminderItems = results;
        _loadedRemindersKey = requestKey;
        _isRemindersLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isRemindersLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _isRemindersLoading = false;
        _tabErrors[3] = AppErrorHandler.messageFromError(error);
      });
    }
  }

  Future<void> _loadAssignmentsByKey({
    required String sourceType,
    required String sourceId,
  }) async {
    final requestKey = '$sourceType::$sourceId';
    if (_isAssignmentsLoading || _loadedAssignmentsKey == requestKey) return;

    final revision = _dataRevision;
    setState(() {
      _isAssignmentsLoading = true;
      _tabErrors.remove(4);
    });
    try {
      final results = await _apiService.getLeadAssignments(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isAssignmentsLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _assignmentItems = results;
        _loadedAssignmentsKey = requestKey;
        _isAssignmentsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isAssignmentsLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _isAssignmentsLoading = false;
        _tabErrors[4] = AppErrorHandler.messageFromError(error);
      });
    }
  }

  Future<void> _loadStatusHistoryByKey({
    required String sourceType,
    required String sourceId,
  }) async {
    final requestKey = '$sourceType::$sourceId';
    if (_isStatusHistoryLoading || _loadedStatusHistoryKey == requestKey) {
      return;
    }

    final revision = _dataRevision;
    setState(() {
      _isStatusHistoryLoading = true;
      _tabErrors.remove(5);
    });
    try {
      final results = await _apiService.getLeadStatusHistory(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isStatusHistoryLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _statusHistoryItems = results;
        _loadedStatusHistoryKey = requestKey;
        _isStatusHistoryLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (revision != _dataRevision) {
        setState(() => _isStatusHistoryLoading = false);
        _triggerTabLoad();
        return;
      }
      setState(() {
        _isStatusHistoryLoading = false;
        _tabErrors[5] = AppErrorHandler.messageFromError(error);
      });
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
              _loadedNotesKey = '';
              _loadedRemindersKey = '';
              _loadedAssignmentsKey = '';
              _loadedStatusHistoryKey = '';
              _timelineItems = const <Map<String, dynamic>>[];
              _followupItems = const <Map<String, dynamic>>[];
              _noteItems = const <Map<String, dynamic>>[];
              _reminderItems = const <Map<String, dynamic>>[];
              _assignmentItems = const <Map<String, dynamic>>[];
              _statusHistoryItems = const <Map<String, dynamic>>[];
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
                } else if (_selectedLeadTab == 2) {
                  _loadNotesByKey(
                    sourceType: _activeSourceType,
                    sourceId: _activeSourceId,
                  );
                } else if (_selectedLeadTab == 3) {
                  _loadRemindersByKey(
                    sourceType: _activeSourceType,
                    sourceId: _activeSourceId,
                  );
                } else if (_selectedLeadTab == 4) {
                  _loadAssignmentsByKey(
                    sourceType: _activeSourceType,
                    sourceId: _activeSourceId,
                  );
                } else if (_selectedLeadTab == 5) {
                  _loadStatusHistoryByKey(
                    sourceType: _activeSourceType,
                    sourceId: _activeSourceId,
                  );
                }
              });
            }

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: CommonTopBar(
                    title: 'Lead Profile',
                    showBackButton: true,
                    compact: true,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshAll,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderSection(
                            lead: lead,
                            onUpdatePriority: () => _openPriorityUpdateDialog(lead),
                          ),
                          const SizedBox(height: 12),
                          _ActionButtons(
                            onAddFollowup: lead.isClosed
                                ? null
                                : () => _openAddFollowupDialog(lead),
                            onUpdateStatus: () => _openStatusUpdateDialog(lead),
                            onUpdatePriority: () => _openPriorityUpdateDialog(lead),
                          ),
                          const SizedBox(height: 12),
                          _LeadInformationCard(lead: lead),
                          const SizedBox(height: 12),
                          _LeadFlowSummary(lead: lead),
                          // const SizedBox(height: 16),
                          // _UpdateStatusCard(lead: lead),
                          const SizedBox(height: 14),
                          _TimelineTabs(tabController: _tabController),
                          const SizedBox(height: 12),
                          if (_tabErrors[_selectedLeadTab] != null)
                            Column(
                              children: [
                                Text(_tabErrors[_selectedLeadTab]!),
                                TextButton(
                                  onPressed: _triggerTabLoad,
                                  child: const Text('Retry'),
                                ),
                              ],
                            )
                          else
                            _LeadTabContent(
                              tabIndex: _selectedLeadTab,
                              timelineItems: _timelineItems,
                              followupItems: _followupItems,
                              noteItems: _noteItems,
                              reminderItems: _reminderItems,
                              assignmentItems: _assignmentItems,
                              statusHistoryItems: _statusHistoryItems,
                              isTimelineLoading: _isTimelineLoading,
                              isFollowupsLoading: _isFollowupsLoading,
                              isNotesLoading: _isNotesLoading,
                              isRemindersLoading: _isRemindersLoading,
                              isAssignmentsLoading: _isAssignmentsLoading,
                              isStatusHistoryLoading: _isStatusHistoryLoading,
                              onAddNote: (note, isPrivate) async {
                                await _apiService.createLeadNote(
                                  sourceType: _buildLeadAssignSource(lead),
                                  sourceId: _resolveLeadSourceId(lead),
                                  note: note,
                                  isPrivate: isPrivate,
                                );
                                _loadedTimelineKey = '';
                                await _refreshAll();

                                if (_selectedLeadTab == 2) {
                                  await _loadNotesByKey(
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
                                await _refreshAll();
                              },
                            ),
                          const SizedBox(height: 14),
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

  String _buildLeadAssignSource(LeadModel lead) => lead.managementSource;
  String _resolveLeadSourceId(LeadModel lead) => lead.managementId;

  Future<void> _refreshAll() async {
    _dataRevision++;
    _loadedTimelineKey = '';
    _loadedFollowupsKey = '';
    _loadedNotesKey = '';
    _loadedRemindersKey = '';
    _loadedAssignmentsKey = '';
    _loadedStatusHistoryKey = '';
    await context.read<LeadDetailProvider>().loadLead(forceRefresh: true);
    if (!mounted) return;
    _triggerTabLoad();
    InAppNotifications.instance.refresh();
  }

  Future<void> _openStatusUpdateDialog(LeadModel lead) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeadActivityDialog(lead: lead, conversation: false),
    );
    if (saved == true && mounted) await _refreshAll();
  }

  Future<void> _openAddFollowupDialog(LeadModel lead) async {
    if (lead.isClosed) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeadActivityDialog(lead: lead),
    );
    if (saved == true && mounted) await _refreshAll();
  }

  Future<void> _openPriorityUpdateDialog(LeadModel lead) async {
    String selectedPriority = lead.displayPriority.toLowerCase();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Update Priority',
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
                title: Text(
                  LeadFlow.label(p),
                  style: AppTextStyles.style(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: p == 'high'
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF1E293B),
                  ),
                ),
                value: p,
                groupValue: selectedPriority,
                activeColor: const Color(0xFF3F51B5),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPriority = val);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                foregroundColor: Colors.white,
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
                  if (context.mounted) Navigator.of(dialogCtx).pop(true);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppErrorHandler.messageFromError(error))),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) await _refreshAll();
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.lead,
    this.onUpdatePriority,
  });
  final LeadModel lead;
  final VoidCallback? onUpdatePriority;

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
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onUpdatePriority,
              child: _PriorityBadge(priority: lead.displayPriority),
            ),
            const SizedBox(width: 6),
            _StatusBadge(status: lead.displayStatus),
          ],
        ),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    final normalized = priority.trim().toLowerCase();
    final Color bg;
    final Color fg;
    if (normalized == 'high') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (normalized == 'low') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            normalized.toUpperCase(),
            style: AppTextStyles.style(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: AppTextStyles.style(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF15803D),
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

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onAddFollowup,
    required this.onUpdateStatus,
    required this.onUpdatePriority,
  });

  final VoidCallback? onAddFollowup;
  final VoidCallback onUpdateStatus;
  final VoidCallback onUpdatePriority;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionButton(
            label: onAddFollowup == null ? 'Lead Closed' : 'Log Conversation',
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
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Priority',
            icon: Icons.flag_outlined,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFD97706),
            borderColor: const Color(0xFFD97706),
            onTap: onUpdatePriority,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.style(
                  fontSize: 12,
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
      padding: const EdgeInsets.all(12),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoItem(label: 'EMAIL', value: lead.displayEmail),
                    const SizedBox(height: 12),
                    _InfoItem(label: 'COMPANY', value: lead.displayCompany),
                    const SizedBox(height: 12),
                    _InfoItem(
                      label: 'LEAD VALUE',
                      value: lead.displayAmount.isEmpty
                          ? 'N/A'
                          : lead.displayAmount,
                    ),
                    const SizedBox(height: 12),
                    _InfoItem(
                      label: 'CREATED DATE',
                      value: _formatDate(lead.createdAt),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    _InfoItem(label: 'SOURCE', value: lead.displaySource),
                    const SizedBox(height: 12),
                    _InfoItem(
                      label: 'PREVIOUS STATUS',
                      value: lead.previousStatus ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _InfoItem(
                      label: 'LOST REASON',
                      value: lead.lostReason ?? '-',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoItem(label: 'DESCRIPTION', value: lead.displayDescription),
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
            fontSize: 12,
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
    required this.noteItems,
    required this.reminderItems,
    required this.assignmentItems,
    required this.statusHistoryItems,
    required this.isTimelineLoading,
    required this.isFollowupsLoading,
    required this.isNotesLoading,
    required this.isRemindersLoading,
    required this.isAssignmentsLoading,
    required this.isStatusHistoryLoading,
    required this.onAddNote,
    required this.onAddReminder,
  });
  final int tabIndex;
  final List<Map<String, dynamic>> timelineItems;
  final List<Map<String, dynamic>> followupItems;
  final List<Map<String, dynamic>> noteItems;
  final List<Map<String, dynamic>> reminderItems;
  final List<Map<String, dynamic>> assignmentItems;
  final List<Map<String, dynamic>> statusHistoryItems;
  final bool isTimelineLoading;
  final bool isFollowupsLoading;
  final bool isNotesLoading;
  final bool isRemindersLoading;
  final bool isAssignmentsLoading;
  final bool isStatusHistoryLoading;
  final Future<void> Function(String note, bool isPrivate) onAddNote;
  final Future<void> Function(String remindAt, String reminderType)
  onAddReminder;

  @override
  Widget build(BuildContext context) {
    switch (tabIndex) {
      case 0:
        return _TimelineList(
          items: timelineItems,
          isLoading: isTimelineLoading,
        );
      case 1:
        return _FollowupList(
          items: followupItems,
          isLoading: isFollowupsLoading,
        );
      case 2:
        return _NotesSection(
          onAddNote: onAddNote,
          items: noteItems,
          isLoading: isNotesLoading,
        );
      case 3:
        return _ReminderSection(
          onAddReminder: onAddReminder,
          items: reminderItems,
          isLoading: isRemindersLoading,
        );
      case 4:
        return _AssignmentList(
          items: assignmentItems,
          isLoading: isAssignmentsLoading,
        );
      case 5:
      default:
        return _StatusHistoryList(
          items: statusHistoryItems,
          isLoading: isStatusHistoryLoading,
        );
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final timelineItems = items
        .map(
          (item) => _TimelineItemData(
            title:
                (item['title'] ??
                        item['event'] ??
                        item['type'] ??
                        item['action'] ??
                        'Activity')
                    .toString(),
            description:
                (item['description'] ??
                        item['message'] ??
                        item['notes'] ??
                        item['details'] ??
                        '-')
                    .toString(),
            time:
                (item['created_at'] ??
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (items.isEmpty) {
      return const _SimpleInfoCard(
        title: 'No Followups Found',
        subtitle: '',
        description: 'No followups available for this lead.',
      );
    }
    return Column(
      children: items
          .map((item) {
            final type = (item['followup_type'] ?? item['type'] ?? '-')
                .toString();
            final outcome = (item['outcome'] ?? '-').toString();
            final time =
                (item['followup_date'] ??
                        item['created_at'] ??
                        item['date'] ??
                        '-')
                    .toString();
            final notes =
                (item['discussion_notes'] ??
                        item['notes'] ??
                        item['description'] ??
                        '-')
                    .toString();
            return _SimpleInfoCard(
              title: type,
              subtitle: '$time | Outcome: $outcome',
              description: notes,
            );
          })
          .toList(growable: false),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.onAddNote,
    required this.items,
    required this.isLoading,
  });
  final Future<void> Function(String note, bool isPrivate) onAddNote;
  final List<Map<String, dynamic>> items;
  final bool isLoading;

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
                      try {
                        await onAddNote(note, isPrivate);
                        if (!context.mounted) return;
                        noteController.clear();
                        setLocalState(() => isPrivate = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Note added successfully.'),
                          ),
                        );
                      } catch (error) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppErrorHandler.messageFromError(error),
                              ),
                            ),
                          );
                      }
                    },
                    child: const Text('Add Note'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          )
        else if (items.isEmpty)
          const _SimpleInfoCard(
            title: 'No Notes Found',
            subtitle: '',
            description: 'No notes available for this lead.',
          )
        else
          Column(
            children: items
                .map((item) {
                  final noteText =
                      (item['note'] ??
                              item['notes'] ??
                              item['description'] ??
                              item['message'] ??
                              '-')
                          .toString();
                  final createdAt =
                      (item['created_at'] ??
                              item['date'] ??
                              item['time'] ??
                              '-')
                          .toString();
                  final isPrivateNote =
                      item['is_private'] == true || item['is_private'] == 1;
                  final author = (() {
                    final createdBy = item['created_by'];
                    final user = item['user'];
                    final createdByName = createdBy is Map
                        ? createdBy['name']
                        : null;
                    final userName = user is Map ? user['name'] : null;
                    return (item['created_by_name'] ??
                            createdByName ??
                            userName ??
                            '')
                        .toString()
                        .trim();
                  })();
                  final subtitleParts = <String>[
                    createdAt,
                    if (author.isNotEmpty) 'By: $author',
                    if (isPrivateNote) 'Private',
                  ];
                  return _SimpleInfoCard(
                    title: 'Note',
                    subtitle: subtitleParts.join(' | '),
                    description: noteText,
                  );
                })
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.onAddReminder,
    required this.items,
    required this.isLoading,
  });
  final Future<void> Function(String remindAt, String reminderType)
  onAddReminder;
  final List<Map<String, dynamic>> items;
  final bool isLoading;

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
                    if (remindAt == null ||
                        !remindAt!.isAfter(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Choose a future reminder date.'),
                        ),
                      );
                      return;
                    }
                    try {
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
                    } catch (error) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppErrorHandler.messageFromError(error),
                            ),
                          ),
                        );
                    }
                  },
                  child: const Text('Add Reminder'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          )
        else if (items.isEmpty)
          const _SimpleInfoCard(
            title: 'No Reminders Found',
            subtitle: '',
            description: 'No reminders available for this lead.',
          )
        else
          Column(
            children: items
                .map((item) {
                  final type =
                      (item['reminder_type'] ??
                              item['type'] ??
                              item['channel'] ??
                              '-')
                          .toString();
                  final remindAtText =
                      (item['remind_at'] ??
                              item['scheduled_at'] ??
                              item['date'] ??
                              item['created_at'] ??
                              '-')
                          .toString();
                  final status = (item['status'] ?? item['state'] ?? '')
                      .toString()
                      .trim();
                  final notes =
                      (item['note'] ??
                              item['notes'] ??
                              item['description'] ??
                              '-')
                          .toString();
                  final subtitle = status.isEmpty
                      ? remindAtText
                      : '$remindAtText | Status: $status';
                  return _SimpleInfoCard(
                    title: type,
                    subtitle: subtitle,
                    description: notes,
                  );
                })
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _AssignmentList extends StatelessWidget {
  const _AssignmentList({required this.items, required this.isLoading});
  final List<Map<String, dynamic>> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (items.isEmpty) {
      return const _SimpleInfoCard(
        title: 'No Assignments Found',
        subtitle: '',
        description: 'No assignments available for this lead.',
      );
    }
    return Column(
      children: items
          .map((item) {
            final assignee = (() {
              final assignedTo = item['assigned_to'];
              final user = item['user'];
              final assignedToName = assignedTo is Map
                  ? assignedTo['name']
                  : null;
              final userName = user is Map ? user['name'] : null;
              return (item['assignee_name'] ??
                      item['assigned_to_name'] ??
                      item['staff_name'] ??
                      assignedToName ??
                      userName ??
                      '-')
                  .toString();
            })();
            final assignedAt =
                (item['assigned_at'] ??
                        item['created_at'] ??
                        item['date'] ??
                        '-')
                    .toString();
            final note =
                (item['assignment_note'] ??
                        item['note'] ??
                        item['notes'] ??
                        item['description'] ??
                        '-')
                    .toString();
            return _SimpleInfoCard(
              title: assignee,
              subtitle: 'Assigned at: $assignedAt',
              description: note,
            );
          })
          .toList(growable: false),
    );
  }
}

class _StatusHistoryList extends StatelessWidget {
  const _StatusHistoryList({required this.items, required this.isLoading});
  final List<Map<String, dynamic>> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (items.isEmpty) {
      return const _SimpleInfoCard(
        title: 'No Status History Found',
        subtitle: '',
        description: 'No status history available for this lead.',
      );
    }
    return Column(
      children: items
          .map((item) {
            final fromStatus =
                (item['from_status'] ?? item['old_status'] ?? '-').toString();
            final toStatus = (item['to_status'] ?? item['new_status'] ?? '-')
                .toString();
            final changedAt = (item['changed_at'] ?? item['created_at'] ?? '-')
                .toString();
            final reason =
                (item['reason'] ?? item['notes'] ?? item['description'] ?? '-')
                    .toString();
            return _SimpleInfoCard(
              title: '$fromStatus -> $toStatus',
              subtitle: changedAt,
              description: reason,
            );
          })
          .toList(growable: false),
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

class _LeadFlowSummary extends StatelessWidget {
  const _LeadFlowSummary({required this.lead});
  final LeadModel lead;
  @override
  Widget build(BuildContext context) {
    final stages = lead.statusOptions.isNotEmpty
        ? lead.statusOptions.keys.toList()
        : LeadFlow.statuses;
    final current = stages.indexOf(lead.status ?? '');
    final next = DateTime.tryParse(lead.nextFollowupDate ?? '');
    final overdue =
        !lead.isClosed && next != null && next.isBefore(DateTime.now());
    final latest = lead.latestConversation;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lead Pipeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < stages.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        avatar: Icon(
                          i == current
                              ? Icons.radio_button_checked
                              : Icons.circle_outlined,
                          size: 16,
                        ),
                        backgroundColor: i == current
                            ? const Color(0xFFDBEAFE)
                            : null,
                        label: Text(
                          lead.statusOptions[stages[i]] ??
                              LeadFlow.label(stages[i]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!lead.isClosed) ...[
              const Divider(),
              Text(
                overdue ? 'Next Action - Overdue' : 'Next Action',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: overdue ? Colors.red : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                next == null
                    ? lead.nextFollowupDate ?? 'No next action scheduled'
                    : DateFormat('dd MMM yyyy, hh:mm a').format(next),
              ),
            ],
            const Divider(),
            Text(
              'Latest Conversation',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            if (latest.isEmpty)
              const Text('No conversation recorded')
            else ...[
              Text(
                '${LeadFlow.label((latest['followup_type'] ?? '').toString())} � ${LeadFlow.label((latest['outcome'] ?? '').toString())}',
              ),
              if (latest['followup_date'] != null)
                Text(latest['followup_date'].toString()),
              if (latest['discussion_notes'] != null)
                Text(latest['discussion_notes'].toString()),
            ],
          ],
        ),
      ),
    );
  }
}
