import 'package:shared_preferences/shared_preferences.dart';

enum VoiceNotificationCategory {
  lead,
  followUp,
  task,
  renewal,
  payment,
  deal,
  general,
}

class VoiceNotificationSettingsSnapshot {
  const VoiceNotificationSettingsSnapshot({
    required this.enabled,
    required this.leadAnnouncementsEnabled,
    required this.followUpAnnouncementsEnabled,
    required this.taskAnnouncementsEnabled,
    required this.renewalAnnouncementsEnabled,
    required this.paymentAnnouncementsEnabled,
    required this.dealAnnouncementsEnabled,
    required this.generalAnnouncementsEnabled,
  });

  final bool enabled;
  final bool leadAnnouncementsEnabled;
  final bool followUpAnnouncementsEnabled;
  final bool taskAnnouncementsEnabled;
  final bool renewalAnnouncementsEnabled;
  final bool paymentAnnouncementsEnabled;
  final bool dealAnnouncementsEnabled;
  final bool generalAnnouncementsEnabled;
}

class VoiceNotificationSettings {
  VoiceNotificationSettings._();

  static final VoiceNotificationSettings instance = VoiceNotificationSettings._();

  static const String _enabledKey = 'voice_notifications_enabled';
  static const String _leadKey = 'voice_notifications_lead_enabled';
  static const String _followUpKey = 'voice_notifications_follow_up_enabled';
  static const String _taskKey = 'voice_notifications_task_enabled';
  static const String _renewalKey = 'voice_notifications_renewal_enabled';
  static const String _paymentKey = 'voice_notifications_payment_enabled';
  static const String _dealKey = 'voice_notifications_deal_enabled';
  static const String _generalKey = 'voice_notifications_general_enabled';

  Future<VoiceNotificationSettingsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return VoiceNotificationSettingsSnapshot(
      enabled: prefs.getBool(_enabledKey) ?? false,
      leadAnnouncementsEnabled: prefs.getBool(_leadKey) ?? true,
      followUpAnnouncementsEnabled: prefs.getBool(_followUpKey) ?? true,
      taskAnnouncementsEnabled: prefs.getBool(_taskKey) ?? true,
      renewalAnnouncementsEnabled: prefs.getBool(_renewalKey) ?? true,
      paymentAnnouncementsEnabled: prefs.getBool(_paymentKey) ?? true,
      dealAnnouncementsEnabled: prefs.getBool(_dealKey) ?? true,
      generalAnnouncementsEnabled: prefs.getBool(_generalKey) ?? true,
    );
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<bool> isCategoryEnabled(VoiceNotificationCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    return _readCategoryEnabled(prefs, category);
  }

  Future<void> setCategoryEnabled(
    VoiceNotificationCategory category,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyForCategory(category), enabled);
  }

  Future<bool> isLeadAnnouncementsEnabled() async {
    return isCategoryEnabled(VoiceNotificationCategory.lead);
  }

  Future<void> setLeadAnnouncementsEnabled(bool enabled) async {
    await setCategoryEnabled(VoiceNotificationCategory.lead, enabled);
  }

  Future<bool> isFollowUpAnnouncementsEnabled() async {
    return isCategoryEnabled(VoiceNotificationCategory.followUp);
  }

  Future<void> setFollowUpAnnouncementsEnabled(bool enabled) async {
    await setCategoryEnabled(VoiceNotificationCategory.followUp, enabled);
  }

  Future<bool> isTaskAnnouncementsEnabled() async {
    return isCategoryEnabled(VoiceNotificationCategory.task);
  }

  Future<void> setTaskAnnouncementsEnabled(bool enabled) async {
    await setCategoryEnabled(VoiceNotificationCategory.task, enabled);
  }

  Future<bool> isRenewalAnnouncementsEnabled() async {
    return isCategoryEnabled(VoiceNotificationCategory.renewal);
  }

  Future<void> setRenewalAnnouncementsEnabled(bool enabled) async {
    await setCategoryEnabled(VoiceNotificationCategory.renewal, enabled);
  }

  Future<bool> isPaymentAnnouncementsEnabled() async {
    return isCategoryEnabled(VoiceNotificationCategory.payment);
  }

  Future<void> setPaymentAnnouncementsEnabled(bool enabled) async {
    await setCategoryEnabled(VoiceNotificationCategory.payment, enabled);
  }

  Future<bool> isDealAnnouncementsEnabled() async {
    return isCategoryEnabled(VoiceNotificationCategory.deal);
  }

  Future<void> setDealAnnouncementsEnabled(bool enabled) async {
    await setCategoryEnabled(VoiceNotificationCategory.deal, enabled);
  }

  Future<bool> isGeneralAnnouncementsEnabled() async {
    return isCategoryEnabled(VoiceNotificationCategory.general);
  }

  Future<void> setGeneralAnnouncementsEnabled(bool enabled) async {
    await setCategoryEnabled(VoiceNotificationCategory.general, enabled);
  }

  String _keyForCategory(VoiceNotificationCategory category) {
    switch (category) {
      case VoiceNotificationCategory.lead:
        return _leadKey;
      case VoiceNotificationCategory.followUp:
        return _followUpKey;
      case VoiceNotificationCategory.task:
        return _taskKey;
      case VoiceNotificationCategory.renewal:
        return _renewalKey;
      case VoiceNotificationCategory.payment:
        return _paymentKey;
      case VoiceNotificationCategory.deal:
        return _dealKey;
      case VoiceNotificationCategory.general:
        return _generalKey;
    }
  }

  bool _readCategoryEnabled(
    SharedPreferences prefs,
    VoiceNotificationCategory category,
  ) {
    switch (category) {
      case VoiceNotificationCategory.lead:
        return prefs.getBool(_leadKey) ?? true;
      case VoiceNotificationCategory.followUp:
        return prefs.getBool(_followUpKey) ?? true;
      case VoiceNotificationCategory.task:
        return prefs.getBool(_taskKey) ?? true;
      case VoiceNotificationCategory.renewal:
        return prefs.getBool(_renewalKey) ?? true;
      case VoiceNotificationCategory.payment:
        return prefs.getBool(_paymentKey) ?? true;
      case VoiceNotificationCategory.deal:
        return prefs.getBool(_dealKey) ?? true;
      case VoiceNotificationCategory.general:
        return prefs.getBool(_generalKey) ?? true;
    }
  }
}
