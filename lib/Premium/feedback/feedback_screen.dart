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

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selectedEmojiIndex = -1;
  final List<String> _issues = [
    'App Crashed & Freezing',
    'Poor Photo Quality',
    'GPS Tracking Issues',
    'Slow Performance',
    'Other',
  ];
  final Set<String> _selectedIssues = {'Other'};
  bool _needQuickSupport = true;
  final TextEditingController _commentController = TextEditingController();

  final List<String> emojiList = ['🥶', '😠', '😐', '😄', '😍'];

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
        appBar: AppBar(
          title: const Text('Feedback', style: TextStyle(color: Colors.black)),
          centerTitle: true,
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
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share your feedback',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Rate your experience',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(emojiList.length, (index) {
                    final isSelected = _selectedEmojiIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmojiIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Text(emojiList[index],
                            style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 15),
                const Text('Select the issues you’ve experienced',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                ..._issues.map((issue) {
                  final isChecked = _selectedIssues.contains(issue);
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isChecked ? Colors.blue : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(issue,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                      value: isChecked,
                      activeColor: Colors.blue,
                      onChanged: (_) {
                        setState(() {
                          if (isChecked) {
                            _selectedIssues.remove(issue);
                          } else {
                            _selectedIssues.add(issue);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Comment',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Checkbox(
                          value: _needQuickSupport,
                          activeColor: Colors.blue,
                          onChanged: (value) {
                            setState(() {
                              _needQuickSupport = value ?? false;
                            });
                          },
                        ),
                        const Text('Need Quick Support'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe your experience here',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    // Submit logic
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Feedback submitted successfully')));
                    _commentController.clear();
                    setState(() {
                      _selectedIssues.clear();
                      _selectedIssues.add("Other");
                      _needQuickSupport = true;
                      _selectedEmojiIndex = 4;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
                      ),
                    ),
                    child: const Center(
                      child: Text('Submit',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
