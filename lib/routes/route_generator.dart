import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tasks_screen.dart';
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
      case AppRoutes.support:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Support'))));
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
