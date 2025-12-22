import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'upload_image_status_event.dart';
part 'upload_image_status_state.dart';

class UploadImageStatusBloc
    extends Bloc<UploadImageStatusEvent, UploadImageStatusState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  UploadImageStatusBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(UploadImageStatusInitial()) {
    on<UploadImageStatus>(_onUploadImageStatus);
  }

  Future<void> _onUploadImageStatus(
      UploadImageStatus event, Emitter<UploadImageStatusState> emit) async {
    emit(UploadImageStatusLoading());

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching upload images status for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '',
      };

      print('endpoint is ${apiUrlConfig.getFaceImageStatusPath}$uid');
      print('headers are $headers');
      // Call the API to fetch documents (assuming a GET request)
      final response = await apiService.makeRequest(
        endpoint:
            '${apiUrlConfig.getFaceImageStatusPath}$uid', // Define this in ApiUrlConfig
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        final uploadImageStatusData = response['data']['data'] ?? [];
        final uploadImageStatusList =
            List<Map<String, dynamic>>.from(uploadImageStatusData);
        emit(UploadImageStatusSuccess(statusData: uploadImageStatusList));
        print(
            'uploaded images status fetched successfully: $uploadImageStatusList');
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
          print('Failed to fetch uploaded images status: $errorMessage');
          emit(UploadImageStatusFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('uploaded images status Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(UploadImageStatusFailure(errorMessage: errorMessage));
    }
  }
}
