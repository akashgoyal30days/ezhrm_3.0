import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../modal/document_type_modal.dart';

part 'get_document_type_event.dart';
part 'get_document_type_state.dart';

class GetDocumentTypeBloc
    extends Bloc<GetDocumentTypeEvent, GetDocumentTypeState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  GetDocumentTypeBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(GetDocumentTypeInitial()) {
    on<FetchDocumentType>(_onFetchDocumentType);
  }

  Future<void> _onFetchDocumentType(
      FetchDocumentType event, Emitter<GetDocumentTypeState> emit) async {
    emit(GetDocumentTypeLoading());

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching documents type for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '',
      };

      // Call the API to fetch documents (assuming a GET request)
      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig.documentType, // Define this in ApiUrlConfig
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        final documentsType = response['data']['data'] ?? [];
        final documentsTypeList = (documentsType as List)
            .map((json) => DocumentTypeModel.fromJson(json))
            .toList();
        if (documentsTypeList.isNotEmpty) {
          emit(GetDocumentTypeSuccess(documentType: documentsTypeList));
          print('Documents type fetched successfully: $documentsTypeList');
        } else {
          emit(GetDocumentTypeSuccess(documentType: []));
          print('Documents type fetched successfully: []');
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
          print('Failed to fetch documents type: $errorMessage');
          emit(GetDocumentTypeFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('Document type Fetch Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(GetDocumentTypeFailure(errorMessage: errorMessage));
    }
  }
}
