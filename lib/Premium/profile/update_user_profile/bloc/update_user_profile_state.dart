part of 'update_user_profile_bloc.dart';

@immutable
sealed class UpdateUserProfileState {}

final class UpdateUserProfileInitial extends UpdateUserProfileState {}

final class UpdateUserProfileLoading extends UpdateUserProfileState {}

final class UpdateUserProfileSuccess extends UpdateUserProfileState {
  final List<Map<String, dynamic>> updatedUserProfile;

  UpdateUserProfileSuccess({
    required this.updatedUserProfile,
  });
}

final class UpdateUserProfileFailure extends UpdateUserProfileState {
  final String message;

  UpdateUserProfileFailure({required this.message});
}
