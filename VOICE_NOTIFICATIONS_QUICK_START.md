# Quick Start: Adding Voice Notifications to Your App

## 1. Install Dependencies

```bash
flutter pub get
```

## 2. Test the Feature

### Option A: Firebase Console (Recommended)
1. Go to Firebase Console → Cloud Messaging
2. Send a test message with:
   ```json
   {
     "notification": {
       "title": "New Lead",
       "body": "You have a new lead"
     },
     "data": {
       "type": "lead",
       "lead_name": "Test Lead"
     }
   }
   ```
3. Select your device
4. Send test notification
5. Verify banner shows and TTS speaks

### Option B: Direct API Call (For Backend Testing)
```bash
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT/messages:send \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "FCM_TOKEN_HERE",
      "notification": {
        "title": "New Lead",
        "body": "You have a new lead"
      },
      "data": {
        "type": "lead",
        "lead_name": "Test Lead"
      }
    }
  }'
```

## 3. Add Settings Toggle to Your App

### Method 1: Simple Widget (Easiest)

```dart
import 'package:mycrm/widgets/voice_notification_settings_widget.dart';

// In your settings screen, add:
VoiceNotificationSettingsTile()
```

### Method 2: Full Settings Section

```dart
import 'package:mycrm/widgets/voice_notification_settings_widget.dart';

// In your settings screen, add:
NotificationSettingsSection()
```

### Method 3: Custom Implementation

```dart
import 'package:mycrm/core/services/app_settings_service.dart';
import 'package:get/get.dart';

FutureBuilder<bool>(
  future: AppSettingsService.instance.isVoiceNotificationsEnabled(),
  builder: (context, snapshot) {
    final isEnabled = snapshot.data ?? false;
    
    return SwitchListTile(
      title: const Text('Voice Notifications'),
      subtitle: const Text('Speak notification announcements'),
      value: isEnabled,
      onChanged: (value) async {
        await AppSettingsService.instance
            .setVoiceNotificationsEnabled(value);
        // Trigger rebuild to reflect change
        if (context.mounted) {
          (context as Element).markNeedsBuild();
        }
      },
      secondary: const Icon(Icons.volume_up),
    );
  },
)
```

## 4. Supported Notification Types

### Lead Notification
```json
{
  "notification": {
    "title": "New Lead",
    "body": "You have received a new lead"
  },
  "data": {
    "type": "lead",
    "lead_name": "John Doe"
  }
}
```
**Announces:** "New lead received from John Doe"

### Follow-up Notification
```json
{
  "notification": {
    "title": "Follow-up Reminder",
    "body": "Time to follow up"
  },
  "data": {
    "type": "followup",
    "client_name": "ABC Industries"
  }
}
```
**Announces:** "Follow up reminder for ABC Industries"

### Task Notification
```json
{
  "notification": {
    "title": "Task Pending",
    "body": "You have a pending task"
  },
  "data": {
    "type": "task",
    "task_description": "Submit quotation"
  }
}
```
**Announces:** "Task pending. Submit quotation"

### Renewal Notification
```json
{
  "notification": {
    "title": "Renewal Due",
    "body": "Contract renewal approaching"
  },
  "data": {
    "type": "renewal",
    "client_name": "ABC Industries",
    "days_until": "1"
  }
}
```
**Announces:** "Renewal due tomorrow for ABC Industries"

### Payment Notification
```json
{
  "notification": {
    "title": "Payment Received",
    "body": "Payment has been received"
  },
  "data": {
    "type": "payment",
    "amount": "twenty five thousand",
    "currency": "rupees"
  }
}
```
**Announces:** "Payment of rupees twenty five thousand received"

### Deal Notification
```json
{
  "notification": {
    "title": "Deal Closed",
    "body": "Congratulations on closing the deal!"
  },
  "data": {
    "type": "deal",
    "deal_amount": "one lakh",
    "currency": "rupees"
  }
}
```
**Announces:** "Congratulations. Deal worth rupees one lakh has been closed"

### Generic Notification
```json
{
  "notification": {
    "title": "System Update",
    "body": "A new feature has been released"
  },
  "data": {
    "type": "general"
  }
}
```
**Announces:** "System Update. A new feature has been released"

