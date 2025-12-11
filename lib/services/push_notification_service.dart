import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'dart:io' show Platform;

// Note: This function needs to be a top-level function (not a class method)
// to be used as a background message handler.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  // Background messages are automatically displayed by FCM
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _dbService = FirebaseDatabaseService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // Notification channels
  static const AndroidNotificationChannel _bookingChannel =
      AndroidNotificationChannel(
    'booking_channel',
    'Booking Notifications',
    description: 'Notifications for booking status updates',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  static const AndroidNotificationChannel _messageChannel =
      AndroidNotificationChannel(
    'message_channel',
    'Message Notifications',
    description: 'Notifications for new chat messages',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  static const AndroidNotificationChannel _generalChannel =
      AndroidNotificationChannel(
    'general_channel',
    'General Notifications',
    description: 'General app notifications',
    importance: Importance.defaultImportance,
    enableVibration: true,
    playSound: true,
  );

  Future<void> init(String userId) async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_bookingChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_messageChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_generalChannel);
    }

    // Request permission from the user (iOS will show system dialog)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

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

    // Handle foreground messages - display local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // Show local notification for foreground messages
        _showLocalNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: message.data['type'] ?? 'general',
          data: message.data,
        );
      }
    });

    // Handle when a user taps a notification and opens the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message.data);
    });

    // Check if app was opened from a terminated state by tapping notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification');
      _handleNotificationTap(initialMessage.data);
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
        if (response.payload != null) {
          // Parse payload and navigate
          _handleNotificationTap({'type': response.payload});
        }
      },
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
    Map<String, dynamic>? data,
  }) async {
    // Determine which channel to use based on notification type
    AndroidNotificationChannel channel;
    String channelKey = data?['type'] ?? 'general';

    switch (channelKey) {
      case 'booking':
      case 'booking_approved':
      case 'booking_rejected':
      case 'booking_cancelled':
        channel = _bookingChannel;
        break;
      case 'message':
      case 'new_message':
        channel = _messageChannel;
        break;
      default:
        channel = _generalChannel;
    }

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      enableVibration: channel.enableVibration,
      playSound: channel.playSound,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(Map<String, dynamic> data) {
    String type = data['type'] ?? '';
    debugPrint('Handling notification tap for type: $type');

    // Navigation logic would go here
    // For now, we just log the action
    // You would typically use a navigator key or routing service
    switch (type) {
      case 'booking':
      case 'booking_approved':
      case 'booking_rejected':
      case 'booking_cancelled':
        debugPrint('Navigate to bookings screen');
        // Navigate to bookings screen
        break;
      case 'message':
      case 'new_message':
        String? chatId = data['chat_id'];
        debugPrint('Navigate to chat screen: $chatId');
        // Navigate to specific chat
        break;
      default:
        debugPrint('Navigate to home screen');
    }
  }

  Future<void> _saveTokenToDatabase(String token, String userId) async {
    try {
      await _dbService.saveFcmToken(token, userId);
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  /// Send notification for booking status change
  /// This would be called from your backend/cloud function
  /// For local testing, you can use this method
  Future<void> sendBookingNotification({
    required String userId,
    required String title,
    required String body,
    required String bookingId,
    required String status,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: 'booking',
      data: {
        'type': 'booking_$status',
        'booking_id': bookingId,
      },
    );
  }

  /// Send notification for new message
  Future<void> sendMessageNotification({
    required String userId,
    required String senderName,
    required String messagePreview,
    required String chatId,
  }) async {
    await _showLocalNotification(
      title: senderName,
      body: messagePreview,
      payload: 'message',
      data: {
        'type': 'new_message',
        'chat_id': chatId,
      },
    );
  }

  /// Send general notification
  Future<void> sendGeneralNotification({
    required String title,
    required String body,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: 'general',
      data: {'type': 'general'},
    );
  }
}
