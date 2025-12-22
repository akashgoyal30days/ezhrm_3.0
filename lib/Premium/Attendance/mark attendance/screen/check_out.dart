//check_out.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Authentication/bloc/auth_bloc.dart';
import '../../../Authentication/screen/login_screen.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../../Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../mark attendance/screen/mark_attendance_screen.dart';

class CurrentTimeWidget extends StatefulWidget {
  const CurrentTimeWidget({super.key});

  @override
  State<CurrentTimeWidget> createState() => _CurrentTimeWidgetState();
}

class _CurrentTimeWidgetState extends State<CurrentTimeWidget> {
  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    setState(() {
      _currentTime = formattedTime;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Text(
      _currentTime,
      style: TextStyle(
        color: Colors.white,
        fontSize: screenWidth * 0.12,
        fontWeight: FontWeight.w300,
        letterSpacing: 2,
      ),
    );
  }
}

class CheckOutScreen extends StatefulWidget {
  final UserSession userSession;

  const CheckOutScreen({
    super.key,
    required this.userSession,
  });

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  String? _inTime;
  String? _outTime;
  final List<String> _pendingRequests = [];
  String _location = '';
  bool _hasLoggedAttendanceData = false;

  @override
  void initState() {
    super.initState();
    _fetchCompanyData();

    // Trigger both events to fetch data
    getIt<GetTodayAttendanceBloc>().add(GetTodayAttendance());
    getIt<GetTodayAttendanceLogsBloc>().add(GetTodayAttendanceLogs());
  }

  Future<void> _fetchCompanyData() async {
    try {
      final apiUrlConfig = getIt<ApiUrlConfig>();
      final userSession = getIt<UserSession>();
      final token = await userSession.token;

      final response = await http.get(
        Uri.parse('${apiUrlConfig.baseUrl}${apiUrlConfig.getCompanyInfoPath}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['company'] != null && data['company']['name'] != null) {
          setState(() {
            _location = data['company']['name'];
          });
          debugPrint('✅ Fetched company name: $_location');
        } else {
          setState(() {
            _location = 'Unknown Location';
          });
          debugPrint('❌ Company name not found in response');
        }
      } else {
        setState(() {
          _location = 'Unknown Location';
        });
        debugPrint('❌ Failed to fetch company data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _location = 'Unknown Location';
      });
      debugPrint('❌ Error fetching company data: $e');
    }
  }

