import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'get_today_attendance_event.dart';
part 'get_today_attendance_state.dart';

class GetTodayAttendanceBloc
    extends Bloc<GetTodayAttendanceEvent, GetTodayAttendanceState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  GetTodayAttendanceBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(GetTodayAttendanceInitial()) {
    on<GetTodayAttendance>(_onGetTodayAttendance);
  }

  Future<void> _onGetTodayAttendance(
      GetTodayAttendance event, Emitter<GetTodayAttendanceState> emit) async {
    emit(GetTodayAttendanceLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching today attendance for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': '$token', // Assuming Bearer token is required
      };

      final endpoint =
          '${apiUrlConfig.getTodayAttendance}$uid'; // Include UID if required
      print(
          'Endpoint: ${apiUrlConfig.baseUrl}${apiUrlConfig.getTodayAttendance}$uid');

      final response = await apiService.makeRequest(
          endpoint: endpoint, method: 'GET', headers: headers);

      print('API Response: $response');

      if (response['success'] == true) {
        // Handle single object instead of a list
        final attendanceData = response['data']['data'] as List<dynamic>;
        final todayAttendanceData = attendanceData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        emit(GetTodayAttendanceSuccess(attendanceData: todayAttendanceData));
        print('Today Attendance response: $todayAttendanceData');
      } else {
        final String errorMessage = extractErrorMessage(response);
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.toLowerCase().contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          print('Error in marking today attendance: $errorMessage');
          emit(GetTodayAttendanceFailure(errorMessage));
        }
      }
    } catch (e) {
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(GetTodayAttendanceFailure(errorMessage));
    }
  }
}

class GetTodayAttendanceLogsBloc
    extends Bloc<GetTodayAttendanceLogs, GetTodayAttendanceState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  GetTodayAttendanceLogsBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(GetTodayAttendanceInitial()) {
    on<GetTodayAttendanceLogs>(_onGetTodayAttendanceLogs);
  }

  Future<void> _onGetTodayAttendanceLogs(GetTodayAttendanceLogs event,
      Emitter<GetTodayAttendanceState> emit) async {
    emit(GetTodayAttendanceLogsLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching today attendance for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': '$token', // Assuming Bearer token is required
      };

      final endpoint =
          '${apiUrlConfig.getTodayAttendanceLog}$uid'; // Include UID if required
      print(
          'Endpoint: ${apiUrlConfig.baseUrl}${apiUrlConfig.getTodayAttendanceLog}$uid');

      final response = await apiService.makeRequest(
          endpoint: endpoint, method: 'GET', headers: headers);

      print('Get today attendance logs API Response: $response');

      if (response['success'] == true) {
        print('Get today attendance logs api response is true');
        // Handle single object instead of a list
        final attendanceData = response['data']['data'] as List<dynamic>;
        final todayAttendanceData = attendanceData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        emit(
            GetTodayAttendanceLogsSuccess(attendanceData: todayAttendanceData));
        print('Today Attendance Logs response: $todayAttendanceData');
      } else {
        print('Get today attendance logs api response is false');
        final String errorMessage = extractErrorMessage(response);
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.toLowerCase().contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          print('Error in marking today attendance: $errorMessage');
          emit(GetTodayAttendanceLogsFailure(errorMessage));
        }
      }
    } catch (e) {
      print('Exception in fetching today attendance logs: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(GetTodayAttendanceLogsFailure(errorMessage));
    }
  }
}

