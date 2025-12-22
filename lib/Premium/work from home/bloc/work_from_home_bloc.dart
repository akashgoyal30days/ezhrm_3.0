import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'work_from_home_event.dart';
part 'work_from_home_state.dart';

class WorkFromHomeBloc extends Bloc<WorkFromHomeEvent, WorkFromHomeState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  WorkFromHomeBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(WorkFromHomeInitial()) {
    on<RequestWorkFromHome>(_onRequestWorkFromHome);
    on<GetWorkFromHome>(_onGetWorkFromHome);
  }

  Future<void> _onRequestWorkFromHome(
      RequestWorkFromHome event, Emitter<WorkFromHomeState> emit) async {
    emit(RequestWorkFromHomeLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Request work from home for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      };

      final body = {
        'employee_id': uid,
        'start_date': event.start_date,
        'end_date': event.end_date,
        'reason': event.reason
      };

      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.requestWorkFromHomePath,
        method: 'POST',
        headers: headers,
        body: body,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        // Expect a single Map<String, dynamic> instead of a List
        final requestWorkFromHomeData =
            response['data']['data'] as Map<String, dynamic>;
        // Wrap it in a list for consistency with the state
        final workFromHomeResponse = [requestWorkFromHomeData];
        emit(RequestWorkFromHomeSuccess(response: workFromHomeResponse));
        print('work from home request successful: $workFromHomeResponse');
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
          emit(RequestWorkFromHomeFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('work from home request Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      } else {
        emit(RequestWorkFromHomeFailure(
            errorMessage: 'Error in marking today attendance: $e'));
      }
    }
  }

  Future<void> _onGetWorkFromHome(
      GetWorkFromHome event, Emitter<WorkFromHomeState> emit) async {
    emit(RequestWorkFromHomeLoading());

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching work from home details for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': 'Bearer ${token ?? ''}', // Added Bearer prefix
      };

      // Call the API to fetch profile (assuming a GET request)
      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.getWorkFromHome}$uid',
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Assuming the API returns profile data under 'data.data'
        final wfhData = response['data']['data'] as List<dynamic>;
        // Wrap the single Map in a List
        final wfhResponse =
            wfhData.map((item) => Map<String, dynamic>.from(item)).toList();
        emit(GetWorkFromHomeSuccess(response: wfhResponse));
        print('Work from home data fetched successfully: $wfhResponse');
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
          print('Failed to fetch work from home data: $errorMessage');
          emit(GetWorkFromHomeFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Work from home data Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      } else {
        emit(GetWorkFromHomeFailure(errorMessage: errorMessage));
      }
    }
  }
}
