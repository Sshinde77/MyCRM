import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';
import '../widgets/app_bottom_navigation.dart';

class LeadsScreen extends StatelessWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D6FEA);
    const Color lightBlue = Color(0xFFE3F2FD);
    const Color textDark = Color(0xFF1E2A3B);
    const Color textLight = Color(0xFF76839A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: MagicBottomNavigation(
        items: const [
          MagicNavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
          MagicNavItem(label: 'Leads', icon: Icons.person_outline_rounded),
          MagicNavItem(label: 'Projects', icon: Icons.assignment_rounded),
          MagicNavItem(label: 'Tasks', icon: Icons.check_circle_outline_rounded),
          MagicNavItem(label: 'Profile', icon: Icons.person_rounded),
        ],
        initialIndex: 1,
        onChanged: (index) {
          if (index == 1) return;
          if (index == 0) Get.toNamed(AppRoutes.dashboard);
          if (index == 2) Get.toNamed(AppRoutes.projects);
          if (index == 3) Get.toNamed(AppRoutes.tasks);
          if (index == 4) Get.toNamed(AppRoutes.profile);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=shubham'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leads',
                          style: GoogleFonts.poppins(
                            color: textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Enterprise Dashboard',
                          style: GoogleFonts.poppins(
                            color: textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Stack(
                      children: [
                        Icon(Icons.notifications_none_rounded, color: primaryBlue),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Total Leads',
                      value: '1,240',
                      percentage: '+12%',
                      icon: Icons.groups_outlined,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      label: 'New Leads',
                      value: '84',
                      percentage: '+5%',
                      icon: Icons.new_label_outlined,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search leads by name or ID...',
                    hintStyle: GoogleFonts.poppins(color: textLight, fontSize: 14),
                    icon: const Icon(Icons.search, color: textLight),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('Excel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text('Add New Lead'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2CB1FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Leads Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT LEADS',
                    style: GoogleFonts.poppins(
                      color: textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: GoogleFonts.poppins(
                            color: primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: primaryBlue),
                      ],
                    ),
                  ),
                ],
              ),

              // Lead Cards
              _LeadCard(
                id: '#LD-9928',
                name: 'Alex Sterling',
                company: 'Quantum Solutions',
                amount: '₹12,500',
                status: 'NEGOTIATION',
                email: 'alex.s@quantum.com',
                phone: '+1 234 567 890',
                date: 'Oct 24, 2023',
                assignedTo: 'John Doe',
                statusColor: const Color(0xFFE1F5FE),
                statusTextColor: const Color(0xFF0288D1),
              ),
              const SizedBox(height: 16),
              _LeadCard(
                id: '#LD-9930',
                name: 'Sarah Chen',
                company: 'Apex Dynamics',
                amount: '₹8,200',
                status: 'INITIAL CONTACT',
                email: 'sarah.c@apexdyn.io',
                phone: '+1 987 654 321',
                date: 'Oct 25, 2023',
                assignedTo: 'John Doe',
                statusColor: const Color(0xFFFFF8E1),
                statusTextColor: const Color(0xFFFFA000),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String percentage;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.percentage,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(0xFF33A1FF), size: 24),
              Text(
                percentage,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF76839A),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E2A3B),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final String id;
  final String name;
  final String company;
  final String amount;
  final String status;
  final String email;
  final String phone;
  final String date;
  final String assignedTo;
  final Color statusColor;
  final Color statusTextColor;

  const _LeadCard({
    required this.id,
    required this.name,
    required this.company,
    required this.amount,
    required this.status,
    required this.email,
    required this.phone,
    required this.date,
    required this.assignedTo,
    required this.statusColor,
    required this.statusTextColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color textLight = Color(0xFF76839A);
    const Color textDark = Color(0xFF1E2A3B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2CB1FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      company,
                      style: GoogleFonts.poppins(
                        color: textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2CB1FF),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(
                        color: statusTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _IconInfoRow(icon: Icons.mail_outline_rounded, text: email),
              ),
              Expanded(
                child: _IconInfoRow(icon: Icons.share_outlined, text: 'LinkedIn'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _IconInfoRow(icon: Icons.call_outlined, text: phone),
              ),
              Expanded(
                child: _IconInfoRow(icon: Icons.calendar_today_outlined, text: date),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage('https://i.pravatar.cc/100?u=john'),
              ),
              const SizedBox(width: 8),
              Text(
                'Assigned: ',
                style: GoogleFonts.poppins(
                  color: textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                assignedTo,
                style: GoogleFonts.poppins(
                  color: textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _ActionIcon(icon: Icons.visibility_outlined),
              const SizedBox(width: 12),
              _ActionIcon(icon: Icons.edit_outlined),
              const SizedBox(width: 12),
              _ActionIcon(icon: Icons.delete_outline_rounded, color: Colors.red.shade400),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ActionIcon({required this.icon, this.color = const Color(0xFF64748B)});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 18, color: color);
  }
}
