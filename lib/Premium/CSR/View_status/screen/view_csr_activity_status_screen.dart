import 'package:ezhrm/Premium/CSR/View_status/screen/view_csr_activity_status_detail_screen.dart';
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
import '../bloc/view_activity_status_bloc.dart';
import '../modal/CSR_Activity_status.dart';
import 'csr_activity_status_card.dart';

class ViewCsrActivityStatusScreen extends StatefulWidget {
  const ViewCsrActivityStatusScreen({super.key});

  @override
  State<ViewCsrActivityStatusScreen> createState() =>
      _ViewCsrActivityStatusScreenState();
}

class _ViewCsrActivityStatusScreenState
    extends State<ViewCsrActivityStatusScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger data load after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ViewActivityStatusBloc>().add(ViewActivityStatus());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state is SessionExpiredState || state is UserNotFoundState) {
              _handleSessionExpired(context);
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              _handleLogoutSuccess(context);
            } else if (state is LogoutFailure) {
              _handleLogoutFailure(context);
            }
          },
        ),
      ],
      child: Scaffold(
        bottomNavigationBar: bottomBarIos(),
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black),
            onPressed: () => _navigateToHomeScreen(context),
          ),
          title: const Text(
            "View My CSR Activities",
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
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ),
        drawer: const CustomSidebar(),
        body: BlocBuilder<ViewActivityStatusBloc, ViewActivityStatusState>(
          builder: (context, state) {
            if (state is ViewActivityStatusInitial ||
                state is ViewActivityStatusLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is ViewActivityStatusError) {
              return Center(
                child: Text(
                  state.errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (state is ViewActivityStatusLoaded) {
              return _buildActivityGrid(state.activityStatus);
            }
            return const Center(
              child: Text('Unexpected state encountered'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivityGrid(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return const Center(
        child: Text(
          "No CSR activities found",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return MasonryGridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final employee = activity['employee'] as Map<String, dynamic>? ?? {};

        return CsrActivityStatusCard(
          userName:
              '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
                  .trim(),
          imagePath: activity['activity']?.toString() ?? '',
          status: (activity['status']?.toString().toLowerCase() ?? 'pending'),
          profileImage: employee['image_path']?.toString() ?? '',
          onTap: () => _navigateToDetailScreen(context, activity, employee),
        );
      },
    );
  }

  String _getUserName(Map<String, dynamic> employee) {
    final firstName = employee['first_name']?.toString() ?? 'Unknown';
    final lastName = employee['last_name']?.toString() ?? '';
    return '$firstName $lastName'.trim();
  }

  void _navigateToDetailScreen(
    BuildContext context,
    Map<String, dynamic> activity,
    Map<String, dynamic> employee,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CSRStatusDetailScreen(
          activity: Activity.fromJson(activity),
          employee: Employee.fromJson(employee),
        ),
      ),
    );
  }

  void _navigateToHomeScreen(BuildContext context) {
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
      (route) => false, // This predicate removes all previous routes
    );
  }

  void _handleSessionExpired(BuildContext context) {
    getIt<UserSession>().clearUserCredentials();
    getIt<UserDetails>().clearUserDetails();

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
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

  void _handleLogoutSuccess(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
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

  void _handleLogoutFailure(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Error logging out.'),
          backgroundColor: Colors.red,
        ),
      );
  }
}
