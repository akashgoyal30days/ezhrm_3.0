import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'view_activity_status_event.dart';
part 'view_activity_status_state.dart';

class ViewActivityStatusBloc
    extends Bloc<ViewActivityStatusEvent, ViewActivityStatusState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ViewActivityStatusBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(ViewActivityStatusInitial()) {
    on<ViewActivityStatus>(_onViewActivityStatus);
  }

  Future<void> _onViewActivityStatus(
      ViewActivityStatus event, Emitter<ViewActivityStatusState> emit) async {
    emit(ViewActivityStatusLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching CSR activity status for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': token ?? '',
      };

      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.viewActivityStatus}$uid',
        method: 'GET',
        headers: headers,
      );

      print(
          'Full API URL: ${apiUrlConfig.baseUrl}/${apiUrlConfig.viewActivityStatus}$uid');
      print('Raw API Response: $response');

      if (response['success'] == true) {
        // Handle the nested data structure
        final dynamic responseData = response['data'];
        List<Map<String, dynamic>> activitiesList = [];

        if (responseData is Map<String, dynamic>) {
          final dynamic innerData = responseData['data'];

          if (innerData is List<dynamic>) {
            activitiesList =
                innerData.map((item) => item as Map<String, dynamic>).toList();
          } else if (innerData is Map<String, dynamic>) {
            activitiesList = [innerData];
          }
        }

        print('Parsed Activities List: $activitiesList');

        if (activitiesList.isNotEmpty) {
          print('Fetched ${activitiesList.length} activities');
          emit(ViewActivityStatusLoaded(activityStatus: activitiesList));
        } else {
          print('No activities found');
          emit(ViewActivityStatusLoaded(activityStatus: []));
        }
      } else {
        final errorMessage = extractErrorMessage(response);
        print('API Error: $errorMessage');
        if (errorMessage.toLowerCase().contains('token') ||
            errorMessage.toLowerCase().contains('session')) {
          sessionBloc.add(SessionExpired());
        } else {
          emit(ViewActivityStatusError(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Error fetching activities: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(ViewActivityStatusError(errorMessage: errorMessage));
    }
  }
}
