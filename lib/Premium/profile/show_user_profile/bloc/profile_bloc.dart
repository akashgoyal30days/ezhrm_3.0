import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../modal/profile_model.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ProfileBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(ProfileInitial()) {
    on<FetchProfileEvent>(_onFetchProfileEvent);
  }

  Future<void> _onFetchProfileEvent(
      FetchProfileEvent event, Emitter<ProfileState> emit) async {
    emit(FetchProfileLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      if (uid == null || token == null) {
        emit(FetchProfileError(error: 'User not authenticated'));
        return;
      }

      final Map<String, String> headers = {
        'Authorization': 'Bearer $token',
      };

      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.getEmployeeDetails}$uid',
        method: 'GET',
        headers: headers,
      );

      if (response['success'] == true) {
        final profileData =
            response['data']['data'] as Map<String, dynamic>? ?? {};
        final userData = ProfileModel.fromJson(profileData);

        // Safely parse and format joining date
        DateTime? formattedJoiningDate;
        try {
          final joiningDateStr = profileData['joining_date']?.toString();
          if (joiningDateStr != null && joiningDateStr.isNotEmpty) {
            final parsedDate = DateTime.parse(joiningDateStr);
            formattedJoiningDate =
                DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
          }
        } catch (e) {
          // Log parsing errors for developers, but don't block the UI
          print('Error parsing joining date: $e');
        }

        emit(FetchProfileSuccess(
          profileData: [profileData],
          joiningDate: formattedJoiningDate,
          email: userData.email,
          userData: userData,
        ));
      } else {
        final String errorMessage = extractErrorMessage(response);

        // Log the actual error from the API for debugging purposes
        print('API Error on Profile Fetch: $errorMessage');

        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        }
        emit(FetchProfileError(error: errorMessage));
      }
    } catch (e) {
      // Log the full exception for debugging purposes
      print('Profile Fetch Exception: $e');

      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(FetchProfileError(error: errorMessage));
    }
  }
}
