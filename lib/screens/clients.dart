import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';

import '../models/client_model.dart';
import '../core/services/permission_service.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
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
  final List<ClientModel> _searchClients = <ClientModel>[];
  bool _isLoading = false;
  bool _isSearchLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalCount = 0;
  int _searchFetchGeneration = 0;

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
    _invalidateSearchCache();
    _loadClientsPage(_currentPage);
  }

  Future<void> _loadClientsPage(int pageNumber) async {
    if (_isLoading) return;
    if (pageNumber < 1) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final page = await ApiService.instance.getClientsListPage(
        page: pageNumber,
      );
      if (!mounted) return;

      setState(() {
        _clients
          ..clear()
          ..addAll(page.items);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _totalCount = page.total;
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

  void _invalidateSearchCache() {
    _searchClients.clear();
    _searchFetchGeneration += 1;
    _isSearchLoading = false;
  }

  Future<void> _handleSearchChanged(String _) async {
    setState(() {});
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchClients.clear();
        _isSearchLoading = false;
      });
      return;
    }
    await _ensureSearchClientsLoaded();
  }

  Future<void> _ensureSearchClientsLoaded() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    if (_isSearchLoading || _searchClients.isNotEmpty) {
      return;
    }

    final generation = _searchFetchGeneration + 1;
    setState(() {
      _searchFetchGeneration = generation;
      _isSearchLoading = true;
    });

    try {
      final firstPage = await ApiService.instance.getClientsListPage(page: 1);
      if (!mounted || generation != _searchFetchGeneration) return;

      final allClients = <ClientModel>[...firstPage.items];
      final normalizedLastPage = firstPage.lastPage < 1
          ? 1
          : firstPage.lastPage;

      for (var page = 2; page <= normalizedLastPage; page++) {
        final nextPage = await ApiService.instance.getClientsListPage(
          page: page,
        );
        if (!mounted || generation != _searchFetchGeneration) return;
        allClients.addAll(nextPage.items);
      }

      final dedupedById = <String, ClientModel>{};
      for (final client in allClients) {
        dedupedById[client.id] = client;
      }

      setState(() {
        _searchClients
          ..clear()
          ..addAll(dedupedById.values);
      });
    } finally {
      if (!mounted || generation != _searchFetchGeneration) return;
      setState(() => _isSearchLoading = false);
    }
  }

  List<ClientModel> _filterClients(List<ClientModel> clients) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return clients;
    }

    return clients.where((client) {
      final haystack = [
        client.name,
        client.email,
        client.industry,
        client.website,
        client.contactName,
        client.contactRole,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 360;
    final hasSearch = _searchController.text.trim().isNotEmpty;
    final clients = hasSearch
        ? (_searchClients.isNotEmpty ? _searchClients : _clients)
        : _clients;
    final activeClientsSource = _searchClients.isNotEmpty
        ? _searchClients
        : _clients;
    final filteredClients = _filterClients(clients);
    final totalClients = _totalCount > 0 ? _totalCount : clients.length;
    final activeClients = activeClientsSource
        .where((client) => client.isActive)
        .length;

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
                const SizedBox(height: 10),
                const CommonTopBar(title: 'Clients'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Clients',
                        value: totalClients.toString(),
                        percent: 'API',
                        icon: Icons.people,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Active',
                        value: activeClients.toString(),
                        percent: 'Loaded',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _handleSearchChanged,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            icon: Icon(Icons.search, color: Colors.grey),
                            hintText: 'Search clients...',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _circleIcon(Icons.tune),
                  ],
                ),
                const SizedBox(height: 16),
                PermissionGate(
                  permission: AppPermission.createClients,
                  child: InkWell(
                    onTap: () => Get.toNamed(AppRoutes.addClient),
                    borderRadius: BorderRadius.circular(30),
                    child: Ink(
                      height: 55,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          '+ Add New Client',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 10),
                if ((_isLoading && clients.isEmpty) ||
                    (hasSearch && _isSearchLoading && filteredClients.isEmpty))
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null && clients.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(_errorMessage!),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _reload,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else
                  _ClientsList(
                    clients: filteredClients,
                    hasSearch: hasSearch,
                    onRefresh: _reload,
                  ),
                if (!hasSearch && clients.isNotEmpty) ...[
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
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _circleIcon(IconData icon) {
    return Container(
      height: 45,
      width: 45,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.grey),
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
            role: client.contactLine,
            email: client.email.isNotEmpty ? client.email : 'No email',
            phone: client.phone.isNotEmpty ? client.phone : 'No phone',
            active: client.isActive,
            onEdit: () {
              Get.toNamed(
                AppRoutes.addClient,
                arguments: {'id': client.id, 'isEdit': true},
              );
            },
            onDelete: () => handleDelete(client.id),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String percent;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.percent,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(percent),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final String id;
  final String name;
  final String role;
  final String email;
  final String phone;
  final bool active;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientCard({
    required this.id,
    required this.name,
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(role, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    active ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.email, email),
            _infoRow(Icons.phone, phone),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.remove_red_eye, color: Colors.grey),
                const SizedBox(width: 16),
                PermissionGate(
                  permission: AppPermission.editClients,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onEdit,
                        child: const Icon(Icons.edit, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                PermissionGate(
                  permission: AppPermission.deleteClients,
                  child: InkWell(
                    onTap: onDelete,
                    child: const Icon(Icons.delete, color: Colors.grey),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: isLink ? Colors.blue : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
