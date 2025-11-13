import 'package:flutter/material.dart';
import 'package:odiorent/services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago; // For time formatting

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  static const Color primaryGreen = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when the screen is opened
    _notificationService.markAllNotificationsAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet!',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll let you know when there\'s something new.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final bool isRead = notification['is_read'] as bool;
              final DateTime createdAt = DateTime.parse(notification['created_at'] as String);

              return Card(
                elevation: 0.5,
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                color: isRead ? Colors.white : Colors.lightGreen.shade50,
                child: ListTile(
                  leading: Icon(
                    isRead ? Icons.notifications_none : Icons.notifications_active,
                    color: isRead ? Colors.grey : primaryGreen,
                  ),
                  title: Text(
                    notification['title'] as String,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['body'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isRead ? Colors.grey[700] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(createdAt), // e.g., "3 days ago"
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Optionally navigate to a specific screen based on notification content
                    // For now, just mark as read if not already
                    if (!isRead) {
                      _notificationService.markNotificationAsRead(notification['id'] as String);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
