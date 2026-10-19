import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'secure_storage_service.dart';

/// Database notifications work independently of Firebase and FCM registration.
class InAppNotifications with WidgetsBindingObserver {
  InAppNotifications._();
  static final instance = InAppNotifications._();
  final unreadCount = ValueNotifier<int>(0);
  bool _loading = false;
  bool _started = false;
  int _session = 0;
  Timer? _timer;
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => refresh());
  }

  void stop() {
    _session++;
    _timer?.cancel();
    _timer = null;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    unreadCount.value = 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
      _timer ??= Timer.periodic(const Duration(seconds: 60), (_) => refresh());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    final session = _session;
    try {
      if (!await SecureStorageService.instance.hasAccessToken()) {
        unreadCount.value = 0;
        return;
      }
      final page = await ApiService.instance.getNotificationsPage(perPage: 1);
      if (session == _session &&
          await SecureStorageService.instance.hasAccessToken())
        unreadCount.value = page.unreadCount;
    } catch (_) {
      // Preserve the last known badge; the notification list exposes request errors.
    } finally {
      _loading = false;
    }
  }
}

class DatabaseNotificationButton extends StatefulWidget {
  const DatabaseNotificationButton({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  State<DatabaseNotificationButton> createState() =>
      _DatabaseNotificationButtonState();
}

class _DatabaseNotificationButtonState
    extends State<DatabaseNotificationButton> {
  @override
  void initState() {
    super.initState();
    InAppNotifications.instance.start();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: InAppNotifications.instance.unreadCount,
    builder: (_, count, _) => IconButton(
      tooltip: 'Notifications',
      onPressed: widget.onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    ),
  );
}
