import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import '../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../Authentication/User Information/user_details.dart';
import '../Authentication/User Information/user_session.dart';
import '../Configuration/ApiUrlConfig.dart';
import '../Dependency_Injection/dependency_injection.dart';

// NEW: Helper to parse time and check if it's before 12 AM
bool _isMorningShift(String? endTime) {
  if (endTime == null || endTime.isEmpty) return false;
  try {
    final timeParts = endTime.split(':');
    final hour = int.parse(timeParts[0]);
    return hour <
        24; // Consider shifts ending before midnight as morning shifts
  } catch (e) {
    print('LocationService: Error parsing end time $endTime: $e');
    return false;
  }
}

// Top-level function for background service onStart
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print(
        'LocationService: Workmanager task $task started at ${DateTime.now()}');
    try {
      // Initialize dependencies
      WidgetsFlutterBinding.ensureInitialized();
      setupDependencies();
      if (!getIt.isRegistered<LocationService>()) {
        print('LocationService: LocationService not registered in Workmanager');
        return false;
      }

      // Initialize notifications in background isolate
      await LocationService._initializeNotifications();
      print('LocationService: Notifications initialized in Workmanager');

      final locationService = getIt<LocationService>();
      final apiUrlConfig = locationService.apiUrlConfig;
      final userSession = locationService.userSession;
      final userDetails = locationService.userDetails;
      final getTodayAttendanceBloc = getIt<GetTodayAttendanceBloc>();

      // Validate dependencies
      final prefs = await SharedPreferences.getInstance();
      String serverUrl = apiUrlConfig.locationSending.isNotEmpty
          ? apiUrlConfig.locationSending
          : prefs.getString('api_url') ?? 'https://fallback-api.com';
      String? token = await userSession.token ?? prefs.getString('user_token');
      String? uid = await userSession.uid ?? prefs.getString('user_uid');
      bool isCheckedIn = await userDetails.getCheckedIn() ??
          prefs.getBool(LocationService._isCheckedInKey) ??
          false;
      bool isCheckedOut = await userDetails.getCheckedOut() ??
          prefs.getBool(LocationService._isCheckedOutKey) ??
          false;
      String? currentCheckoutTime = await userDetails.getCheckoutTime();
      String? shiftEndTime = await userDetails.getEndTime();
      print(
          'LocationService: Dependencies - url=$serverUrl, token=${token?.substring(0, 10)}..., uid=$uid, isCheckedIn=$isCheckedIn,'
          ' isCheckedOut=$isCheckedOut, currentCheckoutTime=$currentCheckoutTime, shiftEndTime=$shiftEndTime');
      if (serverUrl.isEmpty) {
        print(
            'LocationService: Missing dependencies in Workmanager: url=$serverUrl, token=$token, uid=$uid');
        return false;
      }

      final now = DateTime.now();
      final todayDate = DateFormat('yyyy-MM-dd').format(now);
      final lastProcessedDate = await userDetails.getLastProcessedTime();
      print(
          'LocationService: Today: $todayDate, Last Processed Date: $lastProcessedDate');
      final isMorningShift = _isMorningShift(shiftEndTime);
      final isDayChanged =
          lastProcessedDate != null && lastProcessedDate != todayDate;
      print(
          'LocationService: Is Morning Shift: $isMorningShift, Is Day Changed: $isDayChanged');

      final lastShownDate =
          prefs.getString(LocationService._markAttendanceNotification);
      print('LocationService: Last Shown Date: $lastShownDate');
      if (lastShownDate != null && lastShownDate != todayDate) {
        await prefs.remove(LocationService._markAttendanceNotification);
        print(
            'LocationService: Reset mark attendance notification flag for new day');
      }

      if (isDayChanged && isMorningShift) {
        print(
            'LocationService: Day changed (last=$lastProcessedDate, today=$todayDate) or test time 2:30 PM for morning shift, stopping location sending');
        isCheckedIn = false;
        isCheckedOut = false;
        await prefs.setBool('workmanager_initialized', false);
        currentCheckoutTime = null;
        LocationService.resetForNewDay();
        return false;
      } else {
        print('CallBackDispatcher: LocationService: Day is not changed');
        await userDetails.setLastProcessedTime(todayDate);
        print('LocationService: Updated lastProcessedDate to $todayDate');
        print(
            'LocationService: stored value in the local storage ${await userDetails.getLastProcessedTime()}');
      }

      // Check permissions
      print('LocationService: Checking location always permission');
      if (await Permission.locationAlways.isDenied) {
        print(
            'LocationService: Background location permission denied in Workmanager');
        await LocationService.stopLocationService();
        return false;
      }
      print('LocationService: Background location permission granted');

      // Fetch today's attendance
      print('LocationService: Dispatching GetTodayAttendance in Workmanager');
      final completer = Completer<void>();
      String? apiCheckoutTime;
      bool hasValidAttendance = false;

      final subscription = getTodayAttendanceBloc.stream.listen((state) async {
        if (state is GetTodayAttendanceSuccess) {
          print(
              'LocationService: GetTodayAttendanceSuccess, data: ${state.attendanceData}');
          if (state.attendanceData.isEmpty) {
            print('LocationService: No attendance record found in API');
            isCheckedIn = false;
            isCheckedOut = false;
            currentCheckoutTime = null;
            await userDetails.setCheckedIn(false);
            await userDetails.setCheckedOut(false, null);
            await prefs.setBool(LocationService._isCheckedInKey, false);
            await prefs.setBool(LocationService._isCheckedOutKey, false);
            await prefs.remove(LocationService._currentCheckoutTimeKey);
            await prefs.remove(LocationService._newCheckoutTimeKey);
            print(
                'LocationService: Cleared check-in/out states and checkout times');
            await LocationService.stopLocationService();
            // NEW: Removed showMarkAttendanceNotification call to avoid background notifications
            print(
                'LocationService: No attendance record - Stopped location service');
          } else {
            final attendanceRecord = state.attendanceData.firstWhere(
              (data) =>
                  data['type'] == 'Attendance' && data['check-in'] != null,
              orElse: () => <String, dynamic>{},
            );

            print('LocationService: Attendance record: $attendanceRecord');
            if (attendanceRecord.isNotEmpty) {
              hasValidAttendance = true;
              apiCheckoutTime = attendanceRecord['check-out'] as String?;
              print('LocationService: API checkout time: $apiCheckoutTime');
              if (apiCheckoutTime != null && apiCheckoutTime!.isNotEmpty) {
                if (apiCheckoutTime != currentCheckoutTime) {
                  print(
                      'LocationService: Check-out time changed, handling check-out');
                  await LocationService.handleCheckOut(
                      apiCheckoutTime!, userDetails);
                  isCheckedIn = false;
                  isCheckedOut = true;
                  currentCheckoutTime = apiCheckoutTime;
                  await prefs.setBool(LocationService._isCheckedInKey, false);
                  await prefs.setBool(LocationService._isCheckedOutKey, true);
                  print('LocationService: Updated check-out state in prefs');
                  print(
                      'LocationService: Check-out processed - Stopped location service');
                } else if (isCheckedOut) {
                  print(
                      'LocationService: Check-out value is true so stop the location service');
                  isCheckedIn = false;
                  isCheckedOut = true;
                  await prefs.setBool(LocationService._isCheckedInKey, false);
                  await prefs.setBool(LocationService._isCheckedOutKey, true);
                  await LocationService.stopLocationService();
                  bool trackingStatus = await userDetails.getTrackingStatus();
                  if (trackingStatus) {
                    await LocationService._showCheckoutNotification();
                  }
                  print(
                      'LocationService: Check-out processed - Stopped location service');
                  print(
                      'LocationService: Check-out processed, tracking stopped, notification shown');
                } else {
                  print(
                      'LocationService: Check-out already processed with same time');
                  isCheckedIn = true;
                  isCheckedOut = false;
                  await userDetails.setCheckedIn(true);
                  await userDetails.setCheckOutValue(false);
                  await prefs.setBool(LocationService._isCheckedInKey, true);
                  await prefs.setBool(LocationService._isCheckedOutKey, false);
                  print('LocationService: Updated check-in state in prefs');
                }
              } else {
                print('LocationService: Check-in detected, no check-out');
                isCheckedIn = true;
                isCheckedOut = false;
                currentCheckoutTime = null;
                await userDetails.setCheckedIn(true);
                await userDetails.setCheckedOut(false, null);
                await prefs.setBool(LocationService._isCheckedInKey, true);
                await prefs.setBool(LocationService._isCheckedOutKey, false);
                await prefs.remove(LocationService._currentCheckoutTimeKey);
                await prefs.remove(LocationService._newCheckoutTimeKey);
                print(
                    'LocationService: Cleared checkout times and updated check-in state');
                print(
                    'LocationService: Check-in state set - Continuing location sending');
              }
            } else {
              print('LocationService: No valid attendance record found');
              isCheckedIn = false;
              isCheckedOut = false;
              currentCheckoutTime = null;
              await userDetails.setCheckedIn(false);
              await userDetails.setCheckedOut(false, null);
              await prefs.setBool(LocationService._isCheckedInKey, false);
              await prefs.setBool(LocationService._isCheckedOutKey, false);
              await prefs.remove(LocationService._currentCheckoutTimeKey);
              await prefs.remove(LocationService._newCheckoutTimeKey);
              print('LocationService: Cleared all attendance states and times');
              await LocationService.stopLocationService();
              // NEW: Removed showMarkAttendanceNotification call to avoid background notifications
              print(
                  'LocationService: No valid attendance - Stopped location service');
            }
          }
          if (!completer.isCompleted) {
            print('LocationService: Completing attendance fetch');
            completer.complete();
          }
        } else if (state is GetTodayAttendanceFailure) {
          print(
              'LocationService: GetTodayAttendanceFailure: ${state.errorMessage}');
          if (!completer.isCompleted) {
            print('LocationService: Completing attendance fetch on failure');
            completer.complete();
          }
        }
      });

      getTodayAttendanceBloc.add(GetTodayAttendance());
      await completer.future.timeout(const Duration(seconds: 10),
          onTimeout: () {
        print(
            'LocationService: Timeout waiting for attendance data in Workmanager');
      });
      print('LocationService: Cancelling attendance subscription');
      await subscription.cancel();

      // Proceed with location sending only if checked in and not checked out
      if (!isCheckedIn || isCheckedOut) {
        print(
            'LocationService: Not tracking: isCheckedIn=$isCheckedIn, isCheckedOut=$isCheckedOut');
        await LocationService.stopLocationService();
        return false;
      }

      // Fetch position and send location
      print('LocationService: Fetching position for sending');
      Position position = await LocationService._determinePosition();
      print('LocationService: Sending location to server');
      await LocationService._sendLocationToServer(
        position,
        apiUrlConfig: apiUrlConfig,
        userSession: userSession,
        userDetails: userDetails,
      );

      print('LocationService: Workmanager task $task completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('LocationService: Workmanager task error: $e');
      print('LocationService: StackTrace: $stackTrace');
      return false;
    }
  });
}

