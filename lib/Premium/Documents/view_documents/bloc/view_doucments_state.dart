part of 'view_doucments_bloc.dart';

@immutable
sealed class ViewDocumentsState {}

final class ViewDocumentsInitial extends ViewDocumentsState {}

final class FetchEmployeeDocumentLoading extends ViewDocumentsInitial {}

final class FetchEmployeeDocumentSuccess extends ViewDocumentsInitial {
  final List<Map<String, dynamic>> employeeDocuments;

  FetchEmployeeDocumentSuccess({required this.employeeDocuments});
}

final class FetchEmployeeDocumentError extends ViewDocumentsState {
  final String error;

  FetchEmployeeDocumentError(
      {this.error = 'An error occurred while fetching documents.'});
}
