import 'package:flutter/material.dart';
import 'package:cryptoimmobilierapp/services/notification_service.dart';
import 'package:cryptoimmobilierapp/widgets/notification_panel.dart';

class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({Key? key}) : super(key: key);

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  @override
  Widget build(BuildContext context) {
    final unreadCount = notificationService.unreadCount;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            showNotificationPanel(
              context,
              notifications: notificationService.notifications,
              onMarkAsRead: (id) {
                setState(() {
                  notificationService.markAsRead(id);
                });
              },
              onClearAll: () {
                setState(() {
                  notificationService.clearAll();
                });
                Navigator.pop(context);
              },
            );
          },
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
