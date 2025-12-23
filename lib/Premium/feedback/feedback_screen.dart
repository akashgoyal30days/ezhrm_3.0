import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Authentication/User Information/user_details.dart';
import '../Authentication/User Information/user_session.dart';
import '../Authentication/bloc/auth_bloc.dart';
import '../Authentication/screen/login_screen.dart';
import '../Configuration/ApiUrlConfig.dart';
import '../Dependency_Injection/dependency_injection.dart';
import '../SessionHandling/session_bloc.dart';
import '../SideMenuBar/screen/sidebar.dart';
import '../dashboard/location_service.dart';
import '../dashboard/screen/dashboard.dart';
import 'bloc/feedback_bloc.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FeedbackBloc>(),
      child: MultiBlocListener(
        listeners: [
          BlocListener<SessionBloc, SessionState>(
            listener: (context, state) {
              if (state is SessionExpiredState || state is UserNotFoundState) {
                getIt<UserSession>().clearUserCredentials();
                getIt<UserDetails>().clearUserDetails();

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
        ],
        child: Scaffold(
          bottomNavigationBar: bottomBarIos(),
          appBar: AppBar(
            title: const Text('Feedback', style: TextStyle(color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
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
                    ),
                  ),
                      (route) => false,
                );
              },
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ],
          ),
          drawer: const CustomSidebar(),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share your feedback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // TextField with max 3 lines
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  minLines: 3, // Ensures it starts with 3 visible lines
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Describe your experience or issue here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 20),

                // Submit Button directly below the text field
                BlocConsumer<FeedbackBloc, FeedbackState>(
                  listener: (context, state) {
                    if (state is FeedbackSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Feedback submitted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _commentController.clear();
                    } else if (state is FeedbackError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    _isSubmitting = state is FeedbackLoading;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                          final feedbackText = _commentController.text.trim();
                          if (feedbackText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please write your feedback before submitting.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          context.read<FeedbackBloc>().add(
                            FeedbackActivity(feedback_text: feedbackText),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF2196F3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Optional extra space at bottom for better scrolling on small screens
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}