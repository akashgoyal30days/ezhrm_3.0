import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../Attendance/Get Today Attendance/bloc/get_today_attendance_bloc.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiService.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../SessionHandling/session_bloc.dart';
part 'upload_documents_event.dart';
part 'upload_documents_state.dart';

class UploadDocumentsBloc
    extends Bloc<UploadDocumentsEvent, UploadDocumentsState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  UploadDocumentsBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(UploadDocumentsInitial()) {
    on<UploadDocument>(_onUploadDocument);
  }

  Future<void> _onUploadDocument(
      UploadDocument event, Emitter<UploadDocumentsState> emit) async {
    emit(UploadDocumentLoading());

    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Uploading document for UID: $uid with Token: $token');

      final header = {'Authorization': token ?? ''};

      // Prepare form data (convert all fields to strings, handle nulls)
      final formData = {
        'employee_id':
            uid ?? '', // Use null-coalescing operator to ensure non-null String
        'document_type_id': event.document_type_id ?? '1',
        'document_number': event.document_number ?? 'PC1123',
        'verification_status': event.verification_status ?? 'Pending',
      };

      // Prepare files map for a single file
      Map<String, File>? files;
      if (event.image != null) {
        files = {
          'document': event.image!, // Map the single file to the 'document' key
        };
      }

      // Call the common multipart request function
      final response = await apiService.makeMultipartRequest(
        endpoint:
            apiUrlConfig.uploadDocumentsPath, // Define this in ApiUrlConfig
        method: 'POST',
        headers: header,
        formData: formData,
        files: files, // Pass the image file
        fileFieldNames: files != null
            ? ['document']
            : null, // Match your API's expected field name
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Assuming the API returns a list of documents under 'data' or 'data.documents'
        final documentsData = response['data'] is List
            ? response['data']
            : response['data']['documents'] ?? [];
        final documentsList = List<Map<String, dynamic>>.from(documentsData);
        emit(UploadDocumentSuccess(documents: documentsList));
        print('Document upload successful: $documentsList');
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
          print('Failed to upload document: $errorMessage');
          emit(UploadDocumentError(error: errorMessage));
        }
      }
    } catch (e) {
      print('Document Upload Exception: $e');
      String errorMessage = "An unexpected error occurs";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Failed host lookup")) {
        errorMessage = "Please check your internet connection.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "The server took too long to respond. Try again later.";
      }

      emit(UploadDocumentError(error: errorMessage));
    }
  }
}
