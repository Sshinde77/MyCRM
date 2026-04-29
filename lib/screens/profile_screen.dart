import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/screens/book_a_call.dart';
import 'package:mycrm/screens/google_ads_screen.dart';

import '../routes/app_routes.dart';
import '../screens/to_do_list.dart' as to_do;
import '../controllers/auth_controller.dart';
import '../widgets/app_bottom_navigation.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authController.logout();
      if (!mounted) {
        return;
      }
      Get.offAllNamed(AppRoutes.login);
      AppSnackbar.show('Logged out', 'You have been signed out successfully.');
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final responseData = error.response?.data;
      String message = 'Unable to logout right now.';

      if (responseData is Map<String, dynamic>) {
        final apiMessage = responseData['message'] ?? responseData['error'];
        if (apiMessage != null && apiMessage.toString().trim().isNotEmpty) {
          message = apiMessage.toString();
        }
      }

      AppSnackbar.show('Logout failed', message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      AppSnackbar.show(
        'Logout failed',
        'Something went wrong while signing out.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  static const List<_ProfileAction> _actions = [
    _ProfileAction(
      title: 'Personal Information',
      icon: Icons.badge_outlined,
      routeName: AppRoutes.personalInformation,
      accentColor: Color(0xFF1D6FEA),
    ),
    _ProfileAction(
      title: 'Renewal Master',
      icon: Icons.autorenew_rounded,
      routeName: AppRoutes.renewalMaster,
      permission: AppPermission.viewRenewals,
      accentColor: Color(0xFF0F766E),
    ),
    _ProfileAction(
      title: 'Leads',
      icon: Icons.person_outline_rounded,
      routeName: AppRoutes.leads,
      permission: AppPermission.viewLeads,
      accentColor: Color(0xFF7C3AED),
    ),
    _ProfileAction(
      title: 'Raise Issue',
      icon: Icons.report_gmailerrorred_rounded,
      routeName: AppRoutes.raiseIssue,
      permission: AppPermission.viewRaiseIssue,
      accentColor: Color(0xFFDC2626),
    ),
    _ProfileAction(
      title: 'Staff',
      icon: Icons.groups_rounded,
      routeName: AppRoutes.staff,
      permission: AppPermission.viewStaff,
      accentColor: Color(0xFFEA580C),
    ),
    _ProfileAction(
      title: 'Clients',
      icon: Icons.apartment_rounded,
      routeName: AppRoutes.clients,
      permission: AppPermission.viewClients,
      accentColor: Color(0xFF2563EB),
    ),
    _ProfileAction(
      title: 'Role',
      icon: Icons.person,
      routeName: AppRoutes.accessControl,
      permission: AppPermission.viewRoles,
      accentColor: Color(0xFF475569),
    ),
    _ProfileAction(
      title: 'Book A Call',
      icon: Icons.phone_in_talk_outlined,
      routeName: '',
      accentColor: Color(0xFF1D6FEA),
      screenBuilder: BookACallScreen.new,
    ),
    _ProfileAction(
      title: 'Google Ads',
      icon: Icons.ads_click_rounded,
      routeName: '',
      accentColor: Color(0xFF0EA5E9),
      screenBuilder: GoogleAdsScreen.new,
    ),
    _ProfileAction(
      title: 'Settings',
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
                            const SizedBox(height: 12),
                            // _BiometricLoginCard(controller: _authController),
                            const SizedBox(height: 12),
                            _ProfileActionsGrid(actions: actions),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: _isLoggingOut ? null : _logout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: Icon(
                                  _isLoggingOut
                                      ? Icons.hourglass_top_rounded
                                      : Icons.logout_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  _isLoggingOut ? 'Logging out...' : 'Logout',
                                  style: AppTextStyles.style(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
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
        final spacing = maxWidth < 360 ? 12.0 : 16.0;
        final crossAxisCount = maxWidth < 340
            ? 1
            : maxWidth < 680
            ? 2
            : maxWidth < 900
            ? 3
            : 4;
        final cardHeight = crossAxisCount == 1
            ? 76.0
            : maxWidth < 360
            ? 98.0
            : 110.0;

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
              // Text(
              //   '$actionsCount quick actions for your workspace',
              //   style: AppTextStyles.style(
              //     color: const Color(0xFF64748B),
              //     fontSize: 13,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
            ],
          ),
        ),
        _CircleIconButton(
          icon: Icons.checklist_rounded,
          onTap: () => Get.to(() => const to_do.ToDoListScreen()),
        ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 150;
          final isListTile = constraints.maxWidth >= 240;
          final iconSize = isNarrow ? 36.0 : 42.0;
          final padding = isNarrow ? 10.0 : 12.0;

          return InkWell(
            onTap: () {
              final screenBuilder = action.screenBuilder;
              if (screenBuilder != null) {
                Get.to(screenBuilder);
                return;
              }
              Get.toNamed(action.routeName);
            },
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: isListTile
                  ? Row(
                      children: [
                        _ProfileActionIcon(
                          action: action,
                          size: iconSize,
                          iconSize: isNarrow ? 18 : 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _ProfileActionTitle(action: action)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileActionIcon(
                          action: action,
                          size: iconSize,
                          iconSize: isNarrow ? 18 : 20,
                        ),
                        const Spacer(),
                        _ProfileActionTitle(
                          action: action,
                          fontSize: isNarrow ? 10.5 : 11.5,
                        ),
                      ],
                    ),
            ),
          );
        },
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
  const _ProfileActionTitle({required this.action, this.fontSize = 13.5});

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
    required this.icon,
    required this.routeName,
    required this.accentColor,
    this.permission,
    this.screenBuilder,
  });

  final String title;
  final IconData icon;
  final String routeName;
  final Color accentColor;
  final String? permission;
  final Widget Function()? screenBuilder;
}

