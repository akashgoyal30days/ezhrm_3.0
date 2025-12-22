import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'upload_images_event.dart';
part 'upload_images_state.dart';

class UploadImagesBloc extends Bloc<UploadImagesEvent, UploadImagesState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  UploadImagesBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(UploadImagesInitial()) {
    on<UploadImages>(_onUploadImages);
  }

  Future<void> _onUploadImages(
      UploadImages event, Emitter<UploadImagesState> emit) async {
    emit(UploadImagesLoading());

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;
      final String? apiKey = await userSession.apiKey;

      print('Uploading images for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': 'Bearer $token' ?? '',
      };

      // Prepare form data
      final Map<String, String> formData = {
        'employee_id': uid ?? '',
        'image_vector1': jsonEncode(event.imageVector1),
        'image_vector2': jsonEncode(event.imageVector2),
        'image_vector3': jsonEncode(event.imageVector3),
      };

      // Define the endpoint for uploading images
      final String endpoint = apiUrlConfig.uploadImagesPath;

      // Prepare the list of files to upload
      final Map<String, File> files = {
        'image1': event.image1,
        'image2': event.image2,
        'image3': event.image3,
      };

      // Call the multipart request method for multiple files
      final response = await apiService.makeMultipartRequest(
        endpoint: endpoint,
        method: 'POST',
        headers: headers,
        formData: formData,
        files: files, // Pass multiple files
        fileFieldNames: [
          'image1',
          'image2',
          'image3'
        ], // Match API expected field names
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        emit(UploadImagesSuccess(
            message: 'Images uploaded successfully. Awaiting admin approval'));
        print('Images uploaded successfully');
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
          print('Failed to upload images: $errorMessage');
          emit(UploadImagesFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Exception in uploading images: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(UploadImagesFailure(errorMessage: errorMessage));
    }
  }
}
