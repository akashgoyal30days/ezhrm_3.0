part of 'update_user_profile_bloc.dart';

@immutable
sealed class UpdateUserProfileEvent {}

class UpdateUserProfile extends UpdateUserProfileEvent {
  final String firstName;
  final String middleName;
  final String lastName;
  final String dateOfBirth;
  final String mobileNumber;
  final String alternatemobileNumber;
  final File? imagePath; // Made nullable

  UpdateUserProfile({
    this.firstName = '', // Default to empty string
    this.middleName = '',
    this.lastName = '',
    this.dateOfBirth = '',
    this.mobileNumber = '',
    this.imagePath,
    this.alternatemobileNumber = '',
  });
}
