import 'dart:convert'; // Added for JSON parsing

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'apply_loan_event.dart';
part 'apply_loan_state.dart';

class ApplyLoanBloc extends Bloc<ApplyLoanEvent, ApplyLoanState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ApplyLoanBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(ApplyLoanInitial()) {
    on<ApplyLoan>(_onApplyLoan);
    on<GetApplyLoan>(_onGetApplyLoan);
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

  Future<void> _onGetApplyLoan(
      GetApplyLoan event, Emitter<ApplyLoanState> emit) async {
    emit(ApplyLoanLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      if (uid == null || token == null) {
        sessionBloc.add(SessionExpired());
        emit(GetApplyLoanFailure(
            errorMessage: 'Invalid session. Please log in again.'));
        return;
      }

      print('Fetching loan data for UID: $uid');

      final Map<String, String> headers = {
        'Authorization': token,
      };

      final endpoint = '${apiUrlConfig.getApplyLoan}$uid';
      print('Endpoint: ${apiUrlConfig.baseUrl}$endpoint');

      final response = await apiService.makeRequest(
        endpoint: endpoint,
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        final applyLoan = response['data']['data'] as List<dynamic>?;
        if (applyLoan != null && applyLoan.isNotEmpty) {
          final applyLoanData =
              applyLoan.map((item) => Map<String, dynamic>.from(item)).toList();
          emit(GetApplyLoanSuccess(getApplyLoan: applyLoanData));
          print('Loan data retrieved: $applyLoanData');
          return;
        } else {
          emit(GetApplyLoanSuccess(getApplyLoan: []));
          print('No loan data available');
          return;
        }
      }

      final String rawMessage = response['message'] ?? "";
      String message = rawMessage;

      debugPrint('Raw backend message: $rawMessage');

// Extract inner JSON if present
      if (rawMessage.contains("{")) {
        try {
          final jsonString = rawMessage.substring(rawMessage.indexOf("{"));
          final parsedJson = jsonDecode(jsonString);

          if (parsedJson is Map && parsedJson.containsKey("message")) {
            message = parsedJson["message"];
          }
        } catch (e) {
          debugPrint("Error parsing inner message: $e");
        }
      }

      debugPrint("Processed message: $message");

// Now check correctly
      if (message == "No loan records found for this employee") {
        emit(GetApplyLoanSuccess(getApplyLoan: []));
        print("Handled: No loan records found → Returning empty list");
        return;
      }

      final String errorMessage = extractErrorMessage(response);
      emit(GetApplyLoanFailure(errorMessage: errorMessage));
    } catch (e) {
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(GetApplyLoanFailure(errorMessage: errorMessage));
    }
  }

  Future<void> _onApplyLoan(
      ApplyLoan event, Emitter<ApplyLoanState> emit) async {
    emit(ApplyLoanLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      if (uid == null || token == null) {
        sessionBloc.add(SessionExpired());
        emit(ApplyLoanFailure(
            errorMessage: 'Invalid session. Please log in again.'));
        return;
      }

      print('Applying loan for UID: $uid');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      final endpoint = apiUrlConfig.applyLoan;
      print('Endpoint: ${apiUrlConfig.baseUrl}$endpoint');

      final body = {
        'loan_amount': event.loan_amount,
        'employee_id': uid,
        'emi_amount': event.emi_amount,
      };

      final response = await apiService.makeRequest(
        endpoint: endpoint,
        method: 'POST',
        headers: headers,
        body: body,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        final message =
            response['data']['message'] ?? 'Loan applied successfully';
        emit(ApplyLoanSuccess(message: 'Loan applied successfully'));
        print('Loan applied: $message');
        add(GetApplyLoan()); // Refresh loan data
      } else {
        final String errorMessage = extractErrorMessage(response);
        emit(ApplyLoanFailure(errorMessage: errorMessage));
      }
    } catch (e) {
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(ApplyLoanFailure(errorMessage: errorMessage));
    }
  }
}
