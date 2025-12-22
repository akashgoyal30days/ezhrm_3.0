import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../Authentication/User Information/user_details.dart';
import '../Authentication/User Information/user_session.dart';
import '../Configuration/ApiService.dart';
import '../Configuration/ApiUrlConfig.dart';
import '../SessionHandling/session_bloc.dart';

part 'fetch_notification_event.dart';
part 'fetch_notification_state.dart';

class FetchNotificationBloc
    extends Bloc<FetchNotificationEvent, FetchNotificationState> {
  final ApiService apiService;
  final UserDetails userDetails;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  FetchNotificationBloc({
    required this.apiService,
    required this.userDetails,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(FetchNotificationInitial()) {
    on<GetNotifications>(_onGetNotifications);
  }

  Future<void> _onGetNotifications(
      GetNotifications event, Emitter<FetchNotificationState> emit) async {
    emit(FetchNotificationLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetch notification for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      };

      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.fetchNotificationPath}$uid',
        method: 'GET',
        headers: headers,
      );

      if (response['success'] == true) {
        // Expect a single Map<String, dynamic> instead of a List
        final notificationData = response['data']['data'] ?? [];
        // Extract only message + created_at
        final notifications = notificationData.map((item) {
          return {
            "subject": item["subject"] ?? "",
            "message": item["message"] ?? "",
            "created_at": item["created_at"] ?? "",
          };
        }).toList();

        emit(FetchNotificationSuccess(notifications: notifications));
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
          print('Error in fetching notification: $errorMessage');
          emit(FetchNotificationFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Error in changing password: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      } else {
        emit(FetchNotificationFailure(errorMessage: errorMessage));
      }
    }
  }
}
