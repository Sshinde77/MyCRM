import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/models/load_state.dart';

import '../models/client_model.dart';
import '../core/services/permission_service.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/skeletons/app_skeletons.dart';
import '../widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<ClientModel> _clients = <ClientModel>[];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalCount = 0;
  int _activeCount = 0;
  String _appliedSearch = '';
  String _selectedStatusFilter = 'all';
  static const int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _loadClientsPage(1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _loadClientsPage(_currentPage, search: _appliedSearch);
  }

  Future<void> _loadClientsPage(int pageNumber, {String? search}) async {
    if (_isLoading) return;
    if (pageNumber < 1) return;
    final normalizedSearch = (search ?? _appliedSearch).trim();

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final futures = <Future<ClientListPageResult>>[
        ApiService.instance.getClientsListPage(
          page: pageNumber,
          search: normalizedSearch,
          status: _selectedStatusFilter == 'all' ? null : _selectedStatusFilter,
          perPage: _perPage,
        ),
        ApiService.instance.getClientsListPage(
          page: 1,
          search: normalizedSearch,
          status: 'active',
          perPage: 1,
        ),
      ];
      final responses = await Future.wait<ClientListPageResult>(futures);
      final page = responses[0];
      final activePage = responses[1];
      if (!mounted) return;

      setState(() {
        _clients
          ..clear()
          ..addAll(page.items);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _totalCount = page.total;
        _activeCount = activePage.total;
        _appliedSearch = normalizedSearch;
      });
    } on DioException catch (error) {
      if (!mounted) return;

      final responseData = error.response?.data;
      var message = 'Unable to load clients';
      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!.trim();
      }
      setState(() => _errorMessage = message);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applySearch() async {
    await _loadClientsPage(1, search: _searchController.text.trim());
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
                  'Filter Clients',
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
                        buildStatusTile('all', 'All Clients'),
                        const SizedBox(height: 8),
                        buildStatusTile('active', 'Active Clients'),
                        const SizedBox(height: 8),
                        buildStatusTile('inactive', 'Inactive Clients'),
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
                          await _loadClientsPage(1, search: _appliedSearch);
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
                          await _loadClientsPage(1, search: _appliedSearch);
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 360;
    final clients = _clients;
    final totalClients = _totalCount > 0 ? _totalCount : clients.length;
    final activeClients = _activeCount;
    final loadState = _isLoading && clients.isEmpty
        ? LoadState.loading
        : _errorMessage != null && clients.isEmpty
        ? LoadState.error
        : clients.isEmpty
        ? LoadState.empty
        : LoadState.success;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 8),
                const CommonTopBar(title: 'Clients'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Clients',
                        value: totalClients.toString(),
                        icon: Icons.people,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Active',
                        value: activeClients.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            icon: Icon(
                              Icons.search,
                              color: Colors.grey,
                              size: 20,
                            ),
                            hintText: 'Search clients...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _applySearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Search'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _circleIcon(Icons.tune, onTap: _openFilterPopup),
                  ],
                ),
                const SizedBox(height: 12),
                PermissionGate(
                  permission: AppPermission.createClients,
                  child: InkWell(
                    onTap: () => Get.toNamed(AppRoutes.addClient),
                    borderRadius: BorderRadius.circular(22),
                    child: Ink(
                      height: 46,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Text(
                          '+ Add New Client',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'RECENTLY UPDATED',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (loadState.isLoading)
                  const _ClientsLoading()
                else if (loadState.isError)
                  ErrorStateView(
                    title: 'Unable to load clients',
                    message: _errorMessage!,
                    onRetry: _reload,
                  )
                else if (loadState.isEmpty)
                  const EmptyStateView(
                    title: 'No clients available',
                    message: 'The API returned no client records.',
                    icon: Icons.people_outline_rounded,
                  )
                else
                  _ClientsList(
                    clients: clients,
                    hasSearch: _appliedSearch.isNotEmpty,
                    onRefresh: _reload,
                  ),
                if (clients.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Showing ${clients.length} of $totalClients (Page $_currentPage/$_lastPage)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PaginationBar(
                    compact: compact,
                    currentPage: _currentPage,
                    totalPages: _lastPage,
                    onPageTap: (page) {
                      _loadClientsPage(page);
                    },
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _circleIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        width: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey, size: 20),
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
        alignment: Alignment.center,
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
        child: Icon(
          icon,
          size: compact ? 20 : 22,
          color: enabled ? const Color(0xFF122B52) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _ClientsList extends StatelessWidget {
  const _ClientsList({
    required this.clients,
    required this.hasSearch,
    required this.onRefresh,
  });

  final List<ClientModel> clients;
  final bool hasSearch;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    Future<void> handleDelete(String id) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete client'),
          content: const Text('Are you sure you want to delete this client?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      try {
        await ApiService.instance.deleteClient(id);
        AppSnackbar.show(
          'Client deleted',
          'The client has been deleted successfully.',
        );
        onRefresh();
      } on DioException catch (error) {
        final responseData = error.response?.data;
        String message = 'Failed to delete client.';

        if (responseData is Map && responseData['message'] != null) {
          message = responseData['message'].toString();
        } else if (error.message != null && error.message!.trim().isNotEmpty) {
          message = error.message!.trim();
        }

        AppSnackbar.show('Delete failed', message);
      }
    }

    if (clients.isEmpty) {
      return Center(
        child: Text(
          hasSearch ? 'No matching clients' : 'No clients available',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        for (final client in clients)
          _ClientCard(
            id: client.id,
            name: client.name.isNotEmpty ? client.name : 'Client',
            profileImageUrl: client.profileImageUrl,
            role: client.contactLine,
            email: client.email.isNotEmpty ? client.email : 'No email',
            phone: client.phone.isNotEmpty ? client.phone : 'No phone',
            active: client.isActive,
            onEdit: () {
              Get.toNamed(
                AppRoutes.addClient,
                arguments: {
                  'id': client.id,
                  'isEdit': true,
                  'first_name': client.firstName,
                  'last_name': client.lastName,
                },
              );
            },
            onDelete: () => handleDelete(client.id),
          ),
      ],
    );
  }
}

class _ClientsLoading extends StatelessWidget {
  const _ClientsLoading();

  @override
  Widget build(BuildContext context) {
    return SkeletonList(
      itemCount: 4,
      separatorHeight: 12,
      useShimmer: true,
      itemBuilder: (context, index) {
        return AppSkeletonizer(
          enabled: true,
          child: Container(
            height: 168,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    SkeletonBlock(
                      height: 36,
                      width: 36,
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                    ),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonBlock(height: 14)),
                  ],
                ),
                SizedBox(height: 12),
                SkeletonBlock(height: 12),
                SizedBox(height: 8),
                SkeletonBlock(height: 12, width: 170),
                SizedBox(height: 12),
                SkeletonBlock(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final String id;
  final String name;
  final String profileImageUrl;
  final String role;
  final String email;
  final String phone;
  final bool active;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientCard({
    required this.id,
    required this.name,
    required this.profileImageUrl,
    required this.role,
    required this.email,
    required this.phone,
    required this.active,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = active ? Colors.green : Colors.grey;

    return InkWell(
      onTap: () {
        Get.toNamed(AppRoutes.clientDetail, arguments: {'id': id});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ClientAvatar(
                  imageUrl: profileImageUrl,
                  radius: 18,
                  name: name,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        role,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    active ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(color: statusColor, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.email, email),
            _infoRow(Icons.phone, phone),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.remove_red_eye, color: Colors.grey, size: 19),
                const SizedBox(width: 14),
                PermissionGate(
                  permission: AppPermission.editClients,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onEdit,
                        child: const Icon(
                          Icons.edit,
                          color: Colors.grey,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
                PermissionGate(
                  permission: AppPermission.deleteClients,
                  child: InkWell(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.grey,
                      size: 19,
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

  Widget _infoRow(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isLink ? Colors.blue : Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({
    required this.imageUrl,
    required this.radius,
    required this.name,
  });

  final String imageUrl;
  final double radius;
  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) {
      return _fallbackAvatar(radius, name);
    }

    return ClipOval(
      child: Image.network(
        trimmed,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackAvatar(radius, name),
      ),
    );
  }

  Widget _fallbackAvatar(double radius, String name) {
    final initial = name.trim().isEmpty ? 'C' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE2E8F0),
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
