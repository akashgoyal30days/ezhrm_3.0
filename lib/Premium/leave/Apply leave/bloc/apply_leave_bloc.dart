import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../Employee Leave_quota/bloc/leave_quota_bloc.dart';
import '../../Leave status/bloc/leave_status_bloc.dart';

part 'apply_leave_event.dart';
part 'apply_leave_state.dart';

class ApplyLeaveBloc extends Bloc<ApplyLeaveEvent, ApplyLeaveState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final LeaveQuotaBloc leaveQuotaBloc;
  final LeaveStatusBloc leaveStatusBloc;
  final SessionBloc sessionBloc;
  ApplyLeaveBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.leaveQuotaBloc,
      required this.leaveStatusBloc,
      required this.sessionBloc})
      : super(ApplyLeaveInitial()) {
    on<ApplyLeave>(_onApplyLeave);
  }

  Future<void> _onApplyLeave(
      ApplyLeave event, Emitter<ApplyLeaveState> emit) async {
    emit(ApplyLeaveLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Applying leave for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': ' $token', // Assuming Bearer token is required
      };

      final body = {
        'employee_id': event.employee_id ?? uid,
        'quota_id': event.quota_id,
        'credit_type': event.credit_type,
        'start_date': event.start_date,
        'end_date': event.end_date,
        'total_days': event.total_days,
        'reason': event.reason,
      };

      final endpoint = apiUrlConfig.applyLeavePath; // Include UID if required
      print('Endpoint: $endpoint');
      print('Request Body: $body');

      final response = await apiService.makeRequest(
        endpoint: endpoint,
        method: 'POST',
        headers: headers,
        body: body,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        // Handle single object instead of a list
        final applyLeaveResponse =
            response['data']['data'] as Map<String, dynamic>?;
        if (applyLeaveResponse != null) {
          // Wrap the single object in a list for consistency with ApplyLeaveSuccess
          final applyLeave = [applyLeaveResponse];
          emit(ApplyLeaveSuccess(employeeApplyLeave: applyLeave));
          print('Apply leave response: $applyLeave');
          leaveQuotaBloc.add(FetchEmployeeLeaveQuota());
          leaveStatusBloc.add(FetchLeaveStatus());
        } else {
          emit(ApplyLeaveFailure(errorMessage: 'No data found'));
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
          print('Error in applying leave: $errorMessage');
          emit(ApplyLeaveFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Exception in applying leave: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(ApplyLeaveFailure(errorMessage: errorMessage));
    }
  }
}
