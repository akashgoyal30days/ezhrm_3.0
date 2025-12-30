import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../premium_app_entry.dart';
import '../../Attendance/Attendance history/screen/attendance_history_screen.dart';
import '../../Attendance/mark attendance/screen/mark_attendance_screen.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Get Permissions/bloc/get_permission_bloc.dart';
import '../../Holiday/screen/holiday_screen.dart';
import '../../SessionHandling/session_bloc.dart';
import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/bloc/auth_bloc.dart';
import '../../Authentication/screen/login_screen.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../../Attendance/Attendance history/bloc/attendance_history_bloc.dart';
import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Attendance/mark attendance/screen/check_out.dart';
import '../../Attendance/Request Today Attendance/screen/ReqAttendanceScreen.dart';
import '../../Configuration/dashboard_config.dart';
import '../../SideMenuBar/screen/sidebar.dart';
import '../../Tracking Location/bloc/tracking_location_bloc.dart';
import '../../leave/Apply leave/screen/apply_leave.dart';
import '../../leave/Leave status/screen/leave_status_screen.dart';
import '../../notification/screen/notification_screen.dart';
import '../../profile/show_user_profile/screen/user_profile.dart';
import '../location_service.dart';
import 'dashboard_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  final UserSession userSession;
  final UserDetails userDetails;
  final ApiUrlConfig apiUrlConfig;
  final LocationService locationService;
  const HomeScreen({
    super.key,
    required this.userSession,
    required this.userDetails,
    required this.apiUrlConfig,
    required this.locationService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  int _selectedIndex = 0;
  late int selectedDateIndex;
  late DateTime selectedDate;
  List<String> dates = [];
  List<String> days = [];
  int _attendanceApiCallCount = 0;
  // Constants for event keys and cache duration
  static const String _fetchKeyPrefix = 'last_fetch_';
  static const Duration _cacheDuration = Duration(minutes: 5);

  final bool _hasNavigated = false;
  final bool _hasShownSnackBar = false;
  bool _permissionsChecked = false;
  bool _permissionsGranted = false;

  String _trackingStatus = 'Checking permissions...';
  double? timeInterval;
  bool _isDataLoaded = false;
  final List<Map<String, dynamic>> _attendanceData = [];
  String? _userName; // NEW: Class-level variable for user name
  String? _imageUrl; // NEW: Class-level variable for image URL
  String? _employeeCode; // NEW: Class-level variable for employee code
  String? _designation;
  final List<String> _weekOffDays = [];
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  bool _showCheckInPrompt = false;
  String? _currentCheckOutTime;
  String? _newCheckOutTime;
  String? _shiftStartTime;
  String? _shiftEndTime;
  String? gpsLocation;
  bool _checkTracking = false;
  String? _logoUrl;

  bool _hasStartedLocationService = false;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final DebugRouteObserver debugRouteObserver = DebugRouteObserver();

  @override
  void initState() {
    super.initState();
    debugPrint("🔵 initState called");

    // Clear fetch timestamps to force refresh on app launch/restart
    _clearFetchTimestamps();

    // Initialize user data from local storage
    _initializeUserData();

    selectedDateIndex = DateTime.now().weekday - 1;
    debugPrint("📅 selectedDateIndex set to: $selectedDateIndex");

    final weekDates = _generateWeekDates();
    debugPrint("📆 Generated week dates: $weekDates");

    selectedDate = weekDates[selectedDateIndex];
    debugPrint("✅ Selected date: $selectedDate");

    dates = weekDates.map((d) => DateFormat('dd').format(d)).toList();
    debugPrint("📌 Formatted dates list: $dates");

    days = weekDates.map((d) => DateFormat('E').format(d)).toList();
    debugPrint("📌 Days of the week: $days");

    // Guarded dispatches
    _dispatchInitialEvents();

    debugPrint(
        "📤 FetchAttendanceHistory event dispatched to AttendanceHistoryBloc");

    WidgetsBinding.instance.addObserver(this);
    debugPrint("👀 Added WidgetsBinding observer");

    _initialize();
    debugPrint("🚀 _initialize() called");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint("📱 HomeScreen fully built - checking for background location dialog");

      final prefs = await SharedPreferences.getInstance();
      final showDialogFlag = prefs.getString("show_bg_dialog");

      // Show only if the key is NOT set to "false" (i.e., first time or reset)
      if (showDialogFlag != "false") {
        debugPrint("🚨 Showing background location tracking disclosure dialog");
        await showLocationTrackingDialog();  // Your existing method
      } else {
        debugPrint("⏭️ Skipping background location dialog (already shown or dismissed)");
      }
    });
  }

  showLocationTrackingDialog() async {
    await showCupertinoDialog(
        context: context,
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: CupertinoAlertDialog(
              title: const Text("This app collects location data to enable", style: TextStyle(fontFamily: 'Poppins',),),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("- Location Based Attendance Marking", style: TextStyle(fontFamily: 'Poppins'), textAlign: TextAlign.left,),
                  const Text(
                    "- Employer/Company can track your live location",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontFamily: 'Poppins',),
                  ),
                  const Text(
                      "- To Check and approve your travel allowances even when the app is closed or not in use",
                      textAlign: TextAlign.left,
                      style : TextStyle(fontFamily: 'Poppins',)
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Do you want to allow?",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontFamily: 'Poppins',),
                  ),
                  RichText(
                      text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            const TextSpan(text: "Click ", style: TextStyle(fontFamily: 'Poppins',)),
                            TextSpan(
                                text: "here ",
                                style: const TextStyle(color: Colors.blue, fontFamily: 'Poppins',),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launch("https://ezhrm.in/locationpolicy");
                                  }),
                            const TextSpan(text: "for details", style: TextStyle(fontFamily: 'Poppins',)),
                          ])),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Allow", style : TextStyle(fontFamily: 'Poppins',)),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString("show_bg_dialog", "true");
                    Navigator.pop(context);
                    await showLocationTrackingConditions();

                    if (mounted) {
                      await _checkAndRequestPermissions();
                    }
                  },
                ),
                CupertinoDialogAction(
                  onPressed: (){
                    Navigator.pop(context);

                    SystemNavigator.pop();
                  },
                  child: const Text("Exit", style: TextStyle(fontFamily: 'Poppins',),),
                ),
              ],
            ),
          );
        });
  }

  showLocationTrackingConditions() async {
    await showDialog(
        context: context,
        builder: (context) {
          return WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: AlertDialog(
                backgroundColor: Colors.white,
                insetPadding: const EdgeInsets.symmetric(horizontal: 15),
                title: Row(
                  children: const [
                    Text(
                      "Attention",
                      style: TextStyle(
                          color: Color(0xff072a99),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          fontSize: 20),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("For Background Location Tracking : ",
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'Poppins',)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          height: 15,
                          width: 15,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xFF072a99)),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text(
                              "Please, Keep your battery Save Mode Disable",
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Poppins',
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          height: 15,
                          width: 15,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xff072a99)),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child:
                          Text("Please Allow the app to Run in Background",
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Poppins',
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          height: 15,
                          width: 15,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xff072a99)),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text("Keep Your Phone GPS Enabled ",
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Poppins',
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          height: 15,
                          width: 15,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xff072a99)),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text(
                              "Please, Make sure your Internet Connection is active ",
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Poppins',
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                        foregroundColor:
                        WidgetStateProperty.all(const Color(0xff072a99))),
                    child: const Text("OKAY", style : TextStyle(fontFamily: 'Poppins',)),
                  ),
                ],
              ));
        });
  }

  Future<void> _initializeUserData() async {
    try {
      // Fetch name and image URL from UserDetails
      final userDetails = await widget.userDetails.getUserDetails();
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _userName = userDetails['userName'] ?? 'N/A';
        _imageUrl = userDetails['imageUrl'];
        _employeeCode = prefs.getString('employee_code') ?? 'N/A';
        _designation = prefs.getString('designation') ?? 'N/A';
        _logoUrl = prefs.getString('companyLogo');
        debugPrint('HRMDashboard: Initialized user data - userName: $_userName,'
            ' imageUrl: $_imageUrl, employeeCode: $_employeeCode, designation: $_designation');
      });
    } catch (e) {
      debugPrint('HRMDashboard: Error initializing user data: $e');
      setState(() {
        _userName = 'N/A';
        _imageUrl = null;
        _employeeCode = 'N/A';
        _designation = 'N/A';
      });
    }
  }

  Future<void> _clearFetchTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_fetchKeyPrefix}permission');
    await prefs.remove('${_fetchKeyPrefix}attendance');
    await prefs.remove('${_fetchKeyPrefix}contact_us');
    await prefs.remove('${_fetchKeyPrefix}tracking_status');
    await prefs.remove(
        '${_fetchKeyPrefix}attendance_api'); // If used for direct HTTP guarding
    print(
        'HRMDashboard: Cleared fetch timestamps on initState for fresh launch');
  }

  Future<void> _dispatchInitialEvents() async {
    print('HRMDashboard: in the dispatching events function');
    // Permissions
    print('HRMDashboard: checking for  the permission event');
    final permissionBloc = getIt<GetPermissionBloc>();
    if (await _shouldFetchEvent('permission', permissionBloc.state)) {
      print('HRMDashboard: permission event is dispatched');
      permissionBloc.add(GetPermission());
    }

    print('HRMDashboard: checking for  the tracking status event');
    final trackingStatusBloc = getIt<TrackingLocationBloc>();
    if (await _shouldFetchEvent('tracking', trackingStatusBloc.state)) {
      print('HRMDashboard: tracking status event is dispatched');
      trackingStatusBloc.add(GetTimeInterval());
    }

    // Attendance History
    print('HRMDashboard: checking for  the attendance history event');
    final attendanceBloc = getIt<AttendanceHistoryBloc>();
    if (await _shouldFetchEvent('attendance', attendanceBloc.state)) {
      print('HRMDashboard: attendance history event is dispatched');
      attendanceBloc.add(FetchAttendanceHistory());
    }
  }

  Future<void> _initialize() async {
    try {
      await _fetchAndResolveAttendanceState();
      print('HRMDashboard: Completed _fetchAndResolveAttendanceState');

      // Step 3: Initialize notifications
      await _initializeNotifications();
      print('HRMDashboard: Completed _initializeNotifications');
    } catch (e, stackTrace) {
      print('HRMDashboard: Error during initialization: $e');
      print('HRMDashboard: StackTrace: $stackTrace');
      setState(() {
        _trackingStatus = 'Error initializing app: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      debugRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    debugRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() async {
    // ✅ Called when coming back to Dashboard from another screen
    debugPrint("👀 Dashboard reappeared (didPopNext)");

    // Guarded HTTP
    // if (await _shouldFetchEvent('attendance_api', null)) {  // No bloc state for direct HTTP
    //   await _updateFetchTimestamp('attendance_api');
    // }

    debugPrint('HRMDashboard: calling fetch and Resolve Attendance function');
    await _fetchAndResolveAttendanceState();

    // Guarded AttendanceHistory
    // final attendanceBloc = getIt<AttendanceHistoryBloc>();
    // if (await _shouldFetchEvent('attendance', attendanceBloc.state)) {
    //
    // }
    debugPrint('HRMDashboard: dispatching FetchAttendanceHistory');
    getIt<AttendanceHistoryBloc>().add(FetchAttendanceHistory());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('HRMDashboard: AppLifecycleState changed to $state');
    if (state == AppLifecycleState.resumed &&
        _permissionsChecked &&
        !_permissionsGranted) {
      print('HRMDashboard: App resumed, rechecking permissions');
      _recheckPermissions();
    }
  }

  Future<bool> _shouldFetchEvent(String eventKey, dynamic blocState) async {
    // Check if state is already successful (assumes Success states have 'Success' in name)
    if (blocState.toString().contains('Success')) {
      print('⏭️ Skipping $eventKey - already in success state: $blocState');
      return false;
    }

    // Check last fetch timestamp
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getInt('$_fetchKeyPrefix$eventKey') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDiff = Duration(milliseconds: now - lastFetch);

    if (timeDiff < _cacheDuration) {
      print(
          '⏭️ Skipping $eventKey - data fresh (last fetched ${timeDiff.inSeconds}s ago)');
      return false;
    }

    print(
        '🚀 Should dispatch $eventKey - state: $blocState, time since last fetch: ${timeDiff.inSeconds}s');
    return true;
  }

  /// Updates the last fetch timestamp for an event after successful dispatch.
  Future<void> _updateFetchTimestamp(String eventKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        '$_fetchKeyPrefix$eventKey', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _initializeService() async {
    print('HRMDashboard: Initializing location service');
    try {
      await LocationService.initializeService();
      print('HRMDashboard: LocationService initialized successfully');
    } catch (e, stackTrace) {
      print('HRMDashboard: Error initializing location service: $e');
      print('HRMDashboard: StackTrace: $stackTrace');
      setState(() {
        _trackingStatus = 'Error initializing location service';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize location service: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _recheckPermissions() async {
    print('HRMDashboard: Rechecking permissions');
    try {
      final permissions = await widget.userDetails.getUserPermissions();
      print('HRMDashboard: Permissions: $permissions');
      final gpsLocation = permissions[1]; // gpsLocation is at index 1

      if (gpsLocation == '1') {
        final locationStatus = await Permission.locationAlways.status;
        print(
            'HRMDashboard: Current location permission status: $locationStatus');
        if (locationStatus.isGranted) {
          await widget.userDetails.setLocationPermission(true);
          print('HRMDashboard: Location permission granted.');
          setState(() {
            _permissionsGranted = true;
            _trackingStatus = 'Permissions granted';
          });
        } else {
          print('HRMDashboard: Location permission not granted');
          await widget.userDetails.setLocationPermission(false);
          print('HRMDashboard: Location tracking disabled');
          // Show dialog again if permissions are still not granted
        }
      } else {
        print('HRMDashboard: gpsLocation is not 1, disabling tracking');
        await widget.userDetails.setLocationPermission(false);
        setState(() {
          _permissionsGranted = true;
          _trackingStatus =
              'Location tracking disabled as gpsLocation is not 1';
        });
      }
    } catch (e) {
      print('HRMDashboard: Error rechecking permissions: $e');
      await widget.userDetails.setLocationPermission(false);
      setState(() {
        _permissionsGranted = true;
        _trackingStatus = 'Error checking permissions: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking permissions: $e')),
      );
    }
  }

  Future<void> _fetchAndResolveAttendanceState() async {
    print('HRMDashboard: Fetching and resolving attendance state');
    try {
      // Fetch profile and attendance data using the common function
      final results = await _fetchAttendanceData();

      // Extract attendance data from results
      final attendanceData =
          results['attendance'] as List<Map<String, dynamic>>?;

      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _shiftStartTime = prefs.getString('startShiftTime');
          _shiftEndTime = prefs.getString('endShiftTime');
          _isDataLoaded = attendanceData != null &&
              attendanceData.isNotEmpty &&
              _weekOffDays.isNotEmpty;
          print(
              'HRMDashboard: Set shift timings - start: $_shiftStartTime, end: $_shiftEndTime');
        });
      }
      // Process attendance data
      if (attendanceData != null && attendanceData.isNotEmpty) {
        print('HRMDashboard: Processing attendance data: $attendanceData');
        await _processAttendanceData(attendanceData);
      } else {
        print('HRMDashboard: No attendance data received');
        if (mounted) {
          setState(() {
            _trackingStatus = 'No attendance data available';
          });
        }
        return;
      }
    } catch (e, stackTrace) {
      print(
          'HRMDashboard: Error fetching/resolving attendance or profile state: $e');
      print('HRMDashboard: StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _trackingStatus = 'Error initializing dashboard state: $e';
        });
      }
    }
  }

// Common function to fetch profile and attendance data via HTTP
  Future<Map<String, dynamic>> _fetchAttendanceData() async {
    // Limit API calls to a maximum of 2 times
    if (_attendanceApiCallCount >= 2) {
      print(
          '⚠️ HRMDashboard: API call limit reached ($_attendanceApiCallCount calls). Skipping fetch.');
      return {}; // Return empty map or cached data if available
    }

    _attendanceApiCallCount++; // Increment the counter before calling API
    print('HRMDashboard: Fetching profile and attendance data via HTTP');
    final results = <String, dynamic>{};

    final accessToken = await widget.userSession.token;
    final id = await widget.userSession.uid;
    if (accessToken == null) {
      throw Exception('No access token available');
    }

    // Prepare headers
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final prefs = await SharedPreferences.getInstance();
    final trackingInterval = prefs.getDouble('tracking_interval');
    if (trackingInterval != null) {
      print('HRMDashboard: Parsed Tracking Interval = $trackingInterval');
      await widget.userDetails.setTimeInterval(trackingInterval);
    } else {
      print('HRMDashboard: Invalid tracking interval value: $trackingInterval');
      await widget.userDetails
          .setTimeInterval(null); // Clear interval if invalid
    }

    try {
      // Fetch attendance data
      final attendanceUri = Uri.parse(
          '${widget.apiUrlConfig.baseUrl}${widget.apiUrlConfig.getTodayAttendance}$id');
      final attendanceResponse =
          await http.get(attendanceUri, headers: headers);

      if (attendanceResponse.statusCode == 200) {
        final attendanceJson = jsonDecode(attendanceResponse.body);
        print('HRMDashboard: Raw attendance response: $attendanceJson');
        // Handle different possible response structures
        if (attendanceJson is Map<String, dynamic> &&
            attendanceJson.containsKey('data') &&
            attendanceJson['data'] is List) {
          results['attendance'] =
              (attendanceJson['data'] as List).cast<Map<String, dynamic>>();
        } else if (attendanceJson is List) {
          results['attendance'] = attendanceJson.cast<Map<String, dynamic>>();
        } else {
          print(
              'HRMDashboard: Invalid attendance data format: $attendanceJson');
          results['attendance'] = null;
        }
      } else {
        print(
            'HRMDashboard: Failed to fetch attendance data, status: ${attendanceResponse.statusCode}, body: ${attendanceResponse.body}');
        results['attendance'] = null;
      }

      return results;
    } catch (e) {
      print('HRMDashboard: Error in _fetchProfileAndAttendanceData: $e');
      rethrow; // Propagate the error to the caller
    }
  }

  Future<void> _processAttendanceData(
      List<Map<String, dynamic>> attendanceData) async {
    print('HRMDashboard: Processing attendance data: $attendanceData');
    try {
      if (attendanceData.isEmpty) {
        print('HRMDashboard: No attendance record found');
        setState(() {
          _isCheckedIn = false;
          _isCheckedOut = false;
          _currentCheckOutTime = null;
          _newCheckOutTime = null;
          _showCheckInPrompt = true;
          print('check in banner show from process attendance data');
          _trackingStatus =
              'Please mark your attendance to start sending location';
        });
        await widget.userDetails.setCheckedIn(false);
        await widget.userDetails.setCheckedOut(false, null);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_checked_in', false);
        await prefs.setBool('is_checked_out', false);
        await prefs.remove('checkout_time');
        await prefs.remove('new_checkout_time');
        await LocationService.showMarkAttendanceNotification();
        print('HRMDashboard: Set no-attendance state');
        return;
      }

      final attendanceRecord = attendanceData.firstWhere(
        (data) => data['type'] == 'Attendance' && data['check-in'] != null,
        orElse: () => <String, dynamic>{},
      );

      if (attendanceRecord.isEmpty) {
        print('HRMDashboard: No valid attendance record found');
        setState(() {
          _isCheckedIn = false;
          _isCheckedOut = false;
          _currentCheckOutTime = null;
          _newCheckOutTime = null;
          _showCheckInPrompt = true;
          print('check in banner show from process attendance data');
          _trackingStatus =
              'Please mark your attendance to start sending location';
        });
        await widget.userDetails.setCheckedIn(false);
        await widget.userDetails.setCheckedOut(false, null);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_checked_in', false);
        await prefs.setBool('is_checked_out', false);
        await prefs.remove('checkout_time');
        await prefs.remove('new_checkout_time');
        await LocationService.stopLocationService();
        print('HRMDashboard: Set no-attendance state for invalid record');
        return;
      }

      final checkInTime = attendanceRecord['check-in'] as String?;
      final checkOutTime = attendanceRecord['check-out'] as String?;
      final storedCheckOutTime = await widget.userDetails.getCheckoutTime();
      final storedNewCheckOutTime =
          await widget.userDetails.getNewCheckoutTime();

      print('HRMDashboard: Check-in: $checkInTime, Check-out: $checkOutTime');
      print(
          'HRMDashboard: Stored Check-out: $storedCheckOutTime, Stored New Check-out: $storedNewCheckOutTime');

      if (checkInTime != null && checkOutTime == null) {
        print('HRMDashboard: Check-in present, no check-out');
        setState(() {
          _isCheckedIn = true;
          _isCheckedOut = false;
          _currentCheckOutTime = null;
          _newCheckOutTime = null;
          _showCheckInPrompt = false;
          _trackingStatus = 'Checked in';
        });
        await widget.userDetails.setCheckedIn(true);
        await widget.userDetails.setCheckedOut(false, null);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_checked_in', true);
        await prefs.setBool('is_checked_out', false);
        await prefs.remove('checkout_time');
        await _handleCheckIn(true,
            isFromApi: true, preserveCheckoutTimes: false);
        print('HRMDashboard: Set checked-in state');
      } else if (checkInTime == null && checkOutTime == null) {
        print('HRMDashboard: Both check-in and check-out are null');
        setState(() {
          _isCheckedIn = false;
          _isCheckedOut = false;
          _currentCheckOutTime = null;
          _newCheckOutTime = null;
          _showCheckInPrompt = true;
          print('check in banner show from process attendance data');
          _trackingStatus =
              'Please mark your attendance to start sending location';
        });
        await widget.userDetails.setCheckedIn(false);
        await widget.userDetails.setCheckedOut(false, null);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_checked_in', false);
        await prefs.setBool('is_checked_out', false);
        await prefs.remove('checkout_time');
        await prefs.remove('new_checkout_time');
        await LocationService.stopLocationService();
        await LocationService.showMarkAttendanceNotification();
        print('HRMDashboard: Set no-attendance state');
      } else if (checkInTime != null && checkOutTime != null) {
        print(
            'HRMDashboard: Check-out detected from process attendance function');
        await LocationService.handleCheckOut(checkOutTime, widget.userDetails);
        final isCheckedOut = await widget.userDetails.getCheckedOut();
        if (isCheckedOut) {
          // Perform async operations outside setState
          final currentCheckOutTime =
              await widget.userDetails.getCheckoutTime();
          final newCheckOutTime = await widget.userDetails.getNewCheckoutTime();
          setState(() {
            _hasStartedLocationService = false;
            _showCheckInPrompt = true;
            _isCheckedIn = false;
            _isCheckedOut = true;
            _currentCheckOutTime = currentCheckOutTime;
            _newCheckOutTime = newCheckOutTime;
            _trackingStatus = 'Checked out at $newCheckOutTime';
            _showCheckInPrompt = true;
          });
          print(
              'HRMDashboard: Set checked-out state from process attendance data - CheckIn: $_isCheckedIn, CheckOut: $_isCheckedOut, Time: $newCheckOutTime');
        }
      }
      await _checkInitialCheckedIn();
      await _checkInitialCheckedOut();
      await _resolveConflictingCheckStates();
    } catch (e, stackTrace) {
      print('HRMDashboard: Error processing attendance data: $e');
      print('HRMDashboard: StackTrace: $stackTrace');
      setState(() {
        _trackingStatus = 'Error processing attendance data';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing attendance data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkInitialCheckedIn() async {
    print('HRMDashboard: Checking initial checked-in status');
    try {
      final storedCheckedIn = await widget.userDetails.getCheckedIn() ?? false;
      print('HRMDashboard: Initial checked-in from storage: $storedCheckedIn');
      setState(() {
        _isCheckedIn = storedCheckedIn;
        _trackingStatus = _isCheckedIn ? 'Checked in' : 'Not checked in';
      });
    } catch (e, stackTrace) {
      print('HRMDashboard: Error checking initial checked-in: $e');
      print('HRMDashboard: StackTrace: $stackTrace');
      setState(() {
        _trackingStatus = 'Error checking check-in status';
      });
    }
  }

  Future<void> _checkInitialCheckedOut() async {
    print('HRMDashboard: Checking initial checked-out status');
    try {
      final storedCheckedOut =
          await widget.userDetails.getCheckedOut() ?? false;
      _currentCheckOutTime = await widget.userDetails.getCheckoutTime();
      _newCheckOutTime = await widget.userDetails.getNewCheckoutTime();
      // NEW: Fetch shift timings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _shiftStartTime = prefs.getString('shift_start_time');
      _shiftEndTime = prefs.getString('shift_end_time');
      print(
          'HRMDashboard: Initial checked-out: $storedCheckedOut, current checkout time: $_currentCheckOutTime, new checkout time: $_newCheckOutTime, shift start: $_shiftStartTime, shift end: $_shiftEndTime');
      setState(() {
        _isCheckedOut = storedCheckedOut;
        if (_isCheckedOut && _newCheckOutTime != null) {
          _showCheckInPrompt = true;
          print('check in banner show from check initial check out');
          _trackingStatus = 'Checked out at $_newCheckOutTime';
        } else {
          _showCheckInPrompt = false;
          _trackingStatus = _isCheckedIn ? 'Checked in' : 'Not checked in';
        }
      });
    } catch (e, stackTrace) {
      print('HRMDashboard: Error checking initial checked-out: $e');
      print('HRMDashboard: StackTrace: $stackTrace');
      setState(() {
        _trackingStatus = 'Error checking check-out status';
      });
    }
  }

  Future<void> _resolveConflictingCheckStates() async {
    print('HRMDashboard: Resolving conflicting check-in and check-out states');
    try {
      print('HRMDashboard: Check-in: $_isCheckedIn, Check-out: $_isCheckedOut');
      if (_isCheckedIn && _isCheckedOut) {
        print(
            'HRMDashboard: Both checked-in and checked-out are true, aligning with API state');
        final attendanceState = getIt<GetTodayAttendanceBloc>().state;
        if (attendanceState is GetTodayAttendanceSuccess) {
          await _processAttendanceData(attendanceState.attendanceData);
        } else {
          print(
              'HRMDashboard: No API attendance data, defaulting to checked-out');
          setState(() {
            _isCheckedIn = false;
            _isCheckedOut = true;
            _showCheckInPrompt = true;
            print('check in banner show from resolving conflict states');
            _trackingStatus = 'Checked out at $_currentCheckOutTime';
          });
          await widget.userDetails.setCheckedIn(false);
          await widget.userDetails.setCheckedOut(true, _currentCheckOutTime);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_checked_in', false);
          await prefs.setBool('is_checked_out', true);
          await prefs.setString('checkout_time', _currentCheckOutTime ?? '');
          await prefs.setString('new_checkout_time', _newCheckOutTime ?? '');
        }
      } else if (_isCheckedIn && !_isCheckedOut) {
        print(
            'HRMDashboard: Check in is true and Checkout is false so start the location sending service');
        _handleCheckIn(true);
      }
    } catch (e, stackTrace) {
      print('HRMDashboard: Error resolving conflicting states: $e');
      print('HRMDashboard: StackTrace: $stackTrace');
      setState(() {
        _trackingStatus = 'Error resolving check states';
      });
    }
  }

  Future<void> _handleCheckIn(bool isCheckedIn,
      {bool isFromApi = false, bool preserveCheckoutTimes = false}) async {
    if (!mounted) {
      print('HRMDashboard: Widget not mounted, skipping check-in');
      return;
    }
    print(
        'HRMDashboard: Handling check-in: $isCheckedIn at ${DateTime.now()}, isFromApi: $isFromApi, preserveCheckoutTimes: $preserveCheckoutTimes');
    // Update state to reflect check-in
    setState(() {
      _isCheckedIn = isCheckedIn;
      _isCheckedOut = false;
      if (!preserveCheckoutTimes) {
        _currentCheckOutTime = null;
        _newCheckOutTime = null;
      }
      _showCheckInPrompt = !isCheckedIn;
      print('check in banner show from handle check in');
      print('check out time is $_currentCheckOutTime');
      _trackingStatus = isCheckedIn ? 'Checking in...' : 'Checking out...';
      print('HRMDashboard: Updated states - CheckedIn: $_isCheckedIn,'
          ' CheckedOut: $_isCheckedOut, ShowPrompt: $_showCheckInPrompt, tracking status: $_trackingStatus'); // NEW PRINT: Log state update
    });

    // Persist the state
    try {
      final currentCheckOutTime = await widget.userDetails.getCheckoutTime();
      await widget.userDetails.setCheckedIn(isCheckedIn);
      await widget.userDetails.setCheckedOut(false, currentCheckOutTime);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_checked_in', isCheckedIn);
      await prefs.setBool('is_checked_out', false);
      if (!preserveCheckoutTimes) {
        await prefs.remove('checkout_time');
        await prefs.remove('new_checkout_time');
      }
      print(
          'HRMDashboard: Persisted check-in state - CheckedIn: $isCheckedIn, CheckedOut: false, Checkout times ${preserveCheckoutTimes ? 'preserved' : 'cleared'}');
    } catch (e, stackTrace) {
      print('HRMDashboard: Error persisting check-in state: $e');
      print('HRMDashboard: StackTrace: $stackTrace');
      setState(() {
        _trackingStatus = 'Error saving check-in state';
        print(
            'HRMDashboard: Updated tracking status: $_trackingStatus'); // NEW PRINT: Log state update
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving check-in state: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isCheckedIn) {
      try {
        // Check if tracking is enabled by the server
        bool isLocationPermissionEnabled =
            await widget.userDetails.getLocationPermission();
        bool trackingStatus = await widget.userDetails.getTrackingStatus();
        print(
            'HRMDashboard: Tracking enabled: $isLocationPermissionEnabled and Tracking status is $trackingStatus');
        if (!isLocationPermissionEnabled || !trackingStatus) {
          print('HRMDashboard: Tracking disabled by server');
          setState(() {
            _trackingStatus = 'Tracking disabled by server';
            print(
                'HRMDashboard: Updated tracking status: $_trackingStatus'); // NEW PRINT: Log state update
          });
          return;
        }

        print('HRMDashboard: Fetching time interval from local sotrage');
        timeInterval = await widget.userDetails.getTimeInterval();
        // Ensure time interval is set
        if (timeInterval == null) {
          print(
              'HRMDashboard: Time interval is null so location tracking is disabled by the server.');
          return;
        }

        // Request permissions and start location service (only for user-initiated action)
        if (!_hasStartedLocationService) {
          if (!isFromApi) {
            print(
                'HRMDashboard: Requesting location permissions for user-initiated check-in');
            final permissionsGranted =
                await LocationService.requestLocationPermissions(context);
            print('HRMDashboard: Permissions granted: $permissionsGranted');
            if (permissionsGranted) {
              final prefs = await SharedPreferences.getInstance();
              // Check if already initialized
              bool isWorkmanagerInitialized =
                  prefs.getBool('workmanager_initialized') ?? false;
              if (!isWorkmanagerInitialized) {
                await Workmanager().initialize(
                  callbackDispatcher,
                  isInDebugMode: false, // Set to true for debugging
                );
                await prefs.setBool('workmanager_initialized', true);
                print('LocationService: Workmanager initialized and flag set');
              } else {
                print('LocationService: Workmanager already initialized');
              }
              print('HRMDashboard: Starting location service');
              await widget.locationService.startLocationService();
              setState(() {
                _hasStartedLocationService = true;
                _trackingStatus =
                    'Tracking started (Interval: $timeInterval min)';
                print(
                    'HRMDashboard: Updated tracking status: $_trackingStatus');
              });
            } else {
              print('HRMDashboard: Permissions denied, reverting check-in');
              setState(() {
                _isCheckedIn = false;
                _trackingStatus = 'Permissions denied';
                print(
                    'HRMDashboard: Updated states - CheckedIn: $_isCheckedIn, tracking status: $_trackingStatus');
              });
              await widget.userDetails.setCheckedIn(false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location permissions required for tracking'),
                ),
              );
              return;
            }
          } else {
            print(
                'HRMDashboard: API-detected check-in, checking location service');
            if (isLocationPermissionEnabled && trackingStatus) {
              print(
                  'HRMDashboard: Starting location service for API-detected check-in');
              await widget.locationService.startLocationService();
              setState(() {
                _hasStartedLocationService = true;
                _trackingStatus =
                    'Tracking started (Interval: $timeInterval min)';
                print(
                    'HRMDashboard: Updated tracking status: $_trackingStatus');
              });
            } else {
              setState(() {
                _trackingStatus = 'Checked in, tracking not enabled';
                print(
                    'HRMDashboard: Updated tracking status: $_trackingStatus');
              });
            }
          }
        } else {
          print(
              'HRMDashboard: Location service already started for today, skipping');
          setState(() {
            _trackingStatus =
                'Tracking already started (Interval: $timeInterval min)';
            print('HRMDashboard: Updated tracking status: $_trackingStatus');
          });
        }
      } catch (e, stackTrace) {
        print('HRMDashboard: Error handling check-in: $e');
        print('HRMDashboard: StackTrace: $stackTrace');
        setState(() {
          _trackingStatus = 'Error starting tracking: $e';
          print(
              'HRMDashboard: Updated tracking status: $_trackingStatus'); // NEW PRINT: Log state update
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting tracking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Handle check-out case (isCheckedIn = false)
      print('HRMDashboard: Stopping location service');
      await LocationService.stopLocationService();
      setState(() {
        _trackingStatus = 'Tracking stopped';
        print(
            'HRMDashboard: Updated tracking status: $_trackingStatus'); // NEW PRINT: Log state update
      });
    }
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('ezhrm_logo');
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: null, // Add iOS settings if needed
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Check and request permissions
  Future<void> _checkAndRequestPermissions() async {
    if (_permissionsChecked) return;

    setState(() {
      _permissionsChecked = true;
    });

    try {
      final permissions = await widget.userDetails.getUserPermissions();
      print('HRMDashboard: Permissions: $permissions');
      gpsLocation = permissions[1];

      if (gpsLocation == '1') {
        print('HRMDashboard: gpsLocation is 1, requesting permissions');

        // First check if locationAlways is already granted
        final currentLocationStatus = await Permission.locationAlways.status;
        if (currentLocationStatus.isGranted) {
          print('HRMDashboard: Location permission granted');
          await widget.userDetails.setLocationPermission(true);
          print('HRMDashboard: Location tracking now enabled');
          setState(() {
            _permissionsGranted = true;
          });
          await _initializeService();
          print('HRMDashboard: Completed _initializeService');
        } else {
          print('HRMDashboard: Location permission not granted, requesting...');
          final locationStatus = await Permission.locationAlways.request();
          if (locationStatus.isGranted) {
            print('HRMDashboard: Location permission granted after request');
            await widget.userDetails.setLocationPermission(true);
            print('HRMDashboard: Location tracking now enabled');
            setState(() {
              _permissionsGranted = true;
            });
            await _initializeService();
            print('HRMDashboard: Completed _initializeService');
          } else {
            print('HRMDashboard: Location permission denied');
            _showPermissionDialog(
              'Location Permission',
              'Please allow location access to "Allow all the time" for marking attendance.',
              onContinue: () async {
                await widget.userDetails.setLocationPermission(false);
                print(
                    'HRMDashboard: Location tracking disabled due to user continuing without permission');
                setState(() {
                  _permissionsGranted = true;
                  _trackingStatus = 'Location tracking disabled';
                });
              },
              onOpenSettings: () async {
                await openAppSettings();
              },
            );
            return;
          }
        }

        // Camera permission handling (same as before)
        final cameraStatus = await Permission.camera.status;
        if (cameraStatus.isGranted) {
          print('HRMDashboard: Camera permission already granted');
          setState(() {
            _permissionsGranted = true;
          });
        } else {
          print('HRMDashboard: Requesting camera permission...');
          final requestedCameraStatus = await Permission.camera.request();

          if (requestedCameraStatus.isGranted) {
            print('HRMDashboard: Camera permission granted');
            setState(() {
              _permissionsGranted = true;
            });
          } else {
            print('HRMDashboard: Camera permission denied');
            _showPermissionDialog(
              'Camera Permission',
              'Please allow camera access to capture images.',
              onContinue: () async {
                setState(() {
                  _permissionsGranted = true;
                });
              },
              onOpenSettings: () async {
                await openAppSettings();
              },
            );
            return;
          }
        }
      } else {
        print(
            'HRMDashboard: gpsLocation is not 1, proceeding without permissions');
        await widget.userDetails.setLocationPermission(false);
        print(
            'HRMDashboard: Location tracking disabled as gpsLocation is not 1');
        setState(() {
          _permissionsGranted = true;
        });
      }
    } catch (e) {
      print('HRMDashboard: Error checking permissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking permissions: $e')),
      );
      await widget.userDetails.setLocationPermission(false);
      print('HRMDashboard: Location tracking disabled due to error');
      setState(() {
        _permissionsGranted = true;
      });
    }
  }

  // Send notification
  Future<void> _sendNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'permission_channel',
      'Permission Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _flutterLocalNotificationsPlugin.show(
      0,
      'Location Permission Required',
      'Please ensure location services are set to "Always" for attendance tracking.',
      notificationDetails,
    );
    print('DashboardScreen: Notification sent');
  }

  // Show permission dialog
  void _showPermissionDialog(
    String title,
    String message, {
    required VoidCallback onContinue,
    required VoidCallback onOpenSettings,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onOpenSettings();
            },
            child: Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onContinue();
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  List<DateTime> _generateWeekDates() {
    DateTime today = DateTime.now();
    DateTime monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  /// Shows a custom logout confirmation dialog that matches the provided UI image.
  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        // Use Dialog for more custom layout control
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _buildDialogContent(context),
        );
      },
    );
  }

  /// Builds the content of the custom dialog.
  Widget _buildDialogContent(BuildContext context) {
    return Stack(
      children: <Widget>[
        // The main dialog card
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // To make the card compact
            children: <Widget>[
              const Text(
                "Please Confirm",
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                "Are you sure you want to logout?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24.0),
              // Row containing the action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false); // Return false
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side:
                            BorderSide(color: Colors.blue.shade600, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Logout Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Dispatch the logout event before popping.
                        getIt<AuthBloc>().add(Logout());
                        Navigator.of(context).pop(true); // Return true
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Log out",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // The 'X' close button positioned at the top-right
        Positioned(
          right: 0.0,
          top: 0.0,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              Navigator.of(context).pop(false); // Same as Cancel
            },
          ),
        ),
      ],
    );
  }

  /// MODIFIED: This method now calls the custom logout dialog.
  void _onItemTapped(int index) async {
    // If the logout item (index 3) is tapped
    if (index == 3) {
      // Show the custom dialog and wait for the result
      final bool? shouldLogout = await _showLogoutDialog(context);

      // Proceed with logout only if the user confirmed (dialog returned true)
      if (shouldLogout == true) {
        final session = UserSession();
        await session.clearUserCredentials();

        // Check if the widget is still in the tree before navigating
        if (!mounted) return;

        // Navigate to the LoginScreen, replacing the current screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              userSession: getIt<UserSession>(),
              userDetails: getIt<UserDetails>(),
              apiUrlConfig: getIt<ApiUrlConfig>(),
            ),
          ),
        );
      }
    } else {
      // If any other item is tapped, just update the state
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  /// --------
  /// MODIFIED: Returns an image path for "Good Morning" and icons for others.
  /// --------
  Map<String, dynamic> getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return {
        'text': 'Good Morning',
        'isIcon': false,
        'assetPath': 'assets/images/goodMorning.png'
      };
    } else if (hour >= 12 && hour < 18) {
      return {
        'text': 'Good Afternoon',
        'isIcon': false,
        'assetPath': 'assets/images/goodAfternoon.png'
      };
    } else {
      return {
        'text': 'Good Evening',
        'isIcon': false,
        'assetPath': 'assets/images/goodEvening.png'
      };
    }
  }

  /// --------
  /// MODIFIED: This helper method now wraps content widgets in a SafeArea.
  /// --------
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent(); // This one already has a SafeArea inside
      case 1:
        return const SafeArea(
            child: NotificationScreen()); // Added SafeArea wrapper
      case 2:
        return const SafeArea(child: UserProfile()); // Added SafeArea wrapper
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state is SessionExpiredState || state is UserNotFoundState) {
              getIt<UserSession>().clearUserCredentials();
              getIt<UserDetails>().clearUserDetails();

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session expired. Please login again.'),
                  backgroundColor: Colors.red,
                ),
              );

              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      userSession: getIt<UserSession>(),
                      userDetails: getIt<UserDetails>(),
                      apiUrlConfig: getIt<ApiUrlConfig>(),
                    ),
                  ),
                  (route) => false,
                );
              });
            }
          },
        ),
        BlocListener<GetTodayAttendanceBloc, GetTodayAttendanceState>(
          listener: (context, state) {
            if (state is GetTodayAttendanceFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage)),
              );
            }
          },
        ),
        BlocListener<GetPermissionBloc, GetPermissionState>(
          listener: (context, state) async {
            if (state is GetPermissionSuccess) {
              try {
                print(
                    'HRMDashboard: GetPermissionSuccess received with data: ${state.permissions}');
                final permission = state.permissions;
                final faceRecognition =
                    permission['is_face_recognition']?.toString() ?? '0';
                final fetchedGpsLocation =
                    permission['is_gps_location']?.toString() ?? '0';
                final autoAttendance =
                    permission['is_auto_attendance']?.toString() ?? '0';
                final reqAttendance =
                    permission['is_req_attendance']?.toString() ?? '0';

                await widget.userDetails.setUserPermissions(
                  faceRecognition: faceRecognition,
                  gpsLocation: fetchedGpsLocation,
                  autoAttendance: autoAttendance,
                  reqAttendance: reqAttendance,
                );
                setState(() {
                  gpsLocation = fetchedGpsLocation;
                  print('HRMDashboard: gpsLocation updated to: $gpsLocation');
                });
                await _updateFetchTimestamp('permission');
                print(
                    'HRMDashboard: Permissions saved successfully: $permission');
              } catch (e, stackTrace) {
                print('HRMDashboard: Error parsing permissions: $e');
                print('HRMDashboard: StackTrace: $stackTrace');
              }
            } else if (state is GetPermissionFailure) {
              print(
                  'HRMDashboard: GetPermissionFailure: ${state.errorMessage}');
            } else if (state is GetPermissionInitial) {
              print('HRMDashboard: GetPermissionInitial state');
              // Optionally, show a loading indicator or retry
            }
          },
        ),
        BlocListener<TrackingLocationBloc, TrackingLocationState>(
          listener: (context, state) async {
            if (state is TrackingLocationLoading) {
              debugPrint("⏳ Fetching tracking interval...");
            }
            // ✅ On Success — Save the interval to local storage
            if (state is GetTimeIntervalSuccess) {
              final double interval = state.timeInterval;
              debugPrint("✅ Tracking interval fetched: $interval minutes");

              // Save to SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('tracking_interval', interval);
              await widget.userDetails.setTimeInterval(interval);
              await widget.userDetails.setTrackingStatus(true);

              setState(() {
                _checkTracking = true;
              });
              debugPrint(
                  "📦 Saved tracking interval to local storage: $interval");
            }
            if (state is GetTimeIntervalFailure) {
              debugPrint(
                  'HRMDashboard: GetTimeInterval is failure, Tracking status is disabled and time interval is set  to 0');

              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('tracking-status', false);
              await widget.userDetails.setTimeInterval(0.00);
              await widget.userDetails.setTrackingStatus(false);
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully.'),
                  backgroundColor: Color(0xFF416CAF),
                ),
              );

              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      userSession: getIt<UserSession>(),
                      userDetails: getIt<UserDetails>(),
                      apiUrlConfig: getIt<ApiUrlConfig>(),
                    ),
                  ),
                  (route) => false,
                );
              });
            } else if (state is LogoutFailure) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error logging out.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
          drawer: const CustomSidebar(),
          backgroundColor: Colors.white,
          // MODIFIED: The appBar property has been completely removed.
          body: _buildBody(),
          bottomNavigationBar: DashboardNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          )),
    );
  }

  Widget _buildHomeContent() {
    final apiUrlConfig = getIt<ApiUrlConfig>();
    final greeting = getGreeting();
    final mediaQuery = MediaQuery.of(context);
    final textScaler = mediaQuery.textScaler.clamp(maxScaleFactor: 1.4);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final double baseSpacing = screenWidth * 0.04;
    final double baseFontSize = screenWidth * 0.038;
    final tileWidth = screenWidth * 0.28;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          print(
              'HRMDashboard: RefreshIndicator triggered, limit value is set to initial');
          _attendanceApiCallCount = 0;
          await _clearFetchTimestamps();
          _initializeUserData();
          print('HRMDashboard: dispatching the permission event');
          final permissionBloc = getIt<GetPermissionBloc>();
          permissionBloc.add(GetPermission());

          permissionBloc.add(GetPermission());

          // Wait until the bloc emits a success or failure state
          await permissionBloc.stream.firstWhere(
            (state) =>
                state is GetPermissionSuccess || state is GetPermissionFailure,
          );
          // if (await _shouldFetchEvent('permission', permissionBloc.state)) {
          //
          // }

          print('HRMDashboard: Dispatching the tracking status event');
          final trackingStatusBloc = getIt<TrackingLocationBloc>();
          trackingStatusBloc.add(GetTimeInterval());

          // Wait until the bloc emits a success or failure state
          await trackingStatusBloc.stream.firstWhere(
            (state) =>
                state is GetTimeIntervalSuccess ||
                state is GetTimeIntervalFailure,
          );
          // if (await _shouldFetchEvent('tracking', trackingStatusBloc.state)) {
          //   print('HRMDashboard: tracking status event is dispatched');
          // }

          final attendanceBloc = getIt<AttendanceHistoryBloc>();
          print('HRMDashboard: dispatching the attendance history event');
          attendanceBloc.add(FetchAttendanceHistory());

          attendanceBloc.add(FetchAttendanceHistory());

          // Wait until the bloc emits a success or failure state
          await attendanceBloc.stream.firstWhere(
            (state) =>
                state is AttendanceHistorySuccess ||
                state is AttendanceHistoryFailure,
          );

          print('HRMDashboard: Resolving and fetching attendance');
          await _fetchAndResolveAttendanceState();
          // if (await _shouldFetchEvent('attendance', attendanceBloc.state)) {
          //
          // }
        },
        child: MediaQuery(
          data: mediaQuery.copyWith(textScaler: textScaler),
          child: CustomScrollView(
            slivers: [
              // Sliver 1: Check-in/out prompt
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (!_isCheckedIn &&
                        _isCheckedOut &&
                        _showCheckInPrompt &&
                        _checkTracking) ...[
                      Container(
                        padding: EdgeInsets.all(baseSpacing),
                        color: Colors.yellow[100],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checked out. Click to check in and start location tracking.',
                              style: TextStyle(
                                fontSize: baseFontSize * 0.95,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: baseSpacing / 2),
                            ElevatedButton(
                              onPressed: () {
                                _handleCheckIn(true,
                                    preserveCheckoutTimes: true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DashboardColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(baseSpacing * 1.5),
                                ),
                              ),
                              child: Text(
                                'Start Location Sending',
                                style: DashboardTextStyles.buttonText.copyWith(
                                  fontSize: baseFontSize * 0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (!_isCheckedIn &&
                        !_isCheckedOut &&
                        _checkTracking) ...[
                      Container(
                        padding: EdgeInsets.all(baseSpacing),
                        color: Colors.yellow[100],
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Please mark your attendance to start sending location',
                                style: TextStyle(
                                  fontSize: baseFontSize * 0.95,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(width: baseSpacing / 2),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckInScreen(
                                      userSession: widget.userSession,
                                      userDetails: widget.userDetails,
                                      apiUrlConfig: widget.apiUrlConfig,
                                      isCheckOutMode: false,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DashboardColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(baseSpacing * 1.5),
                                ),
                              ),
                              child: Text(
                                'Check In',
                                style: DashboardTextStyles.buttonText.copyWith(
                                  fontSize: baseFontSize * 0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Sliver 2: Header section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(baseSpacing),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: screenWidth * 0.065,
                                backgroundColor: const Color(0xFFFFEACC),
                                child: (greeting['isIcon'] as bool)
                                    ? Icon(
                                        greeting['icon'],
                                        color: greeting['iconColor'],
                                        size: screenWidth * 0.06,
                                      )
                                    : Padding(
                                        padding:
                                            EdgeInsets.all(screenWidth * 0.012),
                                        child: Image.asset(
                                          greeting['assetPath'],
                                        ),
                                      ),
                              ),
                              SizedBox(width: baseSpacing * 0.75),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting['text'],
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: baseFontSize * 0.9,
                                    ),
                                  ),
                                  Text(
                                    _userName ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: baseFontSize * 1.2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Wrap IconButton in Builder to get a context below Scaffold
                          Builder(
                            builder: (BuildContext newContext) {
                              return IconButton(
                                icon:
                                    Icon(Icons.menu, size: screenWidth * 0.07),
                                onPressed: () {
                                  Scaffold.of(newContext).openDrawer();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: baseSpacing * 1.5),
                      SizedBox(
                        height: screenHeight * 0.08,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: dates.length,
                          itemBuilder: (context, index) {
                            final isSelected = index == selectedDateIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDateIndex = index;
                                  selectedDate = _generateWeekDates()[index];
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: baseSpacing * 0.3),
                                child: Container(
                                  width: screenWidth * 0.13,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0072FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        baseSpacing * 0.8),
                                    boxShadow: [
                                      if (!isSelected)
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          blurRadius: baseSpacing * 0.25,
                                        )
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dates[index],
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: baseFontSize,
                                        ),
                                      ),
                                      Text(
                                        days[index],
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: baseFontSize * 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sliver 3: Grid tiles
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: baseSpacing, vertical: baseSpacing * 0.75),
                  child: Wrap(
                    spacing: baseSpacing * 0.75,
                    runSpacing: baseSpacing * 0.75,
                    alignment: WrapAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CheckInScreen(
                                    userSession: widget.userSession,
                                    userDetails: widget.userDetails,
                                    apiUrlConfig: widget.apiUrlConfig,
                                    isCheckOutMode: false,
                                  )),
                        ),
                        child: _buildTile(
                            context,
                            'Mark Attendance',
                            'assets/images/marked_attendance.png',
                            tileWidth,
                            baseFontSize,
                            baseSpacing),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ApplyLeavePage()),
                        ),
                        child: _buildTile(
                            context,
                            'Apply Leave',
                            'assets/images/apply_leave.png',
                            tileWidth,
                            baseFontSize,
                            baseSpacing),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => HolidayListScreen()),
                        ),
                        child: _buildTile(
                            context,
                            'Holiday List',
                            'assets/images/holiday_list.png',
                            tileWidth,
                            baseFontSize,
                            baseSpacing),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LeaveStatusScreen()),
                        ),
                        child: _buildTile(
                            context,
                            'Leave Status',
                            'assets/images/leave_status.png',
                            tileWidth,
                            baseFontSize,
                            baseSpacing),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RequestAttendanceScreen()),
                        ),
                        child: _buildTile(
                            context,
                            'Request Attendance',
                            'assets/images/request_attendance.png',
                            tileWidth,
                            baseFontSize,
                            baseSpacing),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AttendanceHistoryPage()),
                        ),
                        child: _buildTile(
                            context,
                            'Attendance History',
                            'assets/images/attendance_history.png',
                            tileWidth,
                            baseFontSize,
                            baseSpacing),
                      ),
                    ],
                  ),
                ),
              ),

              // Sliver 4: Attendance cards and profile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(baseSpacing),
                  child: Column(
                    children: [
                      Text(
                        'Selected Day Attendance',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: baseFontSize,
                        ),
                      ),
                      SizedBox(height: baseSpacing),
                      IntrinsicHeight(
                        child: BlocBuilder<AttendanceHistoryBloc,
                            AttendanceHistoryState>(
                          builder: (context, state) {
                            String checkInTime = 'Processing';
                            String checkOutTime = 'Processing';

                            if (state is AttendanceHistorySuccess) {
                              final selectedStr =
                                  DateFormat('yyyy-MM-dd').format(selectedDate);
                              final records = state.attendanceHistory
                                  .where((r) =>
                                      (r['date'] as String).substring(0, 10) ==
                                          selectedStr &&
                                      r['type'] == 'Attendance')
                                  .toList();
                              final record =
                                  records.isNotEmpty ? records.last : {};
                              if (record.isNotEmpty) {
                                checkInTime =
                                    record['check_in'] ?? 'No check-in';
                                print('check in time: $checkInTime');
                                checkOutTime =
                                    record['check_out'] ?? 'No check-out';
                                print('check out time: $checkOutTime');
                              } else {
                                checkInTime = "No Check-In";
                                checkOutTime = "No Check-out";
                              }
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => CheckInScreen(
                                                userSession: widget.userSession,
                                                userDetails: widget.userDetails,
                                                apiUrlConfig:
                                                    widget.apiUrlConfig,
                                                isCheckOutMode: false,
                                              )),
                                    ),
                                    child: _buildAttendanceCard(
                                      'Check in',
                                      checkInTime,
                                      'On time',
                                      Icons.login,
                                      baseFontSize,
                                      baseSpacing,
                                    ),
                                  ),
                                ),
                                SizedBox(width: baseSpacing * 0.75),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => CheckOutScreen(
                                              userSession: widget.userSession)),
                                    ),
                                    child: _buildAttendanceCard(
                                      'Check out',
                                      checkOutTime,
                                      'Go home',
                                      Icons.logout,
                                      baseFontSize,
                                      baseSpacing,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: baseSpacing * 1.5),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(baseSpacing * 1.25),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0x331F86E3),
                                      Color(0xFF1D5C9C)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(baseSpacing * 1.25),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(baseSpacing),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: screenWidth * 0.08,
                                            backgroundImage: (_imageUrl
                                                        ?.isNotEmpty ??
                                                    false)
                                                ? NetworkImage(
                                                    '${apiUrlConfig.baseUrl}$_imageUrl')
                                                : const AssetImage(
                                                        'assets/images/user.png')
                                                    as ImageProvider,
                                          ),
                                          SizedBox(width: baseSpacing),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _userName ?? 'N/A',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        baseFontSize * 1.3,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: baseSpacing * 0.25),
                                                Text(
                                                  _designation ?? 'N/A',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: baseFontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.person,
                                                  color: Colors.white,
                                                  size: baseFontSize * 1.2),
                                              SizedBox(
                                                  width: baseSpacing * 0.4),
                                              Text(
                                                _employeeCode ?? 'N/A',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: baseFontSize * 0.9,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: baseSpacing),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                            vertical: baseSpacing * 0.5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              baseSpacing * 0.5),
                                        ),
                                        alignment: Alignment.center,
                                        child: _logoUrl != null &&
                                                _logoUrl!.isNotEmpty
                                            ? Image.network(
                                                _logoUrl!,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return const CircularProgressIndicator();
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Text(
                                                    'Failed to load logo',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  );
                                                },
                                              )
                                            : const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --------
