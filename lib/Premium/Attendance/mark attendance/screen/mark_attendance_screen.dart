import 'dart:async';
// Import for jsonDecode

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Authentication/bloc/auth_bloc.dart';
import '../../../Authentication/screen/login_screen.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../../camera_screen.dart';
import '../../../Get Permissions/bloc/get_permission_bloc.dart';
import '../../Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../geoLocation/geo_location_bloc.dart';
import '../bloc/mark_attendance_bloc.dart';
import 'check_out.dart';

class CheckInScreen extends StatefulWidget {
  final bool isCheckOutMode; // will be overridden by API
  final UserSession userSession;
  final UserDetails userDetails;
  final ApiUrlConfig apiUrlConfig;

  const CheckInScreen({
    super.key,
    this.isCheckOutMode = false,
    required this.userSession,
    required this.userDetails,
    required this.apiUrlConfig,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late GoogleMapController _mapController;
  LatLng? _currentPosition;
  String _currentTime = '';
  String _currentDate = '';
  String _currentAddress = 'Fetching address...';
  Set<Circle> _circles = {};
  Timer? _timer;
  MapType _currentMapType = MapType.normal;
  String username = '';
  String uid = '';

  bool _isFaceRecognitionEnabled = false;
  bool _isGpsRecognitionEnabled = false;
  bool _canMarkAttendanceByGeoLocation = false;
  String _geoFenceStatusMessage = 'Checking attendance zone...';
  List<Map<String, dynamic>> _activeLocations = [];

  @override
  void initState() {
    super.initState();
    // _getCurrentLocation();
    _updateTime();
    _loadUserDetails();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<GetTodayAttendanceBloc>().add(GetTodayAttendance());
      getIt<GetPermissionBloc>().add(GetPermission());
      getIt<GeoLocationBloc>().add(FetchGeoLocations());
    });
  }

