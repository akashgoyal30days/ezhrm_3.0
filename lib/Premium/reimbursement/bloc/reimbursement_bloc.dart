import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'reimbursement_event.dart';
part 'reimbursement_state.dart';

class ReimbursementBloc extends Bloc<ReimbursementEvent, ReimbursementState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ReimbursementBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(ReimbursementInitial()) {
    on<AddReimbursement>(_onAddReimbursement);
    on<GetReimbursment>(_onGetReimbursment);
  }

  Future<void> _onAddReimbursement(
      AddReimbursement event, Emitter<ReimbursementState> emit) async {
    emit(ReimbursementLoading()); // Emit loading state

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Adding reimbursement for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      final formData = {
        'employee_id':
            uid ?? '', // Use null-coalescing operator to ensure non-null String
        'date': event.date,
        'amount': event.amount,
        'expense_against_id': event.expense_against_id,
        'description': event.description,
        'expense_client_id': event.expense_client_id,
      };

      print('date is ${event.date}');
      print('expense against id is ${event.expense_against_id}');
      print('expense against client id is ${event.expense_client_id}');
      print('amount is ${event.amount}');
      // Prepare files map for a single file
      Map<String, File>? files;
      if (event.document != null) {
        files = {
          'document':
              event.document!, // Map the single file to the 'document' key
        };
      }

      // Call the API to fetch company info
      final response = await apiService.makeMultipartRequest(
        endpoint: apiUrlConfig.addReimbursement, // Define this in ApiUrlConfig
        method: 'POST',
        headers: headers,
        formData: formData,
        files: files, // Pass the image file
        fileFieldNames: files != null
            ? ['document']
            : null, // Match your API's expected field name
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Safely extract the data
        final reimbursementData = response['data']['message'];

        emit(ReimbursementSuccess(message: reimbursementData));
        print('reimbursement added successfully: $reimbursementData');
        GetReimbursment();
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
          print('Failed to add reimbursement: $errorMessage');
          emit(ReimbursementFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('reimbursement adding exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      } else {
        emit(ReimbursementFailure(errorMessage: errorMessage));
      }
    }
  }

  Future<void> _onGetReimbursment(
      GetReimbursment event, Emitter<ReimbursementState> emit) async {
    emit(ReimbursementLoading()); // Emit loading state

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Getting reimbursement for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      // Call the API to fetch company info
      final response = await apiService.makeRequest(
          endpoint: '${apiUrlConfig.getReimbursment}$uid',
          method: 'GET',
          headers: headers);

      print('Reimbursment history API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Safely extract the data
        final reimbursementResponse = response['data']['data'] as List<dynamic>;

        final reimbursmentData = reimbursementResponse
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        emit(GetReimbursementSuccess(reimbursmentHistory: reimbursmentData));
        print(
            'reimbursement history retrieved successfully: $reimbursmentData');
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
          print('Failed to get reimbursement history: $errorMessage');
          emit(GetReimbursementFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('exception caught  in fetching reimbursment history: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(GetReimbursementFailure(errorMessage: errorMessage));
    }
  }
}
