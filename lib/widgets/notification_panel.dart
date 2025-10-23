import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:CryptoApp/providers/notification_provider.dart';

class NotificationPanel extends StatefulWidget {
  final List<NotificationModel> notifications;
  final Function(String) onMarkAsRead;
  final VoidCallback onClearAll;

  const NotificationPanel({
    Key? key,
    required this.notifications,
    required this.onMarkAsRead,
    required this.onClearAll,
  }) : super(key: key);

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _close() {
    _animationController.reverse().then((_) => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final unreadNotifications = widget.notifications
        .where((n) => !n.read)
        .toList();
    final readNotifications = widget.notifications
        .where((n) => n.read)
        .toList();

    return GestureDetector(
      onTap: _close,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: Material(
                  elevation: 8,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1F2937)
                          : Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF374151)
                                : const Color(0xFFF3F4F6),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(0),
                              bottomRight: Radius.circular(0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_active,
                                color: const Color(0xFF6366F1),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                              const Spacer(),
                              if (widget.notifications.isNotEmpty)
                                TextButton(
                                  onPressed: widget.onClearAll,
                                  child: Text(
                                    'Tout effacer',
                                    style: TextStyle(
                                      color: const Color(0xFF6366F1),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                                ),
                                onPressed: _close,
                              ),
                            ],
                          ),
                        ),

                        // Notifications List
                        Flexible(
                          child: widget.notifications.isEmpty
                              ? _buildEmptyState(isDarkMode)
                              : ListView(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  children: [
                                    // Unread notifications
                                    if (unreadNotifications.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'Nouvelles',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.grey.shade600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      ...unreadNotifications.map(
                                        (notification) =>
                                            _buildNotificationItem(
                                              notification,
                                              isDarkMode,
                                              isUnread: true,
                                            ),
                                      ),
                                    ],

                                    // Read notifications
                                    if (readNotifications.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'Précédentes',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.grey.shade600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      ...readNotifications.map(
                                        (notification) =>
                                            _buildNotificationItem(
                                              notification,
                                              isDarkMode,
                                              isUnread: false,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous serez notifié quand un agent devient disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    bool isDarkMode, {
    required bool isUnread,
  }) {
    final timeAgo = timeago.format(notification.createdAt, locale: 'fr');
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    return InkWell(
      onTap: () {
        widget.onMarkAsRead(notification.id);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDarkMode
                    ? notificationProvider
                          .getNotificationColor(notification.type)
                          .withOpacity(0.1)
                    : notificationProvider
                          .getNotificationColor(notification.type)
                          .withOpacity(0.05))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar/Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notificationProvider
                    .getNotificationColor(notification.type)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notificationProvider.getNotificationIcon(notification.type),
                color: notificationProvider.getNotificationColor(
                  notification.type,
                ),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: notificationProvider.getNotificationColor(
                              notification.type,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDarkMode
                            ? Colors.white38
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.white38
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu button
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
              ),
              onSelected: (value) {
                if (value == 'mark_read') {
                  widget.onMarkAsRead(notification.id);
                  setState(() {});
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_read',
                  child: Row(
                    children: [
                      Icon(
                        isUnread ? Icons.mark_email_read : Icons.visibility,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(isUnread ? 'Marquer comme lu' : 'Détails'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the notification panel
void showNotificationPanel(
  BuildContext context, {
  required List<NotificationModel> notifications,
  required Function(String) onMarkAsRead,
  required VoidCallback onClearAll,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final unreadNotifications = notifications
              .where((n) => !n.read)
              .toList();
          final readNotifications = notifications.where((n) => n.read).toList();

          return Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      const Spacer(),
                      if (notifications.isNotEmpty)
                        TextButton(
                          onPressed: onClearAll,
                          child: const Text(
                            'Tout effacer',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Notifications List
                Expanded(
                  child: notifications.isEmpty
                      ? _buildEmptyStateSimple(isDarkMode)
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            // Unread notifications
                            if (unreadNotifications.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Nouvelles',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              ...unreadNotifications.map(
                                (notification) => _buildNotificationItemSimple(
                                  context,
                                  notification,
                                  isDarkMode,
                                  onMarkAsRead,
                                  isUnread: true,
                                ),
                              ),
                            ],
                            // Read notifications
                            if (readNotifications.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Précédentes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              ...readNotifications.map(
                                (notification) => _buildNotificationItemSimple(
                                  context,
                                  notification,
                                  isDarkMode,
                                  onMarkAsRead,
                                  isUnread: false,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildEmptyStateSimple(bool isDarkMode) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous serez notifié quand un agent devient disponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildNotificationItemSimple(
  BuildContext context,
  NotificationModel notification,
  bool isDarkMode,
  Function(String) onMarkAsRead, {
  required bool isUnread,
}) {
  final timeAgo = timeago.format(notification.createdAt, locale: 'fr');
  final notificationProvider = Provider.of<NotificationProvider>(
    context,
    listen: false,
  );

  return InkWell(
    onTap: () => onMarkAsRead(notification.id),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUnread
            ? (isDarkMode
                  ? notificationProvider
                        .getNotificationColor(notification.type)
                        .withOpacity(0.1)
                  : notificationProvider
                        .getNotificationColor(notification.type)
                        .withOpacity(0.05))
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar/Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: notificationProvider
                  .getNotificationColor(notification.type)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notificationProvider.getNotificationIcon(notification.type),
              color: notificationProvider.getNotificationColor(
                notification.type,
              ),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: notificationProvider.getNotificationColor(
                            notification.type,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? Colors.white38
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
