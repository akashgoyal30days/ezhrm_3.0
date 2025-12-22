import 'package:flutter_background/flutter_background.dart';

Future<bool> enableMinimalBackgroundMode() async {
  final androidConfig = const FlutterBackgroundAndroidConfig(
    notificationTitle: "EZHRM",
    notificationText: "Location tracking active.",
    notificationImportance:
        AndroidNotificationImportance.normal, // least intrusive
    notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    enableWifiLock: false,
  );
  final result =
      await FlutterBackground.initialize(androidConfig: androidConfig);
  if (result) {
    return await FlutterBackground.enableBackgroundExecution();
  }
  return false;
}
