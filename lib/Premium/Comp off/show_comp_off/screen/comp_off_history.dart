import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../../add comp off/screen/add_comp_off.dart';
import '../bloc/show_comp_off_bloc.dart';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Authentication/bloc/auth_bloc.dart';
import '../../../Authentication/screen/login_screen.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../../SideMenuBar/screen/sidebar.dart';

class CompOffHistoryScreen extends StatefulWidget {
  const CompOffHistoryScreen({super.key});

  @override
  State<CompOffHistoryScreen> createState() => _CompOffHistoryScreenState();
}

class _CompOffHistoryScreenState extends State<CompOffHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger the ShowCompOff event to fetch comp-off history
    getIt<ShowCompOffBloc>().add(ShowCompOff());
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
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Comp Off History',
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
        drawer:
            const CustomSidebar(), // Assuming CustomSideBar is a widget for the drawer
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompOffScreen(),
              ),
            );
          },
          backgroundColor: const Color(0xFF1976D2),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: MultiBlocListener(
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
          child: BlocBuilder<ShowCompOffBloc, ShowCompOffState>(
            builder: (context, state) {
              if (state is ShowCompOffLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ShowCompOffError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${state.errorMessage}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          getIt<ShowCompOffBloc>().add(ShowCompOff());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (state is ShowCompOffSuccess) {
                if (state.compOffHistory.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comp-off records found.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.compOffHistory.length,
                  itemBuilder: (context, index) {
                    final compOff = state.compOffHistory[index];
                    String status = compOff['status'] ?? 'Unknown';
                    bool isApproved = status.toLowerCase() == 'approved';
                    String date = compOff['earned_date'] ?? '';
                    Color statusBgColor = isApproved
                        ? const Color(0xFFCCEAD9)
                        : const Color(0xFFFFDBDA);
                    Color statusTextColor = isApproved
                        ? const Color(0xFF0F8248)
                        : const Color(0xFFD76E71);
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            16.0), // Matches existing card theme
                        side: const BorderSide(
                          color: Color(0xFFC5C6CC), // Border color
                          width: 1.0, // Border width
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  compOff['earned_type']?.toString() ?? 'N/A',
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
                              date,
                              style: const TextStyle(
                                  color: Color(0xFF8F9098),
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 12),
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
                              compOff['remarks']?.toString() ??
                                  'No description available',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF0F3E6B),
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(
                child: Text(
                  'Please wait...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
