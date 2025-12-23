import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// 'http' import is unused, so it can be removed.
// import 'package:http/http.dart' as context;
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Authentication/bloc/auth_bloc.dart';
import '../../../Authentication/screen/login_screen.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../../SideMenuBar/screen/sidebar.dart';
import '../bloc/leave_status_bloc.dart';
import 'leave_card_widget.dart';

class LeaveStatusScreen extends StatefulWidget {
  const LeaveStatusScreen({super.key});

  @override
  State<LeaveStatusScreen> createState() => _LeaveStatusScreenState();
}

class _LeaveStatusScreenState extends State<LeaveStatusScreen> {
  // ✨ ADD THIS initState METHOD
  @override
  void initState() {
    super.initState();
    // Trigger the data fetch when the screen loads
    getIt<LeaveStatusBloc>().add(FetchLeaveStatus());
  }

  // Handle pull-to-refresh
  Future<void> _onRefresh() async {
    getIt<LeaveStatusBloc>().add(FetchLeaveStatus());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen for session-related states (expired or user not found)
        BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state is SessionExpiredState || state is UserNotFoundState) {
              // Clear user credentials and details
              getIt<UserSession>().clearUserCredentials();
              getIt<UserDetails>().clearUserDetails();

              // Show session expired message
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session expired. Please login again.'),
                  backgroundColor: Colors.red,
                ),
              );

              // Navigate to LoginScreen after a 2-second delay
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
                  (route) => false, // Remove all previous routes
                );
              });
            }
          },
        ),
        BlocListener<DeleteBloc, DeleteState>(
          listener: (context, state) {
            if (state is DeleteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(" deleted item successfully"),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is DeleteFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("error deleting item"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        // Listen for authentication-related states (logout success or failure)
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              // Show logout success message
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully.'),
                  backgroundColor: Color(0xFF416CAF),
                ),
              );

              // Navigate to LoginScreen after a 2-second delay
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
                  (route) => false, // Remove all previous routes
                );
              });
            } else if (state is LogoutFailure) {
              // Show logout failure message
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
      child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Scaffold(
            bottomNavigationBar: bottomBarIos(),
              backgroundColor: Colors.white, // Set a white background
              appBar: AppBar(
                title: const Text("Leave Status",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                backgroundColor: const Color(0xFFFFFFFF),
                centerTitle: true,
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context)),
                actions: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu,
                          color: Colors.black, size: 22.72),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ],
              ),
              drawer: const CustomSidebar(),
              body: BlocBuilder<LeaveStatusBloc, LeaveStatusState>(
                builder: (context, state) {
                  if (state is LeaveStatusLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is LeaveStatusSuccess) {
                    if (state.fetchedLeaveData.isEmpty) {
                      return const Center(
                          child: Text("No leave records found."));
                    }
                    print('Processed leave data in LeaveStatusScreen:');
                    for (var leave in state.fetchedLeaveData) {
                      print('''
      ID: ${leave.leaveApplicationId}
      Status: ${leave.status}
      Date: ${leave.startDate}
      Total days: ${leave.totalDays}
      ''');
                    }
                    return ListView.builder(
                      itemCount: state.fetchedLeaveData.length,
                      itemBuilder: (context, index) {
                        return LeaveCard(
                          leave: state.fetchedLeaveData[index],
                          onDeleteSuccess: () {},
                        );
                      },
                    );
                  } else if (state is LeaveStatusFailure) {
                    return Center(child: Text("Failed to fetch leave data"));
                  } else {
                    // This handles the LeaveStatusInitial state before loading begins
                    return const Center(
                        child: Text("Failed to fetch leave data"));
                  }
                },
              ))),
    );
  }
}