//Fetch Pending Request Bloc
class GetAllPendingRequestBloc
    extends Bloc<GetAllPendingRequest, GetTodayAttendanceState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  GetAllPendingRequestBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(GetTodayAttendanceInitial()) {
    on<GetAllPendingRequest>(_onGetAllPendingRequest);
  }

  Future<void> _onGetAllPendingRequest(
      GetAllPendingRequest event, Emitter<GetTodayAttendanceState> emit) async {
    emit(GetAllPendingRequestLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;
      print('Fetching all pending requests for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': '$token',
      };

      // Call first API (Past Pending Requests)
      final endpoint1 = apiUrlConfig.getPastPendingRequest;
      print('Endpoint1: ${apiUrlConfig.baseUrl}$endpoint1');
      final response1 = await apiService.makeRequest(
          endpoint: endpoint1, method: 'GET', headers: headers);
      print('Past Pending Request API Response: $response1');

      // Call second API (Pending Requests)
      final endpoint2 = apiUrlConfig.getPendingRequest;
      print('Endpoint2: ${apiUrlConfig.baseUrl}$endpoint2');
      final response2 = await apiService.makeRequest(
          endpoint: endpoint2, method: 'GET', headers: headers);
      print('Pending Request API Response: $response2');

      // Process data from successful APIs only
      List<Map<String, dynamic>> combinedData = [];
      bool hasValidData = false;

      // Process API 1: Past Pending Requests (if successful)
      if (response1['success'] == true) {
        try {
          final pastDataList = response1['data']['data'] as List<dynamic>;
          final pastPendingData = pastDataList
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) => item['employee_id'] == 20)
              .toList();
          print(
              'Past Pending Data (filtered for employee_id=20): ${pastPendingData.length} items');

          if (pastPendingData.isNotEmpty) {
            combinedData.addAll(pastPendingData);
            hasValidData = true;
          }
        } catch (e) {
          print('Error processing API 1 data: $e');
        }
      }

      // Process API 2: Pending Requests (if successful)
      if (response2['success'] == true) {
        try {
          final pendingDataList = response2['data']['data'] as List<dynamic>;
          final pendingData = pendingDataList
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) => item['employee_id'] == 20)
              .toList();
          print(
              'Pending Data (filtered for employee_id=20): ${pendingData.length} items');

          if (pendingData.isNotEmpty) {
            combinedData.addAll(pendingData);
            hasValidData = true;
          }
        } catch (e) {
          print('Error processing API 2 data: $e');
        }
      }

      // Emit success if AT LEAST ONE API has valid data
      if (hasValidData) {
        print(
            'Combined Pending Requests: ${combinedData.length} items from successful API(s)');
        emit(GetAllPendingRequestSuccess(pendingRequestData: combinedData));
      } else {
        // No valid data from either API - check for session errors
        print('No valid data from either API');
        _handleApiErrors(response1, response2);
        emit(GetAllPendingRequestFailure('No pending requests found'));
      }
    } catch (e) {
      print('Exception in fetching pending requests: $e');
      String errorMessage = "An unexpected error occurred";
      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(GetAllPendingRequestFailure(errorMessage));
    }
  }

  /// Handle session and user errors from API responses
  void _handleApiErrors(
      Map<String, dynamic> response1, Map<String, dynamic> response2) {
    final errorMsg1 = extractErrorMessage(response1);
    final errorMsg2 = extractErrorMessage(response2);

    // Check for session errors in either response
    if (errorMsg1.toLowerCase().contains('invalid token') ||
        errorMsg1.toLowerCase().contains('session expired') ||
        errorMsg2.toLowerCase().contains('invalid token') ||
        errorMsg2.toLowerCase().contains('session expired')) {
      sessionBloc.add(SessionExpired());
      print('Session expired: $errorMsg1 / $errorMsg2');
    } else if (errorMsg1.toLowerCase().contains('User not found') ||
        errorMsg2.toLowerCase().contains('User not found')) {
      sessionBloc.add(UserNotFound());
      print('User not found: $errorMsg1 / $errorMsg2');
    }
  }
}

// Request Today attendance bloc
class RequTodayAttendanceBloc
    extends Bloc<RequTodayAttendanceEvent, RequTodayAttendanceState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  RequTodayAttendanceBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(
          RequTodayAttendanceInitial(),
        ) {
    on<RequTodayAttendance>(_RequTodayAttendance);
  }

  Future<void> _RequTodayAttendance(
      RequTodayAttendance event, Emitter<RequTodayAttendanceState> emit) async {
    emit(RequTodayAttendanceLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching  Requ today attendance for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': '$token', // Assuming Bearer token is Required
      };

      final endpoint =
          '${apiUrlConfig.requTodayAttendance}$uid'; // Include UID if Requuired
      print(
          'Endpoint: ${apiUrlConfig.baseUrl}${apiUrlConfig.requTodayAttendance}$uid');

      final response = await apiService.makeRequest(
          endpoint: endpoint, method: 'GET', headers: headers);

      print('API Response: $response');

      if (response['success'] == true) {
        // Handle single object instead of a list
        final requAttendanceData = response['data']['data'] as List<dynamic>;
        final requTodayAttendanceData = requAttendanceData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        emit(RequTodayAttendanceSuccess(
            requAttendanceData: requTodayAttendanceData));
        print('Requ Today Attendance response: $requTodayAttendanceData');
      } else {
        final String errorMessage = extractErrorMessage(response);
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.toLowerCase().contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          print('Error in marking today attendance: $errorMessage');
          emit(RequTodayAttendanceFailure(errorMessage));
        }
      }
    } catch (e) {
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(RequTodayAttendanceFailure(errorMessage));
    }
  }
}

String extractErrorMessage(Map<String, dynamic> response) {
  try {
    final message = response['message'];
    if (message != null && message is String && message.trim().isNotEmpty) {
      // Check if the message contains a JSON string (e.g., starts with '{')
      if (message.contains('{') && message.contains('}')) {
        // Extract the JSON part by removing the prefix (e.g., "Error: 400 - ")
        final jsonStartIndex = message.indexOf('{');
        final jsonString = message.substring(jsonStartIndex);
        // Parse the JSON string
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        // Extract the inner 'message' field
        final innerMessage = jsonData['message'];
        if (innerMessage != null &&
            innerMessage is String &&
            innerMessage.trim().isNotEmpty) {
          return innerMessage.trim();
        }
      }
      // Fallback to the full message if no JSON or inner message found
      return message.toString().replaceAll('\n', ' ').trim();
    }
  } catch (e) {
    print('Error parsing error message: $e');
  }
  return "An unexpected error occurs";
}