## 5. Debugging

### Check if Voice Notifications Work
```dart
import 'package:mycrm/core/services/tts_service.dart';

// Test TTS directly
await TtsService.instance.initialize();
await TtsService.instance.announceNotification(
  title: 'Test',
  body: 'This is a test announcement',
);
```

### View Logs
Look for messages starting with:
- `[TtsService]` - TTS service logs
- `[PushNotificationService]` - Push notification logs

### Common Issues

**No sound?**
1. Check device volume is not muted
2. Go to app settings → Voice Notifications → ON
3. Check logs for `TTS initialized successfully`

**TTS not speaking?**
1. Verify notification has `data.type` field
2. Check type-specific fields: `lead_name`, `client_name`, etc.
3. Check logs for errors

## 6. Backend Integration

### Laravel Example
```php
// Send FCM notification with voice support
$message = [
    'notification' => [
        'title' => 'New Lead',
        'body' => 'You have a new lead',
    ],
    'data' => [
        'type' => 'lead',
        'lead_name' => 'John Doe',
        'lead_id' => '12345',
    ],
];

Firebase::sendMulticast($message, $deviceTokens);
```

### Important Notes
- Always include `notification.title` and `notification.body`
- Always include `data.type` (use exact values: lead, followup, task, renewal, payment, deal, general)
- Include type-specific fields based on the type
- No backend changes required, but recommended for best UX

## 7. Advanced: Direct TTS Control

```dart
import 'package:mycrm/core/services/tts_service.dart';

final tts = TtsService.instance;

// Type-specific announcements
await tts.announceLead(leadName: 'John Doe');
await tts.announceFollowup(clientName: 'ABC Industries');
await tts.announceTask(taskDescription: 'Submit quotation');
await tts.announceRenewal(clientName: 'ABC Industries', daysUntil: '1');
await tts.announcePayment(amount: 'twenty five thousand', currency: 'rupees');
await tts.announceDealClosed(dealAmount: 'one lakh', currency: 'rupees');

// Stop current speech
await tts.stop();

// Pause/Resume
await tts.pause();
await tts.resume();

// Check queue
print('Queue length: ${tts.queueLength}');
print('Is speaking: ${tts.isSpeaking}');
```

## 8. Testing Checklist

- [ ] App opens without crashes
- [ ] Voice Notifications toggle visible in settings
- [ ] Toggling the setting works
- [ ] Foreground notification speaks when enabled
- [ ] Foreground notification doesn't speak when disabled
- [ ] Multiple notifications queue properly
- [ ] Device volume controls TTS volume
- [ ] Silent mode is respected
- [ ] No app crashes from TTS errors

## 9. User Documentation (Sample)

### For Users

**What is Voice Notifications?**

Voice Notifications allow your app to announce important updates by speaking them aloud. When you receive a notification:
- A visual banner appears (as before)
- If enabled, the notification is also announced through your speaker
- You can control device volume to adjust announcement volume

**How to Enable/Disable?**

1. Open the app
2. Go to Settings
3. Find "Voice Notifications"
4. Toggle ON or OFF
5. When enabled: "Notifications will be announced"
6. When disabled: "Only the banner will be shown"

**What Notifications Can Be Announced?**

- New lead received
- Follow-up reminders
- Task reminders
- Renewal alerts
- Payment confirmations
- Deal closures
- System updates

**Tips:**

- Announcements respect your device volume settings
- "Do Not Disturb" mode will silence announcements
- You can disable announcements anytime in settings
- Announcements won't interrupt while you're on a call

---

## 📚 Documentation

- **Full Guide:** See `VOICE_NOTIFICATIONS_GUIDE.md`
- **Implementation Details:** See `IMPLEMENTATION_SUMMARY.md`
- **Payload Examples:** See `lib/core/services/voice_notification_payloads.dart`

---

**Need Help?**
- Check the logs for `[TtsService]` messages
- Verify device volume is not muted
- Ensure notification includes required fields
- See `VOICE_NOTIFICATIONS_GUIDE.md` for detailed troubleshooting
