import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';

part 'show_comp_off_event.dart';
part 'show_comp_off_state.dart';

class ShowCompOffBloc extends Bloc<ShowCompOffEvent, ShowCompOffState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ShowCompOffBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(ShowCompOffInitial()) {
    on<ShowCompOff>(_onShowCompOff);
  }

  Future<void> _onShowCompOff(
      ShowCompOff event, Emitter<ShowCompOffState> emit) async {
    emit(ShowCompOffLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Adding Comp off for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      };

      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.showCompOffPath}$uid',
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        // Expect a single Map<String, dynamic> instead of a List
        final showCompOffResponse = response['data']['data'] as List<dynamic>;
        // Wrap it in a list for consistency with the state
        final compOffData = showCompOffResponse
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        emit(ShowCompOffSuccess(compOffHistory: compOffData));
        print('Comp off history retrieved successfully: $compOffData');
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
          print('Error in adding comp off: $errorMessage');
          emit(ShowCompOffError(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Comp off Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(ShowCompOffError(errorMessage: errorMessage));
    }
  }
}
