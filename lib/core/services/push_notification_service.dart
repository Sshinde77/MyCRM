import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, describeEnum, kDebugMode, kIsWeb;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../firebase_options.dart';
import '../../services/api_service.dart';
import 'secure_storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (_) {
        await Firebase.initializeApp();
      }
    }
  } catch (_) {
    // Firebase isn't configured yet on this build.
    return;
  }

  if (kDebugMode) {
    log(
      'Handled background push: ${message.messageId}',
      name: 'PushNotificationService',
    );
  }
}

class PushNotificationService {
  PushNotificationService._();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final ApiService _apiService = ApiService.instance;
  static final SecureStorageService _storage = SecureStorageService.instance;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  static String? _latestToken;
  static bool _isInitialized = false;
  static bool _firebaseReady = false;
  static Future<String?>? _tokenFetchInFlight;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    final initialized = await _initializeFirebase();
    _firebaseReady = initialized;
    if (!initialized) {
      return;
    }
    _isInitialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestNotificationPermission();
    await _restoreCachedToken();
    await _fetchAndPersistToken(reason: 'app_start');

    if (_tokenRefreshSubscription != null) {
      await _tokenRefreshSubscription!.cancel();
    }
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) async => await _handleTokenRefresh(token),
      onError: (error) {
        _emitDiagnosticLog('FCM token refresh listener error: $error');
      },
    );

    if (_foregroundMessageSubscription != null) {
      await _foregroundMessageSubscription!.cancel();
    }
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (error) {
        _emitDiagnosticLog('Foreground message listener error: $error');
      },
    );

    if (_messageOpenedSubscription != null) {
      await _messageOpenedSubscription!.cancel();
    }
    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageOpenedApp,
      onError: (error) {
        _emitDiagnosticLog('Message opened listener error: $error');
      },
    );

    await _handleInitialMessage();
  }

  static Future<bool> _initializeFirebase() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firebaseReady = true;
        return true;
      }

      FirebaseOptions? options;
      try {
        options = DefaultFirebaseOptions.currentPlatform;
      } on UnsupportedError catch (error) {
        _emitDiagnosticLog('Firebase options are not configured: $error');
        return false;
      }

      if (options != null) {
        await Firebase.initializeApp(options: options);
        _firebaseReady = true;
        return true;
      }

      if (kIsWeb) {
        _emitDiagnosticLog(
          'Firebase Web configuration not found. Skipping push notification initialization for Web.',
        );
        return false;
      }

      await Firebase.initializeApp();
      _firebaseReady = true;
      return true;
    } catch (error, stackTrace) {
      _emitDiagnosticLog('Firebase initialization failed: $error');
      if (kDebugMode) {
        log(
          'Firebase initialization stacktrace: $stackTrace',
          name: 'PushNotificationService',
        );
      }
      return false;
    }
  }

  static Future<void> _requestNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _emitDiagnosticLog(
      'Notification permission status: ${settings.authorizationStatus}',
    );

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidPermission = await Permission.notification.status;
        if (!androidPermission.isGranted) {
          final requested = await Permission.notification.request();
          _emitDiagnosticLog(
            'Android notification permission request result: $requested',
          );
        }
      } catch (error) {
        _emitDiagnosticLog(
          'Android notification permission request failed: $error',
        );
      }
    }
  }

  static Future<void> _restoreCachedToken() async {
    final cached = await _storage.read(SecureStorageService.fcmTokenKey);
    if (cached == null || cached.trim().isEmpty) {
      return;
    }
    _latestToken = cached.trim();
    _emitDiagnosticLog('Restored cached FCM token.');
    _emitFcmToken(_latestToken);
  }

  static Future<void> _fetchAndPersistToken({required String reason}) async {
    if (!_isFirebaseMessagingReady()) {
      _emitDiagnosticLog(
        'Skipping FCM token fetch (reason: $reason): Firebase is not initialized.',
      );
      return;
    }

    try {
      final token = await _requestTokenWithRetry(reason: reason);
      await _persistToken(token);

      if (token == null || token.trim().isEmpty) {
        _emitDiagnosticLog(
          'FCM token is null/empty during token fetch (reason: $reason).',
        );
        return;
      }

      await _syncTokenWithBackend(event: reason);
    } on DioException catch (error) {
      _emitDiagnosticLog(
        'FCM token fetch sync failed (network/backend): ${error.message}',
      );
    } catch (error) {
      _emitDiagnosticLog('FCM token fetch failed: $error');
    }
  }

  static Future<String?> _requestTokenWithRetry({
    required String reason,
  }) async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        _emitDiagnosticLog(
          'Requesting FCM token (reason: $reason, attempt: $attempt).',
        );
        final token = await _getTokenSingleFlight().timeout(
          const Duration(seconds: 20),
        );
        if (token != null && token.trim().isNotEmpty) {
          return token;
        }
        _emitDiagnosticLog(
          'FCM token was null/empty (reason: $reason, attempt: $attempt).',
        );
      } catch (error) {
        _emitDiagnosticLog(
          'FCM token attempt failed (reason: $reason, attempt: $attempt): $error',
        );
      }

      if (attempt < 3) {
        await Future<void>.delayed(Duration(seconds: attempt * 5));
      }
    }

    return null;
  }

  static Future<String?> _getTokenSingleFlight() {
    final existing = _tokenFetchInFlight;
    if (existing != null) {
      return existing;
    }

    final request = _messaging.getToken().whenComplete(() {
      _tokenFetchInFlight = null;
    });
    _tokenFetchInFlight = request;
    return request;
  }

  static Future<void> _handleTokenRefresh(String token) async {
    await _persistToken(token);
    await _syncTokenWithBackend(event: 'refresh');
  }

  static Future<void> _persistToken(String? token) async {
    final normalized = token?.trim() ?? '';
    _latestToken = normalized.isEmpty ? null : normalized;
    await _storage.write(SecureStorageService.fcmTokenKey, _latestToken ?? '');
    _emitFcmToken(_latestToken);
  }

  static Future<void> onUserLogin({required String userId}) async {
    if (!_isFirebaseMessagingReady()) {
      _emitDiagnosticLog(
        'Skipping FCM login sync: Firebase is not initialized on this platform.',
      );
      return;
    }

    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    await _storage.write(
      SecureStorageService.fcmTokenSyncedUserIdKey,
      normalizedUserId,
    );

    final token = await getCurrentToken();
    if (token == null || token.trim().isEmpty) {
      await _fetchAndPersistToken(reason: 'login');
      return;
    }

    await _syncTokenWithBackend(event: 'login', forcedUserId: normalizedUserId);
  }

  static Future<void> onUserLogout() async {
    if (!_isFirebaseMessagingReady()) {
      return;
    }

    final token = await getCurrentToken();
    if (token == null || token.trim().isEmpty) {
      await _storage.delete(SecureStorageService.fcmTokenSyncedUserIdKey);
      return;
    }

    try {
      final user = await _apiService.getStoredUser();
      final userId = user?.id.trim() ?? '';
      if (userId.isNotEmpty) {
        final deviceInfo = await _collectDeviceInfo();
        final response = await _apiService.unlinkFcmToken(
          token: token,
          userId: userId,
          deviceInfo: deviceInfo,
        );
        _emitDiagnosticLog('FCM unlink backend response: $response');
      }
    } on DioException catch (error) {
      _emitDiagnosticLog(
        'FCM unlink failed (network/backend): ${error.message}',
      );
    } catch (error) {
      _emitDiagnosticLog('FCM unlink failed: $error');
    } finally {
      await _storage.delete(SecureStorageService.fcmTokenSyncedUserIdKey);
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    _emitDiagnosticLog(
      'Foreground message: id=${message.messageId}, '
      'title=${message.notification?.title}, body=${message.notification?.body}, '
      'data=${message.data}',
    );
    _showForegroundNotificationBanner(message);
  }

  static void _showForegroundNotificationBanner(RemoteMessage message) {
    final notification = message.notification;
    final title = (notification?.title ?? message.data['title']?.toString() ?? '')
        .trim();
    final body = (notification?.body ?? message.data['body']?.toString() ?? '')
        .trim();

    if (title.isEmpty && body.isEmpty) {
      return;
    }

    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title.isEmpty ? 'Notification' : title,
        body.isEmpty ? 'You have a new notification.' : body,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    _emitDiagnosticLog(
      'Message opened app: id=${message.messageId}, data=${message.data}',
    );
  }

  static Future<void> _handleInitialMessage() async {
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage == null) {
        return;
      }
      _emitDiagnosticLog(
        'Terminated-state message: id=${initialMessage.messageId}, '
        'data=${initialMessage.data}',
      );
    } catch (error) {
      _emitDiagnosticLog('Failed to read terminated-state message: $error');
    }
  }

  static Future<void> _syncTokenWithBackend({
    required String event,
    String? forcedUserId,
  }) async {
    final token = (_latestToken ?? '').trim();
    if (token.isEmpty) {
      _emitDiagnosticLog('Skipping token sync: local token is empty.');
      return;
    }

    final userId = (forcedUserId ?? await _resolveUserId()).trim();
    if (userId.isEmpty) {
      _emitDiagnosticLog('Skipping token sync: user is not authenticated yet.');
      return;
    }

    try {
      final deviceInfo = await _collectDeviceInfo();
      final response = await _apiService.syncFcmToken(
        token: token,
        userId: userId,
        deviceInfo: deviceInfo,
        event: event,
      );
      _emitDiagnosticLog('FCM sync backend response: $response');
      await _storage.write(
        SecureStorageService.fcmTokenSyncedUserIdKey,
        userId,
      );
    } on DioException catch (error) {
      _emitDiagnosticLog('FCM sync failed (network/backend): ${error.message}');
    } catch (error) {
      _emitDiagnosticLog('FCM sync failed: $error');
    }
  }

  static Future<String> _resolveUserId() async {
    final user = await _apiService.getStoredUser();
    return user?.id.trim() ?? '';
  }

  static Future<Map<String, dynamic>> _collectDeviceInfo() async {
    if (kIsWeb) {
      try {
        final info = await _deviceInfo.webBrowserInfo;
        return <String, dynamic>{
          'platform': 'web',
          'platform_version': info.appVersion ?? '',
          'browser_name': describeEnum(info.browserName),
          'user_agent': info.userAgent ?? '',
          'vendor': info.vendor ?? '',
          'language': info.language ?? '',
          'hardware_concurrency': info.hardwareConcurrency,
        };
      } catch (error) {
        _emitDiagnosticLog('Web device info collection failed: $error');
        return <String, dynamic>{'platform': 'web'};
      }
    }

    final base = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
      'target_platform': describeEnum(defaultTargetPlatform),
    };

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        base.addAll(<String, dynamic>{
          'device_id': info.id,
          'brand': info.brand,
          'model': info.model,
          'manufacturer': info.manufacturer,
          'sdk_int': info.version.sdkInt,
        });
        return base;
      }

      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        base.addAll(<String, dynamic>{
          'device_id': info.identifierForVendor,
          'name': info.name,
          'model': info.model,
          'system_name': info.systemName,
          'system_version': info.systemVersion,
        });
        return base;
      }
    } catch (error) {
      _emitDiagnosticLog('Device info collection failed: $error');
    }

    return base;
  }

  static void _emitFcmToken(String? token) {
    if (!kDebugMode) return;
    final message = 'FCM token: ${token ?? 'null'}';

    // Visible in terminal/stdout.
    print(message);

    // Visible in Flutter run terminal output.
    // debugPrint(message);

    // Visible in IDE/device logs (e.g., logcat / debug console).
    log(message, name: 'PushNotificationService');
  }

  static Future<String?> getCurrentToken() async {
    if (!_isFirebaseMessagingReady()) {
      _emitDiagnosticLog(
        'Skipping FCM token request: Firebase is not initialized on this platform.',
      );
      return null;
    }

    final cached = _latestToken?.trim() ?? '';
    if (cached.isNotEmpty) {
      return cached;
    }

    try {
      final fromStorage = await _storage.read(SecureStorageService.fcmTokenKey);
      if (fromStorage != null && fromStorage.trim().isNotEmpty) {
        _latestToken = fromStorage.trim();
        return _latestToken;
      }

      final token = await _requestTokenWithRetry(reason: 'manual');
      await _persistToken(token);
      return _latestToken;
    } catch (error) {
      _emitDiagnosticLog('FCM token fetch failed: $error');
      return null;
    }
  }

  static void _emitDiagnosticLog(String message) {
    if (!kDebugMode) return;
    print(message);
    // debugPrint(message);
    log(message, name: 'PushNotificationService');
  }

  static bool _isFirebaseMessagingReady() {
    if (_firebaseReady) {
      return true;
    }
    if (Firebase.apps.isNotEmpty) {
      _firebaseReady = true;
      return true;
    }
    return false;
  }
}
