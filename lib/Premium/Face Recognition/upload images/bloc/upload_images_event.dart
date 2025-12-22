part of 'upload_images_bloc.dart';

@immutable
sealed class UploadImagesEvent {}

class UploadImages extends UploadImagesEvent {
  final File image1;
  final File image2;
  final File image3;
  final List<double> imageVector1;
  final List<double> imageVector2;
  final List<double> imageVector3;

  UploadImages({
    required this.image1,
    required this.image2,
    required this.image3,
    required this.imageVector1,
    required this.imageVector2,
    required this.imageVector3,
  });
}