  Future<void> _loadUserDetails() async {
    final userDetails = getIt<UserDetails>();
    final userSession = getIt<UserSession>();

    username = await userDetails.getUserName() ?? ''; // await + null check
    uid = await userSession.uid ?? ''; // await async getter

    print('user name is $username and user id $uid');
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Check if controller has been initialized before disposing
    // This avoids errors if the screen is disposed before map is created.
    // A simple check if mounted can also work well here.
    if (mounted) {
      _mapController.dispose();
    }
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _currentTime = DateFormat('hh:mm a').format(now);
        _currentDate = DateFormat('EEEE - dd MMMM yyyy').format(now);
      });
    }
  }

  void _checkGeoFence() {
    if (_currentPosition == null || _activeLocations.isEmpty) {
      return;
    }

    bool isWithinRange = false;
    for (var location in _activeLocations) {
      final lat = double.tryParse(location['latitude']?.toString() ?? '0');
      final lon = double.tryParse(location['longitude']?.toString() ?? '0');
      final radiusKm =
          double.tryParse(location['distance_km']?.toString() ?? '0');

      if (lat != null && lon != null && radiusKm != null) {
        final radiusMeters = radiusKm * 1000;
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lon,
        );

        if (distance <= radiusMeters) {
          isWithinRange = true;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _canMarkAttendanceByGeoLocation = isWithinRange;
        _geoFenceStatusMessage = isWithinRange
            ? 'You are in a valid attendance zone.'
            : 'You are outside the allowed attendance zone.';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!_isGpsRecognitionEnabled) {
        _canMarkAttendanceByGeoLocation = true;
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _circles = {
            Circle(
              circleId: const CircleId('attendanceRadius'),
              center: _currentPosition!,
              radius: 100, // Visual indicator
              fillColor: Colors.blue.withOpacity(0.2),
              strokeColor: Colors.blue,
              strokeWidth: 2,
            ),
          };
        });
        _getAddressFromLatLng(position);
        _checkGeoFence();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Error getting location: ${e.toString()}';
          _geoFenceStatusMessage = 'Could not get your location.';
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          setState(() {
            _currentAddress =
                '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
          });
        } else {
          setState(() => _currentAddress = 'No address found.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = 'Unable to fetch address');
    }
  }

  void _toggleMapType() {
    if (_isGpsRecognitionEnabled) {
      setState(() {
        _currentMapType = _currentMapType == MapType.normal
            ? MapType.satellite
            : MapType.normal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GeoLocationBloc, GeoLocationState>(
          listener: (context, state) {
            if (state is GeoLocationSuccess) {
              if (mounted) {
                setState(() {
                  _activeLocations = state.activeLocations;
                });
                _checkGeoFence();
              }
            } else if (state is GeoLocationFailure) {
              if (mounted) {
                setState(() {
                  _canMarkAttendanceByGeoLocation = false;
                  _geoFenceStatusMessage = 'Error: ${state.errorMessage}';
                });
              }
            }
          },
        ),
        BlocListener<GetPermissionBloc, GetPermissionState>(
          listener: (context, state) {
            if (state is GetPermissionSuccess) {
              if (mounted) {
                setState(() {
                  _isFaceRecognitionEnabled =
                      state.permissions['is_face_recognition'] == 1;
                  _isGpsRecognitionEnabled =
                      state.permissions['is_gps_location'] == 1;
                  // _isFaceRecognitionEnabled = false;
                  // _isGpsRecognitionEnabled = false;
                });
                _getCurrentLocation();
                print(
                    'face recognition permission is ${state.permissions['is_face_recognition']}');
                print(
                    'gps location permission is ${state.permissions['is_gps_location']}');
                print(
                    'Face recognition permission is $_isFaceRecognitionEnabled');
                print('gps location permission is $_isGpsRecognitionEnabled');
              }
            } else if (state is GetPermissionFailure) {
              print("Failed to fetch permissions: ${state.errorMessage}");
            }
          },
        ),
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
        BlocListener<MarkAttendanceBloc, MarkAttendanceState>(
          listener: (context, state) {
            if (state is MarkAttendanceSuccess) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attendance Marked Successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckOutScreen(
                      userSession: widget.userSession,
                    ),
                  ),
                );
              });
            } else if (state is MarkAttendanceFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, size: 20)),
                    const Spacer(),
                    RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(children: [
                          TextSpan(
                              text: 'Welcome to ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                  fontSize: 24)),
                          TextSpan(
                              text: 'EZHRM',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                  fontFamily: 'Poppins',
                                  fontSize: 24)),
                        ])),
                    const Spacer(flex: 2)
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(_currentTime,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w300)),
              const SizedBox(height: 4),
              Text(_currentDate,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54)),
              const SizedBox(height: 20),
              BlocBuilder<GetTodayAttendanceBloc, GetTodayAttendanceState>(
                builder: (context, state) {
                  bool isCheckOut = widget.isCheckOutMode;
                  if (state is GetTodayAttendanceSuccess &&
                      state.attendanceData.isNotEmpty) {
                    final todayRecord = state.attendanceData.first;
                    final dynamic checkInTime = todayRecord['check-in'];
                    final isNotNull = checkInTime != null;
                    final isNotEmptyString =
                        checkInTime?.toString().isNotEmpty ?? false;
                    isCheckOut = isNotNull && isNotEmptyString;
                  }
                  return GestureDetector(
                    onTap: _canMarkAttendanceByGeoLocation
                        ? () async {
                            if (getIt<MarkAttendanceBloc>().state
                                is MarkAttendanceLoading) {
                              return;
                            }
                            if (_isFaceRecognitionEnabled) {
                              print('Face recognition permission is 1');
                              final cameras = await availableCameras();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CameraScreen(
                                    userSession: widget.userSession,
                                    mode: CameraMode.checkIn,
                                    cameras: cameras,
                                  ),
                                ),
                              );
                            } else {
                              if (_isGpsRecognitionEnabled) {
                                if (_currentPosition == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Current location not found.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                print(
                                    'Gps location permission is provided, marking attendance with lat and long');
                                getIt<MarkAttendanceBloc>().add(
                                  MarkAttendance(
                                    latitude:
                                        _currentPosition!.latitude.toString(),
                                    longitude:
                                        _currentPosition!.longitude.toString(),
                                  ),
                                );
                              } else {
                                print(
                                    'Gps location permission is not provided, passing empty lat and long');
                                getIt<MarkAttendanceBloc>()
                                    .add(MarkAttendance());
                              }
                            }
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_geoFenceStatusMessage),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _canMarkAttendanceByGeoLocation
                            ? (isCheckOut ? const Color(0xFF2C437B) : null)
                            : Colors.grey.shade400,
                        gradient: _canMarkAttendanceByGeoLocation
                            ? (isCheckOut
                                ? null
                                : const LinearGradient(colors: [
                                    Color(0xFF1976D2),
                                    Color(0xFF42A5F5)
                                  ]))
                            : null,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: Center(
                        child: context.watch<MarkAttendanceBloc>().state
                                is MarkAttendanceLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: isCheckOut
                                    ? [
                                        const Icon(Icons.touch_app_outlined,
                                            color: Colors.white, size: 48),
                                        const SizedBox(height: 8),
                                        const Text('CHECK-OUT',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16)),
                                      ]
                                    : [
                                        const Icon(Icons.touch_app,
                                            color: Colors.white, size: 28),
                                        const SizedBox(height: 4),
                                        const Text('CHECK-IN',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16)),
                                      ]),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (_isGpsRecognitionEnabled) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    _geoFenceStatusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _canMarkAttendanceByGeoLocation
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text('Location: $_currentAddress',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.black54),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis))
                ]),
                const SizedBox(height: 16),
              ],
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (_isGpsRecognitionEnabled)
                          GestureDetector(
                              onTap: () {
                                // --- MODIFIED --- Use dynamic user data
                                final message = '''
Hello Sir!
$username this side.
I am sharing my current working location. Please add it in HRM software, so that I can Mark my Attendance from Here.
Employee ID: $uid
Latitude: ${_currentPosition?.latitude.toString() ?? 'N/A'}
Longitude: ${_currentPosition?.longitude.toString() ?? 'N/A'}
''';
                                Share.share(message);
                              },
                              child: const CircleAvatar(
                                  backgroundColor: Color(0xFFF0F4F8),
                                  child:
                                      Icon(Icons.share, color: Colors.blue))),
                        if (_isGpsRecognitionEnabled)
                          GestureDetector(
                              onTap: _toggleMapType,
                              child: const CircleAvatar(
                                  backgroundColor: Color(0xFFF0F4F8),
                                  child: Icon(Icons.map, color: Colors.blue))),
                        if (_isGpsRecognitionEnabled)
                          GestureDetector(
                              onTap: () {
                                if (_currentPosition != null) {
                                  _mapController.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                          CameraPosition(
                                              target: _currentPosition!,
                                              zoom: 16)));
                                }
                              },
                              child: const CircleAvatar(
                                  backgroundColor: Color(0xFFF0F4F8),
                                  child: Icon(Icons.center_focus_strong,
                                      color: Colors.blue)))
                      ])),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _isGpsRecognitionEnabled
                        ? (_currentPosition == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 10),
                                    Text(_currentAddress),
                                  ],
                                ),
                              )
                            : GoogleMap(
                                onMapCreated: (controller) {
                                  if (mounted) {
                                    _mapController = controller;
                                  }
                                },
                                initialCameraPosition: CameraPosition(
                                  target: _currentPosition!,
                                  zoom: 16,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('currentLocation'),
                                    position: _currentPosition!,
                                    infoWindow: InfoWindow(
                                      title: 'Your Location',
                                      snippet: _currentAddress,
                                    ),
                                  ),
                                },
                                circles: _circles,
                                zoomControlsEnabled: false,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                mapType: _currentMapType,
                              ))
                        : const SizedBox
                            .shrink(), // fallback if GPS not enabled
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
