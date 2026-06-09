// FCM Notification Type Definitions and Payload Documentation
//
// This file documents the supported notification types and their payload structures
// for the voice notification system integrated with Firebase Cloud Messaging (FCM).
//
// All notifications work with the voice announcement system automatically.
// The `type` field in the notification data determines how the notification is announced.

// ==================== Notification Types ====================

/// Enum for supported notification types
enum NotificationType {
  lead,
  followup,
  task,
  renewal,
  payment,
  deal,
  general,
}

// ==================== Example FCM Payloads ====================

/// Example FCM Payloads for Different Notification Types
/// 
/// These payloads should be sent from your Laravel backend.
/// The `type` field determines how the notification is announced via TTS.

class NotificationPayloadExamples {
  /// New Lead Notification
  /// 
  /// Announces: "New lead received from John Doe"
  static const Map<String, dynamic> newLeadPayload = {
    'notification': {
      'title': 'New Lead',
      'body': 'You have received a new lead'
    },
    'data': {
      'type': 'lead',
      'lead_name': 'John Doe',
      'lead_id': '12345',
      'company': 'Acme Corp'
    }
  };

  /// Follow-up Reminder Notification
  /// 
  /// Announces: "Follow up reminder for ABC Industries"
  static const Map<String, dynamic> followupReminderPayload = {
    'notification': {
      'title': 'Follow-up Reminder',
      'body': 'Time to follow up with your lead'
    },
    'data': {
      'type': 'followup',
      'client_name': 'ABC Industries',
      'client_id': '12346',
      'last_interaction': '2 days ago'
    }
  };

  /// Task Reminder Notification
  /// 
  /// Announces: "Task pending. Submit quotation"
  static const Map<String, dynamic> taskReminderPayload = {
    'notification': {
      'title': 'Task Pending',
      'body': 'You have a pending task'
    },
    'data': {
      'type': 'task',
      'task_description': 'Submit quotation',
      'task_id': '12347',
      'due_date': '2024-06-15',
      'priority': 'high'
    }
  };

  /// Renewal Reminder Notification
  /// 
  /// Announces: "Renewal due tomorrow for ABC Industries"
  static const Map<String, dynamic> renewalReminderPayload = {
    'notification': {
      'title': 'Renewal Due',
      'body': 'Contract renewal approaching'
    },
    'data': {
      'type': 'renewal',
      'client_name': 'ABC Industries',
      'client_id': '12346',
      'days_until': '1',
      'renewal_amount': '50000'
    }
  };

  /// Payment Received Notification
  /// 
  /// Announces: "Payment of rupees twenty five thousand received"
  static const Map<String, dynamic> paymentReceivedPayload = {
    'notification': {
      'title': 'Payment Received',
      'body': 'Payment has been received'
    },
    'data': {
      'type': 'payment',
      'amount': 'twenty five thousand',
      'currency': 'rupees',
      'invoice_id': '12348',
      'client_name': 'John Doe'
    }
  };

  /// Deal Closed Notification
  /// 
  /// Announces: "Congratulations. Deal worth rupees one lakh has been closed"
  static const Map<String, dynamic> dealClosedPayload = {
    'notification': {
      'title': 'Deal Closed',
      'body': 'Congratulations on closing the deal!'
    },
    'data': {
      'type': 'deal',
      'deal_amount': 'one lakh',
      'currency': 'rupees',
      'deal_id': '12349',
      'client_name': 'XYZ Company'
    }
  };

  /// Generic Notification
  /// 
  /// Announces: title and body as provided
  static const Map<String, dynamic> genericPayload = {
    'notification': {
      'title': 'System Update',
      'body': 'A new feature has been released'
    },
    'data': {
      'type': 'general',
      'action_url': '/app/news'
    }
  };
}

// ==================== Payload Field Documentation ====================

/// Documentation of fields used in notification payloads
class PayloadFieldDocumentation {
  static const Map<String, String> fieldDescriptions = {
    'notification.title':
        'Title of the notification (displayed in notification bar)',
    'notification.body':
        'Body of the notification (displayed in notification bar)',
    'data.type':
        'Type of notification: lead, followup, task, renewal, payment, deal, general',
    'data.lead_name': 'Name of the lead (for lead notifications)',
    'data.client_name': 'Name of the client (for followup, renewal notifications)',
    'data.task_description':
        'Description of the task (for task notifications)',
    'data.days_until': 'Number of days until renewal (for renewal notifications)',
    'data.amount': 'Amount in words (for payment notifications)',
    'data.currency': 'Currency name, e.g., "rupees" (for payment notifications)',
    'data.deal_amount': 'Deal amount in words (for deal notifications)',
  };

