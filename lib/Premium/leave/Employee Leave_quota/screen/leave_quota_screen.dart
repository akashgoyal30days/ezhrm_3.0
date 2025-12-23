import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../bloc/leave_quota_bloc.dart';
import 'circular_leave_balance.dart';

class LeaveQuotaScreen extends StatefulWidget {
  const LeaveQuotaScreen({super.key});

  @override
  State<LeaveQuotaScreen> createState() => _LeaveQuotaScreenState();
}

class _LeaveQuotaScreenState extends State<LeaveQuotaScreen> {
  @override
  void initState() {
    super.initState();
    getIt<LeaveQuotaBloc>().add(FetchEmployeeLeaveQuota());
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
      child: Scaffold(
        bottomNavigationBar: bottomBarIos(),
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
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
          title: const Text('Leave Quota',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
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
        body: BlocBuilder<LeaveQuotaBloc, LeaveQuotaState>(
          builder: (context, state) {
            if (state is LeaveQuotaLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is LeaveQuotaSuccess) {
              final leaveList = state.employeeLeaveQuota;

              num total = 0;
              num used = 0;
              num lapsed = 0;

              for (var item in leaveList) {
                total += double.tryParse(
                        item['available_quota']?.toString() ?? '0') ??
                    0;
                print('total available leaves are $total');

                used +=
                    double.tryParse(item['under_process']?.toString() ?? '0') ??
                        0;
                print('total under process are $used');

                lapsed +=
                    double.tryParse(item['lapsed_quota']?.toString() ?? '0') ??
                        0;
              }

              num totalBalance = (total + used);
              print('total leave are $totalBalance');
              print('available leaves are $total');

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    CircularLeaveBalance(balance: total, total: totalBalance),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text('$totalBalance',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Total Leaves',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('$used',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Used Leaves',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('$lapsed',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('lapsed Leaves',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              );
            }

            if (state is LeaveQuotaNoData) {
              return const Center(child: Text("No leave quota assigned."));
            }

            if (state is LeaveQuotaFailure) {
              return Center(
                  child: Text(state.errorMessage,
                      style: const TextStyle(color: Colors.red)));
            }

            return const Center(child: Text("No data available."));
          },
        ),
      ),
    );
  }

  Color _generateColorFromText(String text) {
    final hash = text.codeUnits.fold(0, (prev, curr) => prev + curr);
    final colors = [
      Colors.green,
      Colors.cyan,
      Colors.pinkAccent,
      Colors.amber,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.blueGrey
    ];
    return colors[hash % colors.length];
  }
}

class LeaveBar extends StatelessWidget {
  final String title;
  final int used;
  final int total;
  final Color color;

  const LeaveBar({
    super.key,
    required this.title,
    required this.used,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double percent = total == 0 ? 0 : used / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('$used/$total',
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
