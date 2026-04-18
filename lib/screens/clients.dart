import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/client_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<ClientModel>> _clientsFuture;

  @override
  void initState() {
    super.initState();
    _clientsFuture = ApiService.instance.getClientsList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _clientsFuture = ApiService.instance.getClientsList();
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: FutureBuilder<List<ClientModel>>(
          future: _clientsFuture,
          builder: (context, snapshot) {
            final clients = snapshot.data ?? const <ClientModel>[];
            final filteredClients = _filterClients(clients);
            final totalClients = clients.length;
            final activeClients = clients
                .where((client) => client.isActive)
                .length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
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
                          percent: 'API',
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
                            onChanged: (_) => setState(() {}),
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
                  InkWell(
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
                      Text('View All', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _ClientsList(
                      snapshot: snapshot,
                      clients: filteredClients,
                      hasSearch: _searchController.text.trim().isNotEmpty,
                      onRefresh: _reload,
                    ),
                  ),
                ],
              ),
            );
          },
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

class _ClientsList extends StatelessWidget {
  const _ClientsList({
    required this.snapshot,
    required this.clients,
    required this.hasSearch,
    required this.onRefresh,
  });

  final AsyncSnapshot<List<ClientModel>> snapshot;
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
        Get.snackbar(
          'Client deleted',
          'The client has been deleted successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF153A63),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
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

        Get.snackbar(
          'Delete failed',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFB91C1C),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Unable to load clients'),
            const SizedBox(height: 8),
            TextButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (clients.isEmpty) {
      return Center(
        child: Text(
          hasSearch ? 'No matching clients' : 'No clients available',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return _ClientCard(
            id: client.id,
            name: client.name.isNotEmpty ? client.name : 'Client',
            role: client.contactLine,
            email: client.email.isNotEmpty ? client.email : 'No email',
            industry: client.industry.isNotEmpty
                ? client.industry
                : 'No industry',
            website: client.website.isNotEmpty ? client.website : 'No website',
            active: client.isActive,
            onEdit: () {
              Get.toNamed(
                AppRoutes.addClient,
                arguments: {'id': client.id, 'isEdit': true},
              );
            },
            onDelete: () => handleDelete(client.id),
          );
        },
      ),
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
  final String industry;
  final String website;
  final bool active;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientCard({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.industry,
    required this.website,
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
            _infoRow(Icons.business, industry),
            _infoRow(Icons.link, website, isLink: true),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.remove_red_eye, color: Colors.grey),
                const SizedBox(width: 16),
                InkWell(
                  onTap: onEdit,
                  child: const Icon(Icons.edit, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: onDelete,
                  child: const Icon(Icons.delete, color: Colors.grey),
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
