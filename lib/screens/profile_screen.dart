import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';
import '../widgets/app_bottom_navigation.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const List<_ProfileAction> _actions = [
    _ProfileAction(
      title: 'Personal Information',
      subtitle: 'View and update your account details.',
      icon: Icons.badge_outlined,
      routeName: AppRoutes.personalInformation,
      accentColor: Color(0xFF1D6FEA),
    ),
    _ProfileAction(
      title: 'Renewal Master',
      subtitle: 'Track contracts, reminders, and renewals.',
      icon: Icons.autorenew_rounded,
      routeName: AppRoutes.renewalMaster,
      accentColor: Color(0xFF0F766E),
    ),
    _ProfileAction(
      title: 'Leads',
      subtitle: 'Open the main leads dashboard.',
      icon: Icons.person_outline_rounded,
      routeName: AppRoutes.leads,
      accentColor: Color(0xFF7C3AED),
    ),
    _ProfileAction(
      title: 'Raise Issue',
      subtitle: 'Create and review support requests.',
      icon: Icons.report_gmailerrorred_rounded,
      routeName: AppRoutes.raiseIssue,
      accentColor: Color(0xFFDC2626),
    ),
    _ProfileAction(
      title: 'Staff',
      subtitle: 'Manage team members and responsibilities.',
      icon: Icons.groups_rounded,
      routeName: AppRoutes.staff,
      accentColor: Color(0xFFEA580C),
    ),
    _ProfileAction(
      title: 'Clients',
      subtitle: 'Jump into your client workspace.',
      icon: Icons.apartment_rounded,
      routeName: AppRoutes.clients,
      accentColor: Color(0xFF2563EB),
    ),
    _ProfileAction(
      title: 'Access Control',
      subtitle: 'Manage roles, permissions, and visibility.',
      icon: Icons.lock_outline_rounded,
      routeName: AppRoutes.accessControl,
      accentColor: Color(0xFF475569),
    ),
    _ProfileAction(
      title: 'Settings',
      subtitle: 'Adjust app preferences and notifications.',
      icon: Icons.settings_outlined,
      routeName: AppRoutes.settings,
      accentColor: Color(0xFF0891B2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      bottomNavigationBar: _AppProfileNavigation(
        onChanged: (index) {
          if (index == 4) return;
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(actionsCount: _actions.length),
                    const SizedBox(height: 18),
                    const _ProfileHeroCard(),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 380;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _actions.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isCompact ? 1 : 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: isCompact ? 2.15 : 0.94,
                          ),
                          itemBuilder: (context, index) {
                            final action = _actions[index];
                            return _ProfileActionCard(action: action);
                          },
                        );
                      },
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

class ProfileSectionScreen extends StatelessWidget {
  const ProfileSectionScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: Get.back,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF162033),
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 58,
                            width: 58,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(icon, color: accentColor, size: 28),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF162033),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'This section is ready for the next workflow or form screen.',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF475569),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.actionsCount});

  final int actionsCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF162033),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$actionsCount quick actions for your workspace',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
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

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF153A63), Color(0xFF1D6FEA)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x201D6FEA),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workspace Control Center',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open client tools, issue reporting, renewal tracking, and account settings from one place.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFD9E7FF),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({required this.action});

  final _ProfileAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(action.routeName),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
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
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: action.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(action.icon, color: action.accentColor, size: 24),
              ),
              const Spacer(),
              Text(
                action.title,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF162033),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _ProfileAction {
  const _ProfileAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeName,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;
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
