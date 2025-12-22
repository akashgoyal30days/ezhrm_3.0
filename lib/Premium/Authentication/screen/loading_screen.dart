import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import '../../dashboard/location_service.dart';
import '../../dashboard/screen/dashboard.dart';
import '../User Information/user_details.dart';
import '../User Information/user_session.dart';
import '../model/user_model.dart';
import 'login_screen.dart';

class InvalidTokenException implements Exception {
  final String message;
  InvalidTokenException(this.message);
}

class LoadingScreen extends StatefulWidget {
  final UserSession userSession;
  final UserDetails userDetails;
  final ApiUrlConfig apiUrlConfig;
  final String userId;

  const LoadingScreen({
    super.key,
    required this.userSession,
    required this.userDetails,
    required this.apiUrlConfig,
    required this.userId,
  });

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _isLoading = true; // Track loading state
  bool _hasServerError = false; // Track if a 500 error occurred

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<Map<String, dynamic>?> _getApiCall(String endPoint, String id) async {
    try {
      final token = await widget.userSession.token;
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      late final Uri url;
      print('LoadingScreen: endpoint is $endPoint');
      if (endPoint == 'api/company-info/') {
        url = Uri.parse('${widget.apiUrlConfig.baseUrl}$endPoint');
      } else {
        url = Uri.parse('${widget.apiUrlConfig.baseUrl}$endPoint$id');
      }
      print('Loading Screen: url is $url');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        print('LoadingScreen: API response  is 200 for $endPoint');
        return jsonDecode(response.body);
      } else {
        // Parse response body to check for invalid token message
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>?;
        if (responseBody != null &&
            responseBody['message'] == 'Invalid token, please login again') {
          print(
              'LoadingScreen: Invalid token detected for $endPoint: ${response.body}');
          throw InvalidTokenException('Invalid token, please login again');
        }
        if (response.statusCode == 500) {
          print(
              'LoadingScreen: Server error (500) for $endPoint: ${response.body}');
          throw http.ClientException(
              'Server error (500)', url); // Throw for 500
        } else if (response.statusCode == 400 || response.statusCode == 401) {
          print(
              'LoadingScreen: Authentication error (${response.statusCode}) for $endPoint: ${response.body}');
          throw http.ClientException(
              'Authentication error (${response.statusCode})',
              url); // Throw for 400/401
        } else {
          print(
              'LoadingScreen: API response is ${response.statusCode} for $endPoint: ${response.body}');
          throw http.ClientException(
              'Unexpected error (${response.statusCode})',
              url); // Throw for other errors
        }
      }
    } catch (e) {
      print('LoadingScreen: Error in getting API call for $endPoint: $e');
      rethrow; // Propagate all errors
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _hasServerError = false;
    });

    try {
      final profileEndpoint = widget.apiUrlConfig.getEmployeeDetails;
      final permissionEndpoint = widget.apiUrlConfig.getPermissions;
      final contactUsEndpoint = widget.apiUrlConfig.getCompanyInfoPath;
      final getTrackingStatusEndpoint = widget.apiUrlConfig.getTimeInterval;
      final id = widget.userId;
      final prefs = await SharedPreferences.getInstance();

      print(
          'LoadingScreen: Fetching profile, permission and contact us data for ID: $id');
      final [profileData, permissionData, contactUsData, trakingStatus] =
          await Future.wait([
        _getApiCall(profileEndpoint, id),
        _getApiCall(permissionEndpoint, id),
        _getApiCall(contactUsEndpoint, id),
        _getApiCall(getTrackingStatusEndpoint, id),
      ]);

      // Log raw API response
      debugPrint('LoadingScreen: Raw profile data: $profileData');
      debugPrint('LoadingScreen: Raw permission data: $permissionData');
      debugPrint('LoadingScreen: Raw contact us data: $contactUsData');
      debugPrint('LoadingScreen: Raw tracking status data: $trakingStatus');

      AppUser appUser =
          AppUser(id: id, token: await widget.userSession.token ?? '');

      // Process profile data
      if (profileData != null) {
        final profileJson =
            (profileData.containsKey('data') && profileData['data'] is Map)
                ? profileData['data']
                : profileData;
        final latestHistory =
            profileJson['latest_history'] as Map<String, dynamic>?;
        if (latestHistory != null) {
          final designation =
              latestHistory['designation']?['designation_name'] ?? 'N/A';
          final employeeCode = profileJson['employee_code'] ?? 'N/A';
          prefs.setString('designation', designation);
          prefs.setString('employee_code', employeeCode);
          print(
              'LoadingScreen: User Designation and Employee code is $designation and $employeeCode');
        } else {
          print('No designation and employee code found');
        }
        final joiningDate = profileJson['joining_date'] ?? '';
        await prefs.setString('joiningDate', joiningDate);

        appUser = appUser.copyWithProfile(profileJson);
        try {
          await widget.userDetails.setUserDetails(
              userName: appUser.name,
              imageUrl: appUser.imageUrl,
              email: appUser.email);
          print(
              'LoadingScreen: Profile data stored locally, name=${appUser.name}, imageUrl=${appUser.imageUrl}');
        } catch (e) {
          print(
              'LoadingScreen: Error saving profile data to local storage: $e');
        }
      } else {
        print('LoadingScreen: Profile data fetch failed, using defaults');
      }

      // Process permission data
      if (permissionData != null) {
        dynamic permissionJson = permissionData;
        if (permissionData.containsKey('data') &&
            permissionData['data'] is List &&
            permissionData['data'].isNotEmpty) {
          permissionJson = permissionData['data'][0];
        } else if (permissionData.containsKey('data') &&
            permissionData['data'] is Map) {
          permissionJson = permissionData['data'];
        }
        appUser = appUser.copyWithPermissions(permissionJson);
        try {
          await widget.userDetails.setUserPermissions(
            faceRecognition: appUser.faceRecognition.toString(),
            gpsLocation: appUser.gpsLocation.toString(),
            autoAttendance: appUser.autoAttendance.toString(),
            reqAttendance: appUser.requestAttendance.toString(),
          );
          final permissionDetails =
              await widget.userDetails.getUserPermissions();
          print(
              'LoadingScreen: Permissions stored locally, faceRecognition=${permissionDetails[0]}, '
              'gpsLocation=${permissionDetails[1]}, autoAttendance=${permissionDetails[2]}, reqAttendance=${permissionDetails[3]}');
        } catch (e) {
          print(
              'LoadingScreen: Error saving permission data to local storage: $e');
        }
      } else {
        print('LoadingScreen: Permission data fetch failed, using defaults');
      }

      if (contactUsData != null) {
        final prefs = await SharedPreferences.getInstance();
        final logoPath = contactUsData['company']?['logo'] as String?;
        if (logoPath != null && logoPath.isNotEmpty) {
          // Merge logo path with base URL
          print('company logo is ${widget.apiUrlConfig.imageBaseUrl}$logoPath');
          prefs.setString(
              'companyLogo', '${widget.apiUrlConfig.imageBaseUrl}$logoPath');
          print('Logo URL set: ${widget.apiUrlConfig.imageBaseUrl}$logoPath');
        } else {
          print('No logo found in company data');
        }
      }

      if (trakingStatus != null) {
        // ✅ Ensure API response is not null and contains valid data
        final dataList = trakingStatus['data'];
        if (dataList != null && dataList is List && dataList.isNotEmpty) {
          final firstItem = dataList.first;

          // ✅ Extract tracking status and interval
          final status = firstItem['status'];
          final trackingInterval = firstItem['tracking_interval'];

          print('📡 Tracking Status: $status');
          print('⏱️ Tracking Interval: $trackingInterval minutes');

          if (status == 1 && trackingInterval != null) {
            await widget.userDetails.setTrackingStatus(true);
            if (trackingInterval is num) {
              final timeInterval = trackingInterval.toDouble();
              await widget.userDetails.setTimeInterval(timeInterval);
            } else if (trackingInterval is String) {
              final timeInterval = double.tryParse(trackingInterval) ?? 0.0;
              await widget.userDetails.setTimeInterval(timeInterval);
            }
          } else {
            print(
                'LoadingScreen: Time interval is null and tracking is not enabled');
            await widget.userDetails.setTrackingStatus(false);
            await widget.userDetails.setTimeInterval(0.00);
          }
          print('✅ Tracking data saved locally');
        } else {
          print('⚠️ No valid tracking data found in response');
        }
      } else {
        print('❌ API response is null');
      }

      // Navigate to DashboardScreen if no errors
      if (mounted) {
        if (profileData == null ||
            permissionData == null ||
            contactUsData == null ||
            trakingStatus == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load some user data, using defaults'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userSession: getIt<UserSession>(),
              userDetails: getIt<UserDetails>(),
              apiUrlConfig: getIt<ApiUrlConfig>(),
              locationService: getIt<LocationService>(),
            ),
          ),
        );
      }
    } catch (e) {
      print('LoadingScreen: Error fetching user data: $e');
      if (e is http.ClientException &&
          e.message.contains('Server error (500)')) {
        setState(() {
          _isLoading = false;
          _hasServerError = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server error occurred. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (e is InvalidTokenException) {
        // Handle invalid token error
        print('LoadingScreen: Invalid token, navigating to LoginScreen');
        if (mounted) {
          // Clear user session and details
          try {
            await widget.userSession.clearUserCredentials();
            await widget.userDetails.clearUserDetails();
            print('LoadingScreen: Cleared user session and details');
          } catch (clearError) {
            print('LoadingScreen: Error clearing session/details: $clearError');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid token. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                userSession: getIt<UserSession>(),
                userDetails: getIt<UserDetails>(),
                apiUrlConfig: getIt<ApiUrlConfig>(),
              ),
            ),
          );
        }
      } else {
        // Handle 400, 401, or other errors
        print('LoadingScreen: Navigating to LoginScreen due to error: $e');
        if (mounted) {
          // Clear user session and details
          try {
            await widget.userSession.clearUserCredentials();
            await widget.userDetails.clearUserDetails();
            print('LoadingScreen: Cleared user session and details');
          } catch (clearError) {
            print('LoadingScreen: Error clearing session/details: $clearError');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e is http.ClientException &&
                        e.message.contains('Authentication error')
                    ? 'Authentication failed. Please log in again.'
                    : 'Failed to load user data. Please log in again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                userSession: getIt<UserSession>(),
                userDetails: getIt<UserDetails>(),
                apiUrlConfig: getIt<ApiUrlConfig>(),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/ezhrm_logo.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Loading user data...',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
            if (_hasServerError) ...[
              const Text(
                'Server error occurred. Please try again.',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
