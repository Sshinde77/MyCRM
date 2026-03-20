import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../widgets/app_bottom_navigation.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      bottomNavigationBar: MagicBottomNavigation(
        items: const [
          MagicNavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
          MagicNavItem(label: 'Leads', icon: Icons.person_outline_rounded),
          MagicNavItem(label: 'Projects', icon: Icons.assignment_rounded),
          MagicNavItem(label: 'Tasks', icon: Icons.check_circle_outline_rounded),
          MagicNavItem(label: 'Profile', icon: Icons.person_rounded),
        ],
        initialIndex: 4,
        onChanged: (index) {
          if (index == 0) {
            Get.toNamed(AppRoutes.dashboard);
          } else if (index == 1) {
            Get.toNamed(AppRoutes.leads);
          } else if (index == 2) {
            Get.toNamed(AppRoutes.projects);
          } else if (index == 3) {
            Get.toNamed(AppRoutes.tasks);
          } else if (index == 4) {
            Get.toNamed(AppRoutes.profile);
          }
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Clients",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.notifications_none, size: 26),
                      const SizedBox(width: 12),
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            NetworkImage("https://i.pravatar.cc/150?img=5"),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 20),

              /// STATS
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      title: "Total Clients",
                      value: "1,284",
                      percent: "+5.2%",
                      icon: Icons.people,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: "Active",
                      value: "942",
                      percent: "+12%",
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// SEARCH
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
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Text(
                            "Search clients...",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _circleIcon(Icons.tune),
                ],
              ),

              const SizedBox(height: 16),

              /// BUTTON
              Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    "+ Add New Client",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// HEADER ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "RECENTLY UPDATED",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "View All",
                    style: TextStyle(color: Colors.blue),
                  )
                ],
              ),

              const SizedBox(height: 10),

              /// LIST
              Expanded(
                child: ListView(
                  children: const [
                    _ClientCard(
                      name: "Acme Corporation",
                      role: "CEO • Jane Doe",
                      email: "j.doe@acmecorp.com",
                      industry: "Technology & Software",
                      website: "www.acmecorp.com",
                      active: true,
                    ),
                    _ClientCard(
                      name: "Stellar Retail Group",
                      role: "COO • Mark Peterson",
                      email: "m.pete@stellar.co",
                      industry: "E-commerce & Retail",
                      website: "www.stellar.co",
                      active: false,
                    ),
                    _ClientCard(
                      name: "NexGen Logistics",
                      role: "Manager • Sarah Lee",
                      email: "slee@nexgen.io",
                      industry: "Supply Chain",
                      website: "www.nexgen.io",
                      active: true,
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

/// ================= STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title, value, percent;
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(percent),
              )
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
          Text(title, style: const TextStyle(color: Colors.grey))
        ],
      ),
    );
  }
}

/// ================= CLIENT CARD =================
class _ClientCard extends StatelessWidget {
  final String name, role, email, industry, website;
  final bool active;

  const _ClientCard({
    required this.name,
    required this.role,
    required this.email,
    required this.industry,
    required this.website,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = active ? Colors.green : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  active ? "ACTIVE" : "INACTIVE",
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),

          const SizedBox(height: 12),

          _infoRow(Icons.email, email),
          _infoRow(Icons.business, industry),
          _infoRow(Icons.link, website, isLink: true),

          const Divider(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Icon(Icons.remove_red_eye, color: Colors.grey),
              SizedBox(width: 16),
              Icon(Icons.edit, color: Colors.grey),
              SizedBox(width: 16),
              Icon(Icons.delete, color: Colors.grey),
            ],
          )
        ],
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
          Text(
            text,
            style: TextStyle(
              color: isLink ? Colors.blue : Colors.black87,
            ),
          )
        ],
      ),
    );
  }
}