class LocationService {
  final ApiUrlConfig apiUrlConfig;
  final UserSession userSession;
  final UserDetails userDetails;
  final GetTodayAttendanceBloc getTodayAttendanceBloc;

  const LocationService({
    required this.apiUrlConfig,
    required this.userSession,
    required this.userDetails,
    required this.getTodayAttendanceBloc,
  });

  // Default update interval
  static const int DEFAULT_UPDATE_INTERVAL = 15;
  static const int MIN_INTERVAL_MINUTES = 15;
  static const int MAX_INTERVAL_MINUTES = 60;
  static String? _currentAddress;

  // Keys for SharedPreferences
  static const String _lastSendTimeKey = 'last_location_send_time';
  static const String _intervalKey = 'location_update_interval';
  static const String _isTrackingEnabledKey = 'is_tracking_enabled';
  static const String _isCheckedInKey = 'is_checked_in';
  static const String _isCheckedOutKey = 'is_checked_out';
  static const String _currentCheckoutTimeKey =
      'current_checkout_time'; // CHANGED: Added from UserDetails
  static const String _newCheckoutTimeKey =
      'last_checkout_time'; // CHANGED: Added from UserDetails
  static const String _markAttendanceNotification =
      'mark_attendance_notification';
  static const bool _nextDayChecked = false;
  static final bool _isPermissionRequestInProgress = false;
  static const String _isTaskRegisteredKey =
      'is_task_registered'; // NEW: Key to track task registration
  static final Set<String> _processedCheckoutTimes = {};

