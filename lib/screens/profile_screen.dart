import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/screens/book_a_call.dart';
import 'package:mycrm/screens/google_ads_screen.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../screens/to_do_list.dart' as to_do;
import '../widgets/app_bottom_navigation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<_ProfileAction> _actions = [
    // _ProfileAction(
    //   title: 'Personal Information',
    //   subtitle: 'View & update your personal details',
    //   icon: Icons.badge_outlined,
    //   routeName: AppRoutes.personalInformation,
    //   accentColor: Color(0xFF1D6FEA),
    // ),
    _ProfileAction(
      title: 'Renewal Master',
      subtitle: 'Manage renewals and reminders',
      icon: Icons.autorenew_rounded,
      routeName: AppRoutes.renewalMaster,
      permission: AppPermission.viewRenewals,
      accentColor: Color(0xFF0F766E),
    ),
    // _ProfileAction(
    //   title: 'Leads',
    //   subtitle: 'Manage and track your leads',
    //   icon: Icons.person_outline_rounded,
    //   routeName: AppRoutes.leads,
    //   permission: AppPermission.viewLeads,
    //   accentColor: Color(0xFF7C3AED),
    // ),
    _ProfileAction(
      title: 'Raise Issue',
      subtitle: 'Report & track issues easily',
      icon: Icons.report_gmailerrorred_rounded,
      routeName: AppRoutes.raiseIssue,
      permission: AppPermission.viewRaiseIssue,
      accentColor: Color(0xFFDC2626),
    ),
    _ProfileAction(
      title: 'Staff',
      subtitle: 'Manage your team members',
      icon: Icons.groups_rounded,
      routeName: AppRoutes.staff,
      permission: AppPermission.viewStaff,
      accentColor: Color(0xFFEA580C),
    ),
    _ProfileAction(
      title: 'Clients',
      subtitle: 'View and manage your clients',
      icon: Icons.apartment_rounded,
      routeName: AppRoutes.clients,
      permission: AppPermission.viewClients,
      accentColor: Color(0xFF2563EB),
    ),
    _ProfileAction(
      title: 'Role',
      subtitle: 'Manage user roles & permissions',
      icon: Icons.person,
      routeName: AppRoutes.accessControl,
      permission: AppPermission.viewRoles,
      accentColor: Color(0xFF475569),
    ),
    _ProfileAction(
      title: 'Book A Call',
      subtitle: 'Schedule a call with our team',
      icon: Icons.phone_in_talk_outlined,
      routeName: '',
      permission: AppPermission.viewBookCalls,
      accentColor: Color(0xFF1D6FEA),
      screenBuilder: BookACallScreen.new,
    ),
    _ProfileAction(
      title: 'Google Ads',
      subtitle: 'Manage your ad campaigns',
      icon: Icons.ads_click_rounded,
      routeName: '',
      permission: AppPermission.viewDigitalMarketingLeads,
      accentColor: Color(0xFF0EA5E9),
      screenBuilder: GoogleAdsScreen.new,
    ),
    _ProfileAction(
      title: 'Settings',
      subtitle: 'App preferences and configuration',
      icon: Icons.settings_outlined,
      routeName: AppRoutes.settings,
      permission: AppPermission.manageSettings,
      accentColor: Color(0xFF0891B2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.profile,
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
          child: LayoutBuilder(
            builder: (context, viewport) {
              final width = viewport.maxWidth;
              final horizontalPadding = width < 360
                  ? 14.0
                  : width < 720
                  ? 20.0
                  : 32.0;
              final contentWidth = width >= 900 ? 920.0 : 520.0;

              return FutureBuilder<List<_ProfileAction>>(
                future: _visibleActions(),
                builder: (context, snapshot) {
                  final actions = snapshot.data ?? const <_ProfileAction>[];

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProfileHeader(actionsCount: actions.length),
                            const SizedBox(height: 14),
                            _QuickStatsCard(actionsCount: actions.length),
                            const SizedBox(height: 16),
                            const _MainMenuHeader(),
                            const SizedBox(height: 10),
                            _ProfileActionsGrid(actions: actions),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<List<_ProfileAction>> _visibleActions() async {
    final visible = <_ProfileAction>[];
    for (final action in _actions) {
      final permission = action.permission;
      if (permission == null || await PermissionService.has(permission)) {
        visible.add(action);
      }
    }
    return visible;
  }
}

class _ProfileActionsGrid extends StatelessWidget {
  const _ProfileActionsGrid({required this.actions});

  final List<_ProfileAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final spacing = maxWidth < 360 ? 10.0 : 12.0;
        final crossAxisCount = maxWidth < 900 ? 2 : 3;
        final cardHeight = maxWidth < 360 ? 100.0 : 108.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _ProfileActionCard(action: action);
          },
        );
      },
    );
  }
}