/// MODIFIED: Replaced `FittedBox` with `Center` to allow text wrapping
///           and ensure consistent font size.
/// --------
Widget _buildTile(BuildContext context, String title, String imagePath,
    double width, double baseFontSize, double baseSpacing) {
  return Container(
    width: width,
    height: width * 1.1,
    padding: EdgeInsets.all(baseSpacing * 0.5),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(baseSpacing * 0.75),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath, width: width * 0.35, height: width * 0.35),
        SizedBox(height: baseSpacing * 0.5),
        Expanded(
          child: Center(
            // Center the text in the remaining space
            child: Text(
              title,
              textAlign: TextAlign.center, // Center-align wrapped text
              style: TextStyle(
                fontSize: baseFontSize * 0.85, // Consistent font size
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAttendanceCard(String label, String time, String status,
    IconData icon, double baseFontSize, double baseSpacing) {
  return Container(
    padding: EdgeInsets.all(baseSpacing),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF0072FF).withOpacity(0.3)),
      borderRadius: BorderRadius.circular(baseSpacing * 0.75),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.black, size: baseFontSize * 1.5),
            SizedBox(width: baseSpacing * 0.5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: baseFontSize * 0.9,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: baseSpacing * 0.5),
        Text(
          time,
          style: TextStyle(
            fontSize: baseFontSize * 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: baseSpacing * 0.25),
        Text(
          status,
          style: TextStyle(
            color: Colors.grey,
            fontSize: baseFontSize * 0.85,
          ),
        ),
      ],
    ),
  );
}
