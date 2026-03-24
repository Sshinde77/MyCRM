import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/app_routes.dart';
import '../widgets/app_bottom_navigation.dart';

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF7FAFF);
    const textMain = Color(0xFF141C33);
    const textSec = Color(0xFF74839D);
    const blue = Color(0xFF1769F3);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Client Details',
          style: GoogleFonts.poppins(
            color: textMain,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: textSec),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: textSec),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: MagicBottomNavigation(
        items: const [
          MagicNavItem(label: 'Home', icon: Icons.home_outlined),
          MagicNavItem(label: 'Clients', icon: Icons.people_outline),
          MagicNavItem(label: 'Projects', icon: Icons.folder_open_outlined),
          MagicNavItem(label: 'Tasks', icon: Icons.check_box_outlined),
          MagicNavItem(label: 'More', icon: Icons.menu_rounded),
        ],
        initialIndex: 1,
        onChanged: (index) {
          if (index == 0) Get.toNamed(AppRoutes.dashboard);
          if (index == 1) Get.toNamed(AppRoutes.clients);
          if (index == 2) Get.toNamed(AppRoutes.projects);
          if (index == 3) Get.toNamed(AppRoutes.tasks);
          if (index == 4) Get.toNamed(AppRoutes.profile);
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Section
                  _ProfileHeader(),
                  const SizedBox(height: 20),
                  
                  // Quick Stats
                  const Row(
                    children: [
                      Expanded(child: _StatBox(icon: Icons.folder_open, value: '1', label: 'Total Projects', color: Color(0xFFE0E7FF), iconColor: Colors.blue)),
                      SizedBox(width: 12),
                      Expanded(child: _StatBox(icon: Icons.assignment_outlined, value: '1', label: 'Active Tasks', color: Color(0xFFFEF3C7), iconColor: Colors.orange)),
                      SizedBox(width: 12),
                      Expanded(child: _StatBox(icon: Icons.error_outline, value: '1', label: 'Open Issues', color: Color(0xFFFEE2E2), iconColor: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Client Information
                  const _ClientInfoCard(),
                  const SizedBox(height: 20),

                  // Projects
                  const _SectionHeader(title: 'Projects', showViewAll: true),
                  const SizedBox(height: 12),
                  const _ProjectCard(),
                  const SizedBox(height: 20),

                  // Recent Tasks
                  const _SectionHeader(title: 'Recent Tasks'),
                  const SizedBox(height: 12),
                  const _TaskCard(),
                  const SizedBox(height: 20),

                  // Open Issues
                  const _SectionHeader(title: 'Open Issues', count: 1),
                  const SizedBox(height: 12),
                  const _IssueCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Arnav',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF141C33),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ACTIVE CLIENT',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Test Company',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF74839D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.email_outlined, 'vkpants@gmail.com'),
          _infoRow(Icons.phone_outlined, '8080721003'),
          _infoRow(Icons.language_outlined, 'technofra.com/oceanic', isLink: true),
          _infoRow(Icons.person_outline, 'Unassigned Manager'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF74839D)),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isLink ? const Color(0xFF1769F3) : const Color(0xFF141C33),
              fontWeight: isLink ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color iconColor;

  const _StatBox({required this.icon, required this.value, required this.label, required this.color, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141C33),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFF74839D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientInfoCard extends StatelessWidget {
  const _ClientInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Client Information',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141C33),
                ),
              ),
              const Icon(Icons.info_outline, color: Color(0xFF74839D), size: 20),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: _InfoField(label: 'CONTACT PERSON', value: 'Arnav Pants')),
              Expanded(child: _InfoField(label: 'CLIENT TYPE', value: 'Enterprise')),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _InfoField(label: 'INDUSTRY', value: 'Technology')),
              Expanded(child: _InfoField(label: 'PRIORITY LEVEL', value: 'High', valueColor: Colors.red)),
            ],
          ),
          const Divider(height: 32),
          const _InfoField(
            label: 'ADDRESS DETAILS',
            value: 'Sector 18, Electronic City\nNoida, Uttar Pradesh\nIndia - 201301',
          ),
          const Divider(height: 32),
          const Row(
            children: [
              Expanded(child: _InfoField(label: 'BILLING TYPE', value: 'Monthly Retainer')),
              Expanded(child: _InfoField(label: 'DUE DAYS', value: '15 Days')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoField({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF74839D),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF141C33),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showViewAll;
  final int? count;

  const _SectionHeader({required this.title, this.showViewAll = false, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141C33),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        if (showViewAll)
          Text(
            'View All',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1769F3),
            ),
          ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Laith Barrera',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141C33),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'In Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1769F3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF74839D)),
              const SizedBox(width: 4),
              Text('01 Jan', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF74839D))),
              const SizedBox(width: 12),
              const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF74839D)),
              const SizedBox(width: 4),
              Text('30 Jun', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF74839D))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'HIGH PRIORITY',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                 Get.toNamed(AppRoutes.projectDetail);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'View Project Details',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF141C33),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ut voluptatem conseq',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF141C33),
                      ),
                    ),
                    Text(
                      'Project: Laith Barrera',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF74839D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Not Started',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF74839D),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Due: 24 May',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.toNamed(AppRoutes.issueDetail);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bug_report_outlined, size: 20, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Issue #1',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF141C33),
                            ),
                          ),
                          Text(
                            'OPEN',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Laith Barrera • Web App Interface',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF74839D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The navigation bar on mobile view gets cut off when scrolling horizontally...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF74839D),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CRITICAL',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ),
                Text(
                  'Added: 18 May',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF74839D),
                    fontWeight: FontWeight.w500,
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
