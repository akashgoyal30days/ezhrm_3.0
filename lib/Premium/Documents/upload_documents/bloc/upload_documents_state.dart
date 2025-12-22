part of 'upload_documents_bloc.dart';

@immutable
sealed class UploadDocumentsState {}

final class UploadDocumentsInitial extends UploadDocumentsState {}

final class UploadDocumentLoading extends UploadDocumentsState {}

final class UploadDocumentSuccess extends UploadDocumentsState {
  final List<Map<String, dynamic>> documents;

  UploadDocumentSuccess({required this.documents});
}

final class UploadDocumentError extends UploadDocumentsState {
  final String error;

  UploadDocumentError({required this.error});
}
