import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import 'package:dio/dio.dart';
import '../models/client_issue_model.dart';
import '../routes/app_routes.dart';
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
  List<ClientIssueModel> _allIssues = const [];
  List<ClientIssueSelectOption> _projectOptions = const [];
  List<ClientIssueSelectOption> _customerOptions = const [];
  bool _isLoading = false;
  bool _isCreatingIssue = false;
  String? _errorMessage;
  String? _deletingIssueId;
  int _page = 1;
  static const _pageSize = 10;
  bool _canCreateIssue = false;
  bool _canDeleteIssue = false;

  List<ClientIssueModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _allIssues;
    return _allIssues.where((issue) => issue.matchesQuery(q)).toList();
  }

  int get _pageCount =>
      _filtered.isEmpty ? 1 : (_filtered.length / _pageSize).ceil();

  int get _totalIssueCount => _allIssues.length;

  int get _completedIssueCount => _allIssues.where((issue) {
    final status = issue.status.trim().toLowerCase();
    return status == 'closed' || status == 'completed';
  }).length;

  List<ClientIssueModel> get _visible {
    final start = (_page - 1) * _pageSize;
    if (start >= _filtered.length) return const [];
    final end = start + _pageSize > _filtered.length
        ? _filtered.length
        : start + _pageSize;
    return _filtered.sublist(start, end);
  }

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _allIssues.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getClientIssuesIndexData();
      if (!mounted) return;
      setState(() {
        _allIssues = data.issues;
        _projectOptions = data.projects;
        _customerOptions = data.customers;
        _page = 1;
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
    if (value < 1 || value > _pageCount) return;
    setState(() => _page = value);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;
            final side = compact ? 12.0 : 14.0;
            final inner = compact ? 12.0 : 14.0;

            return Column(
              children: [
                _MobileAppBar(compact: compact),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      compact ? 4 : 6,
                      0,
                      compact ? 10 : 12,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _IssueSummaryCard(
                                      label: 'Total Issues',
                                      value: '$_totalIssueCount',
                                      icon: Icons.report_problem_outlined,
                                      color: const Color(0xFF3B82F6),
                                      backgroundColor: const Color(0xFFEAF2FF),
                                      compact: compact,
                                    ),
                                  ),
                                  SizedBox(width: compact ? 10 : 12),
                                  Expanded(
                                    child: _IssueSummaryCard(
                                      label: 'Completed',
                                      value: '$_completedIssueCount',
                                      icon: Icons.task_alt_rounded,
                                      color: const Color(0xFF16A34A),
                                      backgroundColor: const Color(0xFFE8F8EE),
                                      compact: compact,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 10 : 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              child: _canCreateIssue
                                  ? _AddIssueButton(
                                      compact: compact,
                                      isLoading: _isCreatingIssue,
                                      onTap: _isCreatingIssue
                                          ? null
                                          : _openCreateIssueDialog,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            if (_canCreateIssue)
                              SizedBox(height: compact ? 10 : 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    compact ? 18 : 20,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFD8E1EF),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0x120F172A),
                                      blurRadius: compact ? 10 : 12,
                                      offset: Offset(0, compact ? 4 : 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        inner,
                                        inner,
                                        inner,
                                        compact ? 10 : 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: compact ? 4 : 6),
                                          TextField(
                                            controller: _searchController,
                                            onChanged: (_) =>
                                                setState(() => _page = 1),
                                              style: _ts(
                                                const Color(0xFF334155),
                                                compact ? 13 : 14,
                                                FontWeight.w500,
                                              ),
                                            decoration: InputDecoration(
                                              hintText: 'Search issues...',
                                              hintStyle: _ts(
                                                const Color(0xFF94A3B8),
                                                compact ? 13 : 14,
                                                FontWeight.w500,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.search_rounded,
                                                color: const Color(0xFF94A3B8),
                                                size: compact ? 18 : 20,
                                              ),
                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF8FAFC,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: compact ? 13 : 15,
                                                  ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      compact ? 14 : 16,
                                                    ),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD8E1EF),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      compact ? 14 : 16,
                                                    ),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF3B82F6),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFD8E1EF),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        compact ? 12 : 14,
                                        compact ? 10 : 12,
                                        compact ? 12 : 14,
                                        compact ? 8 : 10,
                                      ),
                                      child: Column(
                                        children:
                                            _isLoading && _allIssues.isEmpty
                                            ? [
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 28,
                                                  ),
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                ),
                                              ]
                                            : _errorMessage != null &&
                                                  _allIssues.isEmpty
                                            ? [
                                                _IssueStateCard(
                                                  message: _errorMessage!,
                                                  compact: compact,
                                                  actionLabel: 'Retry',
                                                  onAction: () => _loadIssues(
                                                    forceRefresh: true,
                                                  ),
                                                ),
                                              ]
                                            : _visible.isEmpty
                                            ? [
                                                _IssueStateCard(
                                                  message:
                                                      _searchController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? 'No issues available.'
                                                      : 'No issues match your search.',
                                                  compact: compact,
                                                ),
                                              ]
                                            : _visible.map((issue) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    // bottom: compact ? 12 : 14,
                                                    bottom: compact ? 10 : 12,
                                                  ),
                                                  child: _IssueCard(
                                                    issue: issue,
                                                    compact: compact,
                                                    isDeleting:
                                                        _deletingIssueId ==
                                                        issue.id.trim(),
                                                    canDelete: _canDeleteIssue,
                                                    onView: () =>
                                                        _openIssue(issue),
                                                    onDelete: () =>
                                                        _deleteIssue(issue),
                                                  ),
                                                );
                                              }).toList(),
                                      ),
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFD8E1EF),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        compact ? 12 : 14,
                                        compact ? 10 : 12,
                                        compact ? 12 : 14,
                                        compact ? 12 : 14,
                                      ),
                                      child: Column(
                                        children: [
                                          _IssuePaginationBar(
                                            compact: compact,
                                            currentPage: _page,
                                            totalPages: _pageCount,
                                            onPageTap: _setPage,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
    return Container(
      height: compact ? 58 : 62,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFD8E1EF))),
      ),
      child: CommonTopBar(
        title: 'Issue Management',
        compact: compact,
        onBack: Get.back,
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
      height: compact ? 78 : 84,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            height: compact ? 32 : 36,
            width: compact ? 32 : 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compact ? 10 : 12),
            ),
            child: Icon(icon, color: color, size: compact ? 17 : 18),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(
                    color,
                    compact ? 18 : 20,
                    FontWeight.w800,
                    height: 1,
                  ),
                ),
                SizedBox(height: compact ? 4 : 5),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(
                    color,
                    compact ? 10.5 : 11.5,
                    FontWeight.w600,
                    height: 1.15,
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
    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 12,
          compact ? 10 : 12,
          compact ? 10 : 12,
          compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          border: Border.all(color: const Color(0xFFE6ECF5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0D0F172A),
              blurRadius: compact ? 7 : 9,
              offset: Offset(0, compact ? 3 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: compact ? 13 : 14,
                  color: const Color(0xFF94A3B8),
                ),
                SizedBox(width: compact ? 5 : 6),
                Text(
                  issue.displayDate,
                  style: _ts(
                    const Color(0xFF94A3B8),
                    compact ? 10.5 : 11.5,
                    FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 8 : 10),
            Text(
              issue.displayProject.toUpperCase(),
              style: _ts(
                const Color(0xFF3B82F6),
                compact ? 10 : 11,
                FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            Text(
              issue.displayTitle,
              style: _ts(
                const Color(0xFF17213A),
                compact ? 14 : 15,
                FontWeight.w700,
                height: 1.22,
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            Text(
              'Client: ${issue.displayClient}',
              style: _ts(
                const Color(0xFF64748B),
                compact ? 11.5 : 12.5,
                FontWeight.w500,
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            SizedBox(height: compact ? 8 : 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: compact ? 8 : 10,
                    runSpacing: compact ? 8 : 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Pill(
                        issue.priority,
                        _priorityBg(issue.priority),
                        _priorityFg(issue.priority),
                        compact: compact,
                      ),
                      _Pill(
                        issue.displayStatus,
                        _statusBg(issue.status),
                        _statusFg(issue.status),
                        compact: compact,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: compact ? 8 : 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: compact ? 28 : 30,
                        minHeight: compact ? 28 : 30,
                      ),
                      icon: Icon(
                        Icons.remove_red_eye_outlined,
                        color: const Color(0xFF94A3B8),
                        size: compact ? 17 : 18,
                      ),
                      onPressed: onView,
                    ),
                    if (canDelete) ...[
                      SizedBox(width: compact ? 4 : 6),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: compact ? 28 : 30,
                          minHeight: compact ? 28 : 30,
                        ),
                        onPressed: isDeleting ? null : onDelete,
                        icon: isDeleting
                            ? SizedBox(
                                width: compact ? 15 : 16,
                                height: compact ? 15 : 16,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.delete_outline_rounded,
                                color: const Color(0xFF94A3B8),
                                size: compact ? 17 : 18,
                              ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
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
            color: selected
                ? const Color(0xFF2D7EF8)
                : const Color(0xFFDCE6F2),
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
  const _PageToken.ellipsis()
    : page = null,
      isEllipsis = true;

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
