import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';
import '../holiday_model.dart';

part 'holiday_event.dart';
part 'holiday_state.dart';

class HolidayBloc extends Bloc<HolidayEvent, HolidayState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  HolidayBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(HolidayInitial()) {
    on<FetchHolidays>(_onFetchHolidays);
  }

  Future<void> _onFetchHolidays(
      FetchHolidays event, Emitter<HolidayState> emit) async {
    emit(HolidayLoading()); // Emit loading state

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching holidays for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      // Call the API to fetch holidays
      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.getHolidaysPath,
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Extract the holidays list from response['data']['data']
        final holidaysData = response['data']['data'] as List<dynamic>;

        // Convert List<dynamic> to List<Map<String, dynamic>>
        final holidaysList = holidaysData
            .map((item) =>
                HolidayModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (holidaysList.isNotEmpty) {
          emit(HolidayLoaded(holidaysList));
          print('Holidays fetched successfully: $holidaysList');
        } else {
          emit(HolidayLoaded([]));
          print('holiday list is empty');
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
          print('Failed to fetch holidays: $errorMessage');
          emit(HolidayError(errorMessage));
        }
      }
    } catch (e) {
      print('Holidays Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(HolidayError(errorMessage));
    }
  }
}