  String _calculateWorkHours(String checkInStr, String checkOutStr) {
    try {
      if (checkInStr == '--:--:--' || checkOutStr == '--:--:--') {
        return '--:--:--';
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final checkIn = DateTime.parse('$today $checkInStr');
      final checkOut = DateTime.parse('$today $checkOutStr');

      final diff = checkOut.difference(checkIn);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

      return '$hours:$minutes:$seconds';
    } catch (_) {
      return '--:--:--';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> onRefresh() async {
    getIt<GetTodayAttendanceBloc>().add(GetTodayAttendance());
    getIt<GetTodayAttendanceLogsBloc>().add(GetTodayAttendanceLogs());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Attendance Logs',
            style: TextStyle(
              color: const Color(0xFF666666),
              fontWeight: FontWeight.w700,
              fontSize: screenWidth * 0.05,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: Colors.black,
              size: screenWidth * 0.08,
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    userSession: getIt<UserSession>(),
                    userDetails: getIt<UserDetails>(),
                    apiUrlConfig: getIt<ApiUrlConfig>(),
                    locationService: getIt<LocationService>(),
                  ),
                ),
                (route) => false,
              );
            },
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ),
                child: IntrinsicHeight(
                  child: BlocBuilder<GetTodayAttendanceBloc,
                      GetTodayAttendanceState>(
                    builder: (context, attendanceState) {
                      return BlocBuilder<GetTodayAttendanceLogsBloc,
                          GetTodayAttendanceState>(
                        builder: (context, logsState) {
                          debugPrint("📌 Attendance State: $attendanceState");
                          debugPrint("📌 Logs State: $logsState");

                          if (attendanceState is GetTodayAttendanceLoading ||
                              logsState is GetTodayAttendanceLogsLoading) {
                            debugPrint(
                                "⏳ Attendance or Logs data is loading...");
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (attendanceState is GetTodayAttendanceFailure) {
                            debugPrint(
                                "❌ Attendance data fetch failed: ${attendanceState.errorMessage}");
                            return Center(
                                child: Text(
                                    'Error: ${attendanceState.errorMessage}'));
                          }

                          if (logsState is GetTodayAttendanceLogsFailure) {
                            debugPrint(
                                "❌ Logs data fetch failed: ${logsState.errorMessage}");
                            return Center(
                                child:
                                    Text('Error: ${logsState.errorMessage}'));
                          }

                          String? checkIn;
                          String? checkOut;
                          List<String> pendingRequests = [];

                          // Process attendance data for check-in/check-out
                          if (attendanceState is GetTodayAttendanceSuccess) {
                            debugPrint(
                                "✅ Attendance data fetch success. Total records: ${attendanceState.attendanceData.length}");
                            final attendanceData = attendanceState
                                .attendanceData
                                .where((data) => data['type'] == 'Attendance')
                                .toList();

                            if (attendanceData.isNotEmpty) {
                              final latestAttendance = attendanceData.last;
                              checkIn =
                                  _formatTime(latestAttendance['check-in']);
                              checkOut =
                                  _formatTime(latestAttendance['check-out']);
                            }
                          }

                          // Process logs data for all pending requests
                          if (logsState is GetTodayAttendanceLogsSuccess) {
                            debugPrint(
                                "✅ Logs data fetch success. Total records: ${logsState.attendanceData.length}");
                            final pendingLogs = logsState.attendanceData
                                .where((data) => data['type'] == 'Pending')
                                .toList();

                            for (var log in pendingLogs) {
                              if (log['check_in'] != null) {
                                pendingRequests
                                    .add(_formatTime(log['check_in']));
                              } else if (log['check_out'] != null) {
                                pendingRequests
                                    .add(_formatTime(log['check_out']));
                              }
                            }
                          }

                          checkIn ??= '--:--:--';
                          checkOut ??= '--:--:--';
                          pendingRequests = pendingRequests.isEmpty
                              ? ['No pending requests']
                              : pendingRequests;

                          if (!_hasLoggedAttendanceData) {
                            debugPrint(
                                '🕒 First-time log -> Check-in: $checkIn, Check-out: $checkOut, Pending: $pendingRequests');
                            _hasLoggedAttendanceData = true;
                          }

                          debugPrint('🔄 Latest check-in: $checkIn');
                          debugPrint('🔄 Latest check-out: $checkOut');
                          debugPrint('🔄 Pending requests: $pendingRequests');
                          debugPrint('📍 Location: $_location');

                          final totalWorkHours =
                              _calculateWorkHours(checkIn, checkOut);
                          debugPrint(
                              '📊 Total Work Hours: $totalWorkHours at $_location');

                          return _buildContent(
                            checkIn,
                            checkOut,
                            totalWorkHours,
                            _location.isEmpty ? 'Loading...' : _location,
                            pendingRequests: pendingRequests,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    String checkIn,
    String checkOut,
    String totalWorkHours,
    String location, {
    required List<String> pendingRequests,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.03,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * 0.02),
          Container(
            width: screenWidth,
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: BoxDecoration(
              color: const Color(0xFF2C437B),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: screenWidth * 0.012,
                  offset: Offset(0, screenHeight * 0.004),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Current Location',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: screenWidth * 0.04,
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Expanded(
                      // ← This is the key!
                      child: Text(
                        location,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.035,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // ← Adds "..." if too long
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Center(
                  child: CurrentTimeWidget(),
                ),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  children: [
                    Text(
                      'Total work hours today',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      totalWorkHours,
                      style: TextStyle(
                        color: const Color(0xFF7FA6DB),
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.025),
          Container(
            width: screenWidth,
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.025,
              horizontal: screenWidth * 0.04,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: screenWidth * 0.02,
                  offset: Offset(0, screenHeight * 0.005),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Day Activity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.045,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LEFT: Location name (can be very long → wrap with Expanded)
                    Expanded(
                      flex: 2, // Gives it more space than the right side
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Adds "..." if too long
                        maxLines: 1,
                      ),
                    ),

                    // Optional: small spacing in between
                    SizedBox(width: 12),

                    // RIGHT: Time range (usually fixed length)
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$checkIn - $checkOut',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign:
                            TextAlign.end, // Keeps it aligned to the right
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Requests',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      height: screenHeight * 0.18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: pendingRequests.length,
                        itemBuilder: (context, index) {
                          final request = pendingRequests[index];
                          final isMoreThanThree = pendingRequests.length > 3 &&
                              request != 'No pending requests';
                          final displayText = isMoreThanThree
                              ? request.replaceFirst(
                                  RegExp(r'Pending (Check-in|Check-out) at '),
                                  '')
                              : request;

                          return SizedBox(
                            height: screenHeight * 0.05,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    displayText,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (request != 'No pending requests')
                                  SizedBox(
                                    width: screenWidth * 0.12,
                                    height: screenWidth * 0.12,
                                    child: Image.asset(
                                      'assets/images/request.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.025),
          Center(
            child: Container(
              width: screenWidth * 0.35,
              height: screenWidth * 0.35,
              decoration: BoxDecoration(
                color: const Color(0xFF455A76),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: screenWidth * 0.05,
                    offset: Offset(0, screenHeight * 0.01),
                  ),
                ],
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(0),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckInScreen(
                        isCheckOutMode: true,
                        userDetails: getIt<UserDetails>(),
                        apiUrlConfig: getIt<ApiUrlConfig>(),
                        userSession: widget.userSession,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      color: Colors.white,
                      size: screenWidth * 0.12,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'CHECK-OUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.045,
                        letterSpacing: screenWidth * 0.00375,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '--:--:--';
    try {
      if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(timeString)) {
        return timeString;
      }
      final parsed = DateTime.parse(timeString);
      return DateFormat('HH:mm:ss').format(parsed);
    } catch (e) {
      debugPrint('Time parse error: $e');
      return '--:--:--';
    }
  }
}
