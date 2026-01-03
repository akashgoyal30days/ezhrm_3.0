import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'Authentication/User Information/user_details.dart';
import 'notification/modal/notification_modal.dart';

class FcmService {
  // Initialize FCM and request token
  static Future<void> initialize() async {
    UserDetails userDetails = UserDetails();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    // Request notification permissions (required for iOS, recommended for Android)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else {
      print('User declined or has not granted permission');
    }

    if (Platform.isAndroid) {
      // Get the FCM token
      String? token = await messaging.getToken();
      if (token != null) {
        userDetails.setFcmToken(token);
        print('FCM Token: $token');
        String? fcmToken = await userDetails.getFcmToken();
        print('FCM token saved locally and here is the value: $fcmToken');
        // Send token to your server
        // await sendTokenToServer(token, 'user123'); // Replace 'user123' with actual user ID
      } else {
        print('Failed to get FCM token');
      }
      // Handle token refresh (e.g., if Firebase issues a new token)
      messaging.onTokenRefresh.listen((newToken) async {
        print('Refreshed FCM Token: $newToken');
        // Send new token to your server
        // await sendTokenToServer(newToken, 'user123'); // Replace 'user123' with actual user ID
      });
    } else {
      final apnsToken = await messaging.getAPNSToken();
    }
  }

  // Send FCM token to your Laravel server
  static Future<void> sendTokenToServer(String token, String userId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://your-server.com/api/save-token'), // Replace with your server's API URL
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'device_token': token,
          'user_id': userId, // User ID to associate the token with
        }),
      );

      if (response.statusCode == 200) {
        print('Token successfully sent to server: ${response.body}');
      } else {
        print(
            'Failed to send token. Status: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }
}

class NotificationStore {
  static final List<AppNotification> _notifications = [];

  static List<AppNotification> get notifications => _notifications;

  static void addNotification(AppNotification notification) {
    _notifications.insert(0, notification); // Add to the top
  }
}
