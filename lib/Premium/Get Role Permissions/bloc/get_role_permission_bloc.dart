import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'get_role_permission_event.dart';
part 'get_role_permission_state.dart';

class GetRolePermissionBloc
    extends Bloc<GetRolePermissionEvent, GetRolePermissionState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  GetRolePermissionBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(GetRolePermissionInitial()) {
    on<GetRolePermission>(_onGetRolePermission);
  }

  Future<void> _onGetRolePermission(
      GetRolePermission event, Emitter<GetRolePermissionState> emit) async {
    emit(GetRolePermissionLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching role permissions for UID: $uid with Token: $token');

      if (uid == null || token == null) {
        emit(GetRolePermissionFailure(
            errorMessage: 'User session not initialized'));
        return;
      }
      final int roleId = 1;
      final Map<String, String> headers = {
        'Authorization': token,
      };

      print('endpoint is ${apiUrlConfig.getRolePermission}$roleId');
      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.getRolePermission}$roleId',
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        final permissionData = response['data']['data'] as List<dynamic>;
        final rolePermission = permissionData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        emit(GetRolePermissionSuccess(getRolePermission: rolePermission));
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
          print('Failed to fetch role permissions: $errorMessage');
          emit(GetRolePermissionFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Permissions Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(GetRolePermissionFailure(errorMessage: errorMessage));
    }
  }
}
