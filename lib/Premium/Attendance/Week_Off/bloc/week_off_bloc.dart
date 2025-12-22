import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';

import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../Get Today Attendance/bloc/get_today_attendance_bloc.dart';

part 'week_off_event.dart';
part 'week_off_state.dart';

class WeekOffBloc extends Bloc<WeekOffEvent, WeekOffState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  WeekOffBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(WeekOffInitial()) {
    on<GetWeekOff>(_onGetWeekOff);
    on<GetEmployeeWeekOff>(_onGetEmployeeWeekOff);
  }

  Future<void> _onGetWeekOff(
      GetWeekOff event, Emitter<WeekOffState> emit) async {
    emit(WeekOffLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching week off for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': '$token', // Assuming Bearer token is required
      };

      final endpoint = apiUrlConfig.getWeekOffPath; // Include UID if required
      print('Endpoint: ${apiUrlConfig.baseUrl}${apiUrlConfig.getWeekOffPath}');

      final response = await apiService.makeRequest(
          endpoint: endpoint, method: 'GET', headers: headers);

      print('API Response: $response');

      if (response['success'] == true) {
        // Handle single object instead of a list
        final weekOffData = response['data']['data'] as List<dynamic>;
        final weekOffResponseData =
            weekOffData.map((item) => Map<String, dynamic>.from(item)).toList();
        if (weekOffResponseData.isNotEmpty) {
          emit(WeekOffSuccess(weekOffData: weekOffResponseData));
          print('week off response: $weekOffResponseData');
        } else {
          emit(WeekOffSuccess(weekOffData: []));
          print('week off response: []');
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
          print('Error in fetching week off: $errorMessage');
          emit(WeekOffFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Exception in fetching week off: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(WeekOffFailure(errorMessage: errorMessage));
    }
  }

  Future<void> _onGetEmployeeWeekOff(
      GetEmployeeWeekOff event, Emitter<WeekOffState> emit) async {
    emit(WeekOffLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching employee week off for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': '$token', // Assuming Bearer token is required
      };

      final endpoint =
          '${apiUrlConfig.getWeekOffPath}$uid'; // Include UID if required
      print(
          'Endpoint: ${apiUrlConfig.baseUrl}${apiUrlConfig.getWeekOffPath}$uid');

      final response = await apiService.makeRequest(
          endpoint: endpoint, method: 'GET', headers: headers);

      print('API Response: $response');

      if (response['success'] == true) {
        // Handle single object instead of a list
        final employeeWeekOffData = response['data']['data'] as List<dynamic>;
        final employeeWeekOffResponseData = employeeWeekOffData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        if (employeeWeekOffResponseData.isNotEmpty) {
          emit(EmployeeWeekOffSuccess(
              employeeWeekOffData: employeeWeekOffResponseData));
          print('employee week off response: $employeeWeekOffResponseData');
        } else {
          emit(EmployeeWeekOffSuccess(employeeWeekOffData: []));
          print('employee week off response: []');
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
          print('Error in fetching employee week off: $errorMessage');
          emit(EmployeeWeekOffFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Exception in fetching employee week off: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(EmployeeWeekOffFailure(errorMessage: errorMessage));
    }
  }
}
