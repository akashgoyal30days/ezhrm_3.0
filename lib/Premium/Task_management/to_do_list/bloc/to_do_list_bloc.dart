import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'to_do_list_event.dart';
part 'to_do_list_state.dart';

class ToDoListBloc extends Bloc<ToDoListEvent, ToDoListState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ToDoListBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(ToDoListInitial()) {
    on<FetchToDoList>(_onFetchToDoList);
    on<UpdateToDoTask>(_onUpdateToDoTask);
  }

  Future<void> _onFetchToDoList(
      FetchToDoList event, Emitter<ToDoListState> emit) async {
    emit(ToDoListLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching To Do list for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': 'Bearer ${token ?? ''}',
      };

      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.toDoListPath}$uid',
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        final responseData = response['data']['data'] as List<dynamic>;
        final toDoList = responseData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        emit(ToDoListSuccess(toDoList));
        print('To Do List task fetched successfully: $toDoList');
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
          print('Failed to fetch To Do List task: $errorMessage');
          emit(ToDoListFailure(errorMessage));
        }
      }
    } catch (e) {
      print('To Do List task Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(ToDoListFailure(errorMessage));
    }
  }

// In ToDoListBloc class

  Future<void> _onUpdateToDoTask(
      UpdateToDoTask event, Emitter<ToDoListState> emit) async {
    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Adding To Do task for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type':
            'application/json', // It's good practice to set the content type
        'Authorization': 'Bearer ${token ?? ''}',
      };

      // --- START OF FIX ---
      // The request body must match the API's requirements
      final Map<String, dynamic> body = {
        'employee_id': uid,
        "status": event.status
      };
      // --- END OF FIX ---

      final taskId = event.taskId;
      print('Request Body: $body');

      print(
          'ATTEMPTING TO CALL FULL URL: ${apiUrlConfig.baseUrl}${apiUrlConfig.toDoListUpdatePath}$taskId');

      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.toDoListUpdatePath}$taskId',
        method: 'PUT',
        headers: headers,
        body: body,
      );

      print('Update To Do Task API Response: $response');

      if (response['success'] == true) {
        // After adding, trigger a fresh fetch of the entire list to show the new item.
        add(FetchToDoList());
        print('To Do List task update successfully. Fetching updated list.');
        emit(UpdateToDoListSuccess('Task updated successfully'));
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
          print('Failed to add To Do task: $errorMessage');
          emit(UpdateToDoListFailure(errorMessage));
        }
      }
    } catch (e) {
      print('Add To Do Task Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(UpdateToDoListFailure(errorMessage));
    }
  }
}
