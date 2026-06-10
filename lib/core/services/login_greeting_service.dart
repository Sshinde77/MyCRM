import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../../core/services/permission_service.dart';
import '../../models/user_model.dart';
import '../../models/dashboard_data_model.dart';
import '../../models/renewal_model.dart';
import '../../services/api_service.dart';
import 'app_settings_service.dart';
import 'speech_queue_manager.dart';
import 'tts_service.dart';

class LoginGreetingSummary {
  const LoginGreetingSummary({
    required this.leadCount,
    required this.followUpCount,
    required this.renewalCount,
  });

  final int leadCount;
  final int followUpCount;
  final int renewalCount;
}

class LoginGreetingService {
  LoginGreetingService._();

  static final LoginGreetingService instance = LoginGreetingService._();

  final ApiService _apiService = ApiService.instance;
  final AppSettingsService _appSettings = AppSettingsService.instance;
  final TtsService _ttsService = TtsService.instance;

  Future<void> speakGreeting({
    required String userId,
    required String userName,
    UserModel? user,
  }) async {
    try {
      if (!await _appSettings.isVoiceNotificationsEnabled()) {
        _log('[TTS] Login greeting skipped: voice notifications disabled');
        return;
      }

      final currentUser = user ?? await PermissionService.getCurrentUser();
      final canSeeLeadStats = _canSeeLeadStats(currentUser);
      final canSeeRenewalStats = _canSeeRenewalStats(currentUser);

      final summary = (canSeeLeadStats || canSeeRenewalStats)
          ? await _loadSummary(
              userId: userId,
              loadLeadStats: canSeeLeadStats,
              loadFollowUpStats: canSeeLeadStats,
              loadRenewalStats: canSeeRenewalStats,
            )
          : const LoginGreetingSummary(
              leadCount: 0,
              followUpCount: 0,
              renewalCount: 0,
            );
      final greeting = _buildGreetingMessage(
        userName: userName,
        summary: summary,
        showLeadStats: canSeeLeadStats,
        showFollowUpStats: canSeeLeadStats,
        showRenewalStats: canSeeRenewalStats,
        now: DateTime.now(),
      );

      if (greeting.trim().isEmpty) {
        return;
      }

      await _ttsService.initialize();
      await _ttsService.speak(greeting, priority: SpeechPriority.low);
      _log('[TTS] Login greeting spoken');
    } catch (error, stackTrace) {
      _log('[TTS] Login greeting failed: $error');
      if (kDebugMode) {
        log(
          'Login greeting stacktrace',
          name: 'LoginGreetingService',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<LoginGreetingSummary> _loadSummary({
    required String userId,
    required bool loadLeadStats,
    required bool loadFollowUpStats,
    required bool loadRenewalStats,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const LoginGreetingSummary(
        leadCount: 0,
        followUpCount: 0,
        renewalCount: 0,
      );
    }

    final leadsDashboard = loadLeadStats
        ? await _safeGetLeadsDashboard()
        : null;
    final staffAnalytics = loadFollowUpStats
        ? await _safeGetStaffAnalytics(normalizedUserId)
        : null;
    final dashboard = loadRenewalStats ? await _safeGetDashboardData() : null;

    return LoginGreetingSummary(
      leadCount: leadsDashboard?.leadsCount.todayCount ?? 0,
      followUpCount: _readIntFromMap(staffAnalytics, const [
        'todays_followups',
        'today_followups',
        'todaysFollowups',
      ]),
      renewalCount: _countRenewalsDueToday(dashboard),
    );
  }

  Future<LeadDashboardResult?> _safeGetLeadsDashboard() async {
    try {
      return await _apiService.getLeadsDashboard();
    } catch (error, stackTrace) {
      _log('[TTS] Failed to load lead dashboard: $error');
      if (kDebugMode) {
        log(
          'Lead dashboard stacktrace',
          name: 'LoginGreetingService',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _safeGetStaffAnalytics(String userId) async {
    try {
      return await _apiService.getStaffAnalytics(userId);
    } catch (error, stackTrace) {
      _log('[TTS] Failed to load staff analytics: $error');
      if (kDebugMode) {
        log(
          'Staff analytics stacktrace',
          name: 'LoginGreetingService',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return null;
    }
  }

  Future<DashboardDataModel?> _safeGetDashboardData() async {
    try {
      return await _apiService.getDashboardData();
    } catch (error, stackTrace) {
      _log('[TTS] Failed to load dashboard data: $error');
      if (kDebugMode) {
        log(
          'Dashboard data stacktrace',
          name: 'LoginGreetingService',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return null;
    }
  }

  int _countRenewalsDueToday(DashboardDataModel? dashboard) {
    if (dashboard == null) {
      return 0;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final allRenewals = <RenewalModel>[
      ...dashboard.clientRenewals,
      ...dashboard.vendorRenewals,
    ];

    var count = 0;
    for (final renewal in allRenewals) {
      final date = renewal.endDateValue ?? renewal.startDateValue;
      if (date == null) {
        continue;
      }
      final normalized = DateTime(date.year, date.month, date.day);
      if (normalized == normalizedToday) {
        count += 1;
      }
    }

    return count;
  }

  int _readIntFromMap(Map<String, dynamic>? map, List<String> keys) {
    if (map == null || map.isEmpty) {
      return 0;
    }

    for (final key in keys) {
      final value = map[key];
      if (value is num) {
        return value.toInt();
      }

      final parsed = int.tryParse((value ?? '').toString().trim());
      if (parsed != null) {
        return parsed;
      }
    }
    return 0;
  }

  String _buildGreetingMessage({
    required String userName,
    required LoginGreetingSummary summary,
    required bool showLeadStats,
    required bool showFollowUpStats,
    required bool showRenewalStats,
    required DateTime now,
  }) {
    final salutation = _timeBasedGreeting(now);
    final normalizedName = userName.trim().isEmpty ? 'there' : userName.trim();
    final parts = <String>['$salutation, $normalizedName.'];

    if (showLeadStats) {
      parts.add(
        _countSentence(summary.leadCount, 'new lead', 'new leads today'),
      );
    }
    if (showFollowUpStats) {
      parts.add(
        _countSentence(
          summary.followUpCount,
          'follow-up scheduled for today',
          'follow-ups scheduled for today',
        ),
      );
    }
    if (showRenewalStats) {
      parts.add(
        _countSentence(
          summary.renewalCount,
          'renewal due today',
          'renewals due today',
        ),
      );
    }

    if (parts.length > 1) {
      parts.add('Please contact them as soon as possible.');
    }

    return parts.join(' ');
  }

  bool _canSeeLeadStats(UserModel? user) {
    return PermissionService.userHasAny(user, const [
      AppPermission.viewLeadsManagement,
    ]);
  }

  bool _canSeeRenewalStats(UserModel? user) {
    return PermissionService.userHasAny(user, const [
      AppPermission.viewRenewals,
      AppPermission.viewServices,
      AppPermission.viewVendors,
      AppPermission.viewVendorsServices,
    ]);
  }

  String _countSentence(int count, String singular, String plural) {
    if (count <= 0) {
      return 'You have no $plural.';
    }

    return count == 1 ? 'You have 1 $singular.' : 'You have $count $plural.';
  }

  String _timeBasedGreeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
