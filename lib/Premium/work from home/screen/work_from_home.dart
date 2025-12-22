import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Authentication/bloc/auth_bloc.dart';
import '../../Authentication/screen/login_screen.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import '../../SessionHandling/session_bloc.dart';
import '../../SideMenuBar/screen/sidebar.dart';
import '../../success_dialog.dart';
import '../bloc/work_from_home_bloc.dart';

class RequestWorkFromHomeScreen extends StatefulWidget {
  const RequestWorkFromHomeScreen({super.key});

  @override
  State<RequestWorkFromHomeScreen> createState() =>
      _RequestWorkFromHomeScreenState();
}

class _RequestWorkFromHomeScreenState extends State<RequestWorkFromHomeScreen> {
  DateTime? startDate;
  DateTime? endDate;
  TextEditingController reasonController = TextEditingController();

  final dateFormat = DateFormat('dd MMM yyyy');

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  void _submitRequest() {
    if (startDate == null || endDate == null || reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    BlocProvider.of<WorkFromHomeBloc>(context).add(
      RequestWorkFromHome(
        start_date: startDate!.toIso8601String(),
        end_date: endDate!.toIso8601String(),
        reason: reasonController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return MultiBlocListener(
      listeners: [
        BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state is SessionExpiredState || state is UserNotFoundState) {
              // Clear credentials
              getIt<UserSession>().clearUserCredentials();
              getIt<UserDetails>().clearUserDetails();

              // Navigate to login
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
        BlocListener<WorkFromHomeBloc, WorkFromHomeState>(
          listener: (context, state) {
            if (state is RequestWorkFromHomeSuccess) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => SuccessDialog(
                  title: 'Success',
                  message:
                      'Your work from home request has been submitted successfully.',
                  buttonText: 'Proceed ',
                  onPressed:
                      () {}, // This will be handled inside the dialog already
                ),
              );
              // Optional: clear form or navigate
              setState(() {
                startDate = null;
                endDate = null;
                reasonController.clear();
              });
            } else if (state is RequestWorkFromHomeFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage)),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Request work from home',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
          leading: const BackButton(color: Colors.black),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: Colors.black,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ],
        ),
        drawer: const CustomSidebar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Image.asset(
                'assets/images/workfromhome.png',
                width: width * 0.7,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please fill in the details below to apply for work from home',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Select Date',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      context: context,
                      label: "Start Date",
                      date: startDate,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateField(
                      context: context,
                      label: "End Date",
                      date: endDate,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Reason',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: reasonController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: "Share your reason here",
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              BlocBuilder<WorkFromHomeBloc, WorkFromHomeState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0072ff),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: state is RequestWorkFromHomeLoading
                          ? null
                          : _submitRequest,
                      child: state is RequestWorkFromHomeLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Request',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null ? dateFormat.format(date) : label,
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
            const Icon(Icons.calendar_today, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
