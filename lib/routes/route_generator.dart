import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_routes.dart';
import '../providers/lead_detail_provider.dart';
import '../providers/lead_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/clients.dart';
import '../screens/client_detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/biometric_gate_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/add_project_screen.dart';
import '../screens/project_detail_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/task.dart';
import '../screens/create_task_screen.dart';
import '../screens/add_lead_screen.dart';
import '../screens/leads_screen.dart';
import '../screens/lead_detail_screen.dart';
import '../screens/issue_management_screen.dart';
import '../screens/issue_detail_screen.dart';
import '../screens/renewal_master_screen.dart';
import '../screens/client_renewal_screen.dart';
import '../screens/vendor_renewal_screen.dart';
import '../screens/vendor_directory_screen.dart';
import '../screens/dashboard_renewals_screen.dart';
import '../screens/staff_screen.dart';
import '../screens/add_staff_screen.dart';
import '../screens/add_client_screen.dart';
import '../screens/roles_screen.dart';
import '../screens/staff_detail_screen.dart';

/// Builds screens for every named route in the app.
class RouteGenerator {
  /// Returns the matching page for the requested route name.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.biometricGate:
        return MaterialPageRoute(builder: (_) => const BiometricGateScreen());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case AppRoutes.tasks:
        return MaterialPageRoute(
          builder: (_) => TasksScreen(
            staffId: _extractStaffId(settings.arguments),
            staffName: _extractStaffName(settings.arguments),
          ),
        );
      case AppRoutes.editTask:
        return MaterialPageRoute(
          builder: (_) => CreateTaskScreen(
            taskId: _extractTaskId(settings.arguments),
            initialTitle: _extractTaskString(settings.arguments, const [
              'title',
              'name',
              'task_title',
            ]),
            initialDescription: _extractTaskString(settings.arguments, const [
              'description',
              'details',
            ]),
            initialProjectId: _extractTaskString(settings.arguments, const [
              'projectId',
              'project_id',
            ]),
            initialPriority: _extractTaskString(settings.arguments, const [
              'priority',
              'priority_level',
            ]),
            initialStatus: _extractTaskString(settings.arguments, const [
              'status',
              'task_status',
            ]),
            initialStartDate: _extractTaskDate(settings.arguments, const [
              'startDate',
              'start_date',
              'starts_on',
            ]),
            initialDueDate: _extractTaskDate(settings.arguments, const [
              'dueDate',
              'deadline',
              'due_date',
              'end_date',
            ]),
            initialAssigneeIds: _extractTaskStringList(
              settings.arguments,
              const ['assigneeIds'],
            ),
            initialFollowerIds: _extractTaskStringList(
              settings.arguments,
              const ['followerIds'],
            ),
            initialTags: _extractTaskStringList(settings.arguments, const [
              'tags',
            ]),
          ),
        );
      case AppRoutes.leads:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => LeadProvider()..loadLeads(),
            child: const LeadsScreen(),
          ),
        );
      case AppRoutes.addLead:
        return MaterialPageRoute(builder: (_) => const AddLeadScreen());
      case AppRoutes.leadDetail:
        final leadId = _extractLeadId(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => LeadDetailProvider(leadId: leadId)..loadLead(),
            child: const LeadDetailScreen(),
          ),
        );
      case AppRoutes.projects:
        return MaterialPageRoute(
          builder: (_) => ProjectsScreen(
            staffId: _extractStaffId(settings.arguments),
            staffName: _extractStaffName(settings.arguments),
          ),
        );
      case AppRoutes.addProject:
        return MaterialPageRoute(
          builder: (_) => AddProjectScreen(
            projectId: _extractProjectId(settings.arguments),
          ),
        );
      case AppRoutes.projectDetail:
        return MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(
            projectId: _extractProjectId(settings.arguments),
          ),
        );
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case AppRoutes.personalInformation:
        return MaterialPageRoute(
          builder: (_) => const ProfileSectionScreen(
            title: 'Personal Information',
            description:
                'Review your profile details, contact information, and account identity settings.',
            icon: Icons.badge_outlined,
            accentColor: Color(0xFF1D6FEA),
          ),
        );
      case AppRoutes.renewalMaster:
        return MaterialPageRoute(builder: (_) => const RenewalMasterScreen());
      case AppRoutes.clientRenewal:
        return MaterialPageRoute(builder: (_) => const ClientRenewalScreen());
      case AppRoutes.vendorRenewal:
        return MaterialPageRoute(builder: (_) => const VendorRenewalScreen());
      case AppRoutes.renewalClient:
        return MaterialPageRoute(
          builder: (_) => const RenewalDetailScreen(
            title: 'Client',
            description:
                'Open client renewal records and review account-linked renewal information.',
            icon: Icons.apartment_rounded,
            accentColor: Color(0xFF7C3AED),
          ),
        );
      case AppRoutes.renewalVendor:
        return MaterialPageRoute(builder: (_) => const VendorDirectoryScreen());
      case AppRoutes.dashboardRenewals:
        return MaterialPageRoute(
          builder: (_) => const DashboardRenewalsScreen(),
        );
      case AppRoutes.raiseIssue:
        return MaterialPageRoute(builder: (_) => const IssueManagementScreen());
      case AppRoutes.issueDetail:
        return MaterialPageRoute(builder: (_) => const IssueDetailScreen());
      case AppRoutes.staff:
        return MaterialPageRoute(builder: (_) => const StaffScreen());
      case AppRoutes.addStaff:
        return MaterialPageRoute(builder: (_) => const AddStaffScreen());
      case AppRoutes.staffDetail:
        return MaterialPageRoute(
          builder: (_) =>
              StaffDetailScreen(staffId: settings.arguments?.toString()),
        );
      case AppRoutes.clients:
        return MaterialPageRoute(builder: (_) => const ClientsScreen());
      case AppRoutes.addClient:
        return MaterialPageRoute(
          builder: (_) => AddClientScreen(
            clientId: _extractClientId(settings.arguments),
            isEdit: _extractEditFlag(settings.arguments),
          ),
        );
      case AppRoutes.clientDetail:
        return MaterialPageRoute(
          builder: (_) => ClientDetailScreen(
            clientId: _extractClientId(settings.arguments),
          ),
        );
      case AppRoutes.accessControl:
        return MaterialPageRoute(builder: (_) => const RolesScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const ProfileSectionScreen(
            title: 'Settings',
            description:
                'Configure preferences, app behavior, and notification options for your account.',
            icon: Icons.settings_outlined,
            accentColor: Color(0xFF0891B2),
          ),
        );
      default:
        return _errorRoute();
    }
  }

  static String? _extractClientId(dynamic args) {
    if (args == null) return null;
    if (args is String) return args;
    if (args is int) return args.toString();
    if (args is Map) {
      final raw = args['id'] ?? args['clientId'] ?? args['client_id'];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        return raw.toString();
      }
    }
    return null;
  }

  static bool _extractEditFlag(dynamic args) {
    if (args is Map) {
      final rawEdit = args['isEdit'];
      return rawEdit == true || rawEdit == 'true' || rawEdit == 1;
    }
    return false;
  }

  static String _extractLeadId(dynamic args) {
    if (args == null) return '';
    if (args is String) return args;
    if (args is int) return args.toString();
    if (args is Map) {
      final raw = args['id'] ?? args['leadId'] ?? args['lead_id'];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        return raw.toString();
      }
    }
    return '';
  }

  static String? _extractProjectId(dynamic args) {
    if (args == null) return null;
    if (args is String) return args;
    if (args is int) return args.toString();
    if (args is Map) {
      final raw = args['id'] ?? args['projectId'] ?? args['project_id'];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        return raw.toString();
      }
    }
    return null;
  }

  static String? _extractTaskId(dynamic args) {
    return _extractTaskString(args, const ['id', 'taskId', 'task_id']);
  }

  static String? _extractStaffId(dynamic args) {
    if (args == null) return null;
    if (args is String) {
      final normalized = args.trim();
      return normalized.isEmpty ? null : normalized;
    }
    if (args is int) {
      return args.toString();
    }
    if (args is Map) {
      final raw =
          args['staffId'] ??
          args['staff_id'] ??
          args['user_id'] ??
          args['employee_id'] ??
          args['id'];
      if (raw == null) return null;
      final normalized = raw.toString().trim();
      return normalized.isEmpty || normalized.toLowerCase() == 'null'
          ? null
          : normalized;
    }
    return null;
  }

  static String? _extractStaffName(dynamic args) {
    if (args == null) return null;
    if (args is Map) {
      final raw =
          args['staffName'] ??
          args['staff_name'] ??
          args['employee_name'] ??
          args['name'];
      if (raw == null) return null;
      final normalized = raw.toString().trim();
      return normalized.isEmpty || normalized.toLowerCase() == 'null'
          ? null
          : normalized;
    }
    return null;
  }

  static String? _extractTaskString(dynamic args, List<String> keys) {
    if (args is! Map) return null;
    for (final key in keys) {
      final value = args[key];
      if (value == null) {
        continue;
      }
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return null;
  }

  static DateTime? _extractTaskDate(dynamic args, List<String> keys) {
    final raw = _extractTaskString(args, keys);
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  static List<String> _extractTaskStringList(dynamic args, List<String> keys) {
    if (args is! Map) return const [];
    for (final key in keys) {
      final value = args[key];
      if (value is! List) {
        continue;
      }

      return value
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty && entry.toLowerCase() != 'null')
          .toList();
    }
    return const [];
  }

  /// Generic fallback page for unknown routes.
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: const Center(child: Text('Page not found')),
        );
      },
    );
  }
}
