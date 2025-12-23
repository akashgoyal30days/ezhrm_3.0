import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../SideMenuBar/screen/sidebar.dart';
import '../../dashboard/location_service.dart';
import '../../dashboard/screen/dashboard.dart';
import '../bloc/advance_salary_bloc.dart';
import '../modal/advance_salary_card_modal.dart';
import 'advance_Salary_Card.dart';
import 'apply_advance_salary.dart';

import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';
import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/bloc/auth_bloc.dart';
import '../../Authentication/screen/login_screen.dart';
import '../../Dependency_Injection/dependency_injection.dart';

class AdvanceSalaryScreen extends StatefulWidget {
  const AdvanceSalaryScreen({super.key});

  @override
  State<AdvanceSalaryScreen> createState() => _AdvanceSalaryScreenState();
}

class _AdvanceSalaryScreenState extends State<AdvanceSalaryScreen> {
  @override
  void initState() {
    super.initState();
    // It's safer to add the event after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdvanceSalaryBloc>().add(GetAdvanceSalary());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
      ],
      child: WillPopScope(
        onWillPop: () async {
          // ✅ Navigate back to Dashboard when back button is pressed
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
          return false; // Prevent default back navigation
        },
        child: Scaffold(
          bottomNavigationBar: bottomBarIos(),
          appBar: AppBar(
            title: const Text(
              "Advance Salary History",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.white,
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
                  icon: const Icon(Icons.menu, color: Colors.black, size: 22.72),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ],
          ),
          drawer: const CustomSidebar(),
          body: Stack(
            children: [
              /// Main List Body
              BlocBuilder<AdvanceSalaryBloc, AdvanceSalaryState>(
                builder: (context, state) {
                  if (state is AdvanceSalaryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is GetAdvanceSalarySuccess) {
                    // ✅ **THIS IS THE NEW LOGIC**
                    // Check if the list of salaries is empty
                    if (state.advanceSalary.isEmpty) {
                      return const Center(
                        child: Text(
                          'No Advance Salary History Found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    // If the list is not empty, show the ListView
                    return ListView.builder(
                      padding: const EdgeInsets.only(
                          bottom: 80), // leave space for button
                      itemCount: state.advanceSalary.length,
                      itemBuilder: (context, index) {
                        final item = state.advanceSalary[index];
                        return AdvanceSalaryCard(
                          salary: AdvanceSalaryCardModal.fromJson(item),
                        );
                      },
                    );
                  } else if (state is AdvanceSalaryFailure) {
                    // Handle the error state
                    return Center(
                      child: Text(
                        state.errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }
                  // For initial state, show an empty container
                  return const SizedBox.shrink();
                },
              ),

              /// Fixed Positioned Button
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ApplyAdvanceSalary()),
                      );
                    },
                    child: const Text(
                      "Apply New",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
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
