import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/models/staff_member_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

import '../routes/app_routes.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, List<StaffMemberModel>> _staffMembersByPage =
      <int, List<StaffMemberModel>>{};
  bool _isInitialLoading = true;
  bool _isPageLoading = false;
  bool _isSearchLoadingAllPages = false;
  String? _loadError;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRecords = 0;
  String? _deletingStaffId;

  @override
  void initState() {
    super.initState();
    _loadPage(page: 1, showInitialLoader: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await _loadPage(page: 1, showInitialLoader: true);
  }

  Future<void> _loadPage({
    required int page,
    bool showInitialLoader = false,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;

    if (showInitialLoader) {
      setState(() {
        _isInitialLoading = true;
        _isPageLoading = false;
        _loadError = null;
        _staffMembersByPage.clear();
        _currentPage = 1;
        _lastPage = 1;
        _totalRecords = 0;
      });
    } else {
      if (_isInitialLoading || _isPageLoading) return;
      setState(() => _isPageLoading = true);
    }

    try {
      final pageResult = await ApiService.instance.getStaffListPage(
        page: normalizedPage,
      );
      if (!mounted) return;

      setState(() {
        _staffMembersByPage[pageResult.currentPage] = pageResult.items;
        _currentPage = pageResult.currentPage;
        _lastPage = pageResult.lastPage < 1 ? 1 : pageResult.lastPage;
        _totalRecords = pageResult.total;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isPageLoading = false;
        });
      }
    }
  }

  Future<void> _goToPage(int page) async {
    if (page < 1 || page > _lastPage) return;
    if (_isPageLoading || _isInitialLoading) return;

    if (_staffMembersByPage.containsKey(page)) {
      setState(() => _currentPage = page);
      return;
    }

    await _loadPage(page: page);
  }

  Future<void> _ensureAllPagesLoadedForSearch() async {
    if (_isSearchLoadingAllPages || _isInitialLoading || _lastPage <= 1) {
      return;
    }

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    final missingPages = <int>[];
    for (var page = 1; page <= _lastPage; page += 1) {
      if (!_staffMembersByPage.containsKey(page)) {
        missingPages.add(page);
      }
    }
    if (missingPages.isEmpty) {
      return;
    }

    setState(() => _isSearchLoadingAllPages = true);

    try {
      for (final page in missingPages) {
        if (!mounted || _searchController.text.trim().isEmpty) {
          break;
        }
        final pageResult = await ApiService.instance.getStaffListPage(
          page: page,
        );
        if (!mounted) return;

        setState(() {
          _staffMembersByPage[pageResult.currentPage] = pageResult.items;
          _lastPage = pageResult.lastPage < 1 ? 1 : pageResult.lastPage;
          _totalRecords = pageResult.total;
          _loadError = null;
        });
      }
    } catch (_) {
      // Keep current page data visible even if background search-page loading fails.
    } finally {
      if (mounted) {
        setState(() => _isSearchLoadingAllPages = false);
      }
    }
  }

  List<StaffMemberModel> _flattenLoadedMembers() {
    final pageNumbers = _staffMembersByPage.keys.toList()..sort();
    final seen = <String>{};
    final flattened = <StaffMemberModel>[];
    for (final page in pageNumbers) {
      final items = _staffMembersByPage[page] ?? const <StaffMemberModel>[];
      for (final member in items) {
        if (seen.add(member.id)) {
          flattened.add(member);
        }
      }
    }
    return flattened;
  }

  Future<void> _confirmDelete(StaffMemberModel member) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Staff',
            style: AppTextStyles.style(
              color: const Color(0xFF162033),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Delete ${member.name.isNotEmpty ? member.name : 'this staff member'} permanently?',
            style: AppTextStyles.style(
              color: const Color(0xFF475569),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: AppTextStyles.style(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: AppTextStyles.style(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() => _deletingStaffId = member.id);

    try {
      await ApiService.instance.deleteStaff(member.id);
      if (!mounted) return;

      AppSnackbar.show(
        'Staff deleted',
        '${member.name.isNotEmpty ? member.name : 'The staff member'} was deleted successfully.',
      );
      await _reload();
    } on Exception catch (error) {
      if (!mounted) return;

      AppSnackbar.show(
        'Delete failed',
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingStaffId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 360;
    final horizontalPadding = compact ? 12.0 : 14.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEEF5FB)],
          ),
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              final query = _searchController.text.trim();
              final hasSearch = _searchController.text.trim().isNotEmpty;
              final currentPageMembers =
                  _staffMembersByPage[_currentPage] ??
                  const <StaffMemberModel>[];
              final searchableMembers = _flattenLoadedMembers();
              final filteredMembers = hasSearch
                  ? _filterMembers(searchableMembers)
                  : currentPageMembers;
              final headerCount = hasSearch
                  ? filteredMembers.length
                  : (_totalRecords > 0
                        ? _totalRecords
                        : filteredMembers.length);

              if (hasSearch) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _searchController.text.trim() != query)
                    return;
                  _ensureAllPagesLoadedForSearch();
                });
              }

              return RefreshIndicator(
                onRefresh: _reload,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(compact: compact),
                          SizedBox(height: compact ? 12 : 14),
                          _SearchBar(
                            compact: compact,
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                          ),
                          SizedBox(height: compact ? 10 : 12),
                          PermissionGate(
                            permission: AppPermission.createStaff,
                            child: Column(
                              children: [
                                _AddStaffButton(compact: compact),
                                SizedBox(height: compact ? 10 : 12),
                              ],
                            ),
                          ),
                          _SectionHeader(compact: compact, count: headerCount),
                          SizedBox(height: compact ? 10 : 12),
                          if (_isInitialLoading)
                            _LoadingState(compact: compact)
                          else if (_loadError != null &&
                              _staffMembersByPage.isEmpty)
                            _ErrorState(
                              compact: compact,
                              onRetry: () => _reload(),
                            )
                          else if (filteredMembers.isEmpty)
                            _EmptyState(compact: compact, hasSearch: hasSearch)
                          else ...[
                            ...filteredMembers.map(
                              (member) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: compact ? 12 : 14,
                                ),
                                child: _StaffCard(
                                  member: member,
                                  compact: compact,
                                  isDeleting: _deletingStaffId == member.id,
                                  onDelete: () => _confirmDelete(member),
                                ),
                              ),
                            ),
                            if (hasSearch && _isSearchLoadingAllPages)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: compact ? 6 : 8,
                                  bottom: compact ? 8 : 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: compact ? 18 : 20,
                                      width: compact ? 18 : 20,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Searching all pages...',
                                      style: AppTextStyles.style(
                                        color: const Color(0xFF64748B),
                                        fontSize: compact ? 12 : 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (!hasSearch)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: compact ? 6 : 8,
                                  bottom: compact ? 8 : 10,
                                ),
                                child: _PaginationBar(
                                  compact: compact,
                                  currentPage: _currentPage,
                                  totalPages: _lastPage,
                                  onPageTap: (page) => _goToPage(page),
                                ),
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
        ),
      ),
    );
  }

  List<StaffMemberModel> _filterMembers(List<StaffMemberModel> members) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return members;

    return members.where((member) {
      final haystack = [
        member.name,
        member.email,
        member.phone ?? '',
        member.role ?? '',
        member.team ?? '',
        member.departments.join(' '),
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CommonTopBar(title: 'Staff', compact: compact, onBack: Get.back);
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.compact,
    required this.controller,
    this.onChanged,
  });

  final bool compact;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 18,
          ),
          hintText: 'Search staff members...',
          hintStyle: AppTextStyles.style(
            color: const Color(0xFF94A3B8),
            fontSize: compact ? 12 : 13,
          ),
        ),
      ),
    );
  }
}

