import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../User Information/user_details.dart';
import '../User Information/user_session.dart';
import '../model/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

final FlutterSecureStorage storage =
    FlutterSecureStorage(); // Secure storage instance

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;
  final UserSession userSession;
  final UserDetails userDetails;
  final ApiUrlConfig apiUrlConfig;

  AuthBloc({
    required this.apiService,
    required this.userSession,
    required this.userDetails,
    required this.apiUrlConfig,
  }) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<Logout>(_onlogOutTap);
    on<UpdatePassword>(_onUpdatePassword);
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

  Future<void> _onLoginSubmitted(
      LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      print('Attempting login with email: ${event.email}');

      final fcmToken = await userDetails.getFcmToken();
      final deviceId = await userDetails.getDeviceId();
      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.loginPath,
        method: 'POST',
        headers: apiUrlConfig.loginHeader,
        body: {
          'email': event.email,
          'password': event.password,
          'fcm_token': fcmToken,
          'device_id': deviceId,
        },
      );

      print('Login response: $response');

      if (response['success'] == true) {
        final userData = response['data']['user'];
        final cid = userData['company_id'];
        final user = AppUser.fromLoginResponse(response);
        // Store AppUser in session
        print('AuthBloc: User id is ${user.id} token value is ${user.token}');
        await userSession.setUserCredentials(
          userId: user.id,
          userToken: user.token,
          sessionValidity: true,
        );
        await userSession.setCId(CId: cid.toString());

        emit(AuthLoaded(user));
        print('Login Successful. UID: ${user.id}, Token: ${user.token}');
        print('user session: ${await userSession.getSessionValidity()}');
        print(
            'AuthBloc: User session validity: ${await userSession.isSessionValid()}');
      } else {
        final backendMessage = extractErrorMessage(response);
        emit(AuthFailure(backendMessage));
        print('Login failed from Auth failure: $backendMessage');
      }
    } catch (e) {
      print('Login error from catch block: $e');

      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(AuthFailure(errorMessage));
    }
  }

  Future<void> _onUpdatePassword(
      UpdatePassword event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Updating password for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      final body = {
        'email': event.email,
      };

      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.forgotPassword,
        method: 'POST',
        headers: headers,
        body: body,
      );

      print('update password response: $response');

      if (response['success'] == true) {
        emit(UpdatePasswordSuccess('Email sent successfully'));
      } else {
        String errorMessage = extractErrorMessage(response);
        print('Update password: error message is $errorMessage');
        emit(UpdatePasswordFailure(errorMessage));
      }
    } catch (e) {
      print("❌ Exception while sending email: $e");
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(UpdatePasswordFailure(errorMessage));
    }
  }

  Future<void> _onlogOutTap(Logout event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      final Map<String, String> headers = {
        'Authorization': token ?? '',
      };

      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.logoutPath,
        method: 'POST',
        headers: headers,
      );

      print('log out response: $response');

      if (response['success'] == true) {
        // Clear session data and stored AppUser
        await userSession.clearUserCredentials();
        await userDetails.clearUserDetails();
        await storage.delete(key: 'user');
        print(
            'User Credentials value, uid: ${await userSession.uid} token: ${await userSession.token} session validity: ${await userSession.getSessionValidity()}');
        emit(LogoutSuccess());
      } else {
        String errorMessage = extractErrorMessage(response);
        emit(LogoutFailure(errorMessage));
        print('Logout failed from Auth failure: $errorMessage');
      }
    } catch (e) {
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(LogoutFailure(errorMessage));
    }
  }
}
