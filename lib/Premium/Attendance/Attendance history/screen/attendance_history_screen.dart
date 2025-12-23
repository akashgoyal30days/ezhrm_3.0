import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Authentication/bloc/auth_bloc.dart';
import '../../../Authentication/screen/login_screen.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../../SideMenuBar/screen/sidebar.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../../Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Week_Off/bloc/week_off_bloc.dart';
import '../bloc/attendance_history_bloc.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  _AttendanceHistoryPageState createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _detailViewDay;
  DateTime? joiningDate;

  Map<DateTime, String> statusMap = {};
  Map<DateTime, Map<String, String>> timeMap = {};

  int fullDay = 0;
  int halfDay = 0;
  int fullDayLeave = 0;
  int halfDayLeave = 0;
  int shortLeave = 0;
  int workFromHome = 0;
  int weeklyOff = 0;
  int absent = 0;
  int notPayable = 0;
  int notJoined = 0;
  int holiday = 0;
  int latePresent = 0;

  List<DateTime> weekOffDates = [];
  Set<String> weekOffDaysOfWeek = {};
  bool weekOffFetchFailed = false;
  bool companyWeekOffFetched = false;
  bool employeeWeekOffFetched = false;

  // NEW: Pending Data Storage
  List<Map<String, dynamic>> _pendingAttendanceData = [];

  final Map<String, Map<String, Color>> attendanceStatusStyles = {
    'Present': {'background': const Color(0xFF28A745), 'text': Colors.white},
    'Full Day': {'background': const Color(0xFF28A745), 'text': Colors.white},
    'Late Present': {
      'background': const Color(0xFF9ACD32),
      'text': Colors.black
    },
    'Half Day': {'background': const Color(0xFFC3E6CB), 'text': Colors.black},
    'Absent': {'background': const Color(0xFFDC3545), 'text': Colors.white},
    'Holiday': {'background': const Color(0xFFFFC107), 'text': Colors.black},
    'Full Day Leave': {
      'background': const Color(0xFFFF6384),
      'text': Colors.white
    },
    'Half Day Leave': {
      'background': const Color(0xFFF8D7DA),
      'text': Colors.black
    },
    'Short Leave': {
      'background': const Color(0xFFFF9800),
      'text': Colors.white
    },
    'Work From Home': {
      'background': const Color(0xFF17A2B8),
      'text': Colors.white
    },
    'Not Payable': {
      'background': const Color(0xFFD4C4FB),
      'text': Colors.black
    },
    'Not Joined': {'background': const Color(0xFF000000), 'text': Colors.white},
  };

  List<Map<String, dynamic>> _allAttendance = [];

  @override
  void initState() {
    super.initState();
    _loadJoiningDate();
    final now = DateTime.now();
    _selectedDay = now;
    _detailViewDay = now;
    _focusedDay = now;

    getIt<AttendanceHistoryBloc>().add(FetchAttendanceHistory());
    getIt<GetAllPendingRequestBloc>().add(GetAllPendingRequest());
    getIt<WeekOffBloc>().add(GetWeekOff());
  }

  Future<void> _loadJoiningDate() async {
    final prefs = await SharedPreferences.getInstance();
    final joiningDateString = prefs.getString('joiningDate');

    if (joiningDateString != null) {
      setState(() {
        if (joiningDateString == "0000-00-00") {
          // 👈 Replace invalid date with fallback
          joiningDate = DateTime(2025, 01, 01);
        } else {
          joiningDate = DateTime.tryParse(joiningDateString);
        }
        _processMonthlyData(_allAttendance);
      });
    }
  }

  void _processMonthlyData(List<Map<String, dynamic>> attendanceData) {
    // Clear existing data
    statusMap.clear();
    timeMap.clear();
    fullDay = halfDay = absent = holiday = latePresent = 0;
    fullDayLeave = halfDayLeave = shortLeave = workFromHome = weeklyOff = 0;
    notPayable = notJoined = 0;

    final currentMonth = _focusedDay.month;
    final currentYear = _focusedDay.year;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Group records by date
    Map<DateTime, List<Map<String, dynamic>>> recordsByDate = {};
    for (var item in attendanceData) {
      final date = DateTime.parse(item['date']);
      if (date.month != currentMonth || date.year != currentYear) continue;
      final key = DateTime(date.year, date.month, date.day);
      recordsByDate.putIfAbsent(key, () => []).add(item);
    }

    // Process each date's records
    for (var entry in recordsByDate.entries) {
      final date = entry.key;
      final records = entry.value;
      String status = 'Unknown';
      String inTime = '--:--';
      String outTime = '--:--';

      // Prioritize Attendance (present-related) records
      var attendanceRecord = records.firstWhere(
        (item) => item['type'] == 'Attendance',
        orElse: () => <String, dynamic>{},
      );
      if (attendanceRecord.isNotEmpty) {
        status = attendanceRecord['status'] ?? 'Unknown';
        inTime = attendanceRecord['check_in'] ?? '--:--';
        outTime = attendanceRecord['check_out'] ?? '--:--';
      } else {
        // If no Attendance, check for Leave
        var leaveRecord = records.firstWhere(
          (item) => item['type'] == 'Leave',
          orElse: () => <String, dynamic>{},
        );
        if (leaveRecord.isNotEmpty) {
          status = leaveRecord['leave_type'] == 'Full Day'
              ? 'Full Day Leave'
              : 'Half Day Leave';
        } else {
          // If no Leave, check for Holiday
          var holidayRecord = records.firstWhere(
            (item) => item['type'] == 'Holiday',
            orElse: () => <String, dynamic>{},
          );
          if (holidayRecord.isNotEmpty) {
            status = 'Holiday';
          } else {
            // If no Attendance, Leave, or Holiday, check for Rejected
            bool hasRejected =
                records.any((item) => item['type'] == 'Rejected');
            if (hasRejected) {
              if (_isWeekOffDayOfWeek(date) || weekOffDates.contains(date)) {
                continue; // Skip week-off days with Rejected records
              }
              status = 'Absent';
              inTime = 'N/A';
              outTime = 'N/A';
            }
          }
        }
      }

      // Update status and time maps, and increment counter
      if (status != 'Unknown') {
        statusMap[date] = status;
        timeMap[date] = {'in': inTime, 'out': outTime};
        _incrementCounter(status);
      }
    }

    // Process remaining days in the month
    final bool isFutureMonth = currentYear > today.year ||
        (currentYear == today.year && currentMonth > today.month);
    int lastDay;
    if (isFutureMonth) {
      lastDay = 0; // Don't process future months
    } else if (currentYear == today.year && currentMonth == today.month) {
      lastDay = today.day; // Process up to today for current month
    } else {
      lastDay = DateTime(currentYear, currentMonth + 1, 0)
          .day; // Process all days for past months
    }

    for (int i = 1; i <= lastDay; i++) {
      final day = DateTime(currentYear, currentMonth, i);
      final dayOnly = DateTime(day.year, day.month, day.day);

      if (statusMap.containsKey(dayOnly)) {
        continue; // Skip days already processed
      }
      if (joiningDate != null && day.isBefore(joiningDate!)) {
        // Mark days before joining date as Not Joined
        statusMap[dayOnly] = 'Not Joined';
        timeMap[dayOnly] = {'in': 'N/A', 'out': 'N/A'};
        notJoined++;
        continue;
      }
      if (_isWeekOffDayOfWeek(dayOnly) || weekOffDates.contains(dayOnly)) {
        // Skip week-off days
        continue;
      }
      // Mark unprocessed non-week-off days as Absent
      statusMap[dayOnly] = 'Absent';
      timeMap[dayOnly] = {'in': 'N/A', 'out': 'N/A'};
      absent++;
    }
  }

  bool _isWeekOffDayOfWeek(DateTime day) {
    final dayName = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ][day.weekday % 7];
    return weekOffDaysOfWeek.contains(dayName);
  }

  bool _hasAttendanceRecord(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    return _allAttendance.any((item) {
      final itemDate = DateTime.parse(item['date']);
      return itemDate.year == day.year &&
          itemDate.month == day.month &&
          itemDate.day == day.day &&
          item['type'] == 'Attendance';
    });
  }

  void _incrementCounter(String status) {
    switch (status) {
      case 'Present':
      case 'Full Day':
        fullDay++;
        break;
      case 'Late Present':
        latePresent++;
        break;
      case 'Half Day':
        halfDay++;
        break;
      case 'Absent':
        absent++;
        break;
      case 'Holiday':
        holiday++;
        break;
      case 'Full Day Leave':
        fullDayLeave++;
        break;
      case 'Half Day Leave':
        halfDayLeave++;
        break;
      case 'Short Leave':
        shortLeave++;
        break;
      case 'Work From Home':
        workFromHome++;
        break;
      case 'Not Payable':
        notPayable++;
        break;
      case 'Not Joined':
        notJoined++;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

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
        BlocListener<WeekOffBloc, WeekOffState>(
          listener: (context, state) async {
            setState(() {
              if (state is WeekOffSuccess) {
                weekOffFetchFailed = false;
                weekOffDaysOfWeek.clear();
                final userSession = getIt<UserSession>();
                userSession.uid.then((uid) {
                  for (var item in state.weekOffData) {
                    if (item['is_active'] == true) {
                      if (item['employee_id'] == null) {
                        // Company-wide week-off
                        print('all employee week off is present');
                        weekOffDaysOfWeek
                            .addAll(List<String>.from(item['days_of_week']));
                      } else if (item['employee_id']?.toString() ==
                          uid.toString()) {
                        print('uid is $uid and it is found');
                        print('employee id is ${item['employee_id']}');
                        print('here is the week off ${item['days_of_week']}');
                        weekOffDaysOfWeek
                            .addAll(List<String>.from(item['days_of_week']));
                      }
                    }
                  }
                  _processMonthlyData(_allAttendance);
                });
              } else if (state is WeekOffFailure) {
                weekOffFetchFailed = true;
                weekOffDaysOfWeek.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load week off data.'),
                    backgroundColor: Colors.red,
                  ),
                );
                _processMonthlyData(_allAttendance);
              }
            });
          },
        ),
        BlocListener<AttendanceHistoryBloc, AttendanceHistoryState>(
          listener: (context, state) {
            if (state is AttendanceHistorySuccess) {
              setState(() {
                _allAttendance = state.attendanceHistory;
                _processMonthlyData(_allAttendance);
              });
            } else if (state is AttendanceHistoryFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        // ADD NEW: Pending Request BlocListener
        BlocListener<GetAllPendingRequestBloc, GetTodayAttendanceState>(
          listener: (context, state) {
            if (state is GetAllPendingRequestSuccess) {
              setState(() {
                _pendingAttendanceData = state.pendingRequestData;
                // Only update UI if a date is selected
                if (_selectedDay != null) {
                  _filterPendingForSelectedDate();
                }
              });
            } else if (state is GetAllPendingRequestFailure) {
              print('Pending requests failed: ${state.errorMessage}');
              setState(() {
                _pendingAttendanceData = [];
              });
            }
          },
        ),
      ],
      child: Scaffold(
        bottomNavigationBar: bottomBarIos(),
        appBar: AppBar(
          title: Text(
            "Attendance History",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18 * textScaleFactor,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actionsPadding: EdgeInsets.only(right: screenWidth * 0.04),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black),
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
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ],
        ),
        drawer: const CustomSidebar(),
        body: Column(
          children: [
            // Calendar Section
            Expanded(
              child: BlocBuilder<AttendanceHistoryBloc, AttendanceHistoryState>(
                builder: (context, attendanceState) {
                  if (attendanceState is AttendanceHistoryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (attendanceState is AttendanceHistorySuccess) {
                    _allAttendance = attendanceState.attendanceHistory;
                    return _buildCalendarContent(context);
                  } else if (attendanceState is AttendanceHistoryFailure) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        child: Text(
                          attendanceState.errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16 * textScaleFactor),
                        ),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            // Pending Attendance Section
            _buildPendingAttendanceSection(context),
          ],
        ),
      ),
    );
  }

  /// Keep _buildPendingItem unchanged
  Widget _buildPendingItem(BuildContext context, Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    String date = '';
    String? checkInTime;
    String? checkOutTime;

    // Helper to format time safely
    String formatTime(String? dateTimeString) {
      if (dateTimeString == null || dateTimeString.isEmpty) return '';
      try {
        // Handles formats like "2025-10-16T17:34:00.000000Z"
        final parsed = DateTime.parse(dateTimeString);
        return DateFormat('HH:mm:ss').format(parsed);
      } catch (_) {
        // If not a valid DateTime string, just return the input as fallback
        return dateTimeString;
      }
    }

    if (item.containsKey('attendance_date')) {
      final rawDate = item['attendance_date']?.toString() ?? '';
      date = rawDate.contains('T') ? rawDate.split('T')[0] : rawDate;

      checkInTime = formatTime(item['check_in_time']?.toString());
      checkOutTime = formatTime(item['check_out_time']?.toString());
    } else if (item.containsKey('log_date')) {
      date = item['log_date']?.toString() ?? '';

      checkInTime = formatTime(item['check_in_time']?.toString());
      checkOutTime = formatTime(item['check_out_time']?.toString());
    }

    bool hasTime = (checkInTime != null && checkInTime.isNotEmpty) ||
        (checkOutTime != null && checkOutTime.isNotEmpty);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today,
                color: Colors.orange.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 14 * textScaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasTime) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (checkInTime != null && checkInTime.isNotEmpty) ...[
                        const Icon(Icons.login, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('In: $checkInTime'),
                        const SizedBox(width: 16),
                      ],
                      if (checkOutTime != null && checkOutTime.isNotEmpty) ...[
                        const Icon(Icons.logout, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text('Out: $checkOutTime'),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// NEW: Filter pending data for selected date only
  List<Map<String, dynamic>> _getPendingForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _pendingAttendanceData.where((item) {
      String itemDate;
      if (item.containsKey('attendance_date')) {
        itemDate = item['attendance_date'].split('T')[0];
      } else if (item.containsKey('log_date')) {
        itemDate = item['log_date'];
      } else {
        return false;
      }
      final itemDateTime = DateTime.tryParse(itemDate);
      return itemDateTime != null && isSameDay(itemDateTime, targetDate);
    }).toList();
  }

  /// MODIFIED: Show pending ONLY for selected date
  Widget _buildPendingAttendanceSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final pendingForDate =
        _selectedDay != null ? _getPendingForDate(_selectedDay!) : [];

    if (pendingForDate.isEmpty) {
      return SizedBox.shrink(); // Hide completely
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border:
            Border(top: BorderSide(color: Colors.orange.shade200, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade300, shape: BoxShape.circle),
                  child: Icon(Icons.pending_actions,
                      color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pending Requests for ${_formatDateShort(_selectedDay!)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...pendingForDate
              .map<Widget>((item) => _buildPendingItem(context, item)),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  /// NEW: Format date as "14 Oct"
  String _formatDateShort(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// ADD THIS NEW METHOD (Fixes the error!)
  void _filterPendingForSelectedDate() {
    // Empty method - just triggers UI rebuild
    // Actual filtering is done in _buildPendingAttendanceSection
  }

  Widget _buildCalendarContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final detailKey = _detailViewDay != null
        ? DateTime(
            _detailViewDay!.year, _detailViewDay!.month, _detailViewDay!.day)
        : null;
    final inTime = timeMap[detailKey]?['in'];
    final outTime = timeMap[detailKey]?['out'];

    return SingleChildScrollView(
      child: Column(
        children: [
          if (weekOffFetchFailed)
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              color: Colors.yellow.shade100,
              child: Text(
                'Warning: Unable to load week off data. Attendance may not be accurate.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14 * textScaleFactor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.02,
              vertical: screenHeight * 0.01,
            ),
            child: TableCalendar(
              focusedDay: _focusedDay,
              firstDay: joiningDate ?? DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              enabledDayPredicate: (day) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                if (joiningDate != null &&
                    normalizedDay.isBefore(joiningDate!)) {
                  return false; // Disable days before joiningDate
                }
                if (_isWeekOffDayOfWeek(normalizedDay) ||
                    weekOffDates.contains(normalizedDay)) {
                  return _hasAttendanceRecord(
                      normalizedDay); // Enable week-off days only if they have attendance
                }
                return true; // Enable all other days
              },
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: EdgeInsets.all(4.0),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12 * textScaleFactor,
                  fontWeight: FontWeight.w500,
                ),
                weekendStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12 * textScaleFactor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 16 * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                todayBuilder: (context, day, focusedDay) {
                  final dateKey = DateTime(day.year, day.month, day.day);
                  final status = statusMap[dateKey];
                  Color cellColor = Colors.white;
                  Color textColor = Colors.black;

                  if (status != null) {
                    final style = attendanceStatusStyles[status] ??
                        {'background': Colors.white, 'text': Colors.black};
                    cellColor = style['background']!;
                    textColor = style['text']!;
                  }

                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cellColor,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                          color: Colors.blueAccent,
                          width: 2.0), // Highlight today
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold, // Make today bold
                        fontSize: 14 * textScaleFactor,
                      ),
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  final dateKey = DateTime(day.year, day.month, day.day);
                  final status = statusMap[dateKey];
                  final isWeekOff = _isWeekOffDayOfWeek(dateKey) ||
                      weekOffDates.contains(dateKey);
                  final isFutureDay = dateKey.isAfter(todayDate);
                  bool isSelected = isSameDay(_selectedDay, day);
                  Color cellColor = Colors.white;
                  Color textColor = Colors.black;

                  if (status != null) {
                    final style = attendanceStatusStyles[status] ??
                        {'background': Colors.white, 'text': Colors.black};
                    cellColor = style['background']!;
                    textColor = style['text']!;
                  } else if (isWeekOff && !_hasAttendanceRecord(dateKey)) {
                    cellColor = Colors.white;
                    textColor = Colors.black;
                  } else if (isFutureDay) {
                    cellColor = Colors.white;
                    textColor = Colors.black;
                  }

                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cellColor,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 2.0)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14 * textScaleFactor,
                      ),
                    ),
                  );
                },
                disabledBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF0F0F0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14 * textScaleFactor,
                      ),
                    ),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (joiningDate != null && selectedDay.isBefore(joiningDate!)) {
                  return; // Prevent selecting days before joiningDate
                }
                if (_isWeekOffDayOfWeek(selectedDay) ||
                    weekOffDates.contains(DateTime(selectedDay.year,
                        selectedDay.month, selectedDay.day))) {
                  if (!_hasAttendanceRecord(selectedDay)) {
                    return; // Prevent selecting week-off days without attendance
                  }
                }
                setState(() {
                  _selectedDay = selectedDay;
                  _detailViewDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                final now = DateTime.now();
                setState(() {
                  _focusedDay = focusedDay;
                  if (focusedDay.month == now.month &&
                      focusedDay.year == now.year) {
                    _selectedDay = now; // Auto-select today for current month
                    _detailViewDay = now;
                  } else {
                    _selectedDay = null;
                    _detailViewDay =
                        DateTime(focusedDay.year, focusedDay.month, 1);
                  }
                  _processMonthlyData(_allAttendance);
                });
              },
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          if (_detailViewDay != null)
            Column(
              children: [
                Text(
                  "${_detailViewDay!.day}-${_detailViewDay!.month}-${_detailViewDay!.year}",
                  style: GoogleFonts.poppins(
                    fontSize: 18 * textScaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _timeBox(context, inTime, "Check-in",
                          Colors.green.shade100, Colors.green),
                      _timeBox(context, outTime, "Check-out",
                          Colors.purple.shade100, Colors.purple),
                    ],
                  ),
                ),
              ],
            ),
          SizedBox(height: screenHeight * 0.02),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _timeBox(BuildContext context, String? time, String label,
      Color bgColor, Color textColor) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final displayTime =
        time != null && time.isNotEmpty && time != '--:--' ? time : 'N/A';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 14 * textScaleFactor,
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.access_time, color: textColor, size: 28),
            const SizedBox(height: 4),
            Text(
              displayTime,
              style: TextStyle(
                color: textColor,
                fontSize: 22 * textScaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          _legendRow(context, "Full Day",
              attendanceStatusStyles['Full Day']!['background']!, fullDay),
          _legendRow(context, "Half Day",
              attendanceStatusStyles['Half Day']!['background']!, halfDay),
          _legendRow(
              context,
              "Full Day Leave",
              attendanceStatusStyles['Full Day Leave']!['background']!,
              fullDayLeave),
          _legendRow(
              context,
              "Half Day Leave",
              attendanceStatusStyles['Half Day Leave']!['background']!,
              halfDayLeave),
          _legendRow(
              context,
              "Short Leave",
              attendanceStatusStyles['Short Leave']!['background']!,
              shortLeave),
          _legendRow(
              context,
              "Work From Home",
              attendanceStatusStyles['Work From Home']!['background']!,
              workFromHome),
          _legendRow(
              context,
              "Late Present",
              attendanceStatusStyles['Late Present']!['background']!,
              latePresent),
          _legendRow(context, "Absent",
              attendanceStatusStyles['Absent']!['background']!, absent),
          _legendRow(
              context,
              "Not Payable",
              attendanceStatusStyles['Not Payable']!['background']!,
              notPayable),
          _legendRow(context, "Holidays",
              attendanceStatusStyles['Holiday']!['background']!, holiday),
          _legendRow(context, "Not Joined",
              attendanceStatusStyles['Not Joined']!['background']!, notJoined),
        ],
      ),
    );
  }

  Widget _legendRow(
      BuildContext context, String label, Color dotColor, int count) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, color: dotColor, size: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 16 * textScaleFactor),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14 * textScaleFactor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
