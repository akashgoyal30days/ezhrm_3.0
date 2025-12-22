import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../Get Permissions/bloc/get_permission_bloc.dart';

import '../../../success_dialog.dart';
import '../../Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Request Today Attendance/bloc/req_today_attendance_bloc.dart';
import 'Camera_capture_screen.dart';

// Widget to handle time updates independently
class TimeDisplay extends StatefulWidget {
  const TimeDisplay({super.key});

  @override
  State<TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<TimeDisplay> {
  String _currentTime = '';
  String _currentDate = '';
  String _attendanceDate = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      final formattedTime = DateFormat('hh:mm a').format(now);
      final formattedDate = DateFormat('EEEE - dd MMMM yyyy').format(now);
      final attendanceDate = DateFormat('yyyy-MM-dd').format(now);

      setState(() {
        _currentTime = formattedTime;
        _currentDate = formattedDate;
        _attendanceDate = attendanceDate;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_currentTime,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
        const SizedBox(height: 4),
        Text(_currentDate,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54)),
      ],
    );
  }
}

class RequestAttendanceScreen extends StatefulWidget {
  const RequestAttendanceScreen({super.key});

  @override
  State<RequestAttendanceScreen> createState() =>
      _RequestAttendanceScreenState();
}

class _RequestAttendanceScreenState extends State<RequestAttendanceScreen> {
  late GoogleMapController _mapController;
  String _currentTime = '';
  LatLng _currentPosition = const LatLng(28.6904, 76.9789);
  String _currentAddress = 'Fetching address...';
  Set<Circle> _circles = {};
  MapType _currentMapType = MapType.normal;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _todayAttendanceData;
  CameraDescription? _camera;
  bool isRequestAttendanceEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocation();
    print('events called');
    getIt<GetTodayAttendanceBloc>().add(GetTodayAttendance());
    getIt<GetPermissionBloc>().add(GetPermission());
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        setState(() {
          _camera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    if (mounted) {
      _mapController.dispose();
    }
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final now = DateTime.now();
    final formattedTime = DateFormat('hh:mm a').format(now);
    setState(() {
      _currentTime = formattedTime;
    });
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _currentAddress = 'Location services are disabled.');
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) {
          setState(() => _currentAddress = 'Location permission denied.');
        }
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _circles = {
            Circle(
              circleId: const CircleId('attendanceRadius'),
              center: _currentPosition,
              radius: 100,
              fillColor: Colors.blue.withOpacity(0.2),
              strokeColor: Colors.blue,
              strokeWidth: 2,
            ),
          };
        });
        _getAddressFromLatLng(position);
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentPosition, zoom: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = 'Error getting location.');
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        if (mounted) {
          setState(() => _currentAddress =
              '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}');
        }
      } else {
        if (mounted) {
          setState(
              () => _currentAddress = 'No address found for this location.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = 'Unable to fetch address');
    }
  }

  Future<File?> _captureImage() async {
    if (_camera == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not available')),
        );
      }
      return null;
    }

    try {
      final imagePath = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CustomCameraScreen(camera: _camera!),
        ),
      );

      if (imagePath != null && imagePath is String) {
        return File(imagePath);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image captured')),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
      return null;
    }
  }

  void _toggleMapType() {
    if (mounted) {
      setState(() => _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    }
  }

  void _showSuccessDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SuccessDialog(
          title: title,
          message: message,
          buttonText: 'OK',
          onPressed: () {
            Navigator.of(context).pop();
            context.read<GetTodayAttendanceBloc>().add(GetTodayAttendance());
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<GetTodayAttendanceBloc, GetTodayAttendanceState>(
              listener: (context, state) {
                if (state is GetTodayAttendanceSuccess) {
                  Map<String, dynamic>? todayData;
                  for (var item in state.attendanceData) {
                    if (item.containsKey('check-in') &&
                        item['check-in'] != null) {
                      todayData = item;
                      break;
                    }
                  }
                  setState(() => _todayAttendanceData = todayData);
                  debugPrint(
                      'Selected todayAttendanceData: $_todayAttendanceData');
                } else if (state is GetTodayAttendanceFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error fetching status'),
                        backgroundColor: Colors.red),
                  );
                }
              },
            ),
            BlocListener<ReqTodayAttendanceBloc, ReqTodayAttendanceState>(
              listener: (context, state) {
                if (state is ReqTodayAttendanceSuccess) {
                  _showSuccessDialog(
                      title: 'Success',
                      message: 'Your request has been processed successfully.');
                } else if (state is ReqTodayAttendanceFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Request failed: ${state.message}')),
                  );
                }
              },
            ),
            BlocListener<GetPermissionBloc, GetPermissionState>(
              listener: (context, state) {
                if (state is GetPermissionSuccess) {
                  setState(() {
                    // Changed condition to enable button when is_req_attendance is '1'
                    isRequestAttendanceEnabled =
                        state.permissions['is_req_attendance'] == 1;
                    print(
                        'value of the isRequestAttendanceEnabled is $isRequestAttendanceEnabled');
                    print(
                        'permission for the request attendance is ${state.permissions['is_req_attendance']}');
                  });
                } else if (state is GetPermissionFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(state.errorMessage),
                        backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
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
                      text: const TextSpan(
                        children: [
                          TextSpan(
                              text: 'Welcome to ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontFamily: 'Poppins')),
                          TextSpan(
                              text: 'EZHRM',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                  fontSize: 24,
                                  fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const TimeDisplay(), // Use the separate TimeDisplay widget
              const SizedBox(height: 20),
              BlocBuilder<GetTodayAttendanceBloc, GetTodayAttendanceState>(
                builder: (context, state) {
                  final isLoading = context
                      .watch<ReqTodayAttendanceBloc>()
                      .state is ReqTodayAttendanceLoading;

                  if (state is GetTodayAttendanceLoading) {
                    return const CircularProgressIndicator();
                  }
                  if (state is GetTodayAttendanceFailure) {
                    return Text('Error: ${state.errorMessage}');
                  }

                  if (!isRequestAttendanceEnabled) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'You cannot request attendance.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final bool hasCheckedIn = _todayAttendanceData != null;

                  if (hasCheckedIn) {
                    return _buildAttendanceButton(
                      label: 'CHECK-OUT',
                      icon: Icons.touch_app_outlined,
                      isLoading: isLoading,
                      isCheckOut: true,
                      onTap: () async {
                        final imageFile = await _captureImage();
                        if (imageFile != null && _todayAttendanceData != null) {
                          context
                              .read<ReqTodayAttendanceBloc>()
                              .add(RequestTodayAttendance(
                                isCheckIn: false,
                                attendanceId:
                                    _todayAttendanceData!['attendance_id']
                                        .toString(),
                                latitude: _currentPosition.latitude.toString(),
                                longitude:
                                    _currentPosition.longitude.toString(),
                                checkOutTime: DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(DateTime.now()),
                                imageBase: imageFile,
                              ));
                        } else if (imageFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please capture an image for check-out')),
                          );
                        }
                      },
                    );
                  } else {
                    return _buildAttendanceButton(
                      label: 'CHECK-IN',
                      icon: Icons.touch_app,
                      isLoading: isLoading,
                      isCheckOut: false,
                      onTap: () async {
                        final imageFile = await _captureImage();
                        if (imageFile != null) {
                          context
                              .read<ReqTodayAttendanceBloc>()
                              .add(RequestTodayAttendance(
                                isCheckIn: true,
                                latitude: _currentPosition.latitude.toString(),
                                longitude:
                                    _currentPosition.longitude.toString(),
                                attendanceDate: DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now()),
                                checkInTime: DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(DateTime.now()),
                                imageBase: imageFile,
                              ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please capture an image for check-in')),
                          );
                        }
                      },
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                    child: Text('Location: $_currentAddress',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black54),
                        textAlign: TextAlign.center)),
              ]),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const CircleAvatar(
                        backgroundColor: Color(0xFFF0F4F8),
                        child:
                            Icon(Icons.volunteer_activism, color: Colors.blue)),
                    GestureDetector(
                        onTap: () => Share.share(
                            "📍 I'm at: $_currentAddress at $_currentTime"),
                        child: const CircleAvatar(
                            backgroundColor: Color(0xFFF0F4F8),
                            child: Icon(Icons.share, color: Colors.blue))),
                    GestureDetector(
                        onTap: _toggleMapType,
                        child: const CircleAvatar(
                            backgroundColor: Color(0xFFF0F4F8),
                            child: Icon(Icons.map, color: Colors.blue))),
                    GestureDetector(
                        onTap: () => _mapController.animateCamera(
                            CameraUpdate.newCameraPosition(CameraPosition(
                                target: _currentPosition, zoom: 16))),
                        child: const CircleAvatar(
                            backgroundColor: Color(0xFFF0F4F8),
                            child: Icon(Icons.center_focus_strong,
                                color: Colors.blue))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition:
                          CameraPosition(target: _currentPosition, zoom: 16),
                      markers: {
                        Marker(
                            markerId: const MarkerId('currentLocation'),
                            position: _currentPosition,
                            infoWindow: InfoWindow(title: 'Your Location'))
                      },
                      circles: _circles,
                      zoomControlsEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      mapType: _currentMapType,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool isLoading = false,
    required bool isCheckOut,
  }) {
    final IconData displayIcon = isCheckOut ? Icons.touch_app_outlined : icon;
    final double iconSize = isCheckOut ? 48 : 28;
    final double labelFontSize = isCheckOut ? 16 : 16;
    final double spacing = isCheckOut ? 8 : 4;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCheckOut ? const Color(0xFF2C437B) : null,
          gradient: isCheckOut
              ? null
              : LinearGradient(
                  colors: onTap != null
                      ? [const Color(0xFF1976D2), const Color(0xFF42A5F5)]
                      : [Colors.grey, Colors.grey.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(displayIcon, color: Colors.white, size: iconSize),
                    SizedBox(height: spacing),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: labelFontSize,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
