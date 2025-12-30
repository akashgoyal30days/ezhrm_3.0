// lib/old/standard_app_entry.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as notif;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'Standard/LocationService.dart';
import 'Standard/goGreen_Global.dart';
import 'Standard/services/shared_preferences_singleton.dart';
import 'Standard/splash_screen.dart'; // your old splash

GoGreenModel? goGreenModel;
var datak;
final PageController pageController = PageController(initialPage: 0);
int currentIndex = 0;
String? location, token, version, packagename, val, buildNumber;
final List<CameraDescription> cameras = [];

class OldAppEntry extends StatefulWidget {
  const OldAppEntry({super.key});

  @override
  State<OldAppEntry> createState() => _OldAppEntryState();
}

class _OldAppEntryState extends State<OldAppEntry> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeOldApp();
  }

  Future<void> _initializeOldApp() async {
    if (Platform.isAndroid) {
      NotificationService().init();
    }

    HttpOverrides.global = MyHttpOverrides();

    try {
      if (Platform.isAndroid) {
        await Workmanager()
            .initialize(callbackDispatcher, isInDebugMode: false);

        print("Workmanager initialized (Old App)");
      }
    } catch (e) {
      print("Workmanager failed: $e");
    }

    if (mounted) {
      setState(() => _initialized = true);
      print("setstate iniitiialized true");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StandardSplashScreen();
  }
}

initializeApp() async {
  // await Firebase.initializeApp();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  cameras.addAll(await availableCameras());
  await SharedPreferencesInstance.initialize();
  SharedPreferencesInstance.instance!.remove('reqatt');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  version = packageInfo.version;
  packagename = packageInfo.packageName;
  buildNumber = packageInfo.buildNumber;
  await SharedPreferencesInstance.instance!
      .setString("showupdatedailog", "true");
  await SharedPreferencesInstance.setString(
      "Showbackgroundnotification", "true");

  if (!SharedPreferencesInstance.isUserLoggedIn) return;
  await GoGreenGlobal.initialize();
  if (!SharedPreferencesInstance.isUserLoggedIn) return;
  goGreenModel = GoGreenModel(
    backgroundLocationInterval: int.parse(datak['time'].toString()),
    canSendRequest: datak["req_attendance"].toString() == "1",
    locationEnabled: datak["attendance_location"].toString() == "1",
    faceRecognitionEnabled: datak["face_recog"].toString() == "1",
    showattendancetime: datak["attendance_time"].toString() == "1",
    backgroundLocationTrackingEnabled: datak["loc_track"].toString() == "1",
    companyLogo: datak["comp_logo"],
    companyName: datak["comp_name"],
    debugEnable: datak["debug_enable"].toString() == "true",
    showUpdateAvailableDialog: datak['code'].toString() == "1009",
  );
}

class NotificationService {
  AndroidNotificationDetails androidPlatformChannelSpecifics =
      const AndroidNotificationDetails("Android", "Flutter_Notification",
          channelDescription: "Flutter_notification",
          importance: Importance.high,
          playSound: true);
  static final NotificationService _notificationService =
      NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  void init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final notif.DarwinInitializationSettings initializationSettingsIOS =
        notif.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            notif.IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
