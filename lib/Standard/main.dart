// import 'dart:developer';
// import 'dart:io';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:camera/camera.dart';
// import 'package:overlay_support/overlay_support.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'
//     as notif;
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:workmanager/workmanager.dart';
// import 'LocationService.dart';
// import 'goGreen_Global.dart';
// import 'splash_screen.dart';
// // import 'package:firebase_core/firebase_core.dart';
// import 'services/shared_preferences_singleton.dart';
//
// // GoGreenModel? goGreenModel;
// // var datak;
// // final PageController pageController = PageController(initialPage: 0);
// // int currentIndex = 0;
// // String? location, token, version, packagename, val, buildNumber;
// // final List<CameraDescription> cameras = [];
// // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
// String _message = '';
//
// // Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
// //   debugPrint("On Background  : $message");
// //
// //   if (message.containsKey('data')) {
// //     // Handle data message
// //     final dynamic data = message['data'];
// //   }
// //
// //   if (message.containsKey('notification')) {
// //     // Handle notification message
// //     final dynamic notification = message['notification'];
// //   }
// //   // Or do other work.
// // }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   if (Platform.isAndroid) {
//     NotificationService().init();
//   }
//
//   HttpOverrides.global = MyHttpOverrides();
//   try {
//     // Initialize Workmanager with error handling
//     await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
//     log("Workmanager initialized successfully");
//   } catch (e, stackTrace) {
//     log("Error initializing Workmanager: $e\n$stackTrace");
//     // Continue app startup even if Workmanager fails
//   }
//
//   runApp(const Main());
// }
//
// class Main extends StatelessWidget {
//   const Main({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return OverlaySupport.global(
//       child: MaterialApp(
//         theme: ThemeData(useMaterial3: false),
//         debugShowCheckedModeBanner: false,
//         routes: {},
//         home: StandardSplashScreen(),
//       ),
//     );
//   }
// }