  // NEW: Centralized check-out handling
  static Future<void> handleCheckOut(
      String checkoutTime, UserDetails userDetails) async {
    print(
        'LocationService: Handling check-out at ${DateTime.now()} with checkoutTime: $checkoutTime');
    try {
      if (checkoutTime.isEmpty) {
        throw ArgumentError('Checkout time cannot be empty');
      }

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      String? shiftEndTime = await userDetails.getEndTime();
      // if (_shouldSkipCheckout(now, shiftEndTime)) {
      //   print('LocationService: Past midnight for morning shift, skipping check-out as states are reset');
      //   resetForNewDay();
      //   return;
      // }

      String? newCheckoutTime = await userDetails.getNewCheckoutTime();
      bool currentIsCheckedIn = await userDetails.getCheckedIn() ?? false;
      bool currentIsCheckedOut = await userDetails.getCheckedOut() ?? false;

      if (newCheckoutTime != checkoutTime ||
          (!currentIsCheckedIn && currentIsCheckedOut)) {
        print(
            'LocationService: Updating check-out state with checkout time: $checkoutTime');

        await userDetails.setCheckedOut(true, checkoutTime);
        await userDetails.setCheckedIn(false);
        await stopLocationService();
        bool trackingStatus = await userDetails.getTrackingStatus();
        if (trackingStatus) {
          await LocationService._showCheckoutNotification();
        }
        print(
            'LocationService: Check-out processed, tracking stopped, notification shown');
      } else {
        print(
            'LocationService: Check-out already processed with same checkout time, skipping');
      }
    } catch (e, stackTrace) {
      print('LocationService: Error handling check-out: $e');
      print('LocationService: StackTrace: $stackTrace');
      throw Exception('Failed to handle check-out');
    }
  }

