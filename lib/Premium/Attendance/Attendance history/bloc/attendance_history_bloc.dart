import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'dart:convert';

import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'attendance_history_event.dart';
part 'attendance_history_state.dart';

class AttendanceHistoryBloc
    extends Bloc<AttendanceHistoryEvent, AttendanceHistoryState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  AttendanceHistoryBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(AttendanceHistoryInitial()) {
    on<FetchAttendanceHistory>(_onFetchAttendanceHistory);
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

  Future<void> _onFetchAttendanceHistory(FetchAttendanceHistory event,
      Emitter<AttendanceHistoryState> emit) async {
    emit(AttendanceHistoryLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      if (uid == null || token == null) {
        sessionBloc.add(SessionExpired());
        emit(AttendanceHistoryFailure(
            errorMessage: 'Your session has expired. Please log in again.'));
        print('Invalid UID or Token: UID=$uid, Token=$token');
        return;
      }

      print('Fetching attendance history for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization':
            'Bearer $token', // Ensure Bearer token format if required
      };

      final endpoint = '${apiUrlConfig.showAttendanceHistoryPath}$uid';
      print('Endpoint: ${apiUrlConfig.baseUrl}$endpoint');

      final response = await apiService.makeRequest(
        endpoint: endpoint,
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      if (response['success'] == true) {
// Validate the structure of the response
        if (response['data'] == null || response['data']['data'] == null) {
          print('Invalid response structure: Missing data field');
          emit(AttendanceHistorySuccess(attendanceHistory: []));
          return;
        }

// Ensure data is a list
        if (response['data']['data'] is! List<dynamic>) {
          print(
              'Invalid data format: Expected a list, got ${response['data']['data'].runtimeType}');
          emit(AttendanceHistoryFailure(
              errorMessage:
                  'Unable to load attendance data. Please try again later.'));
          return;
        }

        final attendanceHistory = response['data']['data'] as List<dynamic>;
        final attendanceHistoryData = attendanceHistory
            .map((item) {
              try {
                return Map<String, dynamic>.from(item);
              } catch (e) {
                print('Error parsing item: $item, Error: $e');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<Map<String, dynamic>>()
            .toList();

        if (attendanceHistoryData.isNotEmpty) {
          emit(AttendanceHistorySuccess(
              attendanceHistory: attendanceHistoryData));
          print('Attendance History response: $attendanceHistoryData');
        } else {
          emit(AttendanceHistorySuccess(attendanceHistory: []));
          print(
              'No valid attendance history data returned, emitting success with empty list');
        }
      } else {
        final String backendMessage = extractErrorMessage(response);
        if (backendMessage.toLowerCase().contains('invalid token') ||
            backendMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $backendMessage');
        } else if (backendMessage.toLowerCase().contains('user not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $backendMessage');
        }
        print('Error in fetching attendance history: $backendMessage');
        emit(AttendanceHistoryFailure(errorMessage: backendMessage));
      }
    } catch (e) {
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(AttendanceHistoryFailure(errorMessage: errorMessage));
    }
  }
}
