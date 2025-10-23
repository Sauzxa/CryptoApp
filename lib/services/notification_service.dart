import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // List to store notifications for in-app display
  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  /// Initialize Awesome Notifications
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        NotificationChannel(
          channelKey: 'agent_available_channel',
          channelName: 'Agent Availability',
          channelDescription: 'Notifications for agent availability updates',
          defaultColor: const Color(0xFF6366F1),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'message_channel',
          channelName: 'Messages',
          channelDescription: 'Notifications for new messages in rooms',
          defaultColor: const Color(0xFF10B981),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'reminder_channel',
          channelName: 'Reminders',
          channelDescription: 'Availability and calendar reminders',
          defaultColor: const Color(0xFFF59E0B),
          ledColor: Colors.white,
          importance: NotificationImportance.Default,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: true,
    );

    // Request permission if not granted
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  /// Show agent available notification
  Future<void> showAgentAvailableNotification({
    required String agentId,
    required String agentName,
    required String dateAvailable,
  }) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'agent_available_channel',
          title: '🟢 Agent disponible',
          body: '$agentName est maintenant disponible',
          notificationLayout: NotificationLayout.Default,
          payload: {
            'agentId': agentId,
            'agentName': agentName,
            'dateAvailable': dateAvailable,
            'type': 'agent_available',
          },
        ),
      );

      // Store notification for in-app list
      _notifications.insert(0, {
        'id': notificationId.toString(),
        'agentId': agentId,
        'agentName': agentName,
        'dateAvailable': dateAvailable,
        'message': '$agentName est maintenant disponible',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {}
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      _notifications[index]['read'] = true;
    }
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
  }

  /// Show message notification
  Future<void> showMessageNotification({
    required String senderName,
    required String messageText,
    required String roomName,
    required String roomId,
  }) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'message_channel',
          title: '💬 Nouveau message',
          body:
              '$senderName: ${messageText.length > 50 ? messageText.substring(0, 50) + '...' : messageText}',
          notificationLayout: NotificationLayout.Default,
          payload: {
            'senderName': senderName,
            'messageText': messageText,
            'roomName': roomName,
            'roomId': roomId,
            'type': 'message_received',
          },
        ),
      );

      // Store notification for in-app list
      _notifications.insert(0, {
        'id': notificationId.toString(),
        'senderName': senderName,
        'messageText': messageText,
        'roomName': roomName,
        'roomId': roomId,
        'message': '$senderName: $messageText',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      print('Error showing message notification: $e');
    }
  }

  /// Show availability reminder notification
  Future<void> showAvailabilityReminderNotification({
    required String agentName,
  }) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'reminder_channel',
          title: '⏰ Rappel de disponibilité',
          body: 'N\'oubliez pas de mettre à jour votre disponibilité',
          notificationLayout: NotificationLayout.Default,
          payload: {'agentName': agentName, 'type': 'availability_reminder'},
        ),
      );

      // Store notification for in-app list
      _notifications.insert(0, {
        'id': notificationId.toString(),
        'agentName': agentName,
        'message': 'Rappel: Mettez à jour votre disponibilité',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      print('Error showing availability reminder notification: $e');
    }
  }

  /// Show suivi reminder notification
  Future<void> showSuiviReminderNotification({
    required String clientName,
    required String reservedAt,
    required String reservationId,
  }) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'reminder_channel',
          title: '📅 Rappel Suivi',
          body: 'Vous avez un suivi aujourd\'hui avec $clientName',
          notificationLayout: NotificationLayout.Default,
          payload: {
            'clientName': clientName,
            'reservedAt': reservedAt,
            'reservationId': reservationId,
            'type': 'suivi_reminder',
          },
        ),
      );

      // Store notification for in-app list
      _notifications.insert(0, {
        'id': notificationId.toString(),
        'clientName': clientName,
        'reservedAt': reservedAt,
        'reservationId': reservationId,
        'message': 'Suivi avec $clientName',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      print('Error showing suivi reminder notification: $e');
    }
  }

  /// Get unread count
  int get unreadCount {
    return _notifications.where((n) => n['read'] == false).length;
  }
}

// Singleton instance
final notificationService = NotificationService();