  static Future<void> resetForNewDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDetails = getIt<UserDetails>();
      await userDetails.setCheckedIn(false);
      await userDetails.setCheckedOut(false, null);
      await prefs.setBool(LocationService._isCheckedInKey, false);
      await prefs.setBool(LocationService._isCheckedOutKey, false);
      await prefs.remove(LocationService._currentCheckoutTimeKey);
      await prefs.remove(LocationService._newCheckoutTimeKey);

      // NEW: Clear task registration flag
      await prefs.setBool(LocationService._isTaskRegisteredKey, false);
      // NEW: Verify SharedPreferences state
      final checkInAfter =
          prefs.getBool(LocationService._isCheckedInKey) ?? false;
      final checkOutAfter =
          prefs.getBool(LocationService._isCheckedOutKey) ?? false;
      print(
          'LocationService: After reset - isCheckedIn: $checkInAfter, isCheckedOut: $checkOutAfter');
      if (checkInAfter || checkOutAfter) {
        print(
            'LocationService: WARNING: Failed to clear check-in or check-out in SharedPreferences');
      }

      final now = DateTime.now();
      final todayDate = DateFormat('yyyy-MM-dd').format(now);
      // Update last processed date
      await userDetails.setLastProcessedTime(todayDate);
      print('LocationService: Updated lastProcessedDate to $todayDate');
    } catch (e) {
      print('LocationService: Error resetting states: $e');
    }
    await LocationService.stopLocationService();
    await LocationService.showLocationStoppedNotification(
        'Day is over. To start location sending, mark your attendance');
    print(
        'LocationService: Reset states and stopped location service for new day');
  }

  static bool _shouldSkipCheckout(DateTime now, String? shiftEndTime) {
    return now.hour == 0 && now.minute > 0 && _isMorningShift(shiftEndTime);
  }

  // Initialize notification plugin for background isolate
  static Future<void> _initializeNotifications() async {
    print('LocationService: Initializing notifications');
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ezhrm_logo');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print(
            'LocationService: Notification response received: ${response.actionId}');
        if (response.actionId == 'turn_off_notification') {
          print('LocationService: Turn off notification action triggered');
          try {
            await stopLocationService();
            print(
                'LocationService: Location service stopped via notification action');
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_markAttendanceNotification);
            print('LocationService: Cleared mark attendance notification flag');
            if (response.id != null) {
              await flutterLocalNotificationsPlugin.cancel(response.id!);
              print('LocationService: Notification ID ${response.id} canceled');
            }
          } catch (e, stackTrace) {
            print('LocationService: Error handling turn off action: $e');
            print('LocationService: StackTrace: $stackTrace');
          }
        }
      },
    );
    print('LocationService: Notification plugin initialized successfully');

    const AndroidNotificationChannel workmanagerChannel =
        AndroidNotificationChannel(
      'workmanager_location',
      'Background Service',
      description: 'Silent channel for locationService tasks',
      importance: Importance.min,
      showBadge: false,
      enableLights: false,
      enableVibration: false,
      playSound: false,
    );
    const AndroidNotificationChannel locationServiceChannel =
        AndroidNotificationChannel(
      'location_service_channel',
      'Location Service',
      description: 'Notifications for location updates',
      importance: Importance.defaultImportance,
      showBadge: true,
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(workmanagerChannel);
    print('LocationService: Workmanager notification channel created');
    await androidPlugin?.createNotificationChannel(locationServiceChannel);
    print('LocationService: Location notification channel created');
    print('LocationService: Notification channels created');
  }

  // Show notification for successful location sending
  static Future<void> _showLocationSentNotification() async {
    print('LocationService: Showing location sent notification');
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'location_service_channel',
        'Location Service',
        channelDescription: 'Notifications for successful location updates',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
        ticker: 'Location Sent',
      );
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);
      final now = DateTime.now();
      final formattedTime = DateFormat('hh:mm a').format(now);
      await flutterLocalNotificationsPlugin.show(
        889,
        'Location Sending',
        'LocationService successfully sent at $formattedTime',
        notificationDetails,
      );
      print('LocationService: Notification displayed successfully');
    } catch (e) {
      print('LocationService: Error showing notification: $e');
    }
  }

  // Show notification to prompt user to mark attendance
  static Future<void> showMarkAttendanceNotification() async {
    print('LocationService: Attempting to show mark attendance notification');
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayDate = DateFormat('yyyy-MM-dd').format(now);
      final lastShownDate = prefs.getString(_markAttendanceNotification);

      // NEW: Skip if notification was already shown today
      if (lastShownDate == todayDate) {
        print(
            'LocationService: Mark attendance notification already shown today, skipping');
        return;
      }

      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'location_service_channel',
        'Location Service',
        channelDescription: 'Notifications for location updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        ticker: 'Mark Attendance',
        actions: [
          AndroidNotificationAction(
            'turn_off_notification',
            'Turn off notification',
            cancelNotification: true,
          ),
        ],
      );
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);
      final notificationId =
          (DateTime.now().millisecondsSinceEpoch % 10000) + 1000;
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        'Mark Your Attendance',
        'Please mark your attendance to start sending location.',
        notificationDetails,
      );
      await prefs.setString(_markAttendanceNotification, todayDate);
      print(
          'LocationService: Mark attendance notification shown with ID $notificationId and flag set for $todayDate');
    } catch (e) {
      print('LocationService: Error showing mark attendance notification: $e');
    }
  }

  static Future<void> showLocationStoppedNotification(
      String notificationText) async {
    print('LocationService: Showing location stopped notification');
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'location_service_channel',
        'Location Service',
        channelDescription: 'Notifications for location updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        ticker: 'Location Stopped',
      );
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);
      final notificationId =
          (DateTime.now().millisecondsSinceEpoch % 10000) + 2000;
      await flutterLocalNotificationsPlugin.show(
        720,
        'Location Sending Stopped',
        notificationText,
        notificationDetails,
      );
      print(
          'LocationService: Location stopped notification shown with ID $notificationId');
    } catch (e) {
      print('LocationService: Error showing location stopped notification: $e');
    }
  }

  // Show notification for checkout
  static Future<void> _showCheckoutNotification() async {
    print('LocationService: Showing checkout notification');
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'location_service_channel',
        'Location Service',
        channelDescription: 'Notifications for location updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        ticker: 'Checked Out',
        actions: [
          AndroidNotificationAction(
            'turn_off_notification',
            'Turn off notification',
            cancelNotification: true,
          ),
        ],
      );
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);
      final notificationId = DateTime.now().millisecondsSinceEpoch % 10000;
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        'Checked Out',
        'User is checked out. To continue location sending, please check in again.',
        notificationDetails,
      );
      print(
          'LocationService: Checkout notification shown with ID $notificationId');
    } catch (e) {
      print('LocationService: Error showing checkout notification: $e');
    }
  }

  // Modified initializeService to check attendance on app open
  static Future<void> initializeService() async {
    print('LocationService: Starting initializeService at ${DateTime.now()}');
    try {
      final locationService = getIt<LocationService>();
      final userDetails = getIt<UserDetails>();
      // await locationService.userDetails.initialize();
      // print('LocationService: UserDetails initialized');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('workmanager_initialized', true);
      print('LocationService: Workmanager initialization confirmed');

      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        print('LocationService: Requesting battery optimization exemption');
        await Permission.ignoreBatteryOptimizations.request();
        if (await Permission.ignoreBatteryOptimizations.isDenied) {
          print(
              'LocationService: Battery optimization exemption denied, prompting user');
        }
      }

      // Request permissions
      final permissions = await userDetails.getUserPermissions();
      print('HRMDashboard: Permissions: $permissions');
      final gpsLocation = permissions[1]; // gpsLocation is at index 1

      if (gpsLocation == '1') {
        if (await Permission.location.isDenied) {
          print('LocationService: Requesting location permission');
          await Permission.location.request();
        }
        if (await Permission.locationAlways.isDenied) {
          print('LocationService: Requesting background location permission');
          await Permission.locationAlways.request();
        }
      }
      if (await Permission.notification.isDenied) {
        print('LocationService: Requesting notification permission');
        await Permission.notification.request();
      }
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        print('LocationService: Requesting battery optimization exemption');
        await Permission.ignoreBatteryOptimizations.request();
      }

      await _initializeNotifications();

      // final prefs = await SharedPreferences.getInstance();
      try {
        await prefs.setString(
            'api_url', locationService.apiUrlConfig.locationSending);
        await prefs.setString(
            'user_token', await locationService.userSession.token ?? '');
        await prefs.setString(
            'user_uid', await locationService.userSession.uid ?? '');
        await prefs.setBool(_isTrackingEnabledKey,
            await locationService.userDetails.getLocationPermission());
        await prefs.setBool(
            _isCheckedInKey, await locationService.userDetails.getCheckedIn());
        await prefs.setBool(_isCheckedOutKey,
            await locationService.userDetails.getCheckedOut());
        String? currentCheckoutTime =
            await locationService.userDetails.getCheckoutTime();
        String? newCheckoutTime =
            await locationService.userDetails.getNewCheckoutTime();
        print(
            'LocationService: Initializing - currentCheckoutTime=$currentCheckoutTime, newCheckoutTime=$newCheckoutTime');
        if (currentCheckoutTime != null && currentCheckoutTime.isNotEmpty) {
          await prefs.setString(_currentCheckoutTimeKey, currentCheckoutTime);
        }
        if (newCheckoutTime != null && newCheckoutTime.isNotEmpty) {
          await prefs.setString(_newCheckoutTimeKey, newCheckoutTime);
        }

        // Check attendance status to show notification if not marked
        bool isCheckedIn = await locationService.userDetails.getCheckedIn() ??
            prefs.getBool(_isCheckedInKey) ??
            false;
        bool isCheckedOut = await locationService.userDetails.getCheckedOut() ??
            prefs.getBool(_isCheckedOutKey) ??
            false;
        print(
            'LocationService: Initial state - isCheckedIn: $isCheckedIn, isCheckedOut: $isCheckedOut');

        if (!isCheckedIn && !isCheckedOut) {
          print(
              'LocationService: No check-in detected, fetching attendance data');
          final completer = Completer<void>();
          final subscription = locationService.getTodayAttendanceBloc.stream
              .listen((state) async {
            if (state is GetTodayAttendanceSuccess) {
              print(
                  'LocationService: GetTodayAttendanceSuccess, data: ${state.attendanceData}');
              final attendanceRecord = state.attendanceData.firstWhere(
                (data) =>
                    data['type'] == 'Attendance' && data['check-in'] != null,
                orElse: () => <String,
                    dynamic>{}, // FIXED: Return empty map instead of null
              );
              if (attendanceRecord.isEmpty) {
                print(
                    'LocationService: No valid attendance record found, showing notification');
                await showMarkAttendanceNotification();
              }
              if (!completer.isCompleted) completer.complete();
            } else if (state is GetTodayAttendanceFailure) {
              print(
                  'LocationService: GetTodayAttendanceFailure: ${state.errorMessage}');
              // Show notification on failure as fallback
              await showMarkAttendanceNotification();
              if (!completer.isCompleted) completer.complete();
            }
          });

          locationService.getTodayAttendanceBloc.add(GetTodayAttendance());
          await completer.future.timeout(const Duration(seconds: 10),
              onTimeout: () {
            print(
                'LocationService: Timeout waiting for attendance data in initializeService');
            // Show notification on timeout as fallback
            showMarkAttendanceNotification();
          });
          await subscription.cancel();
        }

        // Check checkout status and handle if necessary
        if (isCheckedOut && (currentCheckoutTime != newCheckoutTime)) {
          final checkoutTime = newCheckoutTime!;
          print(
              'LocationService: User is checked out, ensuring notification and tracking stopped with checkoutTime=$checkoutTime');
          await handleCheckOut(checkoutTime, locationService.userDetails);
        }

        print(
            'LocationService: Stored preferences and checked attendance state');
      } catch (e, stackTrace) {
        print(
            'LocationService: Failed to store preferences or check attendance: $e');
        print('LocationService: StackTrace: $stackTrace');
      }
    } catch (e, stackTrace) {
      print('LocationService: Error in initializeService: $e');
      print('LocationService: StackTrace: $stackTrace');
      rethrow;
    }
  }

  // Start the location tracking service
  Future<void> startLocationService() async {
    print('LocationService: Starting location service at ${DateTime.now()}');
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isTrackingEnabled = await userDetails.getLocationPermission() ??
          prefs.getBool(_isTrackingEnabledKey) ??
          false;
      bool isCheckedIn = await userDetails.getCheckedIn() ??
          prefs.getBool(_isCheckedInKey) ??
          false;
      bool isCheckedOut = await userDetails.getCheckedOut() ??
          prefs.getBool(_isCheckedOutKey) ??
          false;
      String? currentCheckoutTime = await userDetails.getCheckoutTime();
      bool isTaskRegistered = prefs.getBool(_isTaskRegisteredKey) ?? false;
      print(
          'LocationService: isTrackingEnabled=$isTrackingEnabled, isCheckedIn=$isCheckedIn, isCheckedOut=$isCheckedOut, currentCheckoutTime=$currentCheckoutTime, isTaskRegistered=$isTaskRegistered');

      bool isWorkmanagerInitialized =
          prefs.getBool('workmanager_initialized') ?? false;
      if (!isWorkmanagerInitialized) {
        print('LocationService: Workmanager not initialized, initializing now');
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: false,
        );
        await prefs.setBool('workmanager_initialized', true);
        print(
            'LocationService: Workmanager initialized in startLocationService');
      }

      if (!isTrackingEnabled || !isCheckedIn || isCheckedOut) {
        print(
            'LocationService: Location sending stopped - Tracking: $isTrackingEnabled, CheckedIn: $isCheckedIn, CheckedOut: $isCheckedOut');
        await stopLocationService();
        await showLocationStoppedNotification(
            'Location sending stopped. Please check the app');
        return;
      }

      if (await Permission.location.isDenied ||
          await Permission.locationAlways.isDenied) {
        print('LocationService: Location permission denied');
        await stopLocationService();
        await showLocationStoppedNotification(
            'Location sending stopped due to permission denied');
        return;
      }

      if (!isTaskRegistered || currentCheckoutTime == null) {
        print('LocationService: Registering Workmanager tasks');
        double? interval = await userDetails.getTimeInterval();
        int timeInterval = interval?.toInt() ??
            prefs.getInt(_intervalKey) ??
            DEFAULT_UPDATE_INTERVAL;
        timeInterval =
            timeInterval.clamp(MIN_INTERVAL_MINUTES, MAX_INTERVAL_MINUTES);
        await prefs.setInt(_intervalKey, timeInterval);

        // Register one-off task for immediate execution
        await Workmanager().registerOneOffTask(
          'location_task_initial_${DateTime.now().millisecondsSinceEpoch}',
          'send_location',
          initialDelay: Duration.zero,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
          ),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
        print('LocationService: One-off task registered');

        // Register periodic task
        await Workmanager().registerPeriodicTask(
          'location_task',
          'send_location',
          frequency: Duration(minutes: timeInterval),
          initialDelay: Duration.zero,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
          ),
          existingWorkPolicy: ExistingWorkPolicy.keep,
        );
        await prefs.setBool(_isTaskRegisteredKey, true);
        print(
            'LocationService: Periodic task registered with $timeInterval-minute interval');
      } else {
        print('LocationService: Task already registered, ensuring execution');
        // Force a one-off task to ensure immediate execution
        await Workmanager().registerOneOffTask(
          'location_task_retry_${DateTime.now().millisecondsSinceEpoch}',
          'send_location',
          initialDelay: Duration.zero,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
          ),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
        print('LocationService: Retry one-off task registered');
      }
    } catch (e, stackTrace) {
      print('LocationService: Error starting service: $e');
      print('LocationService: StackTrace: $stackTrace');
      await stopLocationService();
      rethrow;
    }
  }

  // Stop the location tracking service
  static Future<void> stopLocationService() async {
    print(
        'LocationService: Attempting to stop location service at ${DateTime.now()}');
    try {
      await Workmanager().cancelByUniqueName('location_task');
      print('LocationService: Workmanager task cancelled');
      print('LocationService: stopLocationService checkout notification shown');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
          _isTaskRegisteredKey, false); // NEW: Clear task registration flag
      print(
          'LocationService: Workmanager task cancelled and registration flag cleared');
    } catch (e, stackTrace) {
      print('LocationService: Error stopping service: $e');
      print('LocationService: StackTrace: $stackTrace');
    }
  }

  // Get current position with permission handling
  static Future<Position> _determinePosition() async {
    print('LocationService: Checking location services');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('LocationService: Location services enabled: $serviceEnabled');
    if (!serviceEnabled) {
      print('LocationService: Location services disabled');
      throw Exception('Location services are disabled');
    }

    print('LocationService: Checking location permissions');
    LocationPermission permission = await Geolocator.checkPermission();
    print('LocationService: Current permission: $permission');
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print(
          'LocationService: Location permission denied, attempting to request');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('LocationService: Location permissions denied');
        throw Exception('Location permissions are denied');
      }
    }

    print('LocationService: Getting current position');
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // Optimize battery usage
    );
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        LocationService._currentAddress =
            '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        print(
            'LocationService: Fetching address from _getAddressFromLatLng: ${LocationService._currentAddress}');
      } else {
        _currentAddress = 'No address found for this location.';
      }
    } catch (e) {
      _currentAddress = 'Unable to fetch address';
    }
    print(
        'LocationService: Position obtained: Lat=${position.latitude},Lng=${position.longitude}');
    return position;
  }

  // Send location data to server
  static Future<void> _sendLocationToServer(
    Position position, {
    required ApiUrlConfig apiUrlConfig,
    required UserSession userSession,
    required UserDetails userDetails,
  }) async {
    print(
        'LocationService: Starting _sendLocationToServer at ${DateTime.now()}');
    final prefs = await SharedPreferences.getInstance();
    String serverUrl = apiUrlConfig.locationSending.isNotEmpty
        ? apiUrlConfig.locationSending
        : prefs.getString('api_url') ?? 'https://fallback-api.com';
    String? token = await userSession.token ?? prefs.getString('user_token');
    String? uid = await userSession.uid ?? prefs.getString('user_uid');
    bool isCheckedIn = await userDetails.getCheckedIn() ??
        prefs.getBool(_isCheckedInKey) ??
        false;
    bool isCheckedOut = await userDetails.getCheckedOut() ??
        prefs.getBool(_isCheckedOutKey) ??
        false;
    print(
        'LocationService: serverUrl=$serverUrl, token=${token?.substring(0, 10)}..., uid=$uid, isCheckedIn=$isCheckedIn, isCheckedOut=$isCheckedOut');

    if (serverUrl.isEmpty) {
      print(
          'LocationService: Missing required data (url=$serverUrl, token=$token, uid=$uid)');
      throw Exception('Missing required data for sending location');
    }

    if (!isCheckedIn || isCheckedOut) {
      print(
          'LocationService: Not sending location: isCheckedIn=$isCheckedIn, isCheckedOut=$isCheckedOut');
      throw Exception('User not checked in or already checked out');
    }

    print(
        'LocationService: address from the send location function is $_currentAddress');
    final now = DateTime.now();
    final body = jsonEncode({
      'employee_id': uid,
      'date': DateFormat('yyyy-MM-dd').format(now),
      'time': DateFormat('HH:mm:ss').format(now),
      'lat': position.latitude.toString(),
      'lng': position.longitude.toString(),
      'address': _currentAddress
    });
    print('LocationService: Sending to $serverUrl with body: $body');

    int retryCount = 0;
    const maxRetries = 3;
    while (retryCount < maxRetries) {
      try {
        print('LocationService: Sending HTTP POST, attempt ${retryCount + 1}');
        final response = await http.post(
          Uri.parse(serverUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token ?? '',
          },
          body: body,
        );
        print(
            'LocationService: Response: Status=${response.statusCode}, Body=${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final sendTime = DateTime.now().toUtc().toIso8601String();
          await prefs.setString(_lastSendTimeKey, sendTime);
          await userDetails.setCheckedIn(true);
          print(
              'LocationService: Location sent successfully, stored send time: $sendTime');
          print(
              'LocationService: Triggering location sent notification'); // NEW PRINT: Log notification trigger
          await _showLocationSentNotification();
          return;
        } else {
          print(
              'LocationService: Failed to send location. Status: ${response.statusCode}');
        }
      } catch (e, stackTrace) {
        print('LocationService: HTTP error on attempt ${retryCount + 1}: $e');
        print('LocationService: StackTrace: $stackTrace');
      }
      retryCount++;
      final delaySeconds = (1 << retryCount).clamp(1, 30);
      print(
          'LocationService: Retrying after $delaySeconds seconds'); // NEW PRINT: Log retry delay
      await Future.delayed(Duration(seconds: delaySeconds));
    }
    print('LocationService: Failed to send location after $maxRetries retries');
    throw Exception('Failed to send location after $maxRetries retries');
  }

  // Request location permissions in the foreground
  static Future<bool> requestLocationPermissions(BuildContext context) async {
    print('LocationService: Requesting location permissions');

    if (_isPermissionRequestInProgress) {
      print('LocationService: Permission request already in progress, waiting');
      return false; // Or wait for completion if needed
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('LocationService: Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        print('LocationService: Prompting to enable location services');
        await Geolocator.openLocationSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return false;
      }

      // Check foreground location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('LocationService: Current permission: $permission');
      if (permission == LocationPermission.denied) {
        print('LocationService: Requesting location permission');
        permission = await Geolocator.requestPermission();
        print('LocationService: Permission request result: $permission');
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return false;
        }
      }

      // If permanently denied, guide user to settings
      if (permission == LocationPermission.deniedForever) {
        print(
            'LocationService: Permissions permanently denied, opening settings');
        await Geolocator.openAppSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enable location permissions in settings')),
        );
        return false;
      }

      // ✅ Request background location + battery optimization at once
      final statuses = await [
        Permission.locationAlways,
        Permission.ignoreBatteryOptimizations,
      ].request();

      // Handle background location
      if (statuses[Permission.locationAlways]?.isDenied ?? false) {
        print('LocationService: Background location permissions denied');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enable background location permissions')),
        );
        return false;
      }

      // Handle battery optimization
      if (statuses[Permission.ignoreBatteryOptimizations]?.isDenied ?? false) {
        print('LocationService: Battery optimization exemption denied');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Please disable battery optimization for reliable location tracking'),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: () => Permission.ignoreBatteryOptimizations.request(),
            ),
          ),
        );
      }

      print('LocationService: All required permissions granted ✅');
      return true;
    } catch (e, stackTrace) {
      print('LocationService: Error requesting permissions: $e');
      print('LocationService: StackTrace: $stackTrace');
      return false;
    }
  }
}
