import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'work_reporting_event.dart';
part 'work_reporting_state.dart';

class WorkReportingBloc extends Bloc<WorkReportingEvent, WorkReportingState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  WorkReportingBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(WorkReportingInitial()) {
    on<GetWorkReporting>(_onGetWorkReporting);
    on<UpdateWorkReporting>(_onUpdateWorkReporting);
  }

  Future<void> _onGetWorkReporting(
      GetWorkReporting event, Emitter<WorkReportingState> emit) async {
    emit(WorkReportingLoading()); // Emit loading state

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching work reporting for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      // Call the API to fetch work reporting
      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.getWorkReporting}$uid',
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Extract the data field
        final data = response['data']['data'];

        if (data == null) {
          // Handle null data case
          emit(WorkReportingSuccess(workReporting: []));
          print('Work reporting fetched successfully: no tasks found');
        } else {
          // Convert to Map<String, dynamic>
          final workReportingData = data as Map<String, dynamic>;
          // Convert to List<Map<String, dynamic>> for consistency
          final workReporting = [workReportingData];
          emit(WorkReportingSuccess(workReporting: workReporting));
          print('Work reporting fetched successfully: $workReporting');
        }
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
          print('Failed to fetch work reporting: $errorMessage');
          emit(WorkReportingFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('work reporting Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(WorkReportingFailure(errorMessage: errorMessage));
    }
  }

  Future<void> _onUpdateWorkReporting(
      UpdateWorkReporting event, Emitter<WorkReportingState> emit) async {
    emit(WorkReportingLoading()); // Emit loading state

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Update work reporting for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      final body = {
        'todayplan': event.todayplan,
        'todaycompletework':
            event.todaycompletework.isNotEmpty ? event.todaycompletework : [''],
        'nextdayplanning':
            event.nextdayplanning.isNotEmpty ? event.nextdayplanning : [''],
      };

      print('body is $body');
      print(
          'endpoint is this ${apiUrlConfig.updateWorkReporting}${event.taskId}');
      // Call the API to fetch holidays
      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.updateWorkReporting}${event.taskId}',
        method: 'PUT',
        body: body,
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Extract the holidays list from response['data']['data']
        final updateWorkReportingResponseData =
            response['data']['data'] as Map<String, dynamic>;

        // Convert List<dynamic> to List<Map<String, dynamic>>
        final updateWorkReporting = [updateWorkReportingResponseData];

        emit(UpdateWorkReportingSuccess(
            updateWorkReporting: updateWorkReporting));
        add(GetWorkReporting());
        print('Update Work reporting successfully: $updateWorkReporting');
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
          print('Failed to update Work reporting: $errorMessage');
          emit(UpdateWorkReportingFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('work reporting update Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(UpdateWorkReportingFailure(errorMessage: errorMessage));
    }
  }
}
