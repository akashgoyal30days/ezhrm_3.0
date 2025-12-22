import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  FeedbackBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(FeedbackInitial()) {
    on<FeedbackActivity>(_onFeedbackActivity);
  }

  Future<void> _onFeedbackActivity(
      FeedbackActivity event, Emitter<FeedbackState> emit) async {
    emit(FeedbackLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Feedback for UID:$uid with Token: $token');

      final header = {'Authorization': token ?? ''};

      final formData = {
        'employee_id': uid ?? '',
        'feedback_text': event.feedback_text,
      };

      Map<String, File>? files;

      final response = await apiService.makeMultipartRequest(
          endpoint: apiUrlConfig.feedback,
          method: 'POST',
          headers: header,
          formData: formData,
          files: files,
          fileFieldNames: ['file_url']);

      print('API Response: $response');

      if (response['success'] == true) {
        final feedbackData = response['data']['data'] as Map<String, dynamic>?;
        if (feedbackData != null) {
          final feedback = [feedbackData];
          emit(FeedbackSuccess(feedbackData: feedback));
          print('Feedback Upload Successfully: $feedback');
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
          print('Failed to upload Feedback.: $errorMessage');
          emit(FeedbackError(error: errorMessage));
        }
      }
    } catch (e) {
      print('Feedback Upload Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(FeedbackError(error: errorMessage));
    }
  }
}
