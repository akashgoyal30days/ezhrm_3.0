import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'get_permission_event.dart';
part 'get_permission_state.dart';

class GetPermissionBloc extends Bloc<GetPermissionEvent, GetPermissionState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  GetPermissionBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(GetPermissionInitial()) {
    on<GetPermission>(_onGetPermission);
  }

  Future<void> _onGetPermission(
      GetPermission event, Emitter<GetPermissionState> emit) async {
    emit(GetPermissionLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching Attendance permissions for UID: $uid with Token: $token');

      if (uid == null || token == null) {
        emit(
            GetPermissionFailure(errorMessage: 'User session not initialized'));
        return;
      }

      final Map<String, String> headers = {
        'Authorization': token,
      };

      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.getPermissions}$uid',
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        final permissionData = response['data']['data'] as List<dynamic>;
        if (permissionData.isEmpty) {
          emit(GetPermissionSuccess({})); // Empty map for no data
        } else {
          final permissions = permissionData.first
              as Map<String, dynamic>; // Take the first item
          emit(GetPermissionSuccess(permissions));
          print('Attendance Permissions fetched successfully: $permissions');
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
          print('Failed to fetch Attendance permissions: $errorMessage');
          emit(GetPermissionFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Attendance Permissions Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(GetPermissionFailure(errorMessage: errorMessage));
    }
  }
}
