import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../modal/user_model.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiService apiService;
  final ApiUrlConfig apiUrlConfig;
  final UserSession userSession;

  DashboardBloc({
    required this.apiService,
    required this.apiUrlConfig,
    required this.userSession,
  }) : super(DashboardInitial()) {
    on<FetchDashboardData>(_onFetchDashboardData);
  }

  Future<void> _onFetchDashboardData(
      FetchDashboardData event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());

    try {
      final token = userSession.token;
      final uid = userSession.uid;
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token ?? ''}',
      };

      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.getEmployeeDetails}$uid',
        method: 'GET',
        headers: headers,
      );

      if (response['success'] == true &&
          response.containsKey('data') &&
          response['data'] != null &&
          response['data']['data'] != null) {
        final userProfile = UserProfile.fromJson(response['data']['data']);
        emit(DashboardLoaded(userProfile));
      } else {
        // Handles cases where the API returns a 200 OK but with a success: false flag
        final String message = 'Failed to load data.';
        emit(DashboardError(message));
      }
    } on DioException catch (e) {
      // Catch specific network exceptions
      // Check if the error was caused by a response from the server (like 404, 500)
      if (e.response != null) {
        print('API Error - Status Code: ${e.response?.statusCode}');
        print('API Error - Response Data: ${e.response?.data}');

        if (e.response?.statusCode == 500) {
          emit(DashboardError(
              'Something went wrong on the server. Please try again later.'));
        } else {
          // Handle other HTTP status code errors (e.g., 401, 403, 404)
          emit(DashboardError(
              'Something went wrong. Status: ${e.response?.statusCode}'));
        }
      } else {
        print('Network Error: $e');
        emit(DashboardError('Network error. Please check your connection.'));
      }
    } catch (e) {
      print('Dashboard Fetch Exception: $e');
      emit(DashboardError('Something went wrong.'));
    }
  }
}
