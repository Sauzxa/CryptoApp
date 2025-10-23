import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_endpoints.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? reservationId;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.reservationId,
    this.data,
    required this.read,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      reservationId: json['reservationId']?['_id'] ?? json['reservationId'],
      data: json['data'],
      read: json['read'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'reservationId': reservationId,
      'data': data,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.read).length;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.read).toList();
  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.read).toList();

  /// Fetch notifications from backend
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null) {
        _error = 'No authentication token found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/notifications'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final notificationsData = data['data']['notifications'] as List;
          _notifications = notificationsData
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          _error = null;
        } else {
          _error = data['message'] ?? 'Failed to fetch notifications';
        }
      } else {
        _error = 'Failed to fetch notifications: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching notifications: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null) return;

      final response = await http.put(
        Uri.parse(
          '${ApiEndpoints.baseUrl}/api/notifications/$notificationId/read',
        ),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: _notifications[index].id,
            type: _notifications[index].type,
            title: _notifications[index].title,
            message: _notifications[index].message,
            reservationId: _notifications[index].reservationId,
            data: _notifications[index].data,
            read: true,
            createdAt: _notifications[index].createdAt,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null) return;

      final response = await http.put(
        Uri.parse('${ApiEndpoints.baseUrl}/api/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        _notifications = _notifications
            .map(
              (notification) => NotificationModel(
                id: notification.id,
                type: notification.type,
                title: notification.title,
                message: notification.message,
                reservationId: notification.reservationId,
                data: notification.data,
                read: true,
                createdAt: notification.createdAt,
                updatedAt: DateTime.now(),
              ),
            )
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null) return;

      final response = await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/api/notifications/$notificationId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null) return;

      final response = await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/api/notifications'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        _notifications.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Error clearing all notifications: $e');
    }
  }

  /// Add notification locally (for real-time updates)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Get notification icon based on type
  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'agent_available':
        return Icons.person_add;
      case 'message_received':
        return Icons.message;
      case 'availability_reminder':
        return Icons.schedule;
      case 'suivi_reminder':
        return Icons.event;
      case 'reservation_assigned':
        return Icons.assignment;
      case 'reservation_rapport_received':
        return Icons.description;
      case 'reservation_reminder':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  /// Get notification color based on type
  Color getNotificationColor(String type) {
    switch (type) {
      case 'agent_available':
        return const Color(0xFF10B981); // Green
      case 'message_received':
        return const Color(0xFF3B82F6); // Blue
      case 'availability_reminder':
        return const Color(0xFFF59E0B); // Orange
      case 'suivi_reminder':
        return const Color(0xFF8B5CF6); // Purple
      case 'reservation_assigned':
        return const Color(0xFF6366F1); // Indigo
      case 'reservation_rapport_received':
        return const Color(0xFF059669); // Emerald
      case 'reservation_reminder':
        return const Color(0xFFDC2626); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  /// Get notification title based on type
  String getNotificationTitle(String type) {
    switch (type) {
      case 'agent_available':
        return 'Agent Disponible';
      case 'message_received':
        return 'Nouveau Message';
      case 'availability_reminder':
        return 'Rappel Disponibilité';
      case 'suivi_reminder':
        return 'Rappel Suivi';
      case 'reservation_assigned':
        return 'Rendez-vous Assigné';
      case 'reservation_rapport_received':
        return 'Rapport Reçu';
      case 'reservation_reminder':
        return 'Rappel Rendez-vous';
      default:
        return 'Notification';
    }
  }
}


