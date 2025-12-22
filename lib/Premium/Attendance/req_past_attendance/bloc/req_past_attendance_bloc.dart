import 'package:bloc/bloc.dart';

import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../Get Today Attendance/bloc/get_today_attendance_bloc.dart';

part 'req_past_attendance_event.dart';
part 'req_past_attendance_state.dart';

class ReqPastAttendanceBloc
    extends Bloc<ReqPastAttendanceEvent, ReqPastAttendanceState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ReqPastAttendanceBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(ReqPastAttendanceInitial()) {
    on<ReqPastAttendance>(_onReqPastAttendance);
    on<ReqPastAttendanceHistory>(_onReqPastAttendanceHistory);
  }

  Future<void> _onReqPastAttendance(
      ReqPastAttendance event, Emitter<ReqPastAttendanceState> emit) async {
    emit(ReqPastAttendanceLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Requesting attendance for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Fixed: Added 'Bearer' prefix
      };

      final body = {
        "employee_id": uid,
        "attendance_date": event.attendance_date,
        "attendance_upto": event.attendance_upto,
        "remarks": event.remarks,
        "latitude": event.latitude,
        "longitude": event.longitude,
        if (event.imageBase != null)
          "image": event.imageBase, // Include image if provided
      };

      final endpoint = apiUrlConfig.reqPastAttendancePath;
      print('Endpoint: $endpoint');
      print('Request Body: $body');

      final response = await apiService.makeRequest(
        endpoint: endpoint,
        method: 'POST',
        headers: headers,
        body: body,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        final reqPastAttendance = response['data']['data'] as List<dynamic>;
        final reqAttendance = reqPastAttendance
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        emit(ReqPastAttendanceSuccess(responseData: reqAttendance));
        ReqPastAttendanceHistory();
        print('Req past attendance response: $reqAttendance');
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
          print('Error in Requesting past attendance: $errorMessage');
          emit(ReqPastAttendanceFailure(message: errorMessage));
        }
      }
    } catch (e) {
      print('Exception in Requesting past attendance: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(ReqPastAttendanceFailure(message: errorMessage));
    }
  }

  Future<void> _onReqPastAttendanceHistory(ReqPastAttendanceHistory event, Emitter<ReqPastAttendanceState> emit) async {
    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Get request attendance history data for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': '$token', // Assuming Bearer token is required
      };

      final endpoint = '${apiUrlConfig.getPastPendingRequest}$uid'; // Include UID if required
      print(
          'Endpoint: ${apiUrlConfig.baseUrl}${apiUrlConfig.getPastPendingRequest}$uid');

      final response = await apiService.makeRequest(
          endpoint: endpoint, method: 'GET', headers: headers);

      print('API Response: $response');

      if (response['success'] == true) {
        // Handle single object instead of a list
        final pastPendingRequest = response['data']['data'] as List<dynamic>?;
        if (pastPendingRequest != null) {
          final pastRequestData = [pastPendingRequest];
          emit(ReqPastAttendanceHistorySuccess(
              responseData: pastPendingRequest.cast<Map<String, dynamic>>()));
          print('past attendance data : $pastRequestData');
        } else {
          emit(ReqPastAttendanceHistorySuccess(responseData: []));
          print(
              'No request past attendance data returned, emitting success with empty list');
        }
      } else {
        final String errorMessage = 'Error in getting past request attendance data';
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        }

        String backendMessage = extractErrorMessage(response);
        emit(ReqPastAttendanceHistoryFailure(message: backendMessage));
        print('Error in getting past request attendance data: $errorMessage');
      }
    } catch (e) {
      print('Exception in getting past request attendance data: $e');
      if (e.toString().toLowerCase().contains('token') ||
          e.toString().toLowerCase().contains('session expired')) {
        sessionBloc.add(SessionExpired());
      } else {
        String errorMessage = "An unexpected error occurs";
        if (e.toString().contains("SocketException") ||
            e.toString().contains("Failed host lookup")) {
          errorMessage = "Please check your internet connection.";
        } else if (e.toString().contains("TimeoutException")) {
          errorMessage =
          "The server took too long to respond. Try again later.";
        }
        emit(ReqPastAttendanceHistoryFailure(message: errorMessage));
      }
    }
  }
}
