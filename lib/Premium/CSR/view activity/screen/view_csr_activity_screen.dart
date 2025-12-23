import 'package:ezhrm/Premium/CSR/view%20activity/screen/view_csr_detail_screen.dart';
import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
import '../bloc/view_csr_activity_bloc.dart';
import 'csr_activity_card.dart';

class ViewCsrActivityScreen extends StatelessWidget {
  const ViewCsrActivityScreen({super.key});

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
      child: Scaffold(
        bottomNavigationBar: bottomBarIos(),
        appBar: AppBar(
          // or any CSR theme color
          // elevation: 4,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.black),
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
          title: const Text(
            "View CSR Activities",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: Colors.black,
            ),
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
        body: BlocBuilder<ViewCsrActivityBloc, ViewCsrActivityState>(
          builder: (context, state) {
            if (state is ViewCsrActivityLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ViewCsrActivityError) {
              return Center(child: Text("Error: ${state.error}"));
            } else if (state is ViewCsrActivitySuccess) {
              final activities = state.csrActivityData.where((activity) {
                final status =
                    (activity['status'] ?? '').toString().toLowerCase();
                return status != 'pending' && status != 'rejected';
              }).toList();

              if (activities.isEmpty) {
                return const Center(child: Text("No CSR Activities Found"));
              }

              return MasonryGridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  final employee = activity['employee'] ?? {};

                  final userName =
                      '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}';
                  final imagePath = activity['activity'] ?? '';
                  final description =
                      activity['description'] ?? 'No description';
                  final date = activity['created_at'] ?? 'Unknown date';
                  final image = employee['image_path'] ?? '';

                  final imageUrl = Uri.parse(ApiUrlConfig()
                          .csrimageBaseUrl) // change from base url to CSR image base url
                      .resolve(imagePath)
                      .toString();
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CSRDetailScreen(
                            userName: userName,
                            imageUrl: imageUrl,
                            description: description,
                            date: date,
                            image: image,
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      height: index.isEven ? 220 : 150, // alternate heights
                      child: CsrActivityCard(
                        userName: userName,
                        imagePath: imagePath,
                        colorHex: activity['color'] ?? '0xFF0062B1',
                        image: image,
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
