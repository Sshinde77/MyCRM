import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:dio/dio.dart';
import '../models/client_issue_model.dart';
import '../routes/app_routes.dart';
import '../screens/to_do_list.dart' as to_do;
import '../services/api_service.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class IssueManagementScreen extends StatefulWidget {
  const IssueManagementScreen({super.key});

  @override
  State<IssueManagementScreen> createState() => _IssueManagementScreenState();
}

class _IssueManagementScreenState extends State<IssueManagementScreen> {
  final ApiService _apiService = ApiService.instance;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<ClientIssueModel> _allIssues = const [];
  List<ClientIssueSelectOption> _projectOptions = const [];
  List<ClientIssueSelectOption> _customerOptions = const [];
  bool _isLoading = false;
  bool _isCreatingIssue = false;
  String? _errorMessage;
  String? _deletingIssueId;
  int _page = 1;
  static const _pageSize = 10;
  int _lastPage = 1;
  int _totalIssueCount = 0;
  bool _canCreateIssue = false;
  bool _canDeleteIssue = false;
  String _selectedStatus = 'all';
  String _appliedSearchTerm = '';

  int get _completedIssueCount => _allIssues.where((issue) {
    final status = issue.status.trim().toLowerCase();
    return status == 'closed' || status == 'completed';
  }).length;

  @override
  void initState() {
    super.initState();
    _loadActionPermissions();
    _loadIssues();
  }

