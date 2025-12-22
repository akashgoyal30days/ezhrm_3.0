import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
import '../bloc/req_past_attendance_bloc.dart';
import 'ReqPastAttendanceScreen.dart';

class ReqPastAttendanceHistoryScreen extends StatefulWidget{
  const ReqPastAttendanceHistoryScreen({super.key});

  @override
  State<ReqPastAttendanceHistoryScreen> createState() => _ReqPastAttendanceHistoryState();
}

class _ReqPastAttendanceHistoryState extends State<ReqPastAttendanceHistoryScreen> {

  @override
  void initState(){
    super.initState();
    getIt<ReqPastAttendanceBloc>().add(ReqPastAttendanceHistory());
  }

  String _formatApiDate(String apiDate) {
    try {
      DateTime parsed = DateTime.parse(apiDate.replaceAll('T00:00:00.000000Z', ''));
      return DateFormat('d MMM yyyy').format(parsed);
    } catch (e) {
      try {
        DateTime parsed = DateTime.parse(apiDate);
        return DateFormat('d MMM yyyy').format(parsed);
      } catch (_) {
        return apiDate;
      }
    }
  }

  int _calculateDays(String from, String to) {
    try {
      DateTime fromDate = DateTime.parse(from.replaceAll('T00:00:00.000000Z', ''));
      DateTime toDate = DateTime.parse(to);
      return toDate.difference(fromDate).inDays + 1; // inclusive
    } catch (e) {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;

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
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Request Past Attendance History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
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
                      )),
                      (route) => false,
                );
              },
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ],
          ),
          drawer: const CustomSidebar(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RequestPastAttendanceScreen())
              );
            },
            backgroundColor: Colors.blueAccent,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Request Past Attendance',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: BlocBuilder<ReqPastAttendanceBloc, ReqPastAttendanceState>(
            builder: (context, state) {
              if (state is ReqPastAttendanceLoading || state is ReqPastAttendanceHistoryLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ReqPastAttendanceHistorySuccess) {
                final requests = state.responseData;

                if (requests.isEmpty) {
                  return const Center(
                    child: Text(
                      'No past attendance requests found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final item = requests[index];
                    final fromDate = item['attendance_date'] as String;
                    final uptoDate = item['attendance_upto'] as String;
                    final remarks = item['remarks'] as String? ?? 'No remarks';
                    final status = item['status'];

                    final totalDays = _calculateDays(fromDate, uptoDate);

                    return Card(
                      color: Colors.white,
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Remarks + Status
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    remarks,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: Colors.yellow[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Row 2: From & To Dates
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Attendance From',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatApiDate(fromDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Attendance To',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatApiDate(uptoDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Total Days
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$totalDays day${totalDays > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: Text('Something went wrong.'));
            },
          ),
        )
    );
  }
}