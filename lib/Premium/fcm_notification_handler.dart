import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler (top-level or static function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Handling a background notification: ${message.messageId}');
  if (message.notification != null) {
    print('Title: ${message.notification!.title}');
    print('Body: ${message.notification!.body}');
    // Do not show local notification in background; rely on FCM system notification
  }
}

class FcmNotificationHandler {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    // Register the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(initSettings);

    // Request notification permissions (optional, for iOS)
    await FirebaseMessaging.instance.requestPermission();

    // Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 New foreground notification received');
      if (message.notification != null) {
        print('Title: ${message.notification!.title}');
        print('Body: ${message.notification!.body}');
        _showLocalNotification(
            message); // Show local notification only in foreground
      }
    });

    // App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 App opened from background notification');
      if (message.notification != null) {
        print('Title: ${message.notification!.title}');
        print('Body: ${message.notification!.body}');
        _handleNotificationNavigation(context, message);
      }
    });

    // App launched from terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App launched from terminated notification');
      if (initialMessage.notification != null) {
        print('Title: ${initialMessage.notification!.title}');
        print('Body: ${initialMessage.notification!.body}');
        _handleNotificationNavigation(context, initialMessage);
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'fcm_default_channel', // channel ID
      'FCM Notifications', // channel name
      channelDescription: 'This channel is used for FCM notifications.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
      notificationDetails,
    );
  }

  // Optional: Handle navigation when notification is tapped
  static void _handleNotificationNavigation(
      BuildContext context, RemoteMessage message) {
    // Example: Navigate to a specific screen based on message data
    if (message.data.isNotEmpty) {
      final route = message.data['route'];
      if (route != null && context.mounted) {
        Navigator.of(context).pushNamed(route);
      }
    }
  }
}
