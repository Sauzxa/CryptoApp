import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_endpoints.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Navigation callback
  Function(String route, Map<String, dynamic>? data)? onNotificationTap;

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initialize() async {
    try {
      // Request permission (iOS)
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional notification permission');
      } else {
        print('❌ User declined notification permission');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Send token to backend
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_sendTokenToBackend);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      print('✅ Firebase Notification Service initialized');
    } catch (e) {
      print('❌ Error initializing Firebase Notification Service: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channels
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'reservation_notifications',
        'Reservation Notifications',
        description: 'Notifications for reservations and appointments',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'agent_availability',
        'Agent Availability',
        description: 'Notifications for agent availability updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'Notifications for new messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'reminders',
        'Reminders',
        description: 'Availability and calendar reminders',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Send FCM token to backend (public method for manual calls)
  Future<void> sendTokenToBackend(String token, String authToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token sent to backend successfully');
      } else {
        print('⚠️ Failed to send FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending FCM token: $e');
    }
  }

  /// Send FCM token to backend (private method for automatic calls)
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null) {
        print('⚠️ No auth token, skipping FCM token upload');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token sent to backend successfully');
      } else {
        print('⚠️ Failed to send FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Foreground message: ${message.notification?.title}');

    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      payload: json.encode(message.data),
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reservation_notifications',
          'Reservation Notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _navigateBasedOnData(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Handle Firebase notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification tapped: ${message.data}');
    _navigateBasedOnData(message.data);
  }

  /// Navigate based on notification data
  void _navigateBasedOnData(Map<String, dynamic> data) {
    final type = data['type'];

    if (onNotificationTap != null) {
      switch (type) {
        case 'reservation_assigned':
          onNotificationTap!('/suivi', data);
          break;
        case 'reservation_reminder':
        case 'reservation_rapport_received':
        case 'reservation_state_changed':
          final reservationId = data['reservationId'];
          if (reservationId != null) {
            onNotificationTap!('/reservation-details', {'id': reservationId});
          }
          break;
        case 'agent_available_again':
        case 'agent_available':
          onNotificationTap!('/suivi', data);
          break;
        case 'message_received':
          final roomId = data['roomId'];
          if (roomId != null) {
            onNotificationTap!('/messagerie', {'roomId': roomId});
          } else {
            onNotificationTap!('/messagerie', data);
          }
          break;
        case 'availability_reminder':
          onNotificationTap!('/profile', data);
          break;
        case 'suivi_reminder':
          final reservationId = data['reservationId'];
          if (reservationId != null) {
            onNotificationTap!('/reservation-details', {'id': reservationId});
          } else {
            onNotificationTap!('/suivi', data);
          }
          break;
        default:
          onNotificationTap!('/home', data);
      }
    }
  }

  /// Show reservation assigned notification (for agent terrain)
  Future<void> showReservationAssigned({
    required String clientName,
    required String agentCommercialName,
    required String reservedAt,
  }) async {
    await _showLocalNotification(
      title: '🔔 Nouveau rendez-vous assigné',
      body: 'RDV avec $clientName - Créé par $agentCommercialName',
      payload: json.encode({
        'type': 'reservation_assigned',
        'clientName': clientName,
      }),
    );
  }

  /// Show rapport received notification (for agent commercial)
  Future<void> showRapportReceived({
    required String clientName,
    required String result,
    required String agentTerrainName,
  }) async {
    final resultText = result == 'rented' ? '✅ Loué' : '❌ Non loué';
    await _showLocalNotification(
      title: '📋 Rapport reçu',
      body: '$clientName - $resultText (par $agentTerrainName)',
      payload: json.encode({
        'type': 'reservation_rapport_received',
        'clientName': clientName,
        'result': result,
      }),
    );
  }

  /// Show 3-hour reminder (for agent commercial)
  Future<void> show3HourReminder({
    required String clientName,
    required String reservedAt,
  }) async {
    await _showLocalNotification(
      title: '⏰ Rappel: Rendez-vous dans 3h',
      body: 'RDV avec $clientName',
      payload: json.encode({
        'type': 'reservation_reminder',
        'clientName': clientName,
      }),
    );
  }

  /// Show available again notification (for agent terrain)
  Future<void> showAvailableAgain() async {
    await _showLocalNotification(
      title: '✅ Vous êtes disponible',
      body: 'Votre statut a été changé à disponible',
      payload: json.encode({'type': 'agent_available_again'}),
    );
  }

  /// Show agent available notification (for commercial agents)
  Future<void> showAgentAvailable({
    required String agentName,
    required String agentId,
  }) async {
    await _showLocalNotification(
      title: '🟢 Agent disponible',
      body: '$agentName est maintenant disponible',
      payload: json.encode({
        'type': 'agent_available',
        'agentName': agentName,
        'agentId': agentId,
      }),
    );
  }

  /// Show message notification
  Future<void> showMessageNotification({
    required String senderName,
    required String messageText,
    required String roomName,
    required String roomId,
  }) async {
    await _showLocalNotification(
      title: '💬 Nouveau message',
      body:
          '$senderName: ${messageText.length > 50 ? messageText.substring(0, 50) + '...' : messageText}',
      payload: json.encode({
        'type': 'message_received',
        'senderName': senderName,
        'messageText': messageText,
        'roomName': roomName,
        'roomId': roomId,
      }),
    );
  }

  /// Show availability reminder notification
  Future<void> showAvailabilityReminder({required String agentName}) async {
    await _showLocalNotification(
      title: '⏰ Rappel de disponibilité',
      body: 'N\'oubliez pas de mettre à jour votre disponibilité',
      payload: json.encode({
        'type': 'availability_reminder',
        'agentName': agentName,
      }),
    );
  }

  /// Show suivi reminder notification
  Future<void> showSuiviReminder({
    required String clientName,
    required String reservedAt,
    required String reservationId,
  }) async {
    await _showLocalNotification(
      title: '📅 Rappel Suivi',
      body: 'Vous avez un suivi aujourd\'hui avec $clientName',
      payload: json.encode({
        'type': 'suivi_reminder',
        'clientName': clientName,
        'reservedAt': reservedAt,
        'reservationId': reservationId,
      }),
    );
  }

  /// Remove FCM token on logout
  Future<void> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null) return;

      await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/api/notifications/fcm-token'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      print('✅ FCM token removed');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('✅ Unsubscribed from topic: $topic');
  }
}

// Singleton instance
final firebaseNotificationService = FirebaseNotificationService();
