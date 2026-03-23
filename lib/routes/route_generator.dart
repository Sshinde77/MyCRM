import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../screens/dashboard_screen.dart';
import '../screens/clients.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/task.dart';
import '../screens/leads_screen.dart';
import '../screens/issue_management_screen.dart';
import '../screens/renewal_master_screen.dart';
import '../screens/client_renewal_screen.dart';
import '../screens/vendor_renewal_screen.dart';
import '../screens/staff_screen.dart';
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
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case AppRoutes.tasks:
        return MaterialPageRoute(builder: (_) => const TasksScreen());
      case AppRoutes.leads:
        return MaterialPageRoute(builder: (_) => const LeadsScreen());
      case AppRoutes.projects:
        return MaterialPageRoute(builder: (_) => const ProjectsScreen());
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
        return MaterialPageRoute(
          builder: (_) => const RenewalDetailScreen(
            title: 'Vendor',
            description:
                'Open vendor renewal records and manage vendor-specific renewal workflows.',
            icon: Icons.local_shipping_outlined,
            accentColor: Color(0xFFEA580C),
          ),
        );
      case AppRoutes.raiseIssue:
        return MaterialPageRoute(builder: (_) => const IssueManagementScreen());
      case AppRoutes.staff:
        return MaterialPageRoute(builder: (_) => const StaffScreen());
      case AppRoutes.staffDetail:
        return MaterialPageRoute(builder: (_) => const StaffDetailScreen());
      case AppRoutes.clients:
        return MaterialPageRoute(builder: (_) => const ClientsScreen());
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
