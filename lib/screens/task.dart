import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';

import '../routes/app_routes.dart';
import '../widgets/app_bottom_navigation.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 360;

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
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
          child: Column(
            children: [
              SizedBox(height: compact ? 8 : 10),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tasks",
                        style: AppTextStyles.style(
                          color: const Color(0xFF111827),
                          fontSize: compact ? 22 : 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      Text(
                        "Manage your enterprise workflow",
                        style: AppTextStyles.style(
                          color: const Color(0xFF6B7280),
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _circleIcon(Icons.calendar_today, compact: compact),
                      SizedBox(width: compact ? 8 : 10),
                      CircleAvatar(
                        radius: compact ? 17 : 18,
                        backgroundImage: NetworkImage(
                          "https://i.pravatar.cc/150?img=3",
                        ),
                      ),
                    ],
                  )
                ],
              ),

              SizedBox(height: compact ? 14 : 16),

              /// CARDS
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: "Running Tasks",
                      value: "24",
                      percent: "+12%",
                      color: Color(0xFF3B82F6),
                      bgColor: Color(0xFFE7F0FF),
                      compact: compact,
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  Expanded(
                    child: _StatCard(
                      title: "Completed",
                      value: "145",
                      percent: "+5%",
                      color: Color(0xFF22C55E),
                      bgColor: Color(0xFFE8F8EE),
                      compact: compact,
                    ),
                  ),
                ],
              ),

              SizedBox(height: compact ? 14 : 16),

              /// SEARCH + ACTION
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: compact ? 42 : 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey, size: 18),
                          SizedBox(width: compact ? 8 : 10),
                          Text(
                            "Search tasks...",
                            style: AppTextStyles.style(
                              color: const Color(0xFF6B7280),
                              fontSize: compact ? 12 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  _circleIcon(Icons.tune, compact: compact),
                  SizedBox(width: compact ? 8 : 10),
                  Container(
                    height: compact ? 42 : 44,
                    width: compact ? 42 : 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: compact ? 20 : 22,
                    ),
                  )
                ],
              ),

              SizedBox(height: compact ? 14 : 16),

              /// LIST
              Expanded(
                child: ListView(
                  children: [
                    _TaskCard(
                      id: "TSK-4829",
                      title: "Mobile UI Refactoring",
                      project: "Project Apollo",
                      date: "Oct 24, 2023",
                      hours: "12.5 hrs",
                      priority: "HIGH PRIORITY",
                      priorityColor: Colors.red,
                      user: "Alex Rivera",
                      compact: compact,
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
                      compact: compact,
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
                      compact: compact,
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

  static Widget _circleIcon(IconData icon, {required bool compact}) {
    return Container(
      height: compact ? 40 : 42,
      width: compact ? 40 : 42,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.grey, size: compact ? 18 : 20),
    );
  }
}

/// ================= STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title, value, percent;
  final Color color, bgColor;
  final bool compact;

  const _StatCard({
    required this.title,
    required this.value,
    required this.percent,
    required this.color,
    required this.bgColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 108 : 116,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              percent,
              style: AppTextStyles.style(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.style(
              fontSize: compact ? 22 : 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.style(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          LinearProgressIndicator(
            value: 0.6,
            color: color,
            backgroundColor: color.withOpacity(0.2),
            minHeight: compact ? 5 : 6,
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
  final bool compact;

  const _TaskCard({
    required this.id,
    required this.title,
    required this.project,
    required this.date,
    required this.hours,
    required this.priority,
    required this.priorityColor,
    required this.user,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 10 : 12),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: AppTextStyles.style(
                  color: Colors.grey,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 10,
                      vertical: compact ? 3 : 4,
                    ),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  priority,
                  style: AppTextStyles.style(
                    color: priorityColor,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            ],
          ),

          SizedBox(height: compact ? 8 : 10),

          Text(
            title,
            style: AppTextStyles.style(
              color: const Color(0xFF111827),
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: compact ? 4 : 6),

          Text(
            project,
            style: AppTextStyles.style(
              color: Colors.blue,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: compact ? 8 : 10),

          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: compact ? 14 : 15,
                color: Colors.grey,
              ),
              SizedBox(width: compact ? 4 : 5),
              Text(
                date,
                style: AppTextStyles.style(
                  color: Colors.grey,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: compact ? 14 : 16),
              Icon(
                Icons.access_time,
                size: compact ? 14 : 15,
                color: Colors.grey,
              ),
              SizedBox(width: compact ? 4 : 5),
              Text(
                hours,
                style: AppTextStyles.style(
                  color: Colors.grey,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          Divider(height: compact ? 16 : 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 14),
                  SizedBox(width: compact ? 6 : 8),
                  Text(
                    user,
                    style: AppTextStyles.style(
                      color: const Color(0xFF111827),
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.remove_red_eye,
                    color: Colors.grey,
                    size: compact ? 18 : 20,
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.editTask);
                    },
                    child: Icon(
                      Icons.edit,
                      color: Colors.grey,
                      size: compact ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  Icon(
                    Icons.delete,
                    color: Colors.grey,
                    size: compact ? 18 : 20,
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
