import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'post_csr_activity_event.dart';
part 'post_csr_activity_state.dart';

class PostCsrActivityBloc
    extends Bloc<PostCsrActivityEvent, PostCsrActivityState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  PostCsrActivityBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(PostCsrActivityInitial()) {
    on<PostCsrActivity>(_onPostCsrActivity);
  }

  Future<void> _onPostCsrActivity(
      PostCsrActivity event, Emitter<PostCsrActivityState> emit) async {
    emit(PostCsrActivityLoading());

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Post CSR activity for UID: $uid with Token: $token');

      final header = {'Authorization': token ?? ''};

      // Prepare form data (convert all fields to strings, handle nulls)
      final formData = {
        'employee_id':
            uid ?? '', // Use null-coalescing operator to ensure non-null String
        'description': event.description
      };

      Map<String, File>? files;
      files = {'activity': event.activity};
      // Call the common multipart request function
      final response = await apiService.makeMultipartRequest(
        endpoint: apiUrlConfig.postCsrActivity, // Define this in ApiUrlConfig
        method: 'POST',
        headers: header,
        formData: formData,
        files: files, // Pass the image file
        fileFieldNames: ['activity'], // Match your API's expected field name
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Assuming the API returns a list of documents under 'data' or 'data.documents'
        final activityData = response['data']['data'] as Map<String, dynamic>?;
        if (activityData != null) {
          final activity = [activityData];
          emit(PostCsrActivitySuccess(activityData: activity));
          print('CSR Activity upload successful: $activity');
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
          print('Failed to upload CSR activity.: $errorMessage');
          emit(PostCsrActivityError(error: errorMessage));
        }
      }
    } catch (e) {
      print('CSR activity Upload Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(PostCsrActivityError(error: errorMessage));
    }
  }
}