class _AddStaffButton extends StatelessWidget {
  const _AddStaffButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.addStaff),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: compact ? 12 : 13),
          decoration: BoxDecoration(
            color: const Color(0xFF1D6FEA),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x221D6FEA),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: compact ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Add New Staff',
                style: AppTextStyles.style(
                  color: Colors.white,
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.compact, required this.count});

  final bool compact;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Current team members',
            style: AppTextStyles.style(
              color: const Color(0xFF162033),
              fontSize: compact ? 17 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$count staff records',
          style: AppTextStyles.style(
            color: const Color(0xFF64748B),
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.member,
    required this.compact,
    required this.onDelete,
    this.isDeleting = false,
  });

  final StaffMemberModel member;
  final bool compact;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final statusBackground = member.isActive
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFF1F5F9);
    final statusColor = member.isActive
        ? const Color(0xFF166534)
        : const Color(0xFF64748B);
    final accentColor = _accentColorFor(member);
    final secondaryLine = member.phone?.trim().isNotEmpty == true
        ? member.phone!.trim()
        : member.team?.trim().isNotEmpty == true
        ? member.team!.trim()
        : member.departments.isNotEmpty
        ? member.departments.join(', ')
        : 'Staff member';

    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.staffDetail, arguments: member.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 12 : 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarBadge(member: member, compact: compact),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: AppTextStyles.style(
                          color: const Color(0xFF162033),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          (member.role?.trim().isNotEmpty == true
                              ? member.role!
                              : 'Staff'),
                          style: AppTextStyles.style(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    member.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: AppTextStyles.style(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 8 : 10),
            _InfoRow(
              icon: Icons.email_outlined,
              text: member.email,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 10),
            _InfoRow(
              icon: member.phone?.trim().isNotEmpty == true
                  ? Icons.phone_outlined
                  : Icons.groups_2_outlined,
              text: secondaryLine,
              compact: compact,
            ),
            if (member.lastLogin?.trim().isNotEmpty == true) ...[
              SizedBox(height: compact ? 10 : 12),
              // _InfoRow(
              //   icon: Icons.schedule_rounded,
              //   text: 'Last login: ${member.lastLogin!}',
              //   compact: compact,
              // ),
            ],
            SizedBox(height: compact ? 8 : 10),
            const Divider(height: 1, color: Color(0xFFEAF0F6)),
            SizedBox(height: compact ? 8 : 10),
            Row(
              children: [
                Expanded(
                  child: _CardAction(
                    icon: Icons.remove_red_eye_outlined,
                    label: 'View',
                    onTap: () => Get.toNamed(
                      AppRoutes.staffDetail,
                      arguments: member.id,
                    ),
                  ),
                ),
                Expanded(
                  child: PermissionGate(
                    permission: AppPermission.deleteStaff,
                    child: Row(
                      children: [
                        SizedBox(width: compact ? 8 : 10),
                        Expanded(
                          child: _CardAction(
                            icon: isDeleting
                                ? Icons.hourglass_top_rounded
                                : Icons.delete_outline_rounded,
                            label: isDeleting ? 'Deleting' : 'Delete',
                            isDestructive: true,
                            onTap: isDeleting ? null : onDelete,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.member, required this.compact});

  final StaffMemberModel member;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final initials = member.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final accentColor = _accentColorFor(member);

    return Container(
      height: compact ? 42 : 44,
      width: compact ? 42 : 44,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'ST' : initials,
        style: AppTextStyles.style(
          color: accentColor,
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.compact,
  });

  final IconData icon;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: compact ? 16 : 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.style(
              color: const Color(0xFF475569),
              fontSize: compact ? 11.5 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isDestructive
        ? const Color(0xFFB42318)
        : const Color(0xFF1D4ED8);
    final backgroundColor = isDestructive
        ? const Color(0xFFFEE4E2)
        : const Color(0xFFE8F0FE);

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: foregroundColor, size: 16),
      label: Text(
        label,
        style: AppTextStyles.style(
          color: foregroundColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(36),
        backgroundColor: backgroundColor,
        side: BorderSide(color: backgroundColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: compact ? 36 : 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.compact, required this.onRetry});

  final bool compact;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 34,
            color: Color(0xFFB42318),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load staff data',
            style: AppTextStyles.style(
              color: const Color(0xFF162033),
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh or retry the request.',
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: const Color(0xFF1D6FEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Retry',
                style: AppTextStyles.style(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.compact, required this.hasSearch});

  final bool compact;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.group_off_rounded,
            size: 34,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch
                ? 'No matching staff found'
                : 'No staff records available',
            style: AppTextStyles.style(
              color: const Color(0xFF162033),
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different name, role, email, or team.'
                : 'New staff members from the API will appear here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
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

    return Padding(
      padding: EdgeInsets.only(top: compact ? 6 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationArrowButton(
            compact: compact,
            icon: Icons.chevron_left_rounded,
            enabled: canGoPrev,
            onTap: () => onPageTap(currentPage - 1),
          ),
          SizedBox(width: compact ? 10 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tokens
                .map((token) {
                  if (token == null) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2 : 4,
                        vertical: compact ? 8 : 9,
                      ),
                      child: Text(
                        '...',
                        style: AppTextStyles.style(
                          color: const Color(0xFF64748B),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  final selected = token == currentPage;
                  return InkWell(
                    onTap: () => onPageTap(token),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: compact ? 34 : 36,
                      height: compact ? 34 : 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF122B52)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$token',
                        style: AppTextStyles.style(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF334155),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          SizedBox(width: compact ? 10 : 12),
          _PaginationArrowButton(
            compact: compact,
            icon: Icons.chevron_right_rounded,
            enabled: canGoNext,
            onTap: () => onPageTap(currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<int?> _buildPageTokens(int current, int total) {
    if (total <= 7) {
      return List<int?>.generate(total, (index) => index + 1);
    }

    final tokens = <int?>[1];
    var start = current - 1;
    var end = current + 1;

    if (current <= 3) {
      start = 2;
      end = 4;
    } else if (current >= total - 2) {
      start = total - 3;
      end = total - 1;
    } else {
      start = start < 2 ? 2 : start;
      end = end > total - 1 ? total - 1 : end;
    }

    if (start > 2) {
      tokens.add(null);
    }
    for (var page = start; page <= end; page += 1) {
      tokens.add(page);
    }
    if (end < total - 1) {
      tokens.add(null);
    }
    tokens.add(total);
    return tokens;
  }
}

class _PaginationArrowButton extends StatelessWidget {
  const _PaginationArrowButton({
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

Color _accentColorFor(StaffMemberModel member) {
  const palette = [
    Color(0xFF2563EB),
    Color(0xFF0F766E),
    Color(0xFFEA580C),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
  ];

  final seed = '${member.id}-${member.name}'.codeUnits.fold<int>(
    0,
    (value, code) => value + code,
  );
  return palette[seed % palette.length];
}
