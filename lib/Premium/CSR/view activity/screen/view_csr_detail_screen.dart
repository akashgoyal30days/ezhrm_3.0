import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Authentication/bloc/auth_bloc.dart';
import '../../../Authentication/screen/login_screen.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../../SideMenuBar/screen/sidebar.dart';

class CSRDetailScreen extends StatelessWidget {
  final String userName;
  final String imageUrl; // This is the main large image
  final String description;
  final String date;
  final String image; // This is the user's avatar image

  const CSRDetailScreen({
    super.key,
    required this.userName,
    required this.imageUrl,
    required this.description,
    required this.date,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    // Listeners for session and auth state remain the same
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
        backgroundColor: Colors.white,
        drawer: const CustomSidebar(),
        // ✅ **RESPONSIVE FIX**: Using CustomScrollView to make the entire page scrollable.
        body: CustomScrollView(
          slivers: [
            // ✅ **RESPONSIVE FIX**: SliverAppBar creates a collapsing header for the image.
            SliverAppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              backgroundColor: Colors.white,
              // Makes the app bar float over the content
              floating: false,
              // Keeps the app bar visible at the top when scrolling up
              pinned: true,
              // Allows the image to stretch when over-scrolled
              stretch: true,
              // Set a responsive height for the expanded app bar (e.g., 40% of screen height)
              expandedHeight: MediaQuery.of(context).size.height * 0.4,
              // Use an automatic back button
              automaticallyImplyLeading: false,
              iconTheme: const IconThemeData(
                  color: Colors.black), // Style for back button
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
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/document.png', // Fallback image
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // ✅ **RESPONSIVE FIX**: SliverToBoxAdapter holds the rest of the content.
            SliverToBoxAdapter(
              child: Container(
                // This decoration creates the "sheet" effect from your original design
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User + Date Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20, // Slightly larger for better visibility
                            backgroundImage: image.isNotEmpty
                                ? NetworkImage(image)
                                : const AssetImage('assets/images/user.png')
                                    as ImageProvider,
                            // Added error handling for the user avatar
                            onBackgroundImageError: (_, __) {},
                            backgroundColor: Colors.grey.shade200,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              userName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd-MM-yyyy')
                                .format(DateTime.parse(date)),
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    // A visual separator
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // Description section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5, // Line spacing
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
