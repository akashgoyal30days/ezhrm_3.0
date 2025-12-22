part of 'get_document_type_bloc.dart';

@immutable
sealed class GetDocumentTypeEvent {}

class FetchDocumentType extends GetDocumentTypeEvent {}
