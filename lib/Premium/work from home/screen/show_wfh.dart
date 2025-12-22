import 'package:ezhrm/Premium/work%20from%20home/screen/work_from_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date formatting
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
import '../bloc/work_from_home_bloc.dart';

class WorkFromHomeScreen extends StatelessWidget {
  const WorkFromHomeScreen({super.key});

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
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text(
                'Work from home history',
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
                    builder: (context) => RequestWorkFromHomeScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF1976D2),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            body: RefreshIndicator(
              onRefresh: () async {
                // Trigger the GetWorkFromHome event to refresh data
                getIt<WorkFromHomeBloc>().add(GetWorkFromHome());
                // Wait for the state to update
                await Future.delayed(const Duration(seconds: 1));
              },
              child: BlocBuilder<WorkFromHomeBloc, WorkFromHomeState>(
                builder: (context, state) {
                  if (state is RequestWorkFromHomeLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is GetWorkFromHomeSuccess) {
                    final wfhData = state.response;

                    if (wfhData.isEmpty) {
                      return const Center(
                        child: Text('No work-from-home requests found.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: wfhData.length,
                      itemBuilder: (context, index) {
                        final wfh = wfhData[index];
                        return _buildWfhCard(wfh);
                      },
                    );
                  } else if (state is GetWorkFromHomeFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${state.errorMessage}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              getIt<WorkFromHomeBloc>().add(GetWorkFromHome());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Initial state or other states
                    // Trigger fetching data when the screen loads
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      getIt<WorkFromHomeBloc>().add(GetWorkFromHome());
                    });
                    return const Center(
                        child: Text('Pull to fetch work-from-home requests.'));
                  }
                },
              ),
            ),
          )),
    );
  }

  // Helper method to build a card for each work-from-home request
  Widget _buildWfhCard(Map<String, dynamic> wfh) {
    // Format dates if they exist
    final startDate = wfh['start_date'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(wfh['start_date']))
        : 'N/A';
    final endDate = wfh['end_date'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(wfh['end_date']))
        : 'N/A';
    final reason = wfh['reason'] ?? 'No reason provided';

    String status = wfh['status'] ?? 'Pending';
    bool isApproved = status.toLowerCase() == 'approved';
    Color statusBgColor =
        isApproved ? const Color(0xFFCCEAD9) : const Color(0xFFFFDBDA);
    Color statusTextColor =
        isApproved ? const Color(0xFF0F8248) : const Color(0xFFD76E71);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16.0), // Matches existing card theme
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$startDate - $endDate',
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
            const SizedBox(height: 8),
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
              reason,
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
  }
}
