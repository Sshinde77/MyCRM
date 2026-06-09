import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'speech_queue_manager.dart';
import 'tts_service.dart';
import 'voice_notification_settings.dart';

class VoiceNotificationSpeechPlan {
  const VoiceNotificationSpeechPlan({
    required this.text,
    required this.priority,
    required this.dedupeKey,
    required this.category,
    required this.shouldSpeak,
  });

  final String text;
  final SpeechPriority priority;
  final String dedupeKey;
  final VoiceNotificationCategory category;
  final bool shouldSpeak;
}

class NotificationSpeechManager with WidgetsBindingObserver {
  NotificationSpeechManager._({
    required VoiceNotificationSettings settings,
    required TtsService ttsService,
    required SpeechQueueManager queueManager,
  })  : _settings = settings,
        _ttsService = ttsService,
        _queueManager = queueManager;

  static final NotificationSpeechManager instance = NotificationSpeechManager._(
    settings: VoiceNotificationSettings.instance,
    ttsService: TtsService.instance,
    queueManager: SpeechQueueManager(
      speak: (entry) => TtsService.instance.speak(
        entry.text,
        priority: entry.priority,
        timeout: entry.timeout,
      ),
      stopCurrent: TtsService.instance.stop,
      logger: _log,
      maxQueueSize: 20,
      duplicateExpiry: const Duration(minutes: 2),
      defaultTimeout: const Duration(seconds: 30),
    ),
  );

  final VoiceNotificationSettings _settings;
  final TtsService _ttsService;
  final SpeechQueueManager _queueManager;

  bool _initialized = false;
  bool _disposed = false;

