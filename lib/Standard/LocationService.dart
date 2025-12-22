import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import '../standard_app_entry.dart';
import 'constants.dart';

const String locationTask = "locationBackgroundTask";

final logger = Logger();

// Top-level callback dispatcher for Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  logger.i(
      "LocationService: callbackDispatcher: Starting task execution for task: $locationTask");
  print("callbackDispatcher: Starting task execution for task: $locationTask");

  Workmanager().executeTask((task, inputData) async {
    logger.i(
        "LocationService: callbackDispatcher: Executing task: $task with inputData: $inputData");
    print(
        "callbackDispatcher: Executing task: $task with inputData: $inputData");

    try {
      switch (task) {
        case locationTask:
          logger.i(
              "LocationService: callbackDispatcher: Processing location background task");
          print("callbackDispatcher: Processing location background task");
          try {
            print("callbackDispatcher: Calling sendBackgroundLocation");
            await LocationService()
                .sendBackgroundLocation(inputData: inputData);
            logger.i(
                "LocationService: callbackDispatcher: Location background task completed");
            print("callbackDispatcher: Location background task completed");
          } catch (e) {
            logger.e(
                "LocationService: callbackDispatcher: Error executing sendBackgroundLocation: $e");
            print("callbackDispatcher: Error in sendBackgroundLocation: $e");
          }
          break;
        default:
          logger.w("LocationService: callbackDispatcher: Unknown task: $task");
          print("callbackDispatcher: Unknown task: $task");
      }
      logger.i(
          "LocationService: callbackDispatcher: Task $task execution finished, returning true");
      print(
          "callbackDispatcher: Task $task execution finished, returning true");
      return Future.value(true);
    } catch (e) {
      logger.e(
          "LocationService: callbackDispatcher: Unexpected error in task execution: $e");
      print("callbackDispatcher: Unexpected error in task execution: $e");
      return Future.value(false);
    }
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() {
    logger.i("LocationService: Creating instance");
    return _instance;
  }
  LocationService._internal() {
    logger.i("LocationService: Internal constructor called");
  }

  // final FlutterLocalNotificationsPlugin _notificationsPlugin =
  //     FlutterLocalNotificationsPlugin();
  int? intervalInMiliSeconds;
  static DateTime? _lastRegistrationTime;
  static const Duration _debounceDuration = Duration(seconds: 30);

  // Future<void> initializeNotifications() async {
  //   logger.i("LocationService: Initializing notifications");
  //   try {
  //     const AndroidInitializationSettings initializationSettingsAndroid =
  //         AndroidInitializationSettings('@mipmap/ic_launcher');
  //     const InitializationSettings initializationSettings =
  //         InitializationSettings(android: initializationSettingsAndroid);

  //     // Create notification channel for Android 8.0+
  //     const AndroidNotificationChannel channel = AndroidNotificationChannel(
  //       'location_channel', // Must match AndroidNotificationDetails channel ID
  //       'Location Updates',
  //       description: 'Notifications for location tracking updates',
  //       importance: Importance.max,
  //     );
  //     final androidPlugin =
  //         _notificationsPlugin.resolvePlatformSpecificImplementation<
  //             AndroidFlutterLocalNotificationsPlugin>();
  //     await androidPlugin?.createNotificationChannel(channel);

  //     await _notificationsPlugin.initialize(initializationSettings);
  //     logger.i("LocationService: Notifications initialized successfully");
  //   } catch (e) {
  //     logger.e("LocationService: Error initializing notifications: $e");
  //   }
  // }

  bool _isNightShift(int start, int end) {
    bool isNight = start > end;
    logger.i("_isNightShift: start=$start, end=$end => isNight=$isNight");
    return isNight;
  }

  bool _isCurrentTimeInShift(int start, int end) {
    int now = int.parse(DateFormat('HHmm').format(DateTime.now()));
    bool inShift;
    if (start < end) {
      // Day shift
      inShift = now >= start && now < end;
      logger.i(
          "_isCurrentTimeInShift (Day): now=$now, start=$start, end=$end => inShift=$inShift");
    } else {
      // Night shift
      inShift = now >= start || now < end;
      logger.i(
          "_isCurrentTimeInShift (Night): now=$now, start=$start, end=$end => inShift=$inShift");
    }
    return inShift;
  }

  Future<bool> startBackgroundTracking() async {
    logger.i("LocationService: Attempting to start background tracking");
    print("startBackgroundTracking: Starting background tracking attempt");

    if (_lastRegistrationTime != null &&
        DateTime.now().difference(_lastRegistrationTime!) < _debounceDuration) {
      logger.i(
          "LocationService: Debouncing task registration. Too soon since last attempt.");
      print(
          "startBackgroundTracking: Debouncing, last registration: $_lastRegistrationTime, debounce duration: $_debounceDuration");
      return true;
    }

    _lastRegistrationTime = DateTime.now();
    logger.i(
        "LocationService: Setting last registration time to $_lastRegistrationTime");
    print(
        "startBackgroundTracking: Set last registration time to $_lastRegistrationTime");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("startBackgroundTracking: SharedPreferences instance obtained");

    bool isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
    logger.i("LocationService: isCheckedIn = $isCheckedIn");
    print("startBackgroundTracking: isCheckedIn = $isCheckedIn");

    if (!isCheckedIn) {
      logger.i(
          "LocationService: User has not checked in. Background tracking not started.");
      print("startBackgroundTracking: User not checked in, stopping tracking");
      await stopBackgroundTracking();
      return false;
    }
    String? shiftStartTime = prefs.getString("shiftstart");
    String? shiftEndTime = prefs.getString("shiftend");

    if (shiftStartTime != null && shiftEndTime != null) {
      int shiftStart = int.parse(shiftStartTime.replaceAll(":", ""));
      int shiftEnd = int.parse(shiftEndTime.replaceAll(":", ""));
      int currentTime = int.parse(DateFormat('HHmm').format(DateTime.now()));

// Allow early check-in for both day and night shift.
// For day shift, allow tracking until shift end.
// For night shift, allow tracking from early check-in until the next shift end.
      if (!_isNightShift(shiftStart, shiftEnd)) {
        // Day shift
        if (currentTime >= shiftEnd) {
          logger.w("Current time is past day shift end, stop tracking.");
          return false;
        } else {
          logger.i(
              "Day shift: tracking allowed (early check-in or during shift).");
        }
      } else {
        // Night shift (e.g., 20:00 to 05:00)
        if (currentTime >= shiftEnd && currentTime < shiftStart) {
          // Between end and next start: do not track
          logger.w(
              "Night shift: current time is outside shift window, stop tracking.");
          return false;
        } else {
          logger.i(
              "Night shift: tracking allowed (early check-in or during shift).");
        }
      }

// If here, allow tracking (early check-in allowed for both shift types)
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print(
        "startBackgroundTracking: Location services enabled = $serviceEnabled");
    if (!serviceEnabled) {
      logger.w("LocationService: Location services disabled. Prompting user.");
      print(
          "startBackgroundTracking: Location services disabled, showing notification");
      // await _showNotification(
      //   id: 1236,
      //   title: "Location Services Disabled",
      //   body: "Please enable location services to start tracking.",
      // );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    logger.i("LocationService: Location permission status: $permission");
    print("startBackgroundTracking: Location permission status = $permission");

    if (permission != LocationPermission.always) {
      logger.i("LocationService: Requesting background location permission");
      print(
          "startBackgroundTracking: Requesting background location permission");
      permission = await Geolocator.requestPermission();
      print("startBackgroundTracking: Permission request result = $permission");
      if (permission != LocationPermission.always) {
        logger.w("LocationService: Background location permission denied.");
        print(
            "startBackgroundTracking: Background location permission denied, showing notification");
        // await _showNotification(
        //   id: 1237,
        //   title: "Permission Denied",
        //   body: "Background location permission is required.",
        // );
        return false;
      }
    }

    bool batteryOptimizationDenied =
        await Permission.ignoreBatteryOptimizations.isDenied;
    print(
        "startBackgroundTracking: Battery optimization permission denied = $batteryOptimizationDenied");
    if (batteryOptimizationDenied) {
      logger.i("LocationService: Requesting to disable battery optimization");
      print(
          "startBackgroundTracking: Requesting to disable battery optimization");
      await Permission.ignoreBatteryOptimizations.request();
      print("startBackgroundTracking: Battery optimization request completed");
    }

    // bool notificationDenied = await Permission.notification.isDenied;
    // print(
    //     "startBackgroundTracking: Notification permission denied = $notificationDenied");
    // if (notificationDenied) {
    //   logger.i("LocationService: Requesting notification permission");
    //   print("startBackgroundTracking: Requesting notification permission");
    //   await Permission.notification.request();
    //   print(
    //       "startBackgroundTracking: Notification permission request completed");
    // }

    try {
      print("startBackgroundTracking: Initializing notifications");
      // await initializeNotifications();
      print("startBackgroundTracking: Notifications initialized");

      bool isTaskRegistered = prefs.getBool('isTaskRegistered') ?? false;
      logger.i("LocationService: isTaskRegistered = $isTaskRegistered");
      print("startBackgroundTracking: isTaskRegistered = $isTaskRegistered");

      final taskId = "location-tracking-task";
      intervalInMiliSeconds =
          goGreenModel?.backgroundLocationInterval ?? 900000;
      int taskInterval = intervalInMiliSeconds ?? 900000;
      print(
          "startBackgroundTracking: taskInterval = $taskInterval ms, goGreenModel interval = ${goGreenModel?.backgroundLocationInterval}");

      if (taskInterval < 900000) {
        logger.w(
            "LocationService: Interval $taskInterval ms is too short. Setting to 900000 ms.");
        print(
            "startBackgroundTracking: Interval too short, setting to 900000 ms");
        taskInterval = 900000;
      }

      if (isTaskRegistered) {
        logger.i(
            "LocationService: Task $taskId already registered. Verifying interval.");
        print(
            "startBackgroundTracking: Task $taskId already registered, checking interval");
        int? storedInterval = prefs.getInt('taskInterval');
        print("startBackgroundTracking: Stored interval = $storedInterval");

        if (storedInterval != taskInterval) {
          logger.i(
              "LocationService: Interval changed from $storedInterval to $taskInterval. Updating task.");
          print(
              "startBackgroundTracking: Interval changed, canceling all tasks and registering new one");
          await Workmanager().cancelAll();
          print("startBackgroundTracking: All tasks canceled");
          await registerTask(taskId, taskInterval, prefs);
          print(
              "startBackgroundTracking: New task registered with interval $taskInterval");
        } else {
          logger.i(
              "LocationService: Task interval unchanged. Skipping registration.");
          print(
              "startBackgroundTracking: Task interval unchanged, skipping registration");
          return true;
        }
      } else {
        logger.i("LocationService: No task registered. Registering new task.");
        print(
            "startBackgroundTracking: No task registered, registering new task");
        await registerTask(taskId, taskInterval, prefs);
        print(
            "startBackgroundTracking: Task $taskId registered with interval $taskInterval");
      }

      print(
          "startBackgroundTracking: Showing 'Location Sending Started' notification");
      // await _showNotification(
      //   id: 1234,
      //   title: "Location Sending Started",
      //   body: "Your location is being updated in the background.",
      // );

      logger.i(
          "LocationService: Background location tracking started successfully");
      print(
          "startBackgroundTracking: Background location tracking started successfully");
      return true;
    } catch (e) {
      logger.e("LocationService: Error starting background tracking: $e");
      print("startBackgroundTracking: Error starting background tracking: $e");
      // await _showNotification(
      //   id: 1267,
      //   title: "Tracking Error",
      //   body: "Failed to start background tracking: $e",
      // );
      return false;
    }
  }

  Future<void> registerTask(
      String taskId, int taskInterval, SharedPreferences prefs) async {
    logger.i(
        "LocationService: Registering task $taskId with interval $taskInterval ms");
    await Workmanager().registerPeriodicTask(
      taskId,
      locationTask,
      frequency: Duration(milliseconds: taskInterval),
      inputData: {
        'backgroundLocationInterval': taskInterval.toString(),
      },
      constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresDeviceIdle: false, // ✅ Add this line
          requiresStorageNotLow: false),

      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay:
          Duration(seconds: 5), // Add initial delay for immediate testing
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: Duration(seconds: 10),
    );
    await prefs.setBool('isTaskRegistered', true);
    await prefs.setInt('taskInterval', taskInterval);
    logger.i("LocationService: Task $taskId registered successfully");
  }

  Future<void> stopBackgroundTracking() async {
    logger.i("LocationService: Stopping background tracking");
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isCheckedIn', false);
      await prefs.setBool('isTaskRegistered', false);
      await prefs.remove('taskInterval');
      logger.i("LocationService: All tasks cancelled and flags reset");

      // await _showNotification(
      //   id: 1245,
      //   title: "Location Tracking Stopped",
      //   body: "Your location tracking has been stopped.",
      // );
      // Add delay to ensure notification is queued and rendered
      await Future.delayed(Duration(milliseconds: 5000));
      await Workmanager().cancelAll();
    } catch (e) {
      logger.e("LocationService: Error stopping background tracking: $e");
    }
  }

  Future<void> sendBackgroundLocation({Map<String, dynamic>? inputData}) async {
    logger.i("LocationService: Starting location update process");
    print("sendBackgroundLocation: Starting location update process");

    try {
      print("sendBackgroundLocation: Initializing notifications");
      // await initializeNotifications();
      print("sendBackgroundLocation: Notifications initialized");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      print("sendBackgroundLocation: SharedPreferences instance obtained");

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print(
          "sendBackgroundLocation: Location services enabled = $serviceEnabled");
      if (!serviceEnabled) {
        logger.w("LocationService: Location services disabled. Aborting.");
        print(
            "sendBackgroundLocation: Location services disabled, showing notification");
        // await _showNotification(
        //   id: 1286,
        //   title: "Location Services Disabled",
        //   body: "Please enable location services to continue tracking.",
        // );
        return;
      }

      var permission = await Geolocator.checkPermission();
      print("sendBackgroundLocation: Location permission status = $permission");
      if (permission != LocationPermission.always) {
        logger.w(
            "LocationService: Background location permission not granted. Aborting.");
        print(
            "sendBackgroundLocation: Background permission not granted, showing notification");
        // await _showNotification(
        //   id: 1287,
        //   title: "Permission Denied",
        //   body: "Background location permission is required.",
        // );
        return;
      }

      print("sendBackgroundLocation: Fetching current position");
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      logger.i(
          "LocationService: Position obtained - Lat: ${position.latitude}, Long: ${position.longitude}");
      print(
          "sendBackgroundLocation: Position obtained - Lat: ${position.latitude}, Long: ${position.longitude}");

      int? interval =
          inputData != null && inputData['backgroundLocationInterval'] != null
              ? int.tryParse(inputData['backgroundLocationInterval'])
              : 900000;
      logger.i("LocationService: Using interval: $interval ms");
      print("sendBackgroundLocation: Using interval: $interval ms");

      String? shiftEndTime = prefs.getString("shiftend");
      print(
          "sendBackgroundLocation: Shift end time from SharedPreferences: $shiftEndTime");

      var uri = "$customurl/controller/process/app/profile.php";
      print("sendBackgroundLocation: Fetching profile data from $uri");
      final responseShiftEnd = await http.post(Uri.parse(uri), body: {
        'type': 'fetch_profile',
        'cid': prefs.getString('comp_id'),
        'uid': prefs.getString('uid')
      }, headers: {
        'Accept': 'application/json'
      });

      print(
          "sendBackgroundLocation: Profile fetch response status: ${responseShiftEnd.statusCode}");
      Map? data = json.decode(responseShiftEnd.body);
      print("sendBackgroundLocation: Profile fetch response data: $data");

      if (data?['status'] == true) {
        List? userData = data?["data"];
        String? newEndShiftTime = userData?[0]['shift_end'];
        String? newStartShiftTime = userData?[0]['shift_start'];
        if (newStartShiftTime != null) {
          await prefs.setString("shiftstart", newStartShiftTime);
        }

        print(
            "sendBackgroundLocation: New shift end time from server: $newEndShiftTime");
        if (newEndShiftTime != null && newEndShiftTime != shiftEndTime) {
          logger.i(
              "LocationService: Shift end time changed from $shiftEndTime to $newEndShiftTime");
          print(
              "sendBackgroundLocation: Shift end time changed from $shiftEndTime to $newEndShiftTime");
          await prefs.setString("shiftend", newEndShiftTime);
          shiftEndTime = newEndShiftTime;
          print(
              "sendBackgroundLocation: Updated shiftend in SharedPreferences to $newEndShiftTime");
        }
      }

      if (shiftEndTime == null) {
        logger.w("LocationService: Shift end time not set. Aborting.");
        print(
            "sendBackgroundLocation: Shift end time not set, stopping tracking");
        await stopBackgroundTracking();
        // await _showNotification(
        //   id: 1239,
        //   title: "Shift time is not found",
        //   body: "Your location cannot sent.",
        // );
        return;
      }

      String? shiftStartTime = prefs.getString("shiftstart");
      shiftStartTime = shiftStartTime?.replaceAll(":", "");
      int shiftStart = int.parse(shiftStartTime ?? "0000");

      shiftEndTime = shiftEndTime.replaceAll(":", "");
      print("sendBackgroundLocation: Formatted shift end time: $shiftEndTime");
      int shiftEnd = int.parse(shiftEndTime);
      int currentTime = int.parse(DateFormat('HHmm').format(DateTime.now()));
      logger.i(
          "LocationService: Current time: $currentTime, Shift end: $shiftEnd");
      print(
          "sendBackgroundLocation: Current time: $currentTime, Shift end: $shiftEnd");

      if (!_isNightShift(shiftStart, shiftEnd)) {
        // Day shift: allow early check-in, stop only if after shift end
        if (currentTime >= shiftEnd) {
          await Future.delayed(Duration(milliseconds: 5000));
          await Workmanager().cancelAll();
          await prefs.setBool('isCheckedIn', false);
          await prefs.setBool('isTaskRegistered', false);
          await prefs.remove('taskInterval');
          return;
        }
      } else {
        // Night shift: stop if not in shift window
        if (!_isCurrentTimeInShift(shiftStart, shiftEnd)) {
          await Future.delayed(Duration(milliseconds: 5000));
          await Workmanager().cancelAll();
          await prefs.setBool('isCheckedIn', false);
          await prefs.setBool('isTaskRegistered', false);
          await prefs.remove('taskInterval');
          return;
        }
      }

      print("sendBackgroundLocation: Sending location to server");
      var response = await http.post(
        Uri.parse("$customurl/controller/process/app/location_track.php"),
        body: {
          'uid': prefs.getString('uid') ?? "",
          'cid': prefs.getString('comp_id') ?? "",
          'type': 'add_loc',
          'lat': position.latitude.toString(),
          'long': position.longitude.toString(),
        },
        headers: {'Accept': 'application/json'},
      );

      print(
          "sendBackgroundLocation: Location update response status: ${response.statusCode}");
      Map? locationData = json.decode(response.body);
      logger.i("LocationService: Location update response: $locationData");
      print("sendBackgroundLocation: Location update response: $locationData");

      if (locationData?['status'] == true) {
        logger.i(
            "LocationService: Location updated successfully at ${DateTime.now()}");
        print(
            "sendBackgroundLocation: Location updated successfully at ${DateTime.now()}");
        // await _showNotification(
        //   id: 1235,
        //   title: "Location Updated",
        //   body: "Your location was successfully sent.",
        // );
      } else {
        logger.w("LocationService: Failed to send location.");
        print(
            "sendBackgroundLocation: Failed to send location, showing notification");
        // await _showNotification(
        //   id: 1297,
        //   title: "Location Update Failed",
        //   body: "An unexpected error occurs.",
        // );
      }
    } catch (e) {
      logger.e("LocationService: Error in sendBackgroundLocation: $e");
      print("sendBackgroundLocation: Error occurred: $e");
      // await _showNotification(
      //   id: 1207,
      //   title: "Location Update Error",
      //   body: "An error occurred: $e",
      // );
    }
  }

  // Future<void> _showNotification({
  //   required int id,
  //   required String title,
  //   required String body,
  // }) async {
  //   logger.i(
  //       "LocationService: Showing notification with id: $id, title: $title, body: $body");
  //   try {
  //     const AndroidNotificationDetails androidDetails =
  //         AndroidNotificationDetails(
  //       'location_channel',
  //       'Location Updates',
  //       importance: Importance.max,
  //       priority: Priority.high,
  //     );
  //     const NotificationDetails platformDetails =
  //         NotificationDetails(android: androidDetails);
  //     await _notificationsPlugin.show(id, title, body, platformDetails);
  //     logger.i("LocationService: Notification shown successfully");
  //   } catch (e) {
  //     logger.e("LocationService: Error showing notification: $e");
  //   }
  // }
}
