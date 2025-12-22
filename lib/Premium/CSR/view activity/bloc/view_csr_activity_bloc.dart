import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'view_csr_activity_event.dart';
part 'view_csr_activity_state.dart';

class ViewCsrActivityBloc
    extends Bloc<ViewCsrActivityEvent, ViewCsrActivityState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ViewCsrActivityBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(ViewCsrActivityInitial()) {
    on<ViewCsrActivity>(_onViewCsrActivity);
  }

  Future<void> _onViewCsrActivity(
      ViewCsrActivity event, Emitter<ViewCsrActivityState> emit) async {
    emit(ViewCsrActivityLoading());

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching CSR activity for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '',
      };

      // Call the API to fetch documents (assuming a GET request)
      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.getCsrActivity, // Define this in ApiUrlConfig
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        final csrActivityData = response['data']['data'] ?? [];
        final csrActivityList =
            List<Map<String, dynamic>>.from(csrActivityData);
        if (csrActivityList.isNotEmpty) {
          emit(ViewCsrActivitySuccess(csrActivityData: csrActivityList));
          print('CSR activity fetched successfully: $csrActivityList');
        } else {
          print('No CSR activity found.');
          emit(ViewCsrActivitySuccess(csrActivityData: []));
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
          print('Failed to fetch CSR activity.: $errorMessage');
          emit(ViewCsrActivityError(error: errorMessage));
        }
      }
    } catch (e) {
      print('Document Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(ViewCsrActivityError(error: errorMessage));
    }
  }
}
