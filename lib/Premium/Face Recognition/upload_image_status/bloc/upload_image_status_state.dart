part of 'upload_image_status_bloc.dart';

@immutable
sealed class UploadImageStatusState {}

final class UploadImageStatusInitial extends UploadImageStatusState {}

final class UploadImageStatusLoading extends UploadImageStatusState {}

final class UploadImageStatusSuccess extends UploadImageStatusState {
  final List<Map<String, dynamic>> statusData;

  UploadImageStatusSuccess({required this.statusData});
}

final class UploadImageStatusFailure extends UploadImageStatusState {
  final String errorMessage;

  UploadImageStatusFailure({required this.errorMessage});
}