  Future<void> initialize() async {
    if (_initialized || _disposed) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    await _ttsService.initialize();
    _initialized = true;
    _log('[TTS] Initialized');
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    await _queueManager.dispose();
    await _ttsService.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(dispose());
    }
  }

  Future<bool> handleRemoteMessage(
    RemoteMessage message, {
    String source = 'fcm',
  }) async {
    if (_disposed) {
      return false;
    }

    await initialize();

    final plan = await buildSpeechPlan(
      messageId: message.messageId,
      title: message.notification?.title ?? message.data['title']?.toString(),
      body: message.notification?.body ?? message.data['body']?.toString(),
      data: message.data,
      source: source,
    );

    if (plan == null || !plan.shouldSpeak) {
      return false;
    }

    final entry = SpeechQueueEntry(
      text: plan.text,
      priority: plan.priority,
      dedupeKey: plan.dedupeKey,
      createdAt: DateTime.now(),
      timeout: _timeoutForPriority(plan.priority),
    );

    return _queueManager.enqueue(entry);
  }

  Future<VoiceNotificationSpeechPlan?> buildSpeechPlan({
    String? messageId,
    String? title,
    String? body,
    required Map<String, dynamic> data,
    String source = 'fcm',
  }) async {
    final cleanTitle = (title ?? '').trim();
    final cleanBody = (body ?? '').trim();
    final type = _readType(data);
    final category = _categoryForType(type);
    final enabled = await _isAllowedByCategory(category);

    if (!enabled) {
      return VoiceNotificationSpeechPlan(
        text: '',
        priority: _priorityForCategory(category),
        dedupeKey: _dedupeKey(
          messageId: messageId,
          title: cleanTitle,
          body: cleanBody,
          data: data,
          source: source,
        ),
        category: category,
        shouldSpeak: false,
      );
    }

    final specificText = _buildSpecificAnnouncementText(
      type: type,
      data: data,
    );
    final fallbackText = _buildFallbackText(cleanTitle, cleanBody);
    final text = specificText ?? fallbackText;

    if (text.isEmpty) {
      return null;
    }

    return VoiceNotificationSpeechPlan(
      text: text,
      priority: _priorityForCategory(category),
      dedupeKey: _dedupeKey(
        messageId: messageId,
        title: cleanTitle,
        body: cleanBody,
        data: data,
        source: source,
      ),
      category: category,
      shouldSpeak: true,
    );
  }

  String _readType(Map<String, dynamic> data) {
    return (data['type']?.toString() ??
            data['notification_type']?.toString() ??
            data['category']?.toString() ??
            '')
        .trim()
        .toLowerCase();
  }

  VoiceNotificationCategory _categoryForType(String type) {
    switch (type) {
      case 'lead':
      case 'new_lead':
        return VoiceNotificationCategory.lead;
      case 'followup':
      case 'follow_up':
        return VoiceNotificationCategory.followUp;
      case 'task':
        return VoiceNotificationCategory.task;
      case 'renewal':
        return VoiceNotificationCategory.renewal;
      case 'payment':
      case 'payment_received':
        return VoiceNotificationCategory.payment;
      case 'deal':
      case 'deal_closed':
        return VoiceNotificationCategory.deal;
      default:
        return VoiceNotificationCategory.general;
    }
  }

  Future<bool> _isAllowedByCategory(VoiceNotificationCategory category) async {
    switch (category) {
      case VoiceNotificationCategory.lead:
        return _settings.isLeadAnnouncementsEnabled();
      case VoiceNotificationCategory.followUp:
        return _settings.isFollowUpAnnouncementsEnabled();
      case VoiceNotificationCategory.task:
        return _settings.isTaskAnnouncementsEnabled();
      case VoiceNotificationCategory.renewal:
        return _settings.isRenewalAnnouncementsEnabled();
      case VoiceNotificationCategory.payment:
        return _settings.isPaymentAnnouncementsEnabled();
      case VoiceNotificationCategory.deal:
        return _settings.isDealAnnouncementsEnabled();
      case VoiceNotificationCategory.general:
        return _settings.isGeneralAnnouncementsEnabled();
    }
  }

  SpeechPriority _priorityForCategory(VoiceNotificationCategory category) {
    switch (category) {
      case VoiceNotificationCategory.lead:
      case VoiceNotificationCategory.payment:
      case VoiceNotificationCategory.deal:
        return SpeechPriority.high;
      case VoiceNotificationCategory.followUp:
      case VoiceNotificationCategory.renewal:
        return SpeechPriority.medium;
      case VoiceNotificationCategory.task:
      case VoiceNotificationCategory.general:
        return SpeechPriority.low;
    }
  }

  Duration _timeoutForPriority(SpeechPriority priority) {
    switch (priority) {
      case SpeechPriority.high:
        return const Duration(seconds: 20);
      case SpeechPriority.medium:
        return const Duration(seconds: 25);
      case SpeechPriority.low:
        return const Duration(seconds: 30);
    }
  }

  String? _buildSpecificAnnouncementText({
    required String type,
    required Map<String, dynamic> data,
  }) {
    switch (type) {
      case 'lead':
      case 'new_lead':
        final leadName = data['lead_name']?.toString().trim() ?? '';
        return 'New lead received from ${leadName.isNotEmpty ? leadName : 'a customer'}';
      case 'followup':
      case 'follow_up':
        final clientName = data['client_name']?.toString().trim() ?? '';
        return 'Follow up reminder for ${clientName.isNotEmpty ? clientName : 'your lead'}';
      case 'task':
        final taskDescription = data['task_description']?.toString().trim() ?? '';
        return 'Task pending. ${taskDescription.isNotEmpty ? taskDescription : 'Check your tasks'}';
      case 'renewal':
        final clientName = data['client_name']?.toString().trim() ?? '';
        final daysUntil = data['days_until']?.toString().trim() ?? '0';
        final daysText = daysUntil == '0'
            ? 'today'
            : daysUntil == '1'
                ? 'tomorrow'
                : 'in $daysUntil days';
        return 'Renewal due $daysText for ${clientName.isNotEmpty ? clientName : 'a client'}';
      case 'payment':
      case 'payment_received':
        final amount = data['amount']?.toString().trim() ?? '';
        final currency = data['currency']?.toString().trim() ?? 'rupees';
        final amountText = amount.isNotEmpty ? amount : 'a payment';
        return 'Payment of $currency $amountText received';
      case 'deal':
      case 'deal_closed':
        final dealAmount = data['deal_amount']?.toString().trim() ?? '';
        final currency = data['currency']?.toString().trim() ?? 'rupees';
        final amountText = dealAmount.isNotEmpty ? dealAmount : 'significant value';
        return 'Congratulations. Deal worth $currency $amountText has been closed';
      default:
        return null;
    }
  }

  String _buildFallbackText(String title, String body) {
    if (title.isEmpty && body.isEmpty) {
      return '';
    }
    if (title.isEmpty) {
      return body;
    }
    if (body.isEmpty) {
      return title;
    }
    return '$title. $body';
  }

  String _dedupeKey({
    String? messageId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String source,
  }) {
    final normalizedData = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => value == null)
      ..['source'] = source;
    final encodedData = jsonEncode(_sortedMap(normalizedData));
    if (messageId != null && messageId.trim().isNotEmpty) {
      return 'messageId:${messageId.trim()}';
    }
    return 'hash:${title.trim()}|${body.trim()}|$encodedData';
  }

  Map<String, dynamic> _sortedMap(Map<String, dynamic> input) {
    final entries = input.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return <String, dynamic>{
      for (final entry in entries)
        entry.key: entry.value is Map
            ? _sortedMap(Map<String, dynamic>.from(entry.value as Map))
            : entry.value,
    };
  }

  static void _log(String message) {
    log(message, name: 'NotificationSpeechManager');
  }
}
