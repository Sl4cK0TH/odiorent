import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class NotificationService {
  /// Fetches unread notification count for the current user.
  Stream<int> getUnreadNotificationCount() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint("No user logged in for notifications.");
      return Stream.value(0);
    }

    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .map(
          (events) => events.where((event) => event['is_read'] == false).length,
        );
  }

  /// Fetches all notifications for the current user.
  Stream<List<Map<String, dynamic>>> getNotifications() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint("No user logged in for notifications.");
      return Stream.value([]);
    }

    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false);
  }

  /// Marks a specific notification as read.
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
      rethrow;
    }
  }

  /// Marks all notifications for the current user as read.
  Future<void> markAllNotificationsAsRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint("No user logged in to mark all notifications as read.");
      return;
    }
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('is_read', false); // Only mark unread ones
    } catch (e) {
      debugPrint("Error marking all notifications as read: $e");
      rethrow;
    }
  }
}
