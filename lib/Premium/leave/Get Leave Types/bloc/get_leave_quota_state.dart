part of 'get_leave_quota_bloc.dart';

@immutable
sealed class GetLeaveQuotaState {}

final class GetLeaveQuotaInitial extends GetLeaveQuotaState {}

final class GetLeaveQuotaLoading extends GetLeaveQuotaInitial {}

final class GetLeaveQuotaSuccess extends GetLeaveQuotaInitial {
  final List<Map<String, dynamic>> getLeaveQuota;

  GetLeaveQuotaSuccess({required this.getLeaveQuota});
}

final class GetLeaveQuotaFailure extends GetLeaveQuotaInitial {
  final String errorMessage;

  GetLeaveQuotaFailure({required this.errorMessage});
}
