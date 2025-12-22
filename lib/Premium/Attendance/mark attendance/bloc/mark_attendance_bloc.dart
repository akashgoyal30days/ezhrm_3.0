import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../Get Today Attendance/bloc/get_today_attendance_bloc.dart';

part 'mark_attendance_event.dart';
part 'mark_attendance_state.dart';

class MarkAttendanceBloc
    extends Bloc<MarkAttendanceEvent, MarkAttendanceState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final GetTodayAttendanceBloc getTodayAttendanceBloc;
  final SessionBloc sessionBloc;

  MarkAttendanceBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.getTodayAttendanceBloc,
      required this.sessionBloc})
      : super(MarkAttendanceInitial()) {
    on<MarkAttendance>(_onMarkAttendance);
  }

  Future<void> _onMarkAttendance(
      MarkAttendance event, Emitter<MarkAttendanceState> emit) async {
    emit(MarkAttendanceLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('mark today attendance for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': '$token', // Assuming Bearer token is required
      };

      final endpoint =
          apiUrlConfig.markTodayAttendance; // Include UID if required
      print(
          'Endpoint: ${apiUrlConfig.baseUrl}${apiUrlConfig.markTodayAttendance}');

      final body = {
        'employee_id': uid,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'face_recognition': event.faceRate,
      };

      print('body $body');
      final response = await apiService.makeRequest(
          endpoint: endpoint, method: 'POST', headers: headers, body: body);

      print('API Response: $response');

      if (response['success'] == true) {
        // Handle single object instead of a list
        final attendanceMessage = response['data']['message'];
        emit(MarkAttendanceSuccess(message: attendanceMessage));
        getTodayAttendanceBloc.add(GetTodayAttendance());
        print('Today Attendance response: $attendanceMessage');
      } else {
        final String errorMessage = extractErrorMessage(response);
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          print('Error in marking today attendance: $errorMessage');
          emit(MarkAttendanceFailure(errorMessage: errorMessage));
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
      emit(MarkAttendanceFailure(errorMessage: errorMessage));
    }
  }
}
