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

  /// Get unread count
  int get unreadCount {
    return _notifications.where((n) => n['read'] == false).length;
  }
}

// Singleton instance
final notificationService = NotificationService();
