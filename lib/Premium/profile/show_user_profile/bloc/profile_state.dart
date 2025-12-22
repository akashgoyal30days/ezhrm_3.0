part of 'profile_bloc.dart';

@immutable
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class FetchProfileLoading extends ProfileState {}

final class FetchProfileSuccess extends ProfileState {
  final List<Map<String, dynamic>> profileData; // Raw API response data
  final ProfileModel userData;
  final DateTime? joiningDate;
  final String email;

  FetchProfileSuccess({
    required this.profileData,
    this.joiningDate,
    required this.email,
    required this.userData,
  });
}

class FetchProfileError extends ProfileState {
  final String error;
  FetchProfileError({required this.error});
}
