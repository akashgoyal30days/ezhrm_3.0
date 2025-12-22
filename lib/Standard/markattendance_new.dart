import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:circular_countdown/circular_countdown.dart';
import 'package:ezhrm/Standard/services/flutter_background.dart';
import 'package:ezhrm/Standard/uploadimg_new.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../standard_app_entry.dart';
import 'LocationService.dart';
import 'bottombar_ios.dart/bottombar_ios.dart';
import 'constants.dart';
import 'camera_screen.dart';
import 'attendance_records.dart';
import 'drawer.dart';
import 'error_api.dart';
import 'image_recognition.dart';
import 'login.dart';
import 'services/shared_preferences_singleton.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});
  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  bool? showLoadingSpinnerOnTop = false,
      attendanceloadingOverlay = false,
      checkInButtonLoading = false,
      showTodaysRecords = false,
      showOutOfRangeButton = false,
      imageRequired = goGreenModel!.faceRecognitionEnabled,
      locationRequired = goGreenModel!.locationEnabled,
      ableToSendRequest = goGreenModel!.canSendRequest;
  Position? currentPosition;
  final Set<Marker> marker = {};
  final List attendanceRecordsList = [];
  GoogleMapController? _googleMapController;
  StreamSubscription? locationUpdateStream;
  Uint8List? imageBytes;
  String? messageOnScreen, attendanceRecordStatus;
  MapType mapType = MapType.normal;
  BuildContext? scaffoldContext;
  String attendancerequestreason = "No Reason in Starting";
  final int? intervalInMiliSeconds = goGreenModel!.backgroundLocationInterval;
  Timer? timer;
  int? facePercentage;
  bool attendanceSendRequest = false;

  // Instance of LocationService
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    log("MarkAttendanceScreen: Initializing state");
    checkGPSStatus();
    super.initState();
  }

  @override
  void dispose() {
    log("MarkAttendanceScreen: Disposing resources");
    _googleMapController?.dispose();
    locationUpdateStream?.cancel();
    timer?.cancel();
    super.dispose();
    log("MarkAttendanceScreen: Disposal complete");
  }

  startlocationstream() async {
    log("MarkAttendanceScreen: Starting location stream");
    log("MarkAttendanceScreen: go green model value $goGreenModel");
    if (goGreenModel!.locationEnabled! ||
        goGreenModel!.backgroundLocationTrackingEnabled!) {
      log("MarkAttendanceScreen: Fetching initial location");
      currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {});

      log("MarkAttendanceScreen: Initial position: $currentPosition, Accuracy: ${currentPosition!.accuracy}");
      log("MarkAttendanceScreen: Starting position stream");
      locationUpdateStream = Geolocator.getPositionStream(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).listen((data) {
        log("MarkAttendanceScreen: Position stream update - Lat: ${data.latitude}, Long: ${data.longitude}");
        currentPosition = data;
      });

      log("MarkAttendanceScreen: Starting timer for attendance records");
      timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (currentPosition != null) {
          log("MarkAttendanceScreen: Timer active, position available, cancelling timer");
          if (timer.isActive) {
            timer.cancel();
          }
          log("MarkAttendanceScreen: Fetching attendance records");
          await fetchAttendanceRecords();
        } else {
          log("MarkAttendanceScreen: Timer active, no position available");
        }
      });
    } else {
      log("MarkAttendanceScreen: Location or background tracking not enabled");
    }
  }

  // Method to mark attendance without image recognition and background location tracking
  markattendancedirect() async {
    log("MarkAttendanceScreen: Starting mark attendance direct");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      var uri = "$customurl/controller/process/app/attendance.php";
      debugPrint("MarkAttendanceScreen: Sending POST request to $uri");
      final response = await http.post(Uri.parse(uri), body: {
        'type': '_mark',
        'cid': prefs.getString('comp_id'),
        'uid': prefs.getString('uid'),
      }, headers: <String, String>{
        'Accept': 'application/json',
      });
      var data = json.decode(response.body);
      debugPrint("MarkAttendanceScreen: Mark attendance response: $data");

      debugPrint("MarkAttendanceScreen: Fetching updated attendance records");
      fetchAttendanceRecords();

      if (data['status'] == true) {
        debugPrint("MarkAttendanceScreen: Attendance marked successfully, setting isCheckedIn to true");
        debugPrint("MarkAttendanceScreen: Starting background location tracking");
        await prefs.setBool('isCheckedIn', true);
        var show = prefs.getString("ulocat");
        var locTrack = prefs.getString("locate");
        debugPrint('gps location permission in "markattendancedirect" is $show and location track is $locTrack');
        if (show.toString() == "1" && locTrack.toString() == '1') {
          await enableMinimalBackgroundMode();
          await _sendBackgroundLocation(currentPosition!);
          await _locationService.startBackgroundTracking();
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "${data['msg']}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.green,
        ));
        log("MarkAttendanceScreen: Success snackbar shown with message: ${data['msg']}");
      } else if (data['status'] == false) {
        log("MarkAttendanceScreen: Attendance marking failed, message: ${data['msg']}");
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "${data['msg']}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ));
        log("MarkAttendanceScreen: Error snackbar shown with message: ${data['msg']}");
      } else {
        log("MarkAttendanceScreen: Unexpected response status");
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Problem in marking your attendance please contact to admin",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red,
        ));
        log("MarkAttendanceScreen: Error snackbar shown for unexpected response");
      }
    } catch (error) {
      log("MarkAttendanceScreen: Error marking attendance: $error");
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Unable to process your request at this time",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        duration: Duration(seconds: 5),
        backgroundColor: Colors.red,
      ));
      log("MarkAttendanceScreen: Error snackbar shown for request failure");
    }
  }

  Future<bool> checkUserLocationValidity() async {
    log("MarkAttendanceScreen: Checking user location validity");
    showCheckInButtonLoading(true);
    try {
      var body = {
        'type': 'verify_location',
        'uid': await SharedPreferences.getInstance()
            .then((prefs) => prefs.getString('uid') ?? ""),
        'cid': await SharedPreferences.getInstance()
            .then((prefs) => prefs.getString('comp_id') ?? ""),
        'lat': locationRequired! ? currentPosition!.latitude.toString() : "",
        'long': locationRequired! ? currentPosition!.longitude.toString() : "",
      };
      log("MarkAttendanceScreen: Sending location verification data: $body");
      var response = await http.post(
          Uri.parse("$customurl/controller/process/app/attendance_mark.php"),
          body: body);
      var responseBody = json.decode(response.body);
      log("MarkAttendanceScreen: Location verification response: $responseBody");
      showOutOfRangeButton = responseBody['status'].toString() != "true";
      log("MarkAttendanceScreen: showOutOfRangeButton set to $showOutOfRangeButton");
      showCheckInButtonLoading(false);
      if (showOutOfRangeButton!) {
        log("MarkAttendanceScreen: Location out of range, setting reason and showing dialog");
        attendancerequestreason = "Out of Range";
        locationOutOfRangeDialog();
      }
      return !showOutOfRangeButton!;
    } catch (e) {
      log("MarkAttendanceScreen: Error verifying location: $e");
      showCheckInButtonLoading(false);
      return false;
    }
  }

  checkGPSStatus() async {
    log("MarkAttendanceScreen: Checking GPS status");
    final prefs = await SharedPreferences.getInstance();
    var show = prefs.getString("ulocat");
    debugPrint('gps location permission in mark attendance screen "checkGPSStatus" is $show');
    if (show.toString() == "0") {
      log("MarkAttendanceScreen: Location and background tracking not required, skipping GPS check");
      return;
    }

    if (Platform.isAndroid) {
      // Check and request notification permission
      log("MarkAttendanceScreen: Checking notification permission");
      var notificationStatus = await Permission.notification.status;
      log("MarkAttendanceScreen: Notification permission status: $notificationStatus");
      if (!notificationStatus.isGranted) {
        log("MarkAttendanceScreen: Requesting notification permission");
        notificationStatus = await Permission.notification.request();
        log("MarkAttendanceScreen: New notification permission status: $notificationStatus");
        if (!notificationStatus.isGranted) {
          if (mounted) {
            log("MarkAttendanceScreen: Notification permission denied, showing snackbar");
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                "Notification permission is required for background tracking updates",
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            ));
            Navigator.pop(context);
          }
          return;
        }
      }
    }

    // Check and request location permissions
    log("MarkAttendanceScreen: Checking location permission");
    var permission = await Geolocator.checkPermission();
    log("MarkAttendanceScreen: Location permission status: $permission");
    if (permission == LocationPermission.denied) {
      log("MarkAttendanceScreen: Requesting location permissions");
      Map<Permission, PermissionStatus> permissions = await [
        Permission.location,
        Permission.locationWhenInUse,
      ].request();
      log("MarkAttendanceScreen: Location permissions result: $permissions");

      if (permissions[Permission.locationWhenInUse] ==
              PermissionStatus.denied &&
          permissions[Permission.location] == PermissionStatus.denied) {
        if (mounted) {
          log("MarkAttendanceScreen: Location permissions denied, showing snackbar");
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              "Location permission is denied",
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ));
          Navigator.pop(context);
        }
        return;
      }
    }
    if (Platform.isAndroid) {
      // Request background location permission
      final prefs = await SharedPreferences.getInstance();
      var locTrack = prefs.getString('locate');
      if (locTrack.toString() == '1' && permission != LocationPermission.always) {
        log("MarkAttendanceScreen: Requesting background location permission");
        permission = await Geolocator.requestPermission();
        log("MarkAttendanceScreen: Background permission status: $permission");
        if (permission != LocationPermission.always) {
          if (mounted) {
            log("MarkAttendanceScreen: Background location permission denied, showing snackbar");
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                "Background location permission is required for continuous tracking",
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            ));
            Navigator.pop(context);
          }
          return;
        }
      }
    }

    // Check if location services are enabled
    log("MarkAttendanceScreen: Checking if location services are enabled");
    var locationEnabled = await Geolocator.isLocationServiceEnabled();
    log("MarkAttendanceScreen: Location services enabled: $locationEnabled");
    if (!locationEnabled) {
      if (mounted) {
        log("MarkAttendanceScreen: Location services disabled, showing snackbar");
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Please Turn your GPS ON",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ));
        Navigator.pop(context);
      }
      return;
    }

    log("MarkAttendanceScreen: Starting location stream from checkGPSStatus");
    await startlocationstream();
    startLocationStreaming();
  }

  startLocationStreaming() async {
    log("MarkAttendanceScreen: Starting location streaming");
    var position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {});

    log("MarkAttendanceScreen: Initial position for streaming: Lat: ${position.latitude}, Long: ${position.longitude}");
    updateLocationOnMap(position);
    log("MarkAttendanceScreen: Starting position stream for continuous updates");
    locationUpdateStream = Geolocator.getPositionStream(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high))
        .listen((position) {
      log("MarkAttendanceScreen: Stream position update - Lat: ${position.latitude}, Long: ${position.longitude}");
      updateLocationOnMap(position);
    });
    log("MarkAttendanceScreen: Waiting 10 seconds to check position availability");
    await Future.delayed(const Duration(seconds: 10));
    if (mounted && currentPosition == null) {
      log("MarkAttendanceScreen: No position after 10 seconds, navigating to MarkAttendanceScreen");
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()));
    }
  }

  casesWorkflows() async {
    log("MarkAttendanceScreen: Starting cases workflows");
    if (!locationRequired! && imageRequired!) {
      log("MarkAttendanceScreen: Location not required but image required, navigating to CameraScreen");
      List<CameraDescription> localCameras;
      try {
        localCameras = await availableCameras();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera access denied")),
        );
        return;
      }

      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageRecognitionScreen(
            cameras: localCameras, // From standard_app_entry.dart or wherever initialized
            mode: CameraMode.checkIn,
          ),
        ),
      );
      setState(() {
        facePercentage = result?['faceRate'] as int?;
      });
      markAttendanceAPI(faceRate: facePercentage);
    }
    log("MarkAttendanceScreen: No specific workflow triggered");
  }

  updateLocationOnMap(Position position) async {
    log("MarkAttendanceScreen: Updating location on map - Lat: ${position.latitude}, Long: ${position.longitude}");
    currentPosition = position;
    if (!mounted) {
      log("MarkAttendanceScreen: Widget not mounted, skipping map update");
      return;
    }

    setState(() {
      showLoadingSpinnerOnTop = true;
    });
    log("MarkAttendanceScreen: Setting marker on map");
    setMarkerOnMap();

    log("MarkAttendanceScreen: Animating camera to new position");
    await _googleMapController!.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        zoom: 18,
      ),
    ));
    log("MarkAttendanceScreen: Camera animation complete");
  }

  setMarkerOnMap() => setState(() {
        log("MarkAttendanceScreen: Clearing existing markers");
        marker.clear();
        log("MarkAttendanceScreen: Adding new marker at Lat: ${currentPosition!.latitude}, Long: ${currentPosition!.longitude}");
        marker.add(Marker(
          markerId: const MarkerId("User Location"),
          infoWindow: const InfoWindow(
              title: "This Location will be used for attendance"),
          visible: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position:
              LatLng(currentPosition!.latitude, currentPosition!.longitude),
        ));
        showLoadingSpinnerOnTop = false;
        log("MarkAttendanceScreen: Marker set and loading spinner hidden");
      });

  changeMapType() => setState(() {
        log("MarkAttendanceScreen: Changing map type from $mapType");
        mapType =
            mapType == MapType.normal ? MapType.satellite : MapType.normal;
        log("MarkAttendanceScreen: Map type changed to $mapType");
      });

  shareLocation() async {
    log("MarkAttendanceScreen: Sharing location");
    final prefs = await SharedPreferences.getInstance();
    var shareText = 'Hello Sir!\n'
        '${prefs.getString('username')} this side.\n'
        'I am sharing my current working location. Please add it in HRM software, so that i can Mark my Attendance from Here.\n'
        'Employee ID: ${prefs.getString('empid')}\n'
        'Latitude: ${currentPosition!.latitude}\n'
        'Longitude: ${currentPosition!.longitude}';
    log("MarkAttendanceScreen: Sharing text: $shareText");
    Share.share(shareText);
    log("MarkAttendanceScreen: Location shared");
  }

  Future<void> _sendBackgroundLocation(Position position) async {
    log("1102: Sending location to server");
    var response = await http.post(
      Uri.parse("$customurl/controller/process/app/location_track.php"),
      body: {
        'uid': SharedPreferencesInstance.getString('uid') ?? "",
        'cid': SharedPreferencesInstance.getString('comp_id') ?? "",
        'type': 'add_loc',
        'lat': position.latitude.toString(),
        'long': position.longitude.toString(),
      },
      headers: {'Accept': 'application/json'},
    );

    log({
      "1102"
          'uid': SharedPreferencesInstance.getString('uid') ?? "",
      'cid': SharedPreferencesInstance.getString('comp_id') ?? "",
      'type': 'add_loc',
      'lat': position.latitude.toString(),
      'long': position.longitude.toString(),
    }.toString());

    log("1102: Location update response status: ${response.statusCode}");
    log("1102: Location update response: ${response.body}");
  }

  //-------------------END LOCATION FUNCTIONS---------------------------

  //------------------ START IMAGE FUNCTIONS---------------------------

  //-------------------END IMAGE FUNCTIONS---------------------------

  //------------------ START API FUNCTIONS---------------------------

  markAttendanceAPI({bool sendRequest = false, String faceDistance = "", int? faceRate}) async {

    debugPrint('===== markAttendanceAPI CALLED =====');
    debugPrint('sendRequest: $sendRequest');
    debugPrint('faceDistance: $faceDistance');
    debugPrint('faceRate: $faceRate');
    debugPrint('locationRequired: $locationRequired');
    debugPrint('imageRequired: $imageRequired');
    debugPrint('able to send request: $ableToSendRequest');
    debugPrint('send request value: $sendRequest');
    if (sendRequest && !ableToSendRequest!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cannot Send Request",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      showProcessingOverlay(false);
      return;
    }
    if (currentPosition == null && locationRequired!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location not captured, please try again",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      SharedPreferencesInstance.saveError(
          "location Enabled: ${await Geolocator.isLocationServiceEnabled()} location Not captured");
      showProcessingOverlay(false);
      return;
    }
    showProcessingOverlay(true);

    try {
      var apiStartTime = DateTime.now();

      final uri =
      Uri.parse("$customurl/controller/process/app/attendance_mark.php");

      final request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        'type': 'mark_attendance_new',
        'uid': SharedPreferencesInstance.getString('uid') ?? "",
        'cid': SharedPreferencesInstance.getString('comp_id') ?? "",
        'device_id': SharedPreferencesInstance.getString('deviceid') ?? "",
        'lat': locationRequired! ? currentPosition!.latitude.toString() : "",
        'long': locationRequired! ? currentPosition!.longitude.toString() : "",
        'face_distance':
        faceRate != null ? faceRate.toString() : (faceDistance.isNotEmpty ? faceDistance : "0"),
        'send_request': ableToSendRequest! && sendRequest ? "1" : "0",
        'message':
        ableToSendRequest! && sendRequest ? attendancerequestreason : "",
      });

      debugPrint('Form-data fields: ${request.fields}');
      debugPrint('Form-data files count: ${request.files.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('API status code: ${response.statusCode}');
      debugPrint('API raw response: ${response.body}');

      // Map body = {
      //   'type': 'mark_attendance_new',
      //   'uid': SharedPreferencesInstance.getString('uid') ?? "",
      //   'cid': SharedPreferencesInstance.getString('comp_id') ?? "",
      //   'device_id': SharedPreferencesInstance.getString('deviceid') ?? "",
      //   'lat': locationRequired! ? currentPosition!.latitude.toString() : "",
      //   'long': locationRequired! ? currentPosition!.longitude.toString() : "",
      //   if(faceRate!=null) 'face_distance' : faceRate
      //   else 'face_distance': faceDistance ?? "0",
      //   'img_data': sendRequest ? base64.encode(imageBytes!) : "",
      //   'send_request': ableToSendRequest! && sendRequest ? "1" : "0",
      //   'message':
      //       ableToSendRequest! && sendRequest ? attendancerequestreason : "",
      // };
      //
      // debugPrint('Request body prepared: $body');
      //
      // final response = await http.post(
      //   Uri.parse("$customurl/controller/process/app/attendance_mark.php"),
      //   body: body,
      //   headers: {
      //     'Accept': 'application/json',
      //   },
      // );
      // // debugPrint('API URL: ${response.request!.url}');
      // debugPrint('API status code: ${response.statusCode}');
      // debugPrint('API raw response: ${response.body}');

      var apiEndTime = DateTime.now();
      debugPrint('API call completed in ${apiEndTime.difference(apiStartTime).inSeconds} seconds');
      var logBody = {
        'type': 'mark_attendance',
        'uid': SharedPreferencesInstance.getString('uid') ?? "",
        'cid': SharedPreferencesInstance.getString('comp_id') ?? "",
        'device_id': SharedPreferencesInstance.getString('deviceid') ?? "",
        'lat': locationRequired! ? currentPosition!.latitude.toString() : "",
        'long': locationRequired! ? currentPosition!.longitude.toString() : "",
        'face_distance': faceDistance,
        'img_data': imageRequired! ? "sent Data (Too Long To display)" : "",
        'send_request': ableToSendRequest! && sendRequest ? "1" : "0",
        'message':
            ableToSendRequest! && sendRequest ? attendancerequestreason : "",
      };
      SharedPreferencesInstance.saveLogs(
        response.request!.url.toString(),
        json.encode(logBody),
        response.body,
        duration: apiEndTime.difference(apiStartTime).inSeconds,
      );
      Map data = json.decode(response.body);
      debugPrint("Mark attendance Response : $data");
      showProcessingOverlay(false);

      if (!data.containsKey("code")) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error Occured"),
          backgroundColor: Colors.red,
        ));
        return;
      }

      switch (data["code"].toString()) {
        case "1001":
          return code1001(data, sendRequest);
        case "1002":
          return code1002(data);
        case "1003":
          return code1003(data);
      }

      // logouts if code is not equal to 1001 or 1002 or 1003
      await SharedPreferencesInstance.logOut();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Invalid Device"),
        backgroundColor: Color(0xAAF44336),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const Login(),
          ),
          (route) => false);
    } catch (e) {
      log(e.toString());
      showProcessingOverlay(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error Occured, Try Again",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  code1001(data, bool sendRequestType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (data["status"].toString() == "true") {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: sendRequestType
            ? const Text(
                "Request Sent successfully",
                textAlign: TextAlign.center,
              )
            : const Text(
                "Attendance Marked successfully",
                textAlign: TextAlign.center,
              ),
        backgroundColor: Colors.green,
      ));
      log("MarkAttendanceScreen: Starting background location tracking");
      // Send immediate location update
      log("MarkAttendanceScreen: Sending immediate location update");
      if (Platform.isAndroid) {
        try {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isCheckedIn', true);
          var show = prefs.getString("ulocat");
          var locTrack = prefs.getString("locate");
          debugPrint('gps location permission is $show and location track is $locTrack');
          if (show.toString() == "1" && locTrack.toString() == '1') {
            await enableMinimalBackgroundMode();
            await _sendBackgroundLocation(currentPosition!);
            await _locationService.sendBackgroundLocation();
          }
          print(
              "MarkAttendanceScreen: Immediate location update sent successfully");
        } catch (e) {
          print(
              "MarkAttendanceScreen: Failed to send immediate location update: $e");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed to send location: $e"),
            backgroundColor: Colors.red,
          ));
        }
      }

      await prefs.setBool('isCheckedIn', true);
      print('check in value set to true ${prefs.getBool('isCheckedIn')}');
      // Start background tracking (cancels previous tasks)
      print("MarkAttendanceScreen: Starting background location tracking");

      if (Platform.isAndroid) {
        var show = prefs.getString("ulocat");
        var locTrack = prefs.getString("locate");
        debugPrint('gps location permission is $show and location track is $locTrack');
        bool started = false;
        if (show.toString() == "1" && locTrack.toString() == '1') {
          started = await _locationService.startBackgroundTracking();
          if (started) {
            print(
                "MarkAttendanceScreen: Background tracking started successfully");
          } else {
            print("MarkAttendanceScreen: Failed to start background tracking");
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Failed to start location tracking"),
              backgroundColor: Colors.red,
            ));
          }
        }
      }

      await fetchAttendanceRecords();
      log("MarkAttendanceScreen: Attendance marked successfully, setting isCheckedIn to true");
      await prefs.setBool('isCheckedIn', true);
      log("MarkAttendanceScreen: Starting background location tracking");
      return;
    }
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(
                data["msg"].toString() == "Face not matched, Please try again"
                    ? "Face not matched"
                    : "Out of range",
                style: const TextStyle(color: Colors.red),
              ),
              content: Text(data["msg"]),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all(
                      const Color(0xff072a99),
                    ),
                  ),
                  child: const Text("Try Again"),
                ),
              ],
            ));
  }

  code1002(data) async {
    attendancerequestreason = "Face Not Matched";

    if (!attendanceSendRequest && !ableToSendRequest!) return;
    bool selectedSendRequest = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: Text(
                    data["msg"].toString() ==
                            "Face not matched, Do you want to send attendance request"
                        ? "Face not matched"
                        : "Out of Range",
                    style: const TextStyle(color: Colors.red),
                  ),
                  content: Text(data['msg']),
                  actions: [
                    TextButton(
                      onPressed: Navigator.of(context).pop,
                      style: ButtonStyle(
                          foregroundColor:
                              WidgetStateProperty.all(const Color(0xff072a99))),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ButtonStyle(
                          foregroundColor:
                              WidgetStateProperty.all(const Color(0xff072a99))),
                      child: const Text("Send Request"),
                    ),
                  ],
                )) ??
        false;
    if (!selectedSendRequest) return;
    markAttendanceAPI(sendRequest: true);
  }

  code1003(data) async {
    attendancerequestreason = "Face Images Not Uploaded";
    bool selectedSendRequest = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text(
                    "Face Images Not Uploaded",
                    style: TextStyle(color: Colors.red),
                  ),
                  content: Text(data["msg"]),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(
                          const Color(0xff072a99),
                        ),
                      ),
                      child: const Text("Send Request"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UploadImg()),
                            (route) => route.isFirst);
                      },
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(
                          const Color(0xff072a99),
                        ),
                      ),
                      child: const Text("Upload Images"),
                    ),
                  ],
                )) ??
        false;
    if (!selectedSendRequest) return;
    markAttendanceAPI(sendRequest: true);
  }

  fetchAttendanceRecords() async {
    final response = await http.post(
        Uri.parse("$customurl/controller/process/app/attendance.php"),
        body: {
          'type': 'get_att_fetch',
          'cid': SharedPreferencesInstance.getString('comp_id'),
          'uid': SharedPreferencesInstance.getString('uid'),
        },
        headers: <String, String>{
          'Accept': 'application/json',
        });
    var data = json.decode(response.body);
    log("Attendance Records :$data");

    String status = data['status']?.toString() ?? "";
    if (status != "true") {
      casesWorkflows();
      return;
    }
    attendanceRecordsList.clear();
    attendanceRecordsList.addAll(data["data"]);
    log("Attendance Record List :$attendanceRecordsList");
    if (attendanceRecordsList.isNotEmpty) {
      if (goGreenModel!.backgroundLocationTrackingEnabled!) {
        if (Platform.isAndroid) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isCheckedIn', true);
          var show = prefs.getString("ulocat");
          var locTrack = prefs.getString("locate");
          debugPrint('gps location permission is $show and loation track is $locTrack');
          if (show.toString() == "1" && locTrack.toString() == '1') {
            await enableMinimalBackgroundMode();
            await _sendBackgroundLocation(currentPosition!);
            _locationService.startBackgroundTracking();
          }
          log("Starting background service...");
        }
      }
      log("Attendance Records Present");
    }
    String creditStatus = data["credit"].toString();
    attendanceRecordStatus = creditStatus == "3"
        ? "Full Day"
        : creditStatus == "4"
            ? "Half Day"
            : creditStatus == "7"
                ? "Submitted"
                : "Pending";
    setState(() {});
    if (attendanceRecordsList.isEmpty) {
      casesWorkflows();
      return;
    }
    bool clickedOnProceed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => AttendanceRecordScreen(
                      attendanceRecordsList,
                      attendanceRecordStatus!,
                      openedDirectly: true,
                    ))) ??
        false;
    log("Click on proceed : $clickedOnProceed");

    if (!clickedOnProceed) return Navigator.pop(context);
    casesWorkflows();
  }

  //------------------ END API FUNCTIONS---------------------------

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  showProcessingOverlay(bool value) {
    setState(() {
      attendanceloadingOverlay = value;
    });
  }

  showCheckInButtonLoading(bool value) {
    setState(() {
      checkInButtonLoading = value;
    });
  }

  locationOutOfRangeDialog() async {
    bool sendRequestSelected = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text(
                    "Out of Range",
                    style: TextStyle(color: Colors.red),
                  ),
                  content: RichText(
                      text: const TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: 16),
                          children: [
                        TextSpan(
                            text: "Sorry! Out of Range\n",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: "Do you want to send request to admin?")
                      ])),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (locationRequired!) {
                          if (currentPosition == null) {
                            // toast("please wait..");

                            // currentPosition =
                            //     await Geolocator.getLastKnownPosition(
                            //         forceAndroidLocationManager: true);
                            setState(() {});
                          } else {
                            if (locationRequired!) {
                              var value = await checkUserLocationValidity();
                              if (!value) return;
                            }

                            if (imageRequired!) {
                              List<CameraDescription> localCameras;
                              try {
                                localCameras = await availableCameras();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Camera access denied")),
                                );
                                return;
                              }

                              final result = await Navigator.push<Map<String, dynamic>>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageRecognitionScreen(
                                    cameras: localCameras, // From standard_app_entry.dart or wherever initialized
                                    mode: CameraMode.checkIn,
                                  ),
                                ),
                              );
                              final sendRequest = result?['sendRequest'] as bool?;
                              if(sendRequest!){
                                markAttendanceAPI(sendRequest: true);
                                setState(() {
                                  attendanceSendRequest = true;
                                });
                              }
                              else{
                                setState(() {
                                  attendanceSendRequest = false;
                                  facePercentage = result?['faceRate'] as int?;
                                  debugPrint('Extracted facePercentage: $facePercentage');
                                });
                                debugPrint('Calling markAttendanceAPI with faceRate: $facePercentage');
                                markAttendanceAPI(faceRate: facePercentage);
                              }
                            } else {
                              markAttendanceAPI();
                            }
                          }
                        } else {
                          if (imageRequired!) {
                            List<CameraDescription> localCameras;
                            try {
                              localCameras = await availableCameras();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Camera access denied")),
                              );
                              return;
                            }

                            final result = await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageRecognitionScreen(
                                  cameras: localCameras, // From standard_app_entry.dart or wherever initialized
                                  mode: CameraMode.checkIn,
                                ),
                              ),
                            );
                            final sendRequest = result?['sendRequest'] as bool?;
                            if(sendRequest!){
                              markAttendanceAPI(sendRequest: true);
                              setState(() {
                                attendanceSendRequest = true;
                              });
                            }
                            else{
                              setState(() {
                                attendanceSendRequest = false;
                                facePercentage = result?['faceRate'] as int?;
                                debugPrint('Extracted facePercentage: $facePercentage');
                              });
                              debugPrint('Calling markAttendanceAPI with faceRate: $facePercentage');
                              markAttendanceAPI(faceRate: facePercentage);
                            }
                          }
                        }
                      },
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(
                          const Color(0xff072a99),
                        ),
                      ),
                      child: const Text("Try Again"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(
                          const Color(0xff072a99),
                        ),
                      ),
                      child: const Text("Send Request"),
                    ),
                  ],
                )) ??
        false;
    if (sendRequestSelected) {
      imageBytes = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraScreen(
            imageSizeShouldBeLessThan200kB: true,
          ),
        ),
      );
      if (imageBytes == null) return;
      markAttendanceAPI(sendRequest: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    scaffoldContext = context;
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: const bottombar_ios(),
        key: scaffoldKey,
        drawer: const CustomDrawer(
            currentScreen: AvailableDrawerScreens.markAttendance),
        body: Stack(
          children: [
            if (locationRequired!)
              currentPosition == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TimeCircularCountdown(
                            textStyle: const TextStyle(
                                color: themecolor,
                                fontWeight: FontWeight.w500,
                                fontSize: 15),
                            repeat: true,
                            diameter: 100.0,
                            countdownTotalColor: themecolor,
                            countdownRemainingColor:
                                themecolor.withOpacity(0.20),
                            unit: CountdownUnit.second,
                            countdownTotal: 10,
                            onUpdated: (unit, remainingTime) =>
                                log('Countdown '),
                            onFinished: () => log('Countdown finished'),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Fetching Location",
                            style: TextStyle(
                              color: Color(0xff072a99),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                        ),
                        zoom: 18,
                      ),
                      mapType: mapType,
                      markers: marker,
                      onMapCreated: (controller) async {
                        _googleMapController = controller;
                        if (!locationRequired!) return;
                        await _googleMapController!
                            .animateCamera(CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(
                              currentPosition!.latitude,
                              currentPosition!.longitude,
                            ),
                            zoom: 18,
                          ),
                        ));
                      },
                      mapToolbarEnabled: true,
                      compassEnabled: true,
                      myLocationEnabled: locationRequired!,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                    ),
            if (!locationRequired!)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "To submit your attendance, please click on the button below",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MapButton(
                            Icons.menu,
                            onTap: scaffoldKey.currentState?.openDrawer,
                          ),
                          const Spacer(),
                          if (showLoadingSpinnerOnTop!)
                            Container(
                              width: 34,
                              height: 34,
                              padding: const EdgeInsets.all(4),
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Color(0xff072a99),
                                  shape: BoxShape.circle),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          if (attendanceRecordsList.isNotEmpty)
                            if (currentPosition != null)
                              MapButton(
                                Icons.how_to_reg,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AttendanceRecordScreen(
                                        attendanceRecordsList,
                                        attendanceRecordStatus!,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          if (locationRequired!)
                            if (currentPosition != null)
                              Row(
                                children: [
                                  MapButton(
                                    Icons.share,
                                    onTap: shareLocation,
                                  ),
                                  MapButton(
                                    mapType == MapType.satellite
                                        ? Icons.apartment
                                        : Icons.map,
                                    onTap: changeMapType,
                                  ),
                                  MapButton(
                                    Icons.my_location_sharp,
                                    onTap: () async => updateLocationOnMap(
                                        await Geolocator.getCurrentPosition(
                                      // forceAndroidLocationManager: true,
                                      desiredAccuracy: LocationAccuracy.high,
                                    )),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: checkInButtonLoading!
                                ? CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xff072a99),
                                    child: LoadingAnimationWidget
                                        .threeRotatingDots(
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  )
                                : showOutOfRangeButton!
                                    ? IntrinsicHeight(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Hero(
                                                tag: "The Button",
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    locationOutOfRangeDialog();
                                                  },
                                                  style: ButtonStyle(
                                                    padding:
                                                        WidgetStateProperty.all(
                                                            const EdgeInsets
                                                                .all(15)),
                                                    shape: WidgetStateProperty.all(
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10))),
                                                    backgroundColor:
                                                        WidgetStateProperty.all(
                                                      Colors.red,
                                                    ),
                                                    elevation:
                                                        WidgetStateProperty.all(
                                                            8),
                                                  ),
                                                  child: const Text(
                                                      "Location is out of Range"),
                                                ),
                                              ),
                                            ),
                                            // const SizedBox(width: 8),
                                            // Container(
                                            //   decoration: BoxDecoration(
                                            //     borderRadius:
                                            //         BorderRadius.circular(8),
                                            //     color: Colors.white,
                                            //   ),
                                            //   width: MediaQuery.of(context)
                                            //           .size
                                            //           .width *
                                            //       0.2,
                                            //   child: Column(
                                            //     mainAxisAlignment:
                                            //         MainAxisAlignment.center,
                                            //     children: [
                                            //       GestureDetector(
                                            //         onTap:
                                            //             checkUserLocationValidity,
                                            //         child: const Icon(
                                            //           Icons.refresh,
                                            //           size: 26,
                                            //           color: Color(0xff072a99),
                                            //         ),
                                            //       ),
                                            //     ],
                                            //   ),
                                            // ),
                                          ],
                                        ),
                                      )
                                    : Hero(
                                        tag: "The Button",
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (locationRequired!) {
                                              if (currentPosition == null) {
                                                // toast("please wait..");

                                                // currentPosition = await Geolocator
                                                //     .getLastKnownPosition(
                                                //         forceAndroidLocationManager:
                                                //             true);

                                                setState(() {});
                                              } else {
                                                if (locationRequired!) {
                                                  var value =
                                                      await checkUserLocationValidity();
                                                  if (!value) return;
                                                }

                                                if (imageRequired!) {
                                                  List<CameraDescription> localCameras;
                                                  try {
                                                    localCameras = await availableCameras();
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text("Camera access denied")),
                                                    );
                                                    return;
                                                  }

                                                  final result = await Navigator.push<Map<String, dynamic>>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => ImageRecognitionScreen(
                                                        cameras: localCameras, // From standard_app_entry.dart or wherever initialized
                                                        mode: CameraMode.checkIn,
                                                      ),
                                                    ),
                                                  );
                                                  debugPrint('Returned from ImageRecognitionScreen');
                                                  debugPrint('Navigation result: $result');
                                                  final sendRequest = result?['sendRequest'] as bool?;
                                                  if(sendRequest!){
                                                    markAttendanceAPI(sendRequest: true);
                                                    setState(() {
                                                      attendanceSendRequest = true;
                                                    });
                                                  }
                                                  else{
                                                    setState(() {
                                                      attendanceSendRequest = false;
                                                      facePercentage = result?['faceRate'] as int?;
                                                      debugPrint('Extracted facePercentage: $facePercentage');
                                                    });
                                                    debugPrint('Calling markAttendanceAPI with faceRate: $facePercentage');
                                                    markAttendanceAPI(faceRate: facePercentage);
                                                  }
                                                } else {
                                                  markAttendanceAPI();
                                                }
                                              }
                                            } else {
                                              if (imageRequired!) {
                                                List<CameraDescription> localCameras;
                                                try {
                                                  localCameras = await availableCameras();
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text("Camera access denied")),
                                                  );
                                                  return;
                                                }

                                                final result = await Navigator.push<Map<String, dynamic>>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ImageRecognitionScreen(
                                                      cameras: localCameras, // From standard_app_entry.dart or wherever initialized
                                                      mode: CameraMode.checkIn,
                                                    ),
                                                  ),
                                                );
                                                final sendRequest = result?['sendRequest'] as bool?;
                                                if(sendRequest!){
                                                  markAttendanceAPI(sendRequest: true);
                                                  setState(() {
                                                    attendanceSendRequest = true;
                                                  });
                                                }
                                                else{
                                                  setState(() {
                                                    attendanceSendRequest = false;
                                                    facePercentage = result?['faceRate'] as int?;
                                                    debugPrint('Extracted facePercentage: $facePercentage');
                                                  });
                                                  debugPrint('Calling markAttendanceAPI with faceRate: $facePercentage');
                                                  markAttendanceAPI(faceRate: facePercentage);
                                                }
                                              }
                                            }

                                            if (!locationRequired! &&
                                                !imageRequired!) {
                                              markattendancedirect();
                                            }
                                          },
                                          style: ButtonStyle(
                                            padding: WidgetStateProperty.all(
                                                const EdgeInsets.all(15)),
                                            shape: WidgetStateProperty.all(
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10))),
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                              const Color(0xff072a99),
                                            ),
                                            elevation:
                                                WidgetStateProperty.all(8),
                                          ),
                                          child: attendanceRecordStatus ==
                                                  "Submitted"
                                              ? const Text("Check Out")
                                              : const Text("Check In"),
                                        )),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (attendanceloadingOverlay!)
              SizedBox.expand(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xcc072a99),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingAnimationWidget.threeRotatingDots(
                        color: Colors.white70,
                        size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(messageOnScreen ?? "Processing",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )),
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
