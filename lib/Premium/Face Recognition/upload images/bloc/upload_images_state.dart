part of 'upload_images_bloc.dart';

@immutable
sealed class UploadImagesState {}

final class UploadImagesInitial extends UploadImagesState {}

final class UploadImagesLoading extends UploadImagesState {}

final class UploadImagesSuccess extends UploadImagesState {
  final String message;

  UploadImagesSuccess({required this.message});
}

final class UploadImagesFailure extends UploadImagesState {
  final String errorMessage;

  UploadImagesFailure({required this.errorMessage});
}
