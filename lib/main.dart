import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'core/constants/app_strings.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'theme/app_theme.dart';

/// Application entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  Get.put(AuthController(), permanent: true);
  final darkModeEnabled = await AppSettingsService.instance.isDarkModeEnabled();
  runApp(MyApp(initialDarkModeEnabled: darkModeEnabled));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushNotificationService.initialize();
  });
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;

  FirebaseOptions? options;
  try {
    options = DefaultFirebaseOptions.currentPlatform;
  } catch (error, stackTrace) {
    _printStartupLog('Firebase options initialization failed: $error');
    debugPrint('$stackTrace');
  }

  if (options != null) {
    try {
      await Firebase.initializeApp(options: options);
      return;
    } catch (error, stackTrace) {
      _printStartupLog('Firebase options initialization failed: $error');
      debugPrint('$stackTrace');
    }
  } else if (kIsWeb) {
    _printStartupLog(
      'Firebase Web configuration not found. Skipping Firebase initialization for Web.',
    );
    return;
  }

  try {
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    _printStartupLog('Firebase native initialization failed: $error');
    debugPrint('$stackTrace');
  }
}

void _printStartupLog(String message) {
  print(message);
  debugPrint(message);
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
