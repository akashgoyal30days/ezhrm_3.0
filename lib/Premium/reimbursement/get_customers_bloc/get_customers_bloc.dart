import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'get_customers_event.dart';
part 'get_customers_state.dart';

class GetCustomersBloc extends Bloc<GetCustomersEvent, GetCustomersState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  GetCustomersBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(GetCustomersInitial()) {
    on<GetCustomers>(_onGetCustomers);
  }

  Future<void> _onGetCustomers(
      GetCustomers event, Emitter<GetCustomersState> emit) async {
    emit(GetCustomersLoading()); // Emit loading state

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching customers info for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      // Call the API to fetch company info
      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.getCustomers,
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Safely extract the data
        final customerData = response['data']['data'] as List<dynamic>;

        // Convert List<dynamic> to List<Map<String, dynamic>>
        final customerList = customerData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        emit(GetCustomersSuccess(customers: customerList));
        print(
            'customers data for reimbursement fetched successfully: $customerList');
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
          print(
              'Failed to fetch customers data for reimbursement: $errorMessage');
          emit(GetCustomersFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('customers data for reimbursement info Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      } else {
        emit(GetCustomersFailure(errorMessage: errorMessage));
      }
    }
  }
}
