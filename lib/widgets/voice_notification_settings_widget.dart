import 'package:flutter/material.dart';

import '../core/services/voice_notification_settings.dart';

class VoiceNotificationSettingsSection extends StatefulWidget {
  const VoiceNotificationSettingsSection({super.key});

  @override
  State<VoiceNotificationSettingsSection> createState() =>
      _VoiceNotificationSettingsSectionState();
}

class _VoiceNotificationSettingsSectionState
    extends State<VoiceNotificationSettingsSection> {
  final VoiceNotificationSettings _settings =
      VoiceNotificationSettings.instance;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _enabled = false;
  bool _lead = true;
  bool _followUp = true;
  bool _task = true;
  bool _renewal = true;
  bool _payment = true;
  bool _deal = true;
  bool _general = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _settings.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _enabled = snapshot.enabled;
      _lead = snapshot.leadAnnouncementsEnabled;
      _followUp = snapshot.followUpAnnouncementsEnabled;
      _task = snapshot.taskAnnouncementsEnabled;
      _renewal = snapshot.renewalAnnouncementsEnabled;
      _payment = snapshot.paymentAnnouncementsEnabled;
      _deal = snapshot.dealAnnouncementsEnabled;
      _general = snapshot.generalAnnouncementsEnabled;
      _isLoading = false;
    });
  }

  Future<void> _setEnabled(bool enabled) async {
    await _save(() async {
      await _settings.setEnabled(enabled);
      if (mounted) {
        setState(() => _enabled = enabled);
      }
    });
  }

  Future<void> _setCategory(
    VoiceNotificationCategory category,
    bool enabled,
  ) async {
    await _save(() async {
      await _settings.setCategoryEnabled(category, enabled);
      if (!mounted) {
        return;
      }

      setState(() {
        switch (category) {
          case VoiceNotificationCategory.lead:
            _lead = enabled;
            break;
          case VoiceNotificationCategory.followUp:
            _followUp = enabled;
            break;
          case VoiceNotificationCategory.task:
            _task = enabled;
            break;
          case VoiceNotificationCategory.renewal:
            _renewal = enabled;
            break;
          case VoiceNotificationCategory.payment:
            _payment = enabled;
            break;
          case VoiceNotificationCategory.deal:
            _deal = enabled;
            break;
          case VoiceNotificationCategory.general:
            _general = enabled;
            break;
        }
      });
    });
  }

  Future<void> _save(Future<void> Function() action) async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: Color(0xFF1463D2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Notifications',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Speak incoming notifications aloud when supported.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _enabled,
              title: const Text('Enable Voice Notifications'),
              subtitle: const Text(
                'Master switch for spoken notification alerts',
              ),
              onChanged: _isSaving ? null : _setEnabled,
            ),
            const Divider(height: 24),
            _CategoryTile(
              label: 'Enable Lead Announcements',
              description: 'New lead notifications',
              value: _lead,
              enabled: _enabled,
              onChanged: (value) =>
                  _setCategory(VoiceNotificationCategory.lead, value),
            ),
            _CategoryTile(
              label: 'Enable Follow-up Announcements',
              description: 'Follow-up reminders',
              value: _followUp,
              enabled: _enabled,
              onChanged: (value) =>
                  _setCategory(VoiceNotificationCategory.followUp, value),
            ),
            _CategoryTile(
              label: 'Enable Task Announcements',
              description: 'Task reminders and work items',
              value: _task,
              enabled: _enabled,
              onChanged: (value) =>
                  _setCategory(VoiceNotificationCategory.task, value),
            ),
            _CategoryTile(
              label: 'Enable Renewal Announcements',
              description: 'Renewal due reminders',
              value: _renewal,
              enabled: _enabled,
              onChanged: (value) =>
                  _setCategory(VoiceNotificationCategory.renewal, value),
            ),
            _CategoryTile(
              label: 'Enable Payment Announcements',
              description: 'Payment received notifications',
              value: _payment,
              enabled: _enabled,
              onChanged: (value) =>
                  _setCategory(VoiceNotificationCategory.payment, value),
            ),
            _CategoryTile(
              label: 'Enable Deal Announcements',
              description: 'Closed deal notifications',
              value: _deal,
              enabled: _enabled,
              onChanged: (value) =>
                  _setCategory(VoiceNotificationCategory.deal, value),
            ),
            _CategoryTile(
              label: 'Enable General Announcements',
              description: 'Fallback title/body notifications',
              value: _general,
              enabled: _enabled,
              onChanged: (value) =>
                  _setCategory(VoiceNotificationCategory.general, value),
            ),
            if (_isSaving) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.description,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(label),
      subtitle: Text(description),
      onChanged: enabled ? onChanged : null,
    );
  }
}
