import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:ezhrm/Premium/Policy/screen/policy_card.dart';
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
import '../bloc/policy_bloc.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> {
  final apiUrlConfig = getIt<ApiUrlConfig>();
  @override
  void initState() {
    super.initState();
    getIt<PolicyBloc>().add(GetCompanyPolicy());
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
      child: BlocBuilder<PolicyBloc, PolicyState>(
          bloc: getIt<PolicyBloc>(),
          builder: (context, state) {
            // 👇 Add this block for loading state
            if (state is GetCompanyPolicyLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (state is GetCompanyPolicySuccess) {
              for (var policy in state.policyList) {
                debugPrint(
                    'Name: ${policy.name}, Description: ${policy.description}, File: ${policy.file}');
              }
              final list = state.policyList;

              return Container(
                  color: Colors.white,
                  // padding: EdgeInsets.only(top: 30.0),
                  child: Scaffold(
                    bottomNavigationBar: bottomBarIos(),
                    appBar: AppBar(
                      title: const Text(
                        "Policies",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      centerTitle: true,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
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
                    body: list.isEmpty
                        ? Center(
                            child: Text(
                              "Policy List is Empty",
                            ),
                          )
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final policy = list[index];
                              final String imageUrl =
                                  "${apiUrlConfig.baseUrl}/${policy.file}";

                              return PoliciesCard(
                                  name: policy.name,
                                  description: policy.description,
                                  file: imageUrl);
                            },
                          ),
                  ));
            }

            // 👇 Add this block for error state
            else if (state is GetCompanyPolicyFailure) {
              return Scaffold(
                body: Center(
                  child: Text(
                    "No Policies Found.",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            // 👇 Default fallback
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }),
    );
  }
}
