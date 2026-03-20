import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../widgets/app_bottom_navigation.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

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
        initialIndex: 3,
        onChanged: (index) {
          if (index == 3) return;
          if (index == 0) {
            Get.toNamed(AppRoutes.dashboard);
          } else if (index == 1) {
            Get.toNamed(AppRoutes.leads);
          } else if (index == 2) {
            Get.toNamed(AppRoutes.projects);
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Tasks",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Manage your enterprise workflow",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _circleIcon(Icons.calendar_today),
                      const SizedBox(width: 10),
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          "https://i.pravatar.cc/150?img=3",
                        ),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 20),

              /// CARDS
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      title: "Running Tasks",
                      value: "24",
                      percent: "+12%",
                      color: Color(0xFF3B82F6),
                      bgColor: Color(0xFFE7F0FF),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: "Completed",
                      value: "145",
                      percent: "+5%",
                      color: Color(0xFF22C55E),
                      bgColor: Color(0xFFE8F8EE),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// SEARCH + ACTION
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Text(
                            "Search tasks...",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _circleIcon(Icons.tune),
                  const SizedBox(width: 10),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                ],
              ),

              const SizedBox(height: 20),

              /// LIST
              Expanded(
                child: ListView(
                  children: const [
                    _TaskCard(
                      id: "TSK-4829",
                      title: "Mobile UI Refactoring",
                      project: "Project Apollo",
                      date: "Oct 24, 2023",
                      hours: "12.5 hrs",
                      priority: "HIGH PRIORITY",
                      priorityColor: Colors.red,
                      user: "Alex Rivera",
                    ),
                    _TaskCard(
                      id: "TSK-5102",
                      title: "API Authentication Layer",
                      project: "Cloud Migration",
                      date: "Oct 26, 2023",
                      hours: "8.0 hrs",
                      priority: "MEDIUM",
                      priorityColor: Colors.blue,
                      user: "Sarah Jenkins",
                    ),
                    _TaskCard(
                      id: "TSK-3981",
                      title: "Content Localization",
                      project: "Global Launch",
                      date: "Oct 20, 2023",
                      hours: "32.0 hrs",
                      priority: "LOW",
                      priorityColor: Colors.green,
                      user: "Elena Rodriguez",
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
  final Color color, bgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.percent,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(percent, style: TextStyle(color: color)),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(color: color)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: 0.6,
            color: color,
            backgroundColor: color.withOpacity(0.2),
          )
        ],
      ),
    );
  }
}

/// ================= TASK CARD =================
class _TaskCard extends StatelessWidget {
  final String id, title, project, date, hours, priority, user;
  final Color priorityColor;

  const _TaskCard({
    required this.id,
    required this.title,
    required this.project,
    required this.date,
    required this.hours,
    required this.priority,
    required this.priorityColor,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: const TextStyle(color: Colors.grey)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  priority,
                  style: TextStyle(color: priorityColor, fontSize: 12),
                ),
              )
            ],
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            project,
            style: const TextStyle(color: Colors.blue),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(date, style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 20),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(hours, style: const TextStyle(color: Colors.grey)),
            ],
          ),

          const Divider(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 14),
                  const SizedBox(width: 8),
                  Text(user),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.remove_red_eye, color: Colors.grey),
                  SizedBox(width: 10),
                  Icon(Icons.edit, color: Colors.grey),
                  SizedBox(width: 10),
                  Icon(Icons.delete, color: Colors.grey),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