  Future<void> _loadActionPermissions() async {
    final canCreate = await PermissionService.has(
      AppPermission.createRaiseIssue,
    );
    final canDelete = await PermissionService.has(
      AppPermission.deleteRaiseIssue,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _canCreateIssue = canCreate;
      _canDeleteIssue = canDelete;
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues({
    bool forceRefresh = false,
    String? search,
    int? page,
  }) async {
    if (_isLoading) return;
    final normalizedSearch = (search ?? _appliedSearchTerm).trim();
    final normalizedPage = page ?? _page;
    final apiStatus = _selectedStatus == 'all' ? null : _selectedStatus;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _appliedSearchTerm = normalizedSearch;
    });

    try {
      final data = await _apiService.getClientIssuesPageData(
        search: normalizedSearch,
        status: apiStatus,
        page: normalizedPage,
        perPage: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _allIssues = data.issues;
        _projectOptions = data.projects;
        _customerOptions = data.customers;
        _page = data.currentPage;
        _lastPage = data.lastPage < 1 ? 1 : data.lastPage;
        _totalIssueCount = data.total;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFromError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setPage(int value) {
    if (value < 1 || value > _lastPage) return;
    _loadIssues(forceRefresh: true, page: value);
  }

  Future<void> _openIssue(ClientIssueModel issue) async {
    await Get.toNamed(
      AppRoutes.issueDetail,
      arguments: {'issue_id': issue.id, 'issue': issue},
    );
    if (!mounted) return;
    await _loadIssues(forceRefresh: true);
  }

  Future<void> _openCreateIssueDialog() async {
    if (!_canCreateIssue) {
      _showSnack(
        'Permission denied',
        'You do not have permission to create issues.',
        isError: true,
      );
      return;
    }

    final request = await showDialog<_CreateIssueRequest>(
      context: context,
      barrierDismissible: !_isCreatingIssue,
      builder: (dialogContext) {
        return _CreateIssueDialog(
          projects: _projectOptions,
          customers: _customerOptions,
        );
      },
    );

    if (request == null || !mounted) return;

    setState(() => _isCreatingIssue = true);
    try {
      await _apiService.createClientIssue(
        projectId: request.projectId,
        customerId: request.customerId,
        issueDescription: request.issueDescription,
        priority: request.priority,
        status: request.status,
      );
      if (!mounted) return;
      await _loadIssues(forceRefresh: true);
      if (!mounted) return;
      _showSnack('Issue created', 'Issue saved successfully.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Save failed', _messageFromError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isCreatingIssue = false);
      }
    }
  }

  Future<void> _deleteIssue(ClientIssueModel issue) async {
    if (!_canDeleteIssue) {
      _showSnack(
        'Permission denied',
        'You do not have permission to delete issues.',
        isError: true,
      );
      return;
    }

    final issueId = issue.id.trim();
    if (issueId.isEmpty) {
      _showSnack('Delete failed', 'Issue id is missing.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Issue'),
          content: Text('Delete ${issue.displayTitle} permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingIssueId = issueId);
    try {
      await _apiService.deleteClientIssue(issueId);
      if (!mounted) return;
      await _loadIssues(forceRefresh: true);
      if (!mounted) return;
      _showSnack('Issue deleted', 'Issue deleted successfully.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Delete failed', _messageFromError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _deletingIssueId = null);
      }
    }
  }

  void _showSnack(String title, String message, {bool isError = false}) {
    AppSnackbar.show(title, message, isError: isError);
  }

  String _messageFromError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw.isEmpty ? 'Unable to load issues right now.' : raw;
  }

  void _applySearch() {
    final nextTerm = _searchController.text.trim();
    if (nextTerm == _appliedSearchTerm) {
      return;
    }
    setState(() => _page = 1);
    _loadIssues(forceRefresh: true, search: nextTerm);
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _applySearch);
  }

  Future<void> _openFilterPopup() async {
    var tempStatus = _selectedStatus;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Issues',
                      style: _ts(const Color(0xFF1E2A3B), 16, FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _IssueStatusDropdown(
                      value: tempStatus,
                      onChanged: (value) {
                        setSheetState(() => tempStatus = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedStatus = tempStatus;
                                _page = 1;
                              });
                              _loadIssues(forceRefresh: true, page: 1);
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final totalPages = _lastPage < 1 ? 1 : _lastPage;
    final safeCurrentPage = _page > totalPages ? totalPages : _page;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;
            return RefreshIndicator(
              onRefresh: () => _loadIssues(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
                children: [
                  SizedBox(height: compact ? 8 : 10),
                  _MobileAppBar(compact: compact),
                  SizedBox(height: compact ? 14 : 16),
                  Row(
                    children: [
                      Expanded(
                        child: _IssueSummaryCard(
                          label: 'Total Issues',
                          value: '$_totalIssueCount',
                          icon: Icons.bar_chart_rounded,
                          color: const Color(0xFF4F5D74),
                          backgroundColor: Colors.white,
                          compact: compact,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _IssueSummaryCard(
                          label: 'Completed',
                          value: '$_completedIssueCount',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF1D6FEA),
                          backgroundColor: Colors.white,
                          compact: compact,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 14 : 16),
                  _IssueToolbar(
                    controller: _searchController,
                    canCreateIssue: _canCreateIssue,
                    isCreatingIssue: _isCreatingIssue,
                    onSearchTap: _applySearch,
                    onSearchChanged: _onSearchChanged,
                    onFilterTap: _openFilterPopup,
                    onCreateTap: _isCreatingIssue
                        ? null
                        : _openCreateIssueDialog,
                  ),
                  if (_isLoading) ...[
                    SizedBox(height: compact ? 10 : 12),
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: Color(0xFF2563EB),
                      backgroundColor: Color(0xFFD8E7FB),
                    ),
                  ],
                  if (_errorMessage != null && _allIssues.isEmpty) ...[
                    SizedBox(height: compact ? 12 : 14),
                    _IssueStateCard(
                      message: _errorMessage!,
                      compact: compact,
                      actionLabel: 'Retry',
                      onAction: () => _loadIssues(forceRefresh: true),
                    ),
                  ] else if (_allIssues.isEmpty) ...[
                    SizedBox(height: compact ? 12 : 14),
                    _IssueStateCard(
                      message: _appliedSearchTerm.isEmpty
                          ? 'No issues available.'
                          : 'No issues match your search.',
                      compact: compact,
                    ),
                  ] else ...[
                    SizedBox(height: compact ? 14 : 16),
                    ..._allIssues.map(
                      (issue) => _IssueCard(
                        issue: issue,
                        compact: compact,
                        isDeleting: _deletingIssueId == issue.id.trim(),
                        canDelete: _canDeleteIssue,
                        onView: () => _openIssue(issue),
                        onDelete: () => _deleteIssue(issue),
                      ),
                    ),
                  ],
                  if (_totalIssueCount > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Showing ${_allIssues.length} of $_totalIssueCount (Page $safeCurrentPage/$totalPages)',
                      style: AppTextStyles.style(
                        color: const Color(0xFF475569),
                        fontSize: compact ? 12 : 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _IssuePaginationBar(
                      compact: compact,
                      currentPage: safeCurrentPage,
                      totalPages: totalPages,
                      onPageTap: _setPage,
                    ),
                  ],
                  SizedBox(height: compact ? 8 : 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MobileAppBar extends StatelessWidget {
  const _MobileAppBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = _formatHeaderDate(now);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Get.back(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Issue Management',
                style: AppTextStyles.style(
                  color: const Color(0xFF1E2A3B),
                  fontSize: compact ? 20 : 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateText,
                style: AppTextStyles.style(
                  color: const Color(0xFF64748B),
                  fontSize: compact ? 12 : 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () => Get.toNamed(AppRoutes.notifications),
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.checklist_rounded,
          onTap: () => Get.to(() => const to_do.ToDoListScreen()),
        ),
      ],
    );
  }

  String _formatHeaderDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$day $month ${date.year}';
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF2D3B52), size: 22),
        ),
      ),
    );
  }
}

class _AddIssueButton extends StatelessWidget {
  const _AddIssueButton({
    required this.compact,
    required this.isLoading,
    required this.onTap,
  });

  final bool compact;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 12 : 14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 11),
        decoration: BoxDecoration(
          color: const Color(0xFF1769F3),
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x221769F3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: compact ? 18 : 20,
              ),
            SizedBox(width: compact ? 8 : 10),
            Text(
              isLoading ? 'Saving Issue...' : 'Add New Issue',
              style: _ts(Colors.white, compact ? 13 : 14, FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueSummaryCard extends StatelessWidget {
  const _IssueSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.compact,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 16 : 18,
        compact ? 14 : 18,
        compact ? 16 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: _ts(const Color(0xFF1E2A3B), 20, FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: _ts(
              const Color(0xFF7C8BA1),
              11,
              FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueToolbar extends StatelessWidget {
  const _IssueToolbar({
    required this.controller,
    required this.canCreateIssue,
    required this.isCreatingIssue,
    required this.onSearchTap,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.onCreateTap,
  });

  final TextEditingController controller;
  final bool canCreateIssue;
  final bool isCreatingIssue;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final VoidCallback? onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD2DDEA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    onChanged: onSearchChanged,
                    onSubmitted: (_) => onSearchTap(),
                    decoration: InputDecoration(
                      hintText: 'Search issues...',
                      hintStyle: _ts(
                        const Color(0xFF94A3B8),
                        14,
                        FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                    style: _ts(const Color(0xFF1E293B), 14, FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _IssueToolbarIconButton(
          icon: Icons.filter_alt_outlined,
          onTap: onFilterTap,
        ),
        if (canCreateIssue) ...[
          const SizedBox(width: 8),
          _CreateIssueIconButton(
            onTap: onCreateTap,
            isLoading: isCreatingIssue,
          ),
        ],
      ],
    );
  }
}

class _IssueToolbarIconButton extends StatelessWidget {
  const _IssueToolbarIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD2DDEA)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF475569), size: 20),
        ),
      ),
    );
  }
}

class _CreateIssueIconButton extends StatelessWidget {
  const _CreateIssueIconButton({required this.onTap, required this.isLoading});

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1D6FEA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _IssueStateCard extends StatelessWidget {
  const _IssueStateCard({
    required this.message,
    required this.compact,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final bool compact;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFF),
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: _ts(
              const Color(0xFF64748B),
              compact ? 14 : 15,
              FontWeight.w500,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? 12 : 14),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.compact,
    required this.isDeleting,
    required this.canDelete,
    required this.onView,
    required this.onDelete,
  });

  final ClientIssueModel issue;
  final bool compact;
  final bool isDeleting;
  final bool canDelete;
  final VoidCallback onView;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusBg = _statusBg(issue.status);
    final statusFg = _statusFg(issue.status);
    final priorityBg = _priorityBg(issue.priority);
    final priorityFg = _priorityFg(issue.priority);
    final cardRadius = BorderRadius.circular(compact ? 18 : 20);

    return InkWell(
      onTap: onView,
      borderRadius: cardRadius,
      child: Container(
        margin: EdgeInsets.only(bottom: compact ? 10 : 12),
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 16,
          compact ? 14 : 16,
          compact ? 14 : 16,
          compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: cardRadius,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100F172A),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    issue.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(const Color(0xFF1E293B), 16, FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                _Pill(
                  issue.displayStatus,
                  statusBg,
                  statusFg,
                  compact: compact,
                ),
              ],
            ),
            SizedBox(height: compact ? 6 : 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    issue.displayProject,
                    style: _ts(const Color(0xFF64748B), 12, FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                _Pill(issue.priority, priorityBg, priorityFg, compact: compact),
              ],
            ),
            SizedBox(height: compact ? 10 : 12),
            Row(
              children: [
                Expanded(
                  child: _IssueMetaItem(
                    icon: Icons.person_outline_rounded,
                    value: issue.displayClient,
                    compact: compact,
                  ),
                ),
                SizedBox(width: compact ? 10 : 12),
                Expanded(
                  child: _IssueMetaItem(
                    icon: Icons.calendar_today_outlined,
                    value: issue.displayDate,
                    compact: compact,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 10 : 11),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            SizedBox(height: compact ? 9 : 10),
            Row(
              children: [
                const Spacer(),
                _IssueQuickIconAction(
                  icon: Icons.remove_red_eye_outlined,
                  background: const Color(0xFFE2E8F0),
                  foreground: const Color(0xFF475569),
                  compact: compact,
                  onTap: onView,
                ),
                if (canDelete) ...[
                  SizedBox(width: compact ? 8 : 10),
                  _IssueQuickIconAction(
                    icon: isDeleting
                        ? Icons.hourglass_top_rounded
                        : Icons.delete_outline_rounded,
                    background: const Color(0xFFFFE8E8),
                    foreground: const Color(0xFFDC2626),
                    compact: compact,
                    onTap: isDeleting ? () {} : onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueMetaItem extends StatelessWidget {
  const _IssueMetaItem({
    required this.icon,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: compact ? 14 : 15, color: const Color(0xFF94A3B8)),
        SizedBox(width: compact ? 6 : 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _ts(const Color(0xFF64748B), 11.5, FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _IssueQuickIconAction extends StatelessWidget {
  const _IssueQuickIconAction({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: compact ? 34 : 36,
        height: compact ? 34 : 36,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: compact ? 17 : 18, color: foreground),
      ),
    );
  }
}

class _IssueStatusDropdown extends StatelessWidget {
  const _IssueStatusDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = <String>[
      'all',
      'open',
      'in_progress',
      'resolved',
      'closed',
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD2DDEA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: _ts(const Color(0xFF334155), 14, FontWeight.w700),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(_formatIssueStatusLabel(option)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.bg, this.fg, {required this.compact});

  final String label;
  final Color bg;
  final Color fg;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: _ts(fg, compact ? 10 : 11, FontWeight.w700),
      ),
    );
  }
}

class _IssuePaginationBar extends StatelessWidget {
  const _IssuePaginationBar({
    required this.compact,
    required this.currentPage,
    required this.totalPages,
    required this.onPageTap,
  });

  final bool compact;
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
        _IssuePaginationArrow(
          compact: compact,
          icon: Icons.chevron_left_rounded,
          enabled: canGoPrev,
          onTap: () => onPageTap(currentPage - 1),
        ),
        SizedBox(width: compact ? 10 : 12),
        for (final token in tokens) ...[
          if (token.isEllipsis)
            SizedBox(
              width: compact ? 34 : 36,
              child: Center(
                child: Text(
                  '...',
                  style: _ts(
                    const Color(0xFF94A3B8),
                    compact ? 12 : 13,
                    FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            _IssuePageChip(
              compact: compact,
              label: '${token.page}',
              selected: token.page == currentPage,
              onTap: () => onPageTap(token.page!),
            ),
          SizedBox(width: compact ? 8 : 10),
        ],
        _IssuePaginationArrow(
          compact: compact,
          icon: Icons.chevron_right_rounded,
          enabled: canGoNext,
          onTap: () => onPageTap(currentPage + 1),
        ),
      ],
    );
  }
}

class _IssuePaginationArrow extends StatelessWidget {
  const _IssuePaginationArrow({
    required this.compact,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final bool compact;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: compact ? 34 : 40,
        height: compact ? 34 : 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE6F2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: compact ? 20 : 22,
          color: enabled ? const Color(0xFF122B52) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _IssuePageChip extends StatelessWidget {
  const _IssuePageChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: compact ? 34 : 36,
        height: compact ? 34 : 36,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D7EF8) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF2D7EF8) : const Color(0xFFDCE6F2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: _ts(
            selected ? Colors.white : const Color(0xFF1E293B),
            compact ? 13 : 14,
            FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PageToken {
  const _PageToken.page(this.page) : isEllipsis = false;
  const _PageToken.ellipsis() : page = null, isEllipsis = true;

  final int? page;
  final bool isEllipsis;
}

List<_PageToken> _buildPageTokens(int currentPage, int totalPages) {
  if (totalPages <= 5) {
    return List.generate(totalPages, (index) => _PageToken.page(index + 1));
  }

  final tokens = <_PageToken>[];
  final start = (currentPage - 1).clamp(2, totalPages - 3);
  final end = (start + 2).clamp(3, totalPages - 1);

  tokens.add(const _PageToken.page(1));
  if (start > 2) {
    tokens.add(const _PageToken.ellipsis());
  }
  for (var page = start; page <= end; page++) {
    tokens.add(_PageToken.page(page));
  }
  if (end < totalPages - 1) {
    tokens.add(const _PageToken.ellipsis());
  }
  tokens.add(_PageToken.page(totalPages));

  return tokens;
}

class _CreateIssueRequest {
  const _CreateIssueRequest({
    required this.projectId,
    required this.customerId,
    required this.issueDescription,
    required this.priority,
    required this.status,
  });

  final String projectId;
  final String customerId;
  final String issueDescription;
  final String priority;
  final String status;
}

class _CreateIssueDialog extends StatefulWidget {
  const _CreateIssueDialog({required this.projects, required this.customers});

  final List<ClientIssueSelectOption> projects;
  final List<ClientIssueSelectOption> customers;

  @override
  State<_CreateIssueDialog> createState() => _CreateIssueDialogState();
}

class _CreateIssueDialogState extends State<_CreateIssueDialog> {
  final _descriptionController = TextEditingController();
  String? _projectId;
  String? _customerId;
  String _priority = 'low';
  String _status = 'open';
  String? _inlineError;

  static const _priorities = ['low', 'medium', 'high'];
  static const _statuses = ['open', 'in_progress', 'closed'];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final projectId = _projectId?.trim() ?? '';
    final customerId = _customerId?.trim() ?? '';
    final description = _descriptionController.text.trim();

    if (projectId.isEmpty) {
      setState(() => _inlineError = 'Please select a project.');
      return;
    }
    if (customerId.isEmpty) {
      setState(() => _inlineError = 'Please select a client.');
      return;
    }
    if (description.isEmpty) {
      setState(() => _inlineError = 'Please enter issue description.');
      return;
    }

    Navigator.of(context).pop(
      _CreateIssueRequest(
        projectId: projectId,
        customerId: customerId,
        issueDescription: description,
        priority: _priority,
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 720;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 28,
        vertical: compact ? 18 : 28,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 18 : 24,
                  compact ? 18 : 22,
                  compact ? 12 : 18,
                  compact ? 14 : 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add New Project Issue',
                        style: _ts(
                          const Color(0xFF343A40),
                          compact ? 20 : 24,
                          FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF6B7280),
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 18 : 24,
                  compact ? 18 : 24,
                  compact ? 18 : 24,
                  compact ? 18 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumn = constraints.maxWidth >= 680;
                        final itemWidth = twoColumn
                            ? (constraints.maxWidth - 30) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: 30,
                          runSpacing: 18,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _DialogField(
                                label: 'Project',
                                required: true,
                                child: DropdownButtonFormField<String>(
                                  value: _projectId,
                                  isExpanded: true,
                                  items: widget.projects
                                      .map(
                                        (project) => DropdownMenuItem<String>(
                                          value: project.id,
                                          child: Text(project.displayName),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    setState(() {
                                      _projectId = value;
                                      _inlineError = null;
                                    });
                                  },
                                  decoration: _dialogInputDecoration(
                                    'Select Project',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _DialogField(
                                label: 'Client Name',
                                required: true,
                                child: DropdownButtonFormField<String>(
                                  value: _customerId,
                                  isExpanded: true,
                                  items: widget.customers
                                      .map(
                                        (customer) => DropdownMenuItem<String>(
                                          value: customer.id,
                                          child: Text(customer.displayName),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    setState(() {
                                      _customerId = value;
                                      _inlineError = null;
                                    });
                                  },
                                  decoration: _dialogInputDecoration(
                                    'Select Client',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _DialogField(
                      label: 'Issue Description',
                      required: true,
                      child: TextField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 5,
                        onChanged: (_) {
                          if (_inlineError != null) {
                            setState(() => _inlineError = null);
                          }
                        },
                        decoration: _dialogInputDecoration(''),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumn = constraints.maxWidth >= 680;
                        final itemWidth = twoColumn
                            ? (constraints.maxWidth - 30) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: 30,
                          runSpacing: 18,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _DialogField(
                                label: 'Priority',
                                child: DropdownButtonFormField<String>(
                                  value: _priority,
                                  isExpanded: true,
                                  items: _priorities
                                      .map(
                                        (priority) => DropdownMenuItem<String>(
                                          value: priority,
                                          child: Text(_titleCase(priority)),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _priority = value);
                                  },
                                  decoration: _dialogInputDecoration('Low'),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _DialogField(
                                label: 'Status',
                                child: DropdownButtonFormField<String>(
                                  value: _status,
                                  isExpanded: true,
                                  items: _statuses
                                      .map(
                                        (status) => DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(_titleCase(status)),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _status = value);
                                  },
                                  decoration: _dialogInputDecoration('Open'),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (_inlineError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _inlineError!,
                        style: _ts(
                          const Color(0xFFB3261E),
                          13,
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 18 : 24,
                  compact ? 16 : 20,
                  compact ? 18 : 22,
                  compact ? 18 : 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF6C757D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: _ts(Colors.white, 18, FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF0D86F7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Save Issue',
                        style: _ts(Colors.white, 18, FontWeight.w700),
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

  InputDecoration _dialogInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _ts(const Color(0xFF343A40), 18, FontWeight.w400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD9DEE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF0D86F7)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: _ts(const Color(0xFF5B6067), 18, FontWeight.w400),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: _ts(const Color(0xFFDC2626), 18, FontWeight.w400),
                    ),
                  ]
                : const [],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _formatIssueStatusLabel(String value) {
  switch (value) {
    case 'all':
      return 'All';
    case 'in_progress':
      return 'In Progress';
    case 'resolved':
      return 'Resolved';
    case 'closed':
      return 'Closed';
    case 'open':
      return 'Open';
    default:
      return value;
  }
}

Color _priorityBg(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'high':
    case 'urgent':
      return const Color(0xFFFFEDD5);
    case 'low':
      return const Color(0xFFF1F5F9);
    default:
      return const Color(0xFFFEF3C7);
  }
}

Color _priorityFg(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'high':
    case 'urgent':
      return const Color(0xFFF97316);
    case 'low':
      return const Color(0xFF475569);
    default:
      return const Color(0xFFD97706);
  }
}

Color _statusBg(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.contains('closed') ||
      normalized.contains('complete') ||
      normalized.contains('resolved')) {
    return const Color(0xFFE8F8EE);
  }
  if (normalized.contains('progress')) {
    return const Color(0xFFDCEAFE);
  }
  return const Color(0xFFFCE7E7);
}

Color _statusFg(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.contains('closed') ||
      normalized.contains('complete') ||
      normalized.contains('resolved')) {
    return const Color(0xFF16A34A);
  }
  if (normalized.contains('progress')) {
    return const Color(0xFF2563EB);
  }
  return const Color(0xFFEF4444);
}

TextStyle _ts(
  Color color,
  double size,
  FontWeight weight, {
  double? height,
  double? letterSpacing,
}) {
  return AppTextStyles.style(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
  );
}
