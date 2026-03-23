import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';
import '../widgets/app_bottom_navigation.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  static const List<_StaffMember> _staffMembers = [
    _StaffMember(
      name: 'Philip Hartman',
      role: 'Client Manager',
      email: 'socuf@mailinator.com',
      lastLogin: '04 Mar 2026, 12:20 PM',
      isActive: true,
      accentColor: Color(0xFF2563EB),
    ),
    _StaffMember(
      name: 'Sarah Jenkins',
      role: 'Admin',
      email: 's.jenkins@technofra.com',
      lastLogin: '05 Mar 2026, 09:15 AM',
      isActive: true,
      accentColor: Color(0xFF0F766E),
    ),
    _StaffMember(
      name: 'Mike Ross',
      role: 'Operations Staff',
      email: 'm.ross@technofra.com',
      lastLogin: '01 Mar 2026, 04:45 PM',
      isActive: false,
      accentColor: Color(0xFFEA580C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 360;
    final horizontalPadding = compact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      bottomNavigationBar: _AppProfileNavigation(
        onChanged: (index) {
          if (index == 4) {
            Get.toNamed(AppRoutes.profile);
            return;
          }
          _handleBottomNavigation(index);
        },
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEEF5FB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(compact: compact),
                    SizedBox(height: compact ? 18 : 20),
                    _SearchBar(compact: compact),
                    SizedBox(height: compact ? 14 : 16),
                    _AddStaffButton(compact: compact),
                    SizedBox(height: compact ? 16 : 18),
                    _SectionHeader(compact: compact),
                    SizedBox(height: compact ? 14 : 16),
                    ..._staffMembers.map(
                      (member) => Padding(
                        padding: EdgeInsets.only(bottom: compact ? 12 : 14),
                        child: _StaffCard(member: member, compact: compact),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: Get.back,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF162033),
                  fontSize: compact ? 22 : 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Manage team members and workspace access',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const _CircleIconButton(icon: Icons.notifications_none_rounded),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
          hintText: 'Search staff members...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF94A3B8),
            fontSize: compact ? 13 : 14,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: compact ? 17 : 19),
      decoration: BoxDecoration(
        color: const Color(0xFF1D6FEA),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221D6FEA),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, color: Colors.white, size: compact ? 24 : 26),
          const SizedBox(width: 10),
          Text(
            'Add New Staff',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: compact ? 16 : 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Current team members',
            style: GoogleFonts.poppins(
              color: const Color(0xFF162033),
              fontSize: compact ? 17 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '3 active records',
          style: GoogleFonts.poppins(
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
  const _StaffCard({required this.member, required this.compact});

  final _StaffMember member;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final statusBackground = member.isActive
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFF1F5F9);
    final statusColor = member.isActive
        ? const Color(0xFF166534)
        : const Color(0xFF64748B);

    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.staffDetail),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 16 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, 10),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF162033),
                          fontSize: compact ? 15 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: member.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          member.role,
                          style: GoogleFonts.poppins(
                            color: member.accentColor,
                            fontSize: 11,
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
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 14 : 16),
            _InfoRow(
              icon: Icons.email_outlined,
              text: member.email,
              compact: compact,
            ),
            SizedBox(height: compact ? 10 : 12),
            _InfoRow(
              icon: Icons.schedule_rounded,
              text: 'Last login: ${member.lastLogin}',
              compact: compact,
            ),
            SizedBox(height: compact ? 14 : 16),
            const Divider(height: 1, color: Color(0xFFEAF0F6)),
            SizedBox(height: compact ? 12 : 14),
            Row(
              children: [
                Expanded(child: _CardAction(icon: Icons.remove_red_eye_outlined, onTap: () => Get.toNamed(AppRoutes.staffDetail))),
                _ActionDivider(),
                Expanded(child: _CardAction(icon: Icons.edit_outlined, onTap: () {})),
                _ActionDivider(),
                Expanded(child: _CardAction(icon: Icons.mail_outline_rounded, onTap: () {})),
                _ActionDivider(),
                Expanded(child: _CardAction(icon: Icons.delete_outline_rounded, onTap: () {})),
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

  final _StaffMember member;
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

    return Container(
      height: compact ? 52 : 56,
      width: compact ? 52 : 56,
      decoration: BoxDecoration(
        color: member.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          color: member.accentColor,
          fontSize: compact ? 16 : 17,
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
        Icon(icon, color: const Color(0xFF94A3B8), size: compact ? 20 : 21),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: const Color(0xFF475569),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xFF64748B), size: 24),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: const Color(0xFFEAF0F6));
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: const Color(0xFF475569)),
        ),
      ),
    );
  }
}

class _AppProfileNavigation extends StatelessWidget {
  const _AppProfileNavigation({required this.onChanged});

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return MagicBottomNavigation(
      items: const [
        MagicNavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
        MagicNavItem(label: 'Leads', icon: Icons.person_outline_rounded),
        MagicNavItem(label: 'Projects', icon: Icons.assignment_rounded),
        MagicNavItem(label: 'Tasks', icon: Icons.check_circle_outline_rounded),
        MagicNavItem(label: 'Profile', icon: Icons.person_rounded),
      ],
      initialIndex: 4,
      onChanged: onChanged,
    );
  }
}

class _StaffMember {
  const _StaffMember({
    required this.name,
    required this.role,
    required this.email,
    required this.lastLogin,
    required this.isActive,
    required this.accentColor,
  });

  final String name;
  final String role;
  final String email;
  final String lastLogin;
  final bool isActive;
  final Color accentColor;
}

void _handleBottomNavigation(int index) {
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
}
