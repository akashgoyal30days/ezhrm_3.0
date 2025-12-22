import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';

class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final UserDetails userDetails;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ChangePasswordBloc(
      {required this.apiService,
      required this.userSession,
      required this.userDetails,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(ChangePasswordInitial()) {
    on<ChangePassword>(_onChangePassword);
  }

  Future<void> _onChangePassword(
      ChangePassword event, Emitter<ChangePasswordState> emit) async {
    emit(ChangePasswordLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Password change for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      };

      final body = {
        'email': event.email,
        'old_password': event.old_password,
        'new_password': event.new_password,
        'confirm_password': event.confirm_password,
      };

      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.changePasswordPath}$uid',
        method: 'POST',
        headers: headers,
        body: body,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        // Expect a single Map<String, dynamic> instead of a List
        final message = 'Password changed successfully!';
        userSession.clearUserCredentials();
        userDetails.clearUserDetails();
        print(
            'User Credentials value, uid: ${await userSession.uid} token: ${await userSession.token}  session validity: ${await userSession.getSessionValidity()}');

        emit(ChangePasswordSuccess(message: message));
        print('Password changed successfully');
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
          print('Error in changing password: $errorMessage');
          emit(ChangePasswordFailure(message: errorMessage));
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
        emit(ChangePasswordFailure(message: errorMessage));
      }
    }
  }
}
