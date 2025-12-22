import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../show_comp_off/bloc/show_comp_off_bloc.dart';

part 'add_comp_off_event.dart';
part 'add_comp_off_state.dart';

class AddCompOffBloc extends Bloc<AddCompOffEvent, AddCompOffState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;
  final ShowCompOffBloc showCompOffBloc;

  AddCompOffBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc,
      required this.showCompOffBloc})
      : super(AddCompOffInitial()) {
    on<AddCompOff>(_onAddCompOff);
  }

  Future<void> _onAddCompOff(
      AddCompOff event, Emitter<AddCompOffState> emit) async {
    emit(AddCompOffLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Adding Comp off for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      };

      final body = {
        'employee_id': uid,
        'earned_type': event.earned_type,
        'earned_date': event.earned_date,
        'remarks': event.reason,
      };

      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.addCompOffPath,
        method: 'POST',
        headers: headers,
        body: body,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        // Expect a single Map<String, dynamic> instead of a List
        final addCompOffData = response['data']['data'] as Map<String, dynamic>;
        // Wrap it in a list for consistency with the state
        final addCompOffList = [addCompOffData];
        emit(AddCompOffSuccess(response: addCompOffList));
        print('Comp off added successfully: $addCompOffList');
        showCompOffBloc.add(ShowCompOff());
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
          emit(AddCompOffFailure(errorMessage: errorMessage));
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

      emit(AddCompOffFailure(errorMessage: errorMessage));
    }
  }
}
