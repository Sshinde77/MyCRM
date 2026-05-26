import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/api_constants.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/models/staff_member_model.dart';
import 'package:mycrm/services/api_service.dart';

import '../routes/app_routes.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _appliedSearchTerm = '';
  List<StaffMemberModel> _currentPageMembers = const <StaffMemberModel>[];
  bool _isInitialLoading = true;
  bool _isPageLoading = false;
  String? _loadError;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRecords = 0;
  String? _deletingStaffId;
  String _selectedStatusFilter = 'all';

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
        _currentPageMembers = const <StaffMemberModel>[];
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
        search: _appliedSearchTerm,
        status: _selectedStatusFilter == 'all' ? null : _selectedStatusFilter,
      );
      if (!mounted) return;

      setState(() {
        _currentPageMembers = pageResult.items;
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
    await _loadPage(page: page);
  }

  Future<void> _applySearch() async {
    setState(() {
      _appliedSearchTerm = _searchController.text.trim();
      _currentPage = 1;
    });
    await _loadPage(page: 1, showInitialLoader: true);
  }

  Future<void> _openFilterPopup() async {
    var tempStatus = _selectedStatusFilter;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
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
                  'Filter Staff',
                  style: AppTextStyles.style(
                    color: const Color(0xFF1E2A3B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setSheetState) {
                    Widget buildStatusTile(String value, String label) {
                      final selected = tempStatus == value;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setSheetState(() => tempStatus = value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFDBEAFE)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFFD2DDEA),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: selected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                label,
                                style: AppTextStyles.style(
                                  color: const Color(0xFF334155),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        buildStatusTile('all', 'All Staff'),
                        const SizedBox(height: 8),
                        buildStatusTile('active', 'Active Staff'),
                        const SizedBox(height: 8),
                        buildStatusTile('inactive', 'Inactive Staff'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          if (!mounted) return;
                          if (_selectedStatusFilter == 'all') return;
                          setState(() => _selectedStatusFilter = 'all');
                          await _loadPage(page: 1, showInitialLoader: true);
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          if (!mounted) return;
                          if (_selectedStatusFilter == tempStatus) return;
                          setState(() => _selectedStatusFilter = tempStatus);
                          await _loadPage(page: 1, showInitialLoader: true);
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
              final hasSearch = _appliedSearchTerm.isNotEmpty;
              final filteredMembers = _currentPageMembers;
              final headerCount = _totalRecords > 0
                  ? _totalRecords
                  : filteredMembers.length;

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
                          _StaffToolbar(
                            controller: _searchController,
                            onSearchTap: _applySearch,
                            onFilterTap: _openFilterPopup,
                          ),
                          SizedBox(height: compact ? 10 : 12),
                          _SectionHeader(compact: compact, count: headerCount),
                          SizedBox(height: compact ? 10 : 12),
                          if (_isInitialLoading)
                            _LoadingState(compact: compact)
                          else if (_loadError != null &&
                              _currentPageMembers.isEmpty)
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
}

class _Header extends StatelessWidget {
  const _Header({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Get.back(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff',
                style: AppTextStyles.style(
                  color: const Color(0xFF1E2A3B),
                  fontSize: compact ? 20 : 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatHeaderDate(DateTime.now()),
                style: AppTextStyles.style(
                  color: const Color(0xFF64748B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaffToolbar extends StatelessWidget {
  const _StaffToolbar({
    required this.controller,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

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
                    onSubmitted: (_) => onSearchTap(),
                    decoration: InputDecoration(
                      hintText: 'Search staff members...',
                      hintStyle: AppTextStyles.style(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                    style: AppTextStyles.style(
                      color: const Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
        _StaffToolbarIconButton(
          icon: Icons.filter_alt_outlined,
          onTap: onFilterTap,
        ),
        const SizedBox(width: 8),
        const _CreateStaffButton(),
      ],
    );
  }
}

class _StaffToolbarIconButton extends StatelessWidget {
  const _StaffToolbarIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
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

class _CreateStaffButton extends StatelessWidget {
  const _CreateStaffButton();

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permission: AppPermission.createStaff,
      child: Material(
        color: const Color(0xFF1D6FEA),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.addStaff),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5ECF5)),
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
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.email_outlined,
                    text: member.email,
                    compact: compact,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoRow(
                    icon: member.phone?.trim().isNotEmpty == true
                        ? Icons.phone_outlined
                        : Icons.groups_2_outlined,
                    text: secondaryLine,
                    compact: compact,
                  ),
                ),
              ],
            ),
            if (member.lastLogin?.trim().isNotEmpty == true) ...[
              SizedBox(height: compact ? 10 : 12),
              // _InfoRow(
              //   icon: Icons.schedule_rounded,
              //   text: 'Last login: ${member.lastLogin!}',
              //   compact: compact,
              // ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEAF0F6)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    member.isActive ? 'Active staff' : 'Inactive staff',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(
                      color: const Color(0xFF4C5B70),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StaffCardAction(
                  icon: Icons.remove_red_eye_outlined,
                  onTap: () =>
                      Get.toNamed(AppRoutes.staffDetail, arguments: member.id),
                ),
                const SizedBox(width: 6),
                PermissionGate(
                  permission: AppPermission.deleteStaff,
                  child: _StaffCardAction(
                    icon: isDeleting
                        ? Icons.hourglass_top_rounded
                        : Icons.delete_outline_rounded,
                    isDestructive: true,
                    onTap: isDeleting ? null : onDelete,
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
          child: Icon(icon, color: const Color(0xFF2D3B52), size: 20),
        ),
      ),
    );
  }
}

class _StaffCardAction extends StatelessWidget {
  const _StaffCardAction({
    required this.icon,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
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

    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: foregroundColor, size: 18),
        ),
      ),
    );
  }
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
      child: Builder(
        builder: (context) {
          final imageUrl = _resolveStaffProfileImageUrl(member.profileImage);
          if (imageUrl != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: compact ? 42 : 44,
                height: compact ? 42 : 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  initials.isEmpty ? 'ST' : initials,
                  style: AppTextStyles.style(
                    color: accentColor,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }

          return Text(
            initials.isEmpty ? 'ST' : initials,
            style: AppTextStyles.style(
              color: accentColor,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }
}

String? _resolveStaffProfileImageUrl(String? rawPath) {
  final path = (rawPath ?? '').trim();
  if (path.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(path);
  if (parsed != null && parsed.hasScheme) {
    return path;
  }

  return Uri.parse(
    ApiConstants.appBaseUrl,
  ).resolve(path.startsWith('/') ? path.substring(1) : path).toString();
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
