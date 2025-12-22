part of 'get_document_type_bloc.dart';

@immutable
sealed class GetDocumentTypeState {}

final class GetDocumentTypeInitial extends GetDocumentTypeState {}

final class GetDocumentTypeLoading extends GetDocumentTypeState {}

class GetDocumentTypeSuccess extends GetDocumentTypeState {
  final List<DocumentTypeModel> documentType;
  GetDocumentTypeSuccess({required this.documentType});
}

final class GetDocumentTypeFailure extends GetDocumentTypeState {
  final String errorMessage;

  GetDocumentTypeFailure({required this.errorMessage});
}
