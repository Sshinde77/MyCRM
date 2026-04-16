import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'core/constants/app_strings.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'theme/app_theme.dart';

/// Application entry point.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AuthController(), permanent: true);
  runApp(const MyApp());
}

/// Root widget that configures app-wide theme and navigation.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return SafeArea(child: child);
      },
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
