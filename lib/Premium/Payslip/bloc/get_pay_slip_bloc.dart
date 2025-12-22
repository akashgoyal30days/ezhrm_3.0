import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'get_pay_slip_event.dart';
part 'get_pay_slip_state.dart';

class GetPaySlipBloc extends Bloc<GetPaySlip, GetPaySlipState> {
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final ApiService apiService;
  final SessionBloc sessionBloc;

  GetPaySlipBloc({
    required this.userSession,
    required this.apiUrlConfig,
    required this.apiService,
    required this.sessionBloc,
  }) : super(GetPaySlipInitial()) {
    on<GetPaySlip>(_onGetPaySlip);
  }

  Future<void> _onGetPaySlip(
      GetPaySlip event, Emitter<GetPaySlipState> emit) async {
    emit(GetPaySlipLoading());

    try {
      final employeeId = await userSession.uid;
      final String? token = await userSession.token;

      final headers = {
        'Authorization': '$token',
      };
      final endpoint =
          '${apiUrlConfig.paySlip}$employeeId/${event.month}/${event.year}';
      print('Endpoint: $endpoint');

      final response = await apiService.makeRequest(
        endpoint: endpoint,
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        final dynamic rawData = response['data']['data'];

        if (rawData == null) {
          emit(GetPaySlipFailure(errorMessage: 'No data returned from API'));
          return;
        }

        List<dynamic> payslipList = [];

        // CASE 1: API returns a LIST
        if (rawData is List) {
          payslipList = rawData;
        }
        // CASE 2: API returns a MAP
        else if (rawData is Map<String, dynamic>) {
          payslipList = [rawData];
        }
        // CASE 3: Unexpected format
        else {
          emit(GetPaySlipFailure(
              errorMessage: 'Unexpected data format from API.'));
          return;
        }

        emit(GetPaySlipSuccess(payslips: payslipList));
        print('Get Payslip response: $payslipList');
      } else {
        // **Use the helper function to get the clean message**
        final String errorMessage = extractErrorMessage(response);
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          print('Error in fetching payslip: $errorMessage');
          emit(GetPaySlipFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Exception in fetching payslip: $e');
      // **Use the helper function here as well**
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(GetPaySlipFailure(errorMessage: errorMessage));
    }
  }
}

class CheckPaySlipBloc extends Bloc<CheckPaySlip, GetPaySlipState> {
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final ApiService apiService;
  final SessionBloc sessionBloc;

  CheckPaySlipBloc({
    required this.userSession,
    required this.apiUrlConfig,
    required this.apiService,
    required this.sessionBloc,
  }) : super(GetPaySlipInitial()) {
    on<CheckPaySlip>(_onCheckPaySlip);
  }

  Future<void> _onCheckPaySlip(
      CheckPaySlip event, Emitter<GetPaySlipState> emit) async {
    emit(CheckPaySlipLoading());

    try {
      final employeeId = await userSession.uid;
      final String? token = await userSession.token;

      final headers = {
        'Authorization': '$token',
      };
      final endpoint =
          '${apiUrlConfig.checkPaySlip}$employeeId/${event.month}/${event.year}';
      print('Endpoint: $endpoint');

      final response = await apiService.makeRequest(
        endpoint: endpoint,
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        final payslipList = response['data']['data'] as List<dynamic>?;

        if (payslipList != null && payslipList.isNotEmpty) {
          emit(CheckPaySlipSuccess(payslips: payslipList));
          print('Check payslip response: $payslipList');
        } else {
          emit(CheckPaySlipFailure(errorMessage: 'No data returned from API'));
        }
      } else {
        // **Use the helper function to get the clean message**
        final String errorMessage = extractErrorMessage(response);
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          print('Error in fetching payslip: $errorMessage');
          emit(CheckPaySlipFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Exception in fetching payslip: $e');
      // **Use the helper function here as well**
      String errorMessage = "Salary slip is not generated yet";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(CheckPaySlipFailure(errorMessage: errorMessage));
    }
  }
}
