class DocumentTypeModel {
  final int documentTypeId;
  final String documentName;

  DocumentTypeModel({
    required this.documentTypeId,
    required this.documentName,
  });

  factory DocumentTypeModel.fromJson(Map<String, dynamic> json) {
    return DocumentTypeModel(
      documentTypeId: json['document_type_id'],
      documentName: json['document_name'],
    );
  }
}
