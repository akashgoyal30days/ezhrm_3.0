part of 'upload_documents_bloc.dart';

@immutable
sealed class UploadDocumentsEvent {}

class UploadDocument extends UploadDocumentsEvent {
  final String? employee_id; // Changed to nullable and non-required
  final String? document_type_id; // Changed to nullable and non-required
  final String? document_number; // Changed to nullable and non-required
  final String? verification_status; // Changed to nullable and non-required
  final File? image;

  UploadDocument({
    this.employee_id, // Removed 'required'
    this.document_type_id, // Removed 'required'
    this.document_number, // Removed 'required'
    this.verification_status, // Removed 'required'
    required this.image,
  });
}

class UploadDocuments extends UploadDocumentsEvent {}