  /// Priority levels
  /// 
  /// - low: No interruption, queued behind normal messages
  /// - normal: Standard priority, queued normally
  /// - high: Interrupts current speech, spoken immediately (payments, deals)
  static const List<String> priorityLevels = ['low', 'normal', 'high'];

  /// Supported notification types
  static const List<String> supportedTypes = [
    'lead',
    'followup',
    'task',
    'renewal',
    'payment',
    'deal',
    'general'
  ];
}

// ==================== Backend Integration Guide ====================

/// Integration guide for Laravel backend developers
/// 
/// When sending FCM notifications, follow this structure:
/// 
/// ```
/// $message = [
///     'notification' => [
///         'title' => 'New Lead',
///         'body' => 'You have received a new lead',
///     ],
///     'data' => [
///         'type' => 'lead',
///         'lead_name' => 'John Doe',
///         'lead_id' => '12345',
///         // ... other fields
///     ],
/// ];
/// 
/// Firebase::sendMulticast($message, $tokens);
/// ```
/// 
/// The `type` field is CRITICAL - it determines:
/// 1. How the notification is announced via TTS
/// 2. Which data fields are expected
/// 3. The priority level (payment/deal = high, others = normal)

class BackendIntegrationGuide {
  // Use these constants in your Laravel backend
  static const String notificationTypeField = 'type';
  static const String leadType = 'lead';
  static const String followupType = 'followup';
  static const String taskType = 'task';
  static const String renewalType = 'renewal';
  static const String paymentType = 'payment';
  static const String dealType = 'deal';
  static const String generalType = 'general';

  // Data fields for each type
  static const Map<String, List<String>> requiredFieldsByType = {
    'lead': ['lead_name'],
    'followup': ['client_name'],
    'task': ['task_description'],
    'renewal': ['client_name', 'days_until'],
    'payment': ['amount', 'currency'],
    'deal': ['deal_amount', 'currency'],
    'general': [],
  };

  static const Map<String, List<String>> optionalFieldsByType = {
    'lead': ['lead_id', 'company'],
    'followup': ['client_id', 'last_interaction'],
    'task': ['task_id', 'due_date', 'priority'],
    'renewal': ['client_id', 'renewal_amount'],
    'payment': ['invoice_id', 'client_name', 'reference'],
    'deal': ['deal_id', 'client_name'],
    'general': ['action_url', 'icon'],
  };
}

// ==================== Testing Utilities ====================

/// Utilities for testing voice notifications
class VoiceNotificationTestUtils {
  /// Generate a test notification payload
  /// 
  /// Usage: 
  /// ```dart
  /// final payload = VoiceNotificationTestUtils.generateTestPayload(
  ///   type: 'lead',
  ///   leadName: 'Test Lead',
  /// );
  /// ```
  static Map<String, dynamic> generateTestPayload({
    required String type,
    String? leadName,
    String? clientName,
    String? taskDescription,
    String? daysUntil,
    String? amount,
    String? currency,
    String? dealAmount,
  }) {
    final data = <String, dynamic>{'type': type};

    if (leadName != null) data['lead_name'] = leadName;
    if (clientName != null) data['client_name'] = clientName;
    if (taskDescription != null) data['task_description'] = taskDescription;
    if (daysUntil != null) data['days_until'] = daysUntil;
    if (amount != null) data['amount'] = amount;
    if (currency != null) data['currency'] = currency;
    if (dealAmount != null) data['deal_amount'] = dealAmount;

    return {
      'notification': {
        'title': _getTitleForType(type),
        'body': _getBodyForType(type),
      },
      'data': data,
    };
  }

  static String _getTitleForType(String type) {
    switch (type) {
      case 'lead':
        return 'New Lead';
      case 'followup':
        return 'Follow-up Reminder';
      case 'task':
        return 'Task Pending';
      case 'renewal':
        return 'Renewal Due';
      case 'payment':
        return 'Payment Received';
      case 'deal':
        return 'Deal Closed';
      default:
        return 'Notification';
    }
  }

  static String _getBodyForType(String type) {
    switch (type) {
      case 'lead':
        return 'You have received a new lead';
      case 'followup':
        return 'Time to follow up with your lead';
      case 'task':
        return 'You have a pending task';
      case 'renewal':
        return 'Contract renewal approaching';
      case 'payment':
        return 'Payment has been received';
      case 'deal':
        return 'Congratulations on closing the deal!';
      default:
        return 'You have a new notification';
    }
  }
}
