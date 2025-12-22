import 'package:ezhrm/Premium/Attendance/req_past_attendance/screen/req_past_history.dart';
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
import '../../../success_dialog.dart';
import '../bloc/req_past_attendance_bloc.dart';

class RequestPastAttendanceScreen extends StatefulWidget {
  const RequestPastAttendanceScreen({super.key});

  @override
  State<RequestPastAttendanceScreen> createState() =>
      _RequestPastAttendanceScreenState();
}

class _RequestPastAttendanceScreenState
    extends State<RequestPastAttendanceScreen> {
  DateTime? selectedDate;
  DateTime? selectedDateUpto;
  final TextEditingController reasonController = TextEditingController();

  void _submitRequest(BuildContext context) {
    if (selectedDate == null ||
        selectedDateUpto == null ||
        reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and enter a reason'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    getIt<ReqPastAttendanceBloc>().add(
      ReqPastAttendance(
        attendance_date: DateFormat('yyyy-MM-dd').format(selectedDate!),
        attendance_upto: DateFormat('yyyy-MM-dd').format(selectedDateUpto!),
        remarks: reasonController.text,
        longitude: '',
        latitude: '',
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => ReqPastAttendanceHistoryScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Request Past Attendance',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18 * textScaleFactor,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.black),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => ReqPastAttendanceHistoryScreen()),
                (route) => false,
              );
            },
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ),
        drawer: const CustomSidebar(),
        body: BlocConsumer<ReqPastAttendanceBloc, ReqPastAttendanceState>(
          listener: (context, state) {
            if (state is ReqPastAttendanceSuccess) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => SuccessDialog(
                  title: 'Success',
                  message:
                      'Your past attendance request has been submitted successfully.',
                  buttonText: 'Proceed',
                  onPressed: () {},
                ),
              );
            } else if (state is ReqPastAttendanceFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight * 0.8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    Image.asset(
                      'assets/images/ReqPastAttendance.png',
                      height: screenHeight * 0.2,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Please fill in the details below to apply for\nPast Attendance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16 * textScaleFactor,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Date From',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * textScaleFactor,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    TextFormField(
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Select Date From',
                        hintStyle: TextStyle(
                          fontSize: 14 * textScaleFactor,
                        ),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.02,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14 * textScaleFactor,
                      ),
                      controller: TextEditingController(
                        text: selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                            : '',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Date Upto',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * textScaleFactor,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    TextFormField(
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDateUpto ?? DateTime.now(),
                          firstDate: selectedDate ?? DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDateUpto = picked;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Select Date Upto',
                        hintStyle: TextStyle(
                          fontSize: 14 * textScaleFactor,
                        ),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.02,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14 * textScaleFactor,
                      ),
                      controller: TextEditingController(
                        text: selectedDateUpto != null
                            ? DateFormat('yyyy-MM-dd').format(selectedDateUpto!)
                            : '',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Reason',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * textScaleFactor,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    TextFormField(
                      controller: reasonController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your reason here',
                        hintStyle: TextStyle(
                          fontSize: 14 * textScaleFactor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.02,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14 * textScaleFactor,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is ReqPastAttendanceLoading
                            ? null
                            : () => _submitRequest(context),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: state is ReqPastAttendanceLoading
                            ? SizedBox(
                                height: screenHeight * 0.025,
                                width: screenHeight * 0.025,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 16 * textScaleFactor,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
