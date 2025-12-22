import 'dart:core';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../show_user_profile/bloc/profile_bloc.dart';

part 'update_user_profile_event.dart';
part 'update_user_profile_state.dart';

class UpdateUserProfileBloc
    extends Bloc<UpdateUserProfileEvent, UpdateUserProfileState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final ProfileBloc profileBloc;
  final SessionBloc sessionBloc;

  UpdateUserProfileBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.profileBloc,
      required this.sessionBloc})
      : super(UpdateUserProfileInitial()) {
    on<UpdateUserProfile>(_onUpdateUserProfileEvent);
  }

  Future<void> _onUpdateUserProfileEvent(
      UpdateUserProfile event, Emitter<UpdateUserProfileState> emit) async {
    emit(UpdateUserProfileLoading());

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Updating profile for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '',
      };

      // Prepare form data, only including non-empty fields
      final Map<String, String> formData = {};
      if (event.firstName.isNotEmpty) formData['first_name'] = event.firstName;
      if (event.middleName.isNotEmpty) {
        formData['middle_name'] = event.middleName;
      }
      if (event.lastName.isNotEmpty) formData['last_name'] = event.lastName;
      if (event.mobileNumber.isNotEmpty) {
        formData['mobile_number'] = event.mobileNumber;
      }
      if (event.alternatemobileNumber.isNotEmpty) {
        formData['emergency_contact_number'] = event.alternatemobileNumber;
      }
      if (event.dateOfBirth.isNotEmpty) {
        formData['date_of_birth'] = event.dateOfBirth;
      }

      // Define the endpoint for updating the profile
      final String endpoint = '${apiUrlConfig.updateEmployeeDetailsPath}$uid';

      Map<String, File>? files;
      if (event.imagePath != null) {
        files = {
          'image':
              event.imagePath!, // Map the single file to the 'document' key
        };
      }
      // Call the multipart request method
      final response = await apiService.makeMultipartRequest(
        endpoint: endpoint,
        method: 'POST', // Use POST for updating data
        headers: headers,
        formData:
            formData, // Always pass formData, empty if no fields are updated
        files: files, // File can be null if no image is provided
        fileFieldNames: files != null
            ? ['image']
            : null, // Match the API's expected field name for the file
      );

      print('API Response: $response');
      final userData = response;
      // Check response
      if (response['success'] == true) {
        final updatedProfileData =
            response['data']['data'] as Map<String, dynamic>;
        final updatedProfileList = [updatedProfileData];
        emit(UpdateUserProfileSuccess(updatedUserProfile: updatedProfileList));
        print('Updated Profile fetched successfully: $updatedProfileList');
        profileBloc.add(FetchProfileEvent());
      } else {
        final String errorMessage = extractErrorMessage(response);
        print('Update User Profile bloc error: $errorMessage');
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          print('Failed to update user profile: $errorMessage');
          emit(UpdateUserProfileFailure(message: errorMessage));
        }
      }
    } catch (e) {
      print('Exception in updating user profile: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(UpdateUserProfileFailure(message: errorMessage));
    }
  }
}
