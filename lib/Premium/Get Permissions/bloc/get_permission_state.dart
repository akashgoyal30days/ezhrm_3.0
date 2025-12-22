part of 'get_permission_bloc.dart';

@immutable
abstract class GetPermissionState {}

class GetPermissionInitial extends GetPermissionState {}

class GetPermissionLoading extends GetPermissionState {}

class GetPermissionSuccess extends GetPermissionState {
  final Map<String, dynamic> permissions; // Changed from List to Map

  GetPermissionSuccess(this.permissions);
}

class GetPermissionFailure extends GetPermissionState {
  final String errorMessage;

  GetPermissionFailure({required this.errorMessage});
}
