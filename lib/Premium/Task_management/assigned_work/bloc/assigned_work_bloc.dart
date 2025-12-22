import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../modal/assigned_work_modal.dart';

part 'assigned_work_event.dart';
part 'assigned_work_state.dart';

class AssignedWorkBloc extends Bloc<AssignedWorkEvent, AssignedWorkState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  AssignedWorkBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(AssignedWorkInitial()) {
    on<AssignedWork>(_onAssignWork);
    on<UpdateAssignedWork>(_onUpdateAssignedWork);
  }

  Future<void> _onAssignWork(
      AssignedWork event, Emitter<AssignedWorkState> emit) async {
    emit(AssignedWorkLoading());

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching Assigned Work for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': 'Bearer ${token ?? ''}', // Added Bearer prefix
      };

      // Call the API to fetch profile (assuming a GET request)
      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.getAssignedWork}$uid',
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        final responseData = response['data']['data'] as List<dynamic>;
        final assignedWorkList = responseData
            .map((item) => AssignedTask.fromJson(item as Map<String, dynamic>))
            .toList();
        emit(AssignedWorkSuccess(assignedWorkList));
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
          print('Failed to fetch Assigned Work: $errorMessage');
          emit(AssignedWorkFailure(errorMessage));
        }
      }
    } catch (e) {
      print('Assigned Work Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(AssignedWorkFailure(errorMessage));
    }
  }

  Future<void> _onUpdateAssignedWork(
      UpdateAssignedWork event, Emitter<AssignedWorkState> emit) async {
    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Update assigned work for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type':
            'application/json', // It's good practice to set the content type
        'Authorization': 'Bearer ${token ?? ''}',
      };

      // --- START OF FIX ---
      // The request body must match the API's requirements
      final Map<String, dynamic> body = {
        'employee_id': uid,
        "status": 'Completed'
      };
      // --- END OF FIX ---

      final taskId = event.workId;
      print('Request Body: $body');

      print(
          'ATTEMPTING TO CALL FULL URL: ${apiUrlConfig.baseUrl}${apiUrlConfig.updateAssignedWork}$taskId');

      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.updateAssignedWork}$taskId',
        method: 'PUT',
        headers: headers,
        body: body,
      );

      print('Update To Do Task API Response: $response');

      if (response['success'] == true) {
        // After adding, trigger a fresh fetch of the entire list to show the new item.
        add(AssignedWork());
        print('Assigned work update successfully. Fetching updated list.');
        emit(UpdateAssignedWorkSuccess('Assigned work updated successfully'));
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
          print('Failed to update assigned work: $errorMessage');
          emit(UpdateAssignedWorkFailure(errorMessage));
        }
      }
    } catch (e) {
      print('Exception caught in assigned work: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(UpdateAssignedWorkFailure(errorMessage));
    }
  }
}
