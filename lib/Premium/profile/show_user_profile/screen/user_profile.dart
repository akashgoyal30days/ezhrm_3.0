import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Authentication/bloc/auth_bloc.dart';
import '../../../Authentication/screen/login_screen.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../../update_user_profile/screen/update_user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../modal/profile_model.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final userDetails = getIt<UserDetails>();

  @override
  void initState() {
    getIt<ProfileBloc>().add(FetchProfileEvent());
    super.initState();
  }

  Future<void> _updateLocalUserCache(ProfileModel userData) async {
    try {
      await userDetails.setUserDetails(
        userName: userData.name.trim(),
        email: userData.email,
        imageUrl: userData.profileImageUrl ??
            '', // Can be null → becomes empty string
        forceUpdate: true,
      );
      debugPrint('Local user cache updated with latest profile data');
    } catch (e) {
      debugPrint('Failed to update local user cache: $e');
    }
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
        child: Scaffold(
          body: BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              // Listen for success and update local cache immediately
              if (state is FetchProfileSuccess) {
                final userData = state.userData;
                _updateLocalUserCache(userData);
              }
            },
            builder: (context, state) {
              if (state is FetchProfileLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is FetchProfileSuccess) {
                return ProfileContent(userData: state.userData);
                return const Center(child: Text('Profile data is null.'));
              } else if (state is FetchProfileError) {
                return Center(child: Text('No profile found'));
              }
              return const Center(child: Text('No profile data available.'));
            },
          ),
        ),
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  final ProfileModel userData;

  ProfileContent({super.key, required this.userData});

  final apiUrlConfig = getIt<ApiUrlConfig>();

  Widget DetailCard(String imagePath, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 12),
            // Added right padding
            // --- MODIFIED HERE ---
            // Replaced the Icon with your custom image
            child: Image.asset(
              imagePath,
              width: 16,
              height: 16,
              // This makes your image take on the blue color, just like the icon.
              // Remove this line if your images are multi-colored.
              color: const Color(0xFF268AE4),
            ),
          ),
          // Removed the SizedBox
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    // //fontFamily: "Poppins",
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value, // Changed from phoneNumber to a generic 'value'
                  style: const TextStyle(
                    //fontFamily: "Poppins",
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(color: Colors.grey, thickness: 1),
                // spacing above and below
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to show the full-size image in a dialog
  void _showFullImage(BuildContext context, ImageProvider imageProvider) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Full-size image
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 50),
                      );
                    },
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // String profile_image='${ApiUrlConfig().imageBaseUrl}/${userData.profileImageUrl}'
    String? profileImageUrl = userData.profileImageUrl;
    String profileImage = (profileImageUrl ?? '').isNotEmpty
        ? '${apiUrlConfig.imageBaseUrl}$profileImageUrl'
        : '';

    final ImageProvider imageProvider = profileImage.isNotEmpty
        ? NetworkImage(profileImage)
        : const AssetImage('assets/images/user.png') as ImageProvider;
    final screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          SizedBox(
            child: Container(
              height: screenHeight * 0.25,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF154C7E), Color(0xFF3A96E9)],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: 18,
                    top: 23, // adjust vertical alignment
                    child: Material(
                      type: MaterialType
                          .transparency, // Makes the ripple effect visible
                      child: InkWell(
                        onTap: () {
                          debugPrint("Edit button clicked");
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  UpdateUserProfileScreen(userData: userData),
                            ),
                          );
                        },
                        borderRadius:
                            BorderRadius.circular(15), // Half of container size
                        splashColor: Color(0xFF268AE4)
                            .withOpacity(0.2), // Matching ripple color
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Color(0xFF268AE4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _showFullImage(context, imageProvider),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: imageProvider,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData.designation,
                                style: const TextStyle(
                                  //fontFamily: "Poppins",
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(userData.name,
                                  style: const TextStyle(
                                      //fontFamily: "Poppins",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Image.asset(
                                      'assets/images/mail.png',
                                      width: 18,
                                      height: 18,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.error,
                                            color: Colors.red);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      userData.email,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ).copyWith(
                                        color: Colors.white.withOpacity(
                                            0.6), // 👈 0.0 = fully transparent, 1.0 = fully visible
                                      ),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          DetailCard("assets/images/time.png", "Office Timing",
              "${userData.start_time} - ${userData.end_time}"),
          DetailCard(
              "assets/images/employee.png", "Employee ID", userData.employeeId),
          DetailCard(
              "assets/images/call.png", "Phone Number", userData.phone_number),
          DetailCard("assets/images/reporting.png", "Reporting To",
              userData.reporting_to),
          DetailCard("assets/images/calender.png", "Date of Joining",
              userData.joinDate),
          DetailCard(
              "assets/images/calender.png", "Date of Birth", userData.dob),
        ],
      ),
    );
  }
}
