import 'package:bloc/bloc.dart';

import 'package:meta/meta.dart';

import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'contact_us_event.dart';
part 'contact_us_state.dart';

class ContactUsBloc extends Bloc<ContactUsEvent, ContactUsState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ContactUsBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(ContactUsInitial()) {
    on<FetchContactUs>(_onFetchContactUs);
  }

  Future<void> _onFetchContactUs(
      FetchContactUs event, Emitter<ContactUsState> emit) async {
    emit(ContactUsLoading()); // Emit loading state

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching company info for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      // Call the API to fetch company info
      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.getCompanyInfoPath,
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Safely extract the data
        final data = response['data'];
        if (data != null && data['company'] != null) {
          // Extract the company object (a single Map)
          final companyData = data['company'] as Map<String, dynamic>?;

          if (companyData != null) {
            // Wrap the single company object in a list for consistency with the UI
            final companyInfo = [Map<String, dynamic>.from(companyData)];
            emit(ContactUsSuccess(contactUsData: companyInfo));
            print('Company info fetched successfully: $companyInfo');
          } else {
            emit(ContactUsSuccess(contactUsData: []));
            print('Company data is null in response.');
          }
        } else {
          emit(ContactUsFailure(
              errorMessage:
                  'Invalid response structure: company field is missing.'));
          print('Response data or data["company"] is null: $data');
        }
      } else {
        final String errorMessage = extractErrorMessage(response);
        print('Company info fetch error: $errorMessage');
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          emit(ContactUsFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Company info Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(ContactUsFailure(errorMessage: errorMessage));
    }
  }
}
