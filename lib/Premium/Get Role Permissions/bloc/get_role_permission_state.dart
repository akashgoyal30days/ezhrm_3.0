part of 'get_role_permission_bloc.dart';

@immutable
sealed class GetRolePermissionState {}

final class GetRolePermissionInitial extends GetRolePermissionState {}

final class GetRolePermissionLoading extends GetRolePermissionState {}

final class GetRolePermissionSuccess extends GetRolePermissionState {
  final List<Map<String, dynamic>> getRolePermission;

  GetRolePermissionSuccess({required this.getRolePermission});
}

final class GetRolePermissionFailure extends GetRolePermissionState {
  final String errorMessage;

  GetRolePermissionFailure({required this.errorMessage});
}
