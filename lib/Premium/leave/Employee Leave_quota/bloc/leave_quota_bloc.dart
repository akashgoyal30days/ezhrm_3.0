import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'leave_quota_event.dart';
part 'leave_quota_state.dart';

class LeaveQuotaBloc extends Bloc<LeaveQuotaEvent, LeaveQuotaState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  LeaveQuotaBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(LeaveQuotaInitial()) {
    on<FetchEmployeeLeaveQuota>(_onFetchLeaveQuota);
  }

  Future<void> _onFetchLeaveQuota(
      FetchEmployeeLeaveQuota event, Emitter<LeaveQuotaState> emit) async {
    emit(LeaveQuotaLoading()); // Emit loading state

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching leave quota for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      // Call the API to fetch leave quota
      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.getEmployeeLeaveQuotaPath}$uid',
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Extract the leave quota list from response['data']['data']
        final leaveQuotaData = response['data']['data'] as List<dynamic>;

        // Convert List<dynamic> to List<Map<String, dynamic>>
        final leaveQuotaList = leaveQuotaData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        emit(LeaveQuotaSuccess(employeeLeaveQuota: leaveQuotaList));
        print('Leave quota fetched successfully: $leaveQuotaList');
      } else {
        // Check for 404-specific error
        final String errorMessage = extractErrorMessage(response);
        if (response['status'] == 404 ||
            response['message']?.toLowerCase().contains('no leave quota') ==
                true) {
          emit(LeaveQuotaNoData()); // Emit custom state for no leave quota
          print('No leave quota assigned to user');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else {
          print('Error in fetching leave quota: $errorMessage');
          emit(LeaveQuotaFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Leave quota Fetch Exception: $e');
      // Check if the exception indicates a 404 error (depends on ApiService implementation)
      if (e.toString().contains('404')) {
        emit(LeaveQuotaNoData());
        print('No leave quota assigned to user (exception)');
      } else if (e.toString().toLowerCase().contains('token') ||
          e.toString().toLowerCase().contains('session expired')) {
        sessionBloc.add(SessionExpired());
      } else if (e.toString().contains('User not found')) {
        sessionBloc.add(UserNotFound());
        print('User not found: $e');
      } else {
        emit(LeaveQuotaFailure(errorMessage: 'Error in fetching leave quota'));
      }
    }
  }
}
