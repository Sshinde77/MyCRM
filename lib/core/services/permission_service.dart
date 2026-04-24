import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class AppPermission {
  static const viewCalendar = 'view_calendar';
  static const manageCalendar = 'manage_calendar';
  static const viewDashboard = 'view_dashboard';
  static const viewDashboardWelcome = 'view_dashboard_welcome';
  static const viewRenewals = 'view_renewals';
  static const createRenewals = 'create_renewals';
  static const editRenewals = 'edit_renewals';
  static const deleteRenewals = 'delete_renewals';
  static const viewLeads = 'view_leads';
  static const createLeads = 'create_leads';
  static const editLeads = 'edit_leads';
  static const deleteLeads = 'delete_leads';
  static const viewProjects = 'view_projects';
  static const createProjects = 'create_projects';
  static const editProjects = 'edit_projects';
  static const deleteProjects = 'delete_projects';
  static const viewTasks = 'view_tasks';
  static const createTasks = 'create_tasks';
  static const editTasks = 'edit_tasks';
  static const deleteTasks = 'delete_tasks';
  static const viewRaiseIssue = 'view_raise_issue';
  static const createRaiseIssue = 'create_raise_issue';
  static const editRaiseIssue = 'edit_raise_issue';
  static const deleteRaiseIssue = 'delete_raise_issue';
  static const viewClients = 'view_clients';
  static const createClients = 'create_clients';
  static const editClients = 'edit_clients';
  static const deleteClients = 'delete_clients';
  static const viewStaff = 'view_staff';
  static const createStaff = 'create_staff';
  static const editStaff = 'edit_staff';
  static const deleteStaff = 'delete_staff';
  static const viewRoles = 'view_roles';
  static const viewPermissions = 'view_permissions';
  static const viewServices = 'view_services';
  static const viewVendors = 'view_vendors';
  static const manageSettings = 'manage_settings';
  static const viewGeneralSettings = 'view_general_settings';
}

class PermissionService {
  PermissionService._();

  static UserModel? _cachedUser;
  static Future<UserModel?>? _userLoadFuture;

  static Future<UserModel?> getCurrentUser() async {
    if (_cachedUser != null) {
      return _cachedUser;
    }
    final inFlight = _userLoadFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final loader = ApiService.instance.getStoredUser();
    _userLoadFuture = loader;
    try {
      final user = await loader;
      _cachedUser = user;
      return user;
    } finally {
      if (identical(_userLoadFuture, loader)) {
        _userLoadFuture = null;
      }
    }
  }

  static void setCurrentUser(UserModel? user) {
    if (user != null &&
        user.permissions.isEmpty &&
        _cachedUser != null &&
        _cachedUser!.id == user.id &&
        _cachedUser!.permissions.isNotEmpty) {
      _cachedUser = user.copyWith(permissions: _cachedUser!.permissions);
      _userLoadFuture = null;
      return;
    }
    _cachedUser = user;
    _userLoadFuture = null;
  }

  static void clearCachedUser() {
    _cachedUser = null;
    _userLoadFuture = null;
  }

  static Future<bool> has(String permission) async {
    final user = await getCurrentUser();
    return userHas(user, permission);
  }

  static Future<bool> canOpenRoute(String routeName) async {
    final user = await getCurrentUser();
    return canOpenRouteForUser(user, routeName);
  }

  static Future<String> firstAllowedRoute() async {
    final user = await getCurrentUser();
    return firstAllowedRouteForUser(user);
  }

  static String firstAllowedRouteForUser(UserModel? user) {
    for (final routeName in const [
      AppRoutes.dashboard,
      AppRoutes.projects,
      AppRoutes.tasks,
      AppRoutes.leads,
      AppRoutes.raiseIssue,
      AppRoutes.clients,
      AppRoutes.staff,
      AppRoutes.renewalMaster,
      AppRoutes.settings,
    ]) {
      if (canOpenRouteForUser(user, routeName)) {
        return routeName;
      }
    }

    return AppRoutes.profile;
  }

  static bool canOpenRouteForUser(UserModel? user, String routeName) {
    if (routeName == AppRoutes.dashboard) {
      return userHasAny(user, const [
        AppPermission.viewDashboard,
        AppPermission.viewDashboardWelcome,
      ]);
    }

    final requiredPermission = routePermission(routeName);
    if (requiredPermission == null) {
      return true;
    }
    return userHas(user, requiredPermission);
  }

  static bool userHasAny(UserModel? user, List<String> permissions) {
    for (final permission in permissions) {
      if (userHas(user, permission)) {
        return true;
      }
    }
    return false;
  }

  static bool userHas(UserModel? user, String permission) {
    if (user == null) {
      return false;
    }

    final role = (user.role ?? '').trim().toLowerCase();
    if (role == 'super' ||
        role == 'super-admin' ||
        role == 'super admin' ||
        role == 'admin') {
      return true;
    }

    final normalizedPermission = permission.trim().toLowerCase();
    if (normalizedPermission.isEmpty) {
      return false;
    }

    return user.permissions
        .map((entry) => entry.trim().toLowerCase())
        .where((entry) => entry.isNotEmpty)
        .contains(normalizedPermission);
  }

  static String? routePermission(String routeName) {
    switch (routeName) {
      case AppRoutes.dashboard:
        return AppPermission.viewDashboard;
      case AppRoutes.tasks:
        return AppPermission.viewTasks;
      case AppRoutes.editTask:
        return AppPermission.editTasks;
      case AppRoutes.leads:
      case AppRoutes.leadDetail:
        return AppPermission.viewLeads;
      case AppRoutes.addLead:
        return AppPermission.createLeads;
      case AppRoutes.projects:
      case AppRoutes.projectDetail:
        return AppPermission.viewProjects;
      case AppRoutes.addProject:
        return AppPermission.createProjects;
      case AppRoutes.renewalMaster:
      case AppRoutes.clientRenewal:
      case AppRoutes.vendorRenewal:
      case AppRoutes.clientRenewalDetail:
      case AppRoutes.vendorRenewalDetail:
      case AppRoutes.renewalClient:
      case AppRoutes.renewalVendor:
      case AppRoutes.dashboardRenewals:
        return AppPermission.viewRenewals;
      case AppRoutes.raiseIssue:
      case AppRoutes.issueDetail:
        return AppPermission.viewRaiseIssue;
      case AppRoutes.staff:
      case AppRoutes.staffDetail:
        return AppPermission.viewStaff;
      case AppRoutes.addStaff:
        return AppPermission.createStaff;
      case AppRoutes.clients:
      case AppRoutes.clientDetail:
        return AppPermission.viewClients;
      case AppRoutes.addClient:
        return AppPermission.createClients;
      case AppRoutes.accessControl:
        return AppPermission.viewRoles;
      case AppRoutes.settings:
        return AppPermission.manageSettings;
      default:
        return null;
    }
  }
}

class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.placeholder = const SizedBox.shrink(),
  });

  final String permission;
  final Widget child;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PermissionService.has(permission),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return child;
        }
        return placeholder;
      },
    );
  }
}

class RoutePermissionGate extends StatelessWidget {
  const RoutePermissionGate({
    super.key,
    required this.routeName,
    required this.child,
  });

  final String routeName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PermissionService.canOpenRoute(routeName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return const _PermissionDeniedScreen();
      },
    );
  }
}

class _PermissionDeniedScreen extends StatelessWidget {
  const _PermissionDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Access denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You do not have permission to open this screen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final routeName = await PermissionService.firstAllowedRoute();
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pushReplacementNamed(routeName);
                },
                child: const Text('Go to my workspace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
