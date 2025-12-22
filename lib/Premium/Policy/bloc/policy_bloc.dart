import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';
import '../modal/policy_modal.dart';

part 'policy_event.dart';
part 'policy_state.dart';

class PolicyBloc extends Bloc<PolicyEvent, PolicyState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  PolicyBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(PolicyInitial()) {
    on<GetCompanyPolicy>(_onGetCompanyPolicy);
  }

  Future<void> _onGetCompanyPolicy(
      GetCompanyPolicy event, Emitter<PolicyState> emit) async {
    print('🟢 GetCompanyPolicy EVENT RECEIVED'); // Debug print
    emit(GetCompanyPolicyLoading());

    try {
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching Company Policy for UID: $uid with Token: $token');

      final Map<String, String> headers = {
        'Authorization': token ?? '',
      };

      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.getCompanyPolicyPath,
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      if (response['success'] == true) {
        final PolicyData = response['data']['data'] as List<dynamic>;
        final policyList = PolicyData.map(
                (item) => PolicyModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (policyList.isNotEmpty) {
          emit(GetCompanyPolicySuccess(policyList));
          print('policy fetched successfully: $policyList');
        } else {
          emit(GetCompanyPolicySuccess([]));
          print('policy list is empty');
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
          print('Error in fetching company policy: $errorMessage');
          emit(GetCompanyPolicyFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Company Policy fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }
      emit(GetCompanyPolicyFailure(errorMessage: errorMessage));
    }
  }
}
