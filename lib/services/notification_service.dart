import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odiorent/services/firebase_auth_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuthService _authService = FirebaseAuthService();

  /// Fetches unread notification count for the current user.
  Stream<int> getUnreadNotificationCount() {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) {
      debugPrint("No user logged in for notifications.");
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('recipient_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Fetches all notifications for the current user.
  Stream<List<Map<String, dynamic>>> getNotifications() {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) {
      debugPrint("No user logged in for notifications.");
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('recipient_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Marks a specific notification as read.
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
      rethrow;
    }
  }

  /// Marks all notifications for the current user as read.
  Future<void> markAllNotificationsAsRead() async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) {
      debugPrint("No user logged in to mark all notifications as read.");
      return;
    }
    try {
      final unreadDocs = await _firestore
          .collection('notifications')
          .where('recipient_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error marking all notifications as read: $e");
      rethrow;
    }
  }
}
