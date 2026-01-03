import 'package:ezhrm/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print(
      '🔥 [Background Handler] Notification received: ${message.notification?.title} - ${message.notification?.body}');
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important notifications',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  try {
    print('📩 Setting up background message handler...');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Background handler set');

    print('⚙️ Initializing local notifications...');
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) =>
          print('👉 [Notification Tapped] Payload: ${response.payload}'),
    );
    print('✅ Local notifications initialized');

    print('📢 Creating Android notification channel...');
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    print('✅ Notification channel created: ${channel.id}');

    print('🔒 Requesting notification permission...');
    final settings = await FirebaseMessaging.instance.requestPermission();
    print('✅ Permission status: ${settings.authorizationStatus}');
    // Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('💡 [Foreground] Message received!');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');

      final notification = message.notification;
      final android = message.notification?.android;

      // Use data if notification payload is missing
      final title =
          notification?.title ?? message.data['title'] ?? 'New Notification';
      final body = notification?.body ??
          message.data['body'] ??
          'You have a new message';

      // Trigger local notification
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode, // unique ID
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['user_id'], // optional extra
      );
      print('📢 Local notification shown in foreground.');
    });

    // When app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 [onMessageOpenedApp] Notification tapped (app in background).');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
    });

    // When app is opened from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('🟢 [getInitialMessage] App opened from terminated state.');
      print('   Title: ${initialMessage.notification?.title}');
      print('   Body: ${initialMessage.notification?.body}');
    } else {
      print('🟢 [getInitialMessage] No initial notification found.');
    }
  } catch (e) {
    print('❌ Initialization error: $e');
  }
}
