import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:ezhrm/Premium/reimbursement/screen/reinbursement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Authentication/bloc/auth_bloc.dart';
import '../../Authentication/screen/login_screen.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import '../../SessionHandling/session_bloc.dart';
import '../../SideMenuBar/screen/sidebar.dart';
import '../../dashboard/location_service.dart';
import '../../dashboard/screen/dashboard.dart';
import '../bloc/reimbursement_bloc.dart';

class ReimbursementHistoryScreen extends StatefulWidget {
  const ReimbursementHistoryScreen({super.key});

  @override
  State<ReimbursementHistoryScreen> createState() =>
      _ReimbursementHistoryScreenState();
}

class _ReimbursementHistoryScreenState
    extends State<ReimbursementHistoryScreen> {
  @override
  void initState() {
    super.initState();
    getIt<ReimbursementBloc>().add(GetReimbursment());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
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
      child: MultiBlocListener(
          listeners: [
            BlocListener<SessionBloc, SessionState>(
              listener: (context, state) {
                if (state is SessionExpiredState ||
                    state is UserNotFoundState) {
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
          child: Scaffold(
            backgroundColor: Colors.white,
            bottomNavigationBar: bottomBarIos(),
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text(
                'Reimbursement History',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    color: Colors.black,
                    onPressed: () {
                      Scaffold.of(context).openDrawer(); // Safe call
                    },
                  ),
                ),
              ],
            ),
            drawer: const CustomSidebar(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplyReimbursementScreen(
                      userDetails: getIt<UserDetails>(),
                      userSession: getIt<UserSession>(),
                    ),
                  ),
                );
              },
              backgroundColor: const Color(0xFF1976D2),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            body: BlocBuilder<ReimbursementBloc, ReimbursementState>(
              builder: (context, state) {
                if (state is ReimbursementLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is GetReimbursementSuccess) {
                  if (state.reimbursmentHistory.isEmpty) {
                    return const Center(
                      child: Text(
                        'No reimbursement history available',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: state.reimbursmentHistory.length,
                    itemBuilder: (context, index) {
                      final item = state.reimbursmentHistory[index];
                      String expenseAgainst =
                          item['expense_against_type'] ?? 'Unknown';
                      if (item['client_name'] != null) {
                        expenseAgainst += ' (${item['client_name']})';
                      }
                      String status = item['status'] ?? 'Unknown';
                      bool isApproved = status.toLowerCase() == 'approved';
                      Color statusBgColor = isApproved
                          ? const Color(0xFFCCEAD9)
                          : const Color(0xFFFFDBDA);
                      Color statusTextColor = isApproved
                          ? const Color(0xFF0F8248)
                          : const Color(0xFFD76E71);
                      String description = item['description'] ?? '';
                      String amount = item['expense_amount']?.toString() ?? '0';
                      String date = item['date'] ?? '';
                      String createdAt = item['created_at'] ??
                          DateTime.now().toIso8601String();
                      DateTime createdDate;
                      try {
                        createdDate = DateTime.parse(createdAt);
                      } catch (e) {
                        createdDate = DateTime.now();
                      }
                      int daysPassed =
                          DateTime.now().difference(createdDate).inDays.abs();
                      String daysStr =
                          daysPassed == 1 ? '1 day' : '$daysPassed days';

                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              16.0), // Matches existing card theme
                          side: const BorderSide(
                            color: Color(0xFFC5C6CC), // Border color
                            width: 1.0, // Border width
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    expenseAgainst,
                                    style: const TextStyle(
                                      color: Color(0xFF0F3E6B),
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 6.0),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Text(
                                      status,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: statusTextColor,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                '$daysStr • $date',
                                style: const TextStyle(
                                    color: Color(0xFF8F9098),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 12.0),
                              const Text(
                                'Description:',
                                style: TextStyle(
                                    color: Color(0xFF8F9098),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                description,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF0F3E6B),
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 12.0),
                              const Divider(
                                color: Color(
                                    0xFFC5C6CC), // Matches card border color
                                thickness: 2.0, // Divider width
                              ),
                              const SizedBox(
                                  height: 8.0), // Spacing after divider
                              Text(
                                amount,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD76E71),
                                    fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is GetReimbursementFailure) {
                  return Center(
                    child: Text(
                      state.errorMessage,
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  );
                } else {
                  return const Center(
                    child: Text(
                      'Failed to load reimbursement history',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  );
                }
              },
            ),
          )),
    );
  }
}
