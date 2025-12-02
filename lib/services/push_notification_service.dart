import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:odiorent/services/database_service.dart';

// Note: This function needs to be a top-level function (not a class method)
// to be used as a background message handler.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  // If you want to do something with the message data in the background,
  // you can do it here.
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _dbService = DatabaseService();

  Future<void> init(String userId) async {
    // Request permission from the user
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get the FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      debugPrint("FCM Token: $token");
      // Save the token to your database
      await _saveTokenToDatabase(token, userId);
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToDatabase(newToken, userId);
    });

    // Set up message handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // Here you could show a local notification using a package like
        // `flutter_local_notifications` to alert the user.
      }
    });

    // Handle when a user taps a notification and opens the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Here you can navigate to the specific chat screen
      // e.g., final chatId = message.data['chat_id'];
      // if (chatId != null) { /* navigate logic */ }
    });
  }

  Future<void> _saveTokenToDatabase(String token, String userId) async {
    try {
      await _dbService.saveFcmToken(token, userId);
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }
}
