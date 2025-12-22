import 'package:ezhrm/Premium/profile/show_user_profile/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Authentication/User Information/user_details.dart';
import 'Authentication/User Information/user_session.dart';
import 'Authentication/model/user_model.dart';
import 'Authentication/screen/login_screen.dart';
import 'Configuration/ApiUrlConfig.dart';
import 'Contact Us/bloc/contact_us_bloc.dart';
import 'Dependency_Injection/dependency_injection.dart';
import 'Get Permissions/bloc/get_permission_bloc.dart';
import 'Tracking Location/bloc/tracking_location_bloc.dart';
import 'dashboard/location_service.dart';
import 'dashboard/screen/dashboard.dart';

class SplashScreen extends StatefulWidget {
  final UserSession userSession;
  final UserDetails userDetails;

  const SplashScreen({
    super.key,
    required this.userSession,
    required this.userDetails,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  AppUser? _appUser;
  bool _showLoader = false;
  bool _profileFetched = false;
  bool _trackingInterval = false;
  bool _permissionsFetched = false;
  bool _contactUsDataFetched = false;
  bool _hasNavigated = false;

  // Animation Controllers
  late AnimationController _circlesController;
  late AnimationController _logoController;

  // Animations
  late Animation<double> _smallCircleRadius;
  late Animation<double> _bigCircleRadius;
  late Animation<double> _logoScale;
  late Animation<double> _linesAndIconsOpacity;

  @override
  void initState() {
    super.initState();

    debugPrint('Initializing SplashScreen');
    // Controller for the expanding circles (Stages 1-3)
    _circlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Controller for the logo scaling in (Stage 4)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Define animations
    _smallCircleRadius = Tween<double>(begin: 0.0, end: 80.0).animate(
      CurvedAnimation(
        parent: _circlesController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _bigCircleRadius = Tween<double>(begin: 0.0, end: 115.0).animate(
      CurvedAnimation(
        parent: _circlesController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    //debugPrint('Starting splash sequence');
    _startSplashSequence();
  }

  void _startSplashSequence() async {
    // Stage 1-3: Circles expand
    await Future.delayed(const Duration(milliseconds: 300));
    //debugPrint('Starting circles animation');
    _circlesController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));

    // Stage 4: Logo scales in
    //debugPrint('Starting logo animation');
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 800));

    // Stage 5: Show loader and start checking session
    //debugPrint('Showing loader and checking session');
    debugPrint('Showing loader and checking session');
    if (mounted) {
      // ✅ ADD MOUNTED CHECK
      setState(() => _showLoader = true);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _checkSessionAndNavigate();
  }

  void _navigateIfReady() async {
    // ✅ FIXED: Early return if already navigated or not mounted
    if (_hasNavigated || !mounted) {
      debugPrint(
          'Navigation blocked: alreadyNavigated=$_hasNavigated, mounted=$mounted');
      return;
    }

    if (_profileFetched &&
        _permissionsFetched &&
        _contactUsDataFetched &&
        _trackingInterval &&
        _appUser != null) {
      _hasNavigated = true; // NEW: Set flag to prevent future calls
      if (!mounted) {
        debugPrint('Navigation attempted but widget not mounted');
        return;
      }
      debugPrint(
          'Both profile and permissions fetched, navigating to HomeScreen');
      debugPrint(
          'Final stored user details: ${await widget.userDetails.getUserDetails()}');
      debugPrint(
          'Final stored permissions: ${await widget.userDetails.getUserPermissions()}');
      // In the splash screen or entry point
      if (mounted) {
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
      }
    } else {
      debugPrint(
          'Navigation delayed: profileFetched=$_profileFetched, permissionsFetched=$_permissionsFetched, contactUsFetched=$_contactUsDataFetched, trackingStatusFetched=$_trackingInterval');
    }
  }

  Future<void> _checkSessionAndNavigate() async {
    debugPrint('Starting _checkSessionAndNavigate');
    final bool isValid = await widget.userSession.isSessionValid();
    debugPrint('Session valid: $isValid');
    if (!mounted) {
      debugPrint('Widget not mounted, exiting');
      return;
    }

    if (isValid) {
      final userDetails = await widget.userDetails.getUserDetails();
      final userName = userDetails['userName'] ?? '';
      final imageUrl = userDetails['imageUrl'] ?? '';
      final id = await widget.userSession.uid;
      final token = await widget.userSession.token;
      final permissions = await widget.userDetails.getUserPermissions();
      debugPrint(
          'Initial user details: userName=$userName, imageUrl=$imageUrl');
      debugPrint('Initial permissions: $permissions');
      debugPrint('Session: id=$id, token=$token');

      if (id == null || token == null) {
        debugPrint('Invalid session: id or token is null');
        return;
      }

      setState(() {
        _appUser = AppUser(
          id: id,
          token: token,
          name: userName,
          imageUrl: imageUrl,
          faceRecognition: int.tryParse(permissions[0]) ?? 0,
          gpsLocation: int.tryParse(permissions[1]) ?? 0,
          autoAttendance: int.tryParse(permissions[2]) ?? 0,
          requestAttendance: int.tryParse(permissions[3]) ?? 0,
        );
      });
      debugPrint('AppUser initialized: ${_appUser.toString()}');

      getIt<GetPermissionBloc>().add(GetPermission());
      getIt<ProfileBloc>().add(FetchProfileEvent());
      getIt<TrackingLocationBloc>().add(GetTimeInterval());
      getIt<ContactUsBloc>().add(FetchContactUs());
    } else {
      debugPrint('Session invalid, navigating to LoginScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            userSession: widget.userSession,
            userDetails: widget.userDetails,
            apiUrlConfig: getIt<ApiUrlConfig>(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    //debugPrint('Disposing SplashScreen: controllers disposed');
    _circlesController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint('Building SplashScreen UI');
    final apiUrlConfig = getIt<ApiUrlConfig>();
    return MultiBlocListener(
      listeners: [
        BlocListener<ContactUsBloc, ContactUsState>(
          listener: (context, state) async {
            if (state is ContactUsSuccess) {
              // Check if contactUsData is not empty and contains the logo
              if (state.contactUsData.isNotEmpty) {
                final companyData = state.contactUsData[0];
                final prefs = await SharedPreferences.getInstance();
                final logoPath = companyData['logo'] as String?;
                if (logoPath != null && logoPath.isNotEmpty) {
                  // Merge logo path with base URL
                  print(
                      'company logo is ${apiUrlConfig.imageBaseUrl}$logoPath');
                  prefs.setString(
                      'companyLogo', '${apiUrlConfig.imageBaseUrl}$logoPath');
                  print('Logo URL set: ${apiUrlConfig.imageBaseUrl}$logoPath');
                  setState(() {
                    _contactUsDataFetched = true;
                  });
                } else {
                  print('No logo found in company data');
                }
                _navigateIfReady();
              } else {
                print('No company data available');
              }
            }
          },
        ),
        BlocListener<GetPermissionBloc, GetPermissionState>(
          listener: (context, state) async {
            debugPrint('GetPermissionBloc state: $state');
            try {
              if (state is GetPermissionSuccess && _appUser != null) {
                final updatedUser =
                    _appUser!.copyWithPermissions(state.permissions);
                await widget.userDetails.setUserPermissions(
                  faceRecognition: updatedUser.faceRecognition.toString(),
                  gpsLocation: updatedUser.gpsLocation.toString(),
                  autoAttendance: updatedUser.autoAttendance.toString(),
                  reqAttendance: updatedUser.requestAttendance.toString(),
                );
                debugPrint(
                    'Permissions updated in local storage: ${await widget.userDetails.getUserPermissions()}');
                setState(() {
                  _appUser = updatedUser;
                  _permissionsFetched = true;
                });
                debugPrint(
                    'Updated AppUser with permissions: ${_appUser.toString()}');
                _navigateIfReady();
              }
            } catch (e) {
              debugPrint('Exception caught in the splash screen $e');
            }
            if (state is GetPermissionFailure) {
              debugPrint('Permission fetch failed, navigating to login...');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    userSession: widget.userSession,
                    userDetails: widget.userDetails,
                    apiUrlConfig: getIt<ApiUrlConfig>(),
                  ),
                ),
              );
            }
          },
        ),
        BlocListener<TrackingLocationBloc, TrackingLocationState>(
          listener: (context, state) async {
            if (state is TrackingLocationLoading) {
              debugPrint("⏳ Fetching tracking interval...");
            }
            // ✅ On Success — Save the interval to local storage
            if (state is GetTimeIntervalSuccess) {
              final double interval = state.timeInterval;
              debugPrint("✅ Tracking interval fetched: $interval minutes");

              // Save to SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('tracking_interval', interval);
              await widget.userDetails.setTimeInterval(interval);
              await widget.userDetails.setTrackingStatus(true);
              debugPrint(
                  "📦 Saved tracking interval to local storage: $interval");
            }
            if (state is GetTimeIntervalFailure) {
              debugPrint('Tracking status is disabled');

              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('tracking-status', false);
              await widget.userDetails.setTrackingStatus(false);
              await widget.userDetails.setTimeInterval(0.0);
            }
            setState(() {
              _trackingInterval = true;
            });
            _navigateIfReady();
          },
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) async {
            debugPrint('ProfileBloc state: $state');
            if (state is FetchProfileSuccess && _appUser != null) {
              final updatedUser =
                  _appUser!.copyWithProfile(state.profileData.first);
              print('Splash Screen: user name is ${updatedUser.name}');
              print('Splash Screen: image url is ${updatedUser.imageUrl}');
              await widget.userDetails.setUserDetails(
                  userName: updatedUser.name,
                  imageUrl: updatedUser.imageUrl,
                  email: updatedUser.email);
              final prefs = await SharedPreferences.getInstance();
              final profileData = state.profileData.first;
              final latestHistory =
                  profileData['latest_history'] as Map<String, dynamic>?;
              if (latestHistory != null) {
                final designation =
                    latestHistory['designation']?['designation_name'] ?? 'N/A';
                final employeeCode = profileData['employee_code'];
                prefs.setString('designation', designation);
                prefs.setString('employee_code', employeeCode);
                final shift = latestHistory['shift'] as Map<String, dynamic>?;
                if (shift != null) {
                  final startTime = shift['start_time'] as String?;
                  final endTime = shift['end_time'] as String?;
                  prefs.setString('startShiftTime', startTime!);
                  prefs.setString('endShiftTime', endTime!);
                  print('Splash screen: Shift timings from profile: '
                      'start: ${prefs.getString('startShiftTime')}, end: ${prefs.getString('endShiftTime')}');
                } else {
                  print('SplashScreen: shift is null');
                }
              } else {
                print('SplashScreen: Latest history is null');
              }
              await widget.userDetails.setUserDetails(
                  userName: updatedUser.name,
                  imageUrl: updatedUser.imageUrl,
                  email: updatedUser.email);
              debugPrint(
                  'Profile updated in local storage: ${await widget.userDetails.getUserDetails()}');
              setState(() {
                _appUser = updatedUser;
                _profileFetched = true;
              });
              debugPrint(
                  'Updated AppUser with profile: ${_appUser.toString()}');
              _navigateIfReady();
            }

            if (state is FetchProfileError) {
              debugPrint('Profile fetch failed, navigating to login...');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    userSession: widget.userSession,
                    userDetails: widget.userDetails,
                    apiUrlConfig: getIt<ApiUrlConfig>(),
                  ),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FF),
        body: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated Circles Background
              AnimatedBuilder(
                animation: _circlesController,
                builder: (context, child) {
                  //debugPrint('Building circles: smallRadius=${_smallCircleRadius.value}, bigRadius=${_bigCircleRadius.value}');
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _ConcentricCirclePainter(
                      smallRadius: _smallCircleRadius.value,
                      bigRadius: _bigCircleRadius.value,
                    ),
                  );
                },
              ),

              // Animated Logo
              ScaleTransition(
                scale: _logoScale,
                child: Image.asset(
                  'assets/images/ezhrm_splash_logo.png',
                  width: 180,
                  height: 55,
                ),
              ),

              // Loading Indicator
              if (_showLoader)
                Positioned(
                  bottom: 80,
                  child: const Column(
                    children: [
                      CircularProgressIndicator(color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Painter for the expanding concentric circles
class _ConcentricCirclePainter extends CustomPainter {
  final double smallRadius;
  final double bigRadius;

  _ConcentricCirclePainter(
      {required this.smallRadius, required this.bigRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // Inner circle
    paint.color = Colors.blue.withOpacity(0.1);
    canvas.drawCircle(center, smallRadius, paint);

    // Outer circle
    paint.color = Colors.blue.withOpacity(0.05);
    canvas.drawCircle(center, bigRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _ConcentricCirclePainter oldDelegate) {
    return oldDelegate.smallRadius != smallRadius ||
        oldDelegate.bigRadius != bigRadius;
  }
}
