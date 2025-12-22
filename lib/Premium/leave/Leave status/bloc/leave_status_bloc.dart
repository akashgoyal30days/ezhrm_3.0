import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../modal/leave_card_model.dart';
import '../modal/leave_modal.dart';

part 'leave_status_event.dart';
part 'leave_status_state.dart';

class LeaveStatusBloc extends Bloc<LeaveStatusEvent, LeaveStatusState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  LeaveStatusBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(LeaveStatusInitial()) {
    on<FetchLeaveStatus>(_onFetchLeaveStatus);
  }

  Future<void> _onFetchLeaveStatus(
      FetchLeaveStatus event, Emitter<LeaveStatusState> emit) async {
    debugPrint('🔄 FetchLeaveStatus event triggered');
    emit(LeaveStatusLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;
      debugPrint('🆔 UID: $uid');
      debugPrint('🔐 Token: $token');

      final headers = {'Authorization': 'Bearer $token'};
      Map<int, String> quotaMap = {};

      // 1. Fetch Leave Quotas
      debugPrint('📡 Fetching Leave Quotas...');
      final quotaResponse = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.getEmployeeLeaveQuotaPath}$uid',
        method: 'GET',
        headers: headers,
      );
      debugPrint('📥 Quota Response: $quotaResponse');

      if (quotaResponse['success'] == true) {
        final quotaList = (quotaResponse['data']['data'] as List)
            .map((json) => LeaveQuota.fromJson(json))
            .toList();
        debugPrint('✅ Parsed Quota List: $quotaList');

        quotaMap = {
          for (var quota in quotaList) quota.quotaid: quota.leaveTypeName
        };
        debugPrint('📌 Quota Map: $quotaMap');
      }
      if (quotaResponse['message'] ==
          "No leave quota found for this employee.") {
        emit(LeaveStatusFailure(
            errorMessage: 'Failed to fetch employee leave status info'));
      }

      // 3. Fetch Leave Applications
      debugPrint('📡 Fetching Leave Applications...');
      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.showEmployeeLeaveStatusPath}$uid',
        method: 'GET',
        headers: headers,
      );
      debugPrint('📥 Leave Applications Response: $response');

      if (response['success'] == true) {
        final leaveStatusData = response['data']['data'] as List;
        final String settingValue = response['setting']?.toString() ?? '0';
        debugPrint('🛠 Setting Value: $settingValue');

        final leaveCards = leaveStatusData.map((leaveJson) {
          final leave = Map<String, dynamic>.from(leaveJson);
          final quotaId = LeaveQuota.parseQuotaId(leave['quota_id']);
          final matchedName = quotaMap[quotaId] ?? 'Unknown Leave';

          return LeaveCardModel.fromJson({
            ...leave,
            'leave_type_name': matchedName,
          });
        }).toList();

        debugPrint('📄 Leave Cards Created: $leaveCards');
        emit(LeaveStatusSuccess(leaveCards, settingValue));
        print(
            '✅ Employee leave status and setting ($settingValue) fetched successfully.');
      } else {
        final String errorMessage = extractErrorMessage(response);
        debugPrint('⚠️ Error Message: $errorMessage');

        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          debugPrint('🚫 Session expired - triggering SessionExpired event');
          sessionBloc.add(SessionExpired());
        } else if (errorMessage.contains('User not found')) {
          debugPrint('❌ User not found - triggering UserNotFound event');
          sessionBloc.add(UserNotFound());
        } else if (errorMessage.contains('No leave applications found.')) {
          final String settingValue = response['setting']?.toString() ?? '0';
          debugPrint('📭 No leave applications found, setting = $settingValue');
          emit(LeaveStatusSuccess([], settingValue));
        } else {
          emit(LeaveStatusFailure(errorMessage: errorMessage));
          debugPrint("❗ General Error: $errorMessage");
        }
      }
    } catch (e) {
      debugPrint('🔥 Exception Caught: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(LeaveStatusFailure(errorMessage: errorMessage));
    }
  }
}

class DeleteBloc extends Bloc<DeleteEvent, DeleteState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;
  final LeaveStatusBloc leaveStatusBloc;

  DeleteBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc,
      required this.leaveStatusBloc})
      : super(DeleteInitial()) {
    on<DeleteItem>(_deleteItem);
  }

  Future<void> _deleteItem(DeleteItem event, Emitter<DeleteState> emit) async {
    debugPrint(
        '🔄 DeleteItem event triggered for leaveApplicationId: ${event.leaveApplicationId}');
    emit(DeleteLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      debugPrint('🆔 UID from session: $uid');
      debugPrint('🔐 Token from session: $token');

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> body = {
        "approved_by": "$uid",
        "status": "Cancelled",
      };

      debugPrint(
          '📡 Sending DELETE (PUT) request to endpoint: ${apiUrlConfig.deleteEmployeeLeave}${event.leaveApplicationId}');
      debugPrint('📝 Request Headers: $headers');
      debugPrint('📝 Request Body: $body');

      final deleteResponse = await apiService.makeRequest(
        endpoint:
            '${apiUrlConfig.deleteEmployeeLeave}${event.leaveApplicationId}',
        method: 'PUT',
        headers: headers,
        body: body,
      );

      debugPrint('📥 Delete Response: $deleteResponse');

      if (deleteResponse['success'] == true) {
        debugPrint('✅ Leave deletion successful');
        emit(DeleteSuccess());
        leaveStatusBloc.add(FetchLeaveStatus());
      } else {
        final errorMessage = extractErrorMessage(deleteResponse);
        debugPrint('❌ Delete failed with message: $errorMessage');
        emit(DeleteFailure(errorMessage));
      }
    } catch (e) {
      debugPrint('🔥 Exception during delete process: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(DeleteFailure(errorMessage));
    }
  }
}
