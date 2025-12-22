import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';

import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../Get Today Attendance/bloc/get_today_attendance_bloc.dart';

part 'req_today_attendance_event.dart';
part 'req_today_attendance_state.dart';

class ReqTodayAttendanceBloc
    extends Bloc<ReqTodayAttendanceEvent, ReqTodayAttendanceState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ReqTodayAttendanceBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(ReqTodayAttendanceInitial()) {
    on<RequestTodayAttendance>(_onRequestTodayAttendance);
  }

  Future<void> _onRequestTodayAttendance(
    RequestTodayAttendance event,
    Emitter<ReqTodayAttendanceState> emit,
  ) async {
    debugPrint("===== ReqTodayAttendanceBloc START =====");
    emit(ReqTodayAttendanceLoading());
    debugPrint("State: Loading");

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;
      debugPrint("User ID: $uid");
      debugPrint("Token: $token");

      final Map<String, String> headers = {'Authorization': 'Bearer $token'};
      debugPrint("Headers: $headers");

      late String endpoint;
      late Map<String, String> formData;
      Map<String, File>? files;
      List<String>? fileFieldNames;

      if (event.isCheckIn) {
        debugPrint("Action: Check-In");
        endpoint = apiUrlConfig.reqTodayAttendancePath;
        formData = {
          'employee_id': uid ?? '',
          'lat': event.latitude,
          'lng': event.longitude,
          'attendance_date': event.attendanceDate!,
          'check_in_time': event.checkInTime!,
        };
        debugPrint("FormData (Check-In): $formData");

        if (event.imageBase != null) {
          files = {'employee_image': event.imageBase!};
          fileFieldNames = ['employee_image'];
          debugPrint("Files attached: ${files.keys}");
        }
      } else {
        debugPrint("Action: Check-Out");
        endpoint = apiUrlConfig.reqTodayAttendancePath;
        formData = {
          'employee_id': uid ?? '',
          'lat': event.latitude,
          'lng': event.longitude,
          'check_out_time': event.checkOutTime!,
        };
        debugPrint("FormData (Check-Out): $formData");

        if (event.imageBase != null) {
          files = {'employee_image': event.imageBase!};
          fileFieldNames = ['employee_image'];
          debugPrint("Files attached: ${files.keys}");
        }
      }

      debugPrint("Making multipart request to: $endpoint");
      final response = await apiService.makeMultipartRequest(
        endpoint: endpoint,
        method: 'POST',
        headers: headers,
        formData: formData,
        files: files,
        fileFieldNames: fileFieldNames,
      );
      debugPrint("Response received: $response");

      if (response['success'] == true) {
        debugPrint("Attendance request SUCCESS");
        emit(ReqTodayAttendanceSuccess(responseData: response['data']));
      } else {
        final String errorMessage = extractErrorMessage(response);
        debugPrint("Attendance request FAILURE: $errorMessage");

        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          debugPrint(
              "Session expired detected. Dispatching SessionExpired event");
          sessionBloc.add(SessionExpired());
        } else {
          emit(ReqTodayAttendanceFailure(message: errorMessage));
        }
      }
    } catch (e) {
      String errorMessage = "An unexpected error occurs";
      debugPrint("Exception caught: $e");

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      debugPrint("Emitting ReqTodayAttendanceFailure: $errorMessage");
      emit(ReqTodayAttendanceFailure(message: errorMessage));
    }
  }
}
