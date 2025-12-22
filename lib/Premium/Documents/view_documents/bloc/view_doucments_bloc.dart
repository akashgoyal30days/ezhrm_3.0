import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';

part 'view_doucments_event.dart';
part 'view_doucments_state.dart';

class ViewDocumentsBloc extends Bloc<ViewDoucmentsEvent, ViewDocumentsState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  ViewDocumentsBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(ViewDocumentsInitial()) {
    on<FetchEmployeeDocument>(_onFetchEmployeeDocument);
  }

  Future<void> _onFetchEmployeeDocument(
      FetchEmployeeDocument event, Emitter<ViewDocumentsState> emit) async {
    emit(FetchEmployeeDocumentLoading());

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching documents for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '',
      };

      // Call the API to fetch documents (assuming a GET request)
      final response = await apiService.makeRequest(
        endpoint:
            '${apiUrlConfig.viewDocumentsPath}$uid', // Define this in ApiUrlConfig
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        final documentsData = response['data']['data'] ?? [];
        final documentsList = List<Map<String, dynamic>>.from(documentsData);
        if (documentsList.isNotEmpty) {
          emit(FetchEmployeeDocumentSuccess(employeeDocuments: documentsList));
          print('Documents fetched successfully: $documentsList');
        } else {
          emit(FetchEmployeeDocumentSuccess(employeeDocuments: []));
          print('Documents fetched successfully: []');
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
        } else if (errorMessage.contains('No documents found.')) {
          emit(FetchEmployeeDocumentSuccess(employeeDocuments: []));
          print('Documents fetched successfully: []');
        } else {
          print('Failed to fetch documents: $errorMessage');
          emit(FetchEmployeeDocumentError(error: errorMessage));
        }
      }
    } catch (e) {
      print('Document Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(FetchEmployeeDocumentError(error: errorMessage));
    }
  }
}
