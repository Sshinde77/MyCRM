import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'core/constants/app_strings.dart';
import 'core/services/app_settings_service.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'theme/app_theme.dart';

/// Application entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AuthController(), permanent: true);
  final darkModeEnabled = await AppSettingsService.instance.isDarkModeEnabled();
  runApp(MyApp(initialDarkModeEnabled: darkModeEnabled));
}

/// Root widget that configures app-wide theme and navigation.
class MyApp extends StatelessWidget {
  const MyApp({required this.initialDarkModeEnabled, super.key});

  final bool initialDarkModeEnabled;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: initialDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return SafeArea(child: child);
      },
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
