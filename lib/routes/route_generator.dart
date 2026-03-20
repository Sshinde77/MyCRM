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
            description: 'Review your profile details, contact information, and account identity settings.',
            icon: Icons.badge_outlined,
            accentColor: Color(0xFF1D6FEA),
          ),
        );
      case AppRoutes.renewalMaster:
        return MaterialPageRoute(
          builder: (_) => const ProfileSectionScreen(
            title: 'Renewal Master',
            description: 'Keep renewals visible with contract dates, ownership, and reminder checkpoints.',
            icon: Icons.autorenew_rounded,
            accentColor: Color(0xFF0F766E),
          ),
        );
      case AppRoutes.raiseIssue:
        return MaterialPageRoute(
          builder: (_) => const ProfileSectionScreen(
            title: 'Raise Issue',
            description: 'Create support tickets, share status updates, and follow issue resolution history.',
            icon: Icons.report_gmailerrorred_rounded,
            accentColor: Color(0xFFDC2626),
          ),
        );
      case AppRoutes.staff:
        return MaterialPageRoute(
          builder: (_) => const ProfileSectionScreen(
            title: 'Staff',
            description: 'Manage team members, assignments, and workspace ownership in one place.',
            icon: Icons.groups_rounded,
            accentColor: Color(0xFFEA580C),
          ),
        );
      case AppRoutes.clients:
        return MaterialPageRoute(builder: (_) => const ClientsScreen());
      case AppRoutes.accessControl:
        return MaterialPageRoute(
          builder: (_) => const ProfileSectionScreen(
            title: 'Access Control',
            description: 'Handle permission rules, role visibility, and admin access policies.',
            icon: Icons.lock_outline_rounded,
            accentColor: Color(0xFF475569),
          ),
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const ProfileSectionScreen(
            title: 'Settings',
            description: 'Configure preferences, app behavior, and notification options for your account.',
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
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      );
    });
  }
}
