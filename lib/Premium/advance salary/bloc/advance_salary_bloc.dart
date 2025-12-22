import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'advance_salary_event.dart';
part 'advance_salary_state.dart';

class AdvanceSalaryBloc extends Bloc<AdvanceSalaryEvent, AdvanceSalaryState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  AdvanceSalaryBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(AdvanceSalaryInitial()) {
    on<AdvanceSalary>(_onAdvanceSalary);
    on<GetAdvanceSalary>(_onGetAdvanceSalary);
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

  Future<void> _onGetAdvanceSalary(
      GetAdvanceSalary event, Emitter<AdvanceSalaryState> emit) async {
    emit(AdvanceSalaryLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Get advance salary for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': '$token', // Assuming Bearer token is required
      };

      final endpoint =
          '${apiUrlConfig.getAdvanceSalary}$uid'; // Include UID if required
      print(
          'Endpoint: ${apiUrlConfig.baseUrl}${apiUrlConfig.getAdvanceSalary}$uid');

      final response = await apiService.makeRequest(
          endpoint: endpoint, method: 'GET', headers: headers);

      print('API Response: $response');

      if (response['success'] == true) {
        // Handle single object instead of a list
        final advanceSalary = response['data']['data'] as List<dynamic>?;
        if (advanceSalary != null) {
          final advanceSalaryData = [advanceSalary];
          emit(GetAdvanceSalarySuccess(
              advanceSalary: advanceSalary.cast<Map<String, dynamic>>()));
          print('advance salary data : $advanceSalaryData');
        } else {
          emit(GetAdvanceSalarySuccess(advanceSalary: []));
          print(
              'No advance salary data returned, emitting success with empty list');
        }
      } else {
        final String errorMessage = 'Error in getting advance salary data';
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        }

        String backendMessage = extractErrorMessage(response);
        emit(GetAdvanceSalaryFailure(errorMessage: backendMessage));
        print('Error in getting advance salary data: $errorMessage');
      }
    } catch (e) {
      print('Exception in getting advance salary data: $e');
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
        emit(GetAdvanceSalaryFailure(errorMessage: errorMessage));
      }
    }
  }

  Future<void> _onAdvanceSalary(
      AdvanceSalary event, Emitter<AdvanceSalaryState> emit) async {
    emit(AdvanceSalaryLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('applying advance salary for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': '$token', // Assuming Bearer token is required
      };

      final endpoint =
          apiUrlConfig.applyAdvanceSalary; // Include UID if required
      print(
          'Endpoint: ${apiUrlConfig.baseUrl}${apiUrlConfig.applyAdvanceSalary}');

      final body = {
        'advance_amount': event.advance_amount,
        'employee_id': uid,
        'month': event.month,
        'remarks': event.remarks
      };
      final response = await apiService.makeRequest(
          endpoint: endpoint, method: 'POST', headers: headers, body: body);

      print('API Response: $response');

      if (response['success'] == true) {
        // Handle single object instead of a list
        final message = response['data']['message'];

        if (message == '"Advance salary created successfully') {
          print('Advance salary applied successfully : $message');
          emit(AdvanceSalarySuccess(
              message: 'Advance salary applied successfully'));
          add(GetAdvanceSalary());
        } else {
          print('Different response: $message');
          emit(AdvanceSalarySuccess(
              message: 'Advance salary applied successfully'));
          add(GetAdvanceSalary());
        }
      } else {
        final String errorMessage = 'Error in applying advance salary';
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print(AdvanceSalaryFailure(errorMessage: errorMessage));
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          String backendMessage = extractErrorMessage(response);
          emit(AdvanceSalaryFailure(errorMessage: backendMessage));
          print('Error in applying advance salary: $errorMessage');
        }
      }
    } catch (e) {
      print('Exception in applying advance salary: $e');
      if (e.toString().toLowerCase().contains('token') ||
          e.toString().toLowerCase().contains('session expired')) {
        sessionBloc.add(SessionExpired());
      } else if (e.toString().contains('User not found')) {
        sessionBloc.add(UserNotFound());
        print('User not found: $e');
      } else {
        String errorMessage = "An unexpected error occurs";

        if (e.toString().contains("SocketException") ||
            e.toString().contains("Failed host lookup")) {
          errorMessage = "Please check your internet connection.";
        } else if (e.toString().contains("TimeoutException")) {
          errorMessage =
              "The server took too long to respond. Try again later.";
        }
        emit(AdvanceSalaryFailure(errorMessage: errorMessage));
      }
    }
  }
}