class _BiometricLoginCard extends StatelessWidget {
  const _BiometricLoginCard({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = controller.biometricEnabled.value;
      final narrow = MediaQuery.of(context).size.width < 360;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EDF5)),
        ),
        child: SwitchListTile(
          value: enabled,
          onChanged: (value) async {
            if (!value) {
              await controller.disableBiometricLogin();
              return;
            }
            await controller.enableBiometricLogin();
          },
          title: Text(
            'Biometric Login',
            style: AppTextStyles.style(
              color: const Color(0xFF153A63),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            enabled
                ? 'Enabled. Unlock MyCRM using fingerprint/face.'
                : 'Enable fingerprint/face unlock for faster sign-in.',
            style: AppTextStyles.style(
              color: const Color(0xFF6B7C8F),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          secondary: Container(
            width: narrow ? 40 : 44,
            height: narrow ? 40 : 44,
            decoration: BoxDecoration(
              color: const Color(0xFF18C6D3).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Color(0xFF18C6D3),
            ),
          ),
          activeThumbColor: const Color(0xFF18C6D3),
          contentPadding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 16),
        ),
      );
    });
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
                            style: AppTextStyles.style(
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
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(icon, color: accentColor, size: 28),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            style: AppTextStyles.style(
                              color: const Color(0xFF162033),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: AppTextStyles.style(
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
                              style: AppTextStyles.style(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: AppTextStyles.style(
                  color: const Color(0xFF162033),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$actionsCount quick actions',
                style: AppTextStyles.style(
                  color: const Color(0xFF64748B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _ProfileHeaderCalendarBadge(date: DateTime.now()),
        const SizedBox(width: 10),
        _CircleIconButton(
          icon: Icons.checklist_rounded,
          onTap: () => Get.to(() => const to_do.ToDoListScreen()),
        ),
      ],
    );
  }
}

class _ProfileHeaderCalendarBadge extends StatelessWidget {
  const _ProfileHeaderCalendarBadge({required this.date});

  final DateTime date;

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 360;
    final day = date.day.toString().padLeft(2, '0');
    final month = _months[date.month - 1];
    final dateLabel = '$day $month ${date.year}';
    final weekdayLabel = _weekdays[date.weekday - 1];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 22 : 24,
            height: compact ? 22 : 24,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF4F46E5),
              size: 14,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: AppTextStyles.style(
                  color: const Color(0xFF4F46E5),
                  fontSize: compact ? 9.8 : 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                weekdayLabel,
                style: AppTextStyles.style(
                  color: const Color(0xFF64748B),
                  fontSize: compact ? 9 : 9.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({required this.actionsCount});

  final int actionsCount;

  @override
  Widget build(BuildContext context) {
    final stats = <_QuickStatItem>[
      _QuickStatItem('Projects', actionsCount.toString(), Icons.work_outline),
      const _QuickStatItem('Leads', '24', Icons.person_outline_rounded),
      const _QuickStatItem('Tasks', '16', Icons.check_circle_outline_rounded),
      const _QuickStatItem('Issues', '08', Icons.shield_outlined),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A52E2), Color(0xFF5E2DCF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332A52E2),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Quick Stats',
                style: AppTextStyles.style(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'This Month',
                      style: AppTextStyles.style(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: stats
                .map(
                  (item) => Expanded(child: _QuickStatTile(item: item)),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickStatTile extends StatelessWidget {
  const _QuickStatTile({required this.item});

  final _QuickStatItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          item.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.style(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.style(
            color: Colors.white.withValues(alpha: 0.86),
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _MainMenuHeader extends StatelessWidget {
  const _MainMenuHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Main Menu',
          style: AppTextStyles.style(
            color: const Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        // Text(
        //   'Customize',
        //   style: AppTextStyles.style(
        //     color: const Color(0xFF64748B),
        //     fontSize: 12,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
        // const SizedBox(width: 4),
        // const Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 16),
      ],
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
        onTap: () {
          final screenBuilder = action.screenBuilder;
          if (screenBuilder != null) {
            Get.to(screenBuilder);
            return;
          }
          Get.toNamed(action.routeName);
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _ProfileActionIcon(action: action, size: 38, iconSize: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileActionTitle(action: action),
                    const SizedBox(height: 3),
                    // Text(
                    //   action.subtitle,
                    //   maxLines: 2,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: AppTextStyles.style(
                    //     color: const Color(0xFF64748B),
                    //     fontSize: 11.5,
                    //     fontWeight: FontWeight.w500,
                    //     height: 1.25,
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActionIcon extends StatelessWidget {
  const _ProfileActionIcon({
    required this.action,
    required this.size,
    required this.iconSize,
  });

  final _ProfileAction action;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: action.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(action.icon, color: action.accentColor, size: iconSize),
    );
  }
}

class _ProfileActionTitle extends StatelessWidget {
  const _ProfileActionTitle({required this.action, this.fontSize = 13});

  final _ProfileAction action;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      action.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.style(
        color: const Color(0xFF162033),
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.25,
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
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: const Color(0xFF475569), size: 20),
        ),
      ),
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
    this.permission,
    this.screenBuilder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;
  final Color accentColor;
  final String? permission;
  final Widget Function()? screenBuilder;
}

class _QuickStatItem {
  const _QuickStatItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}
