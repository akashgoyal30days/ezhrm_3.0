import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'get_leave_quota_event.dart';
part 'get_leave_quota_state.dart';

class GetLeaveQuotaBloc extends Bloc<GetLeaveQuotaEvent, GetLeaveQuotaState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  GetLeaveQuotaBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(GetLeaveQuotaInitial()) {
    on<FetchLeaveQuota>(_onFetchLeaveQuota);
  }

  Future<void> _onFetchLeaveQuota(
      FetchLeaveQuota event, Emitter<GetLeaveQuotaState> emit) async {
    emit(GetLeaveQuotaLoading()); // Emit loading state

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching types leave quota for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      // Call the API to fetch holidays
      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.getLeaveTypesPath,
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Extract the holidays list from response['data']['data']
        final leaveQuotaData = response['data']['data'] as List<dynamic>;

        // Convert List<dynamic> to List<Map<String, dynamic>>
        final leaveQuotaList = leaveQuotaData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        emit(GetLeaveQuotaSuccess(getLeaveQuota: leaveQuotaList));
        print('types of Leave fetched successfully: $leaveQuotaList');
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
          print('Failed to fetch leave quota: $errorMessage');
          emit(GetLeaveQuotaFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('exception in fetching types of leaves: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(GetLeaveQuotaFailure(errorMessage: errorMessage));
    }
  }
}
