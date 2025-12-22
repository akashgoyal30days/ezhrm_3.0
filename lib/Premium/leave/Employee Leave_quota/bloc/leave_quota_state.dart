part of 'leave_quota_bloc.dart';

@immutable
sealed class LeaveQuotaState {}

final class LeaveQuotaInitial extends LeaveQuotaState {}

final class LeaveQuotaLoading extends LeaveQuotaInitial {}

final class LeaveQuotaSuccess extends LeaveQuotaInitial {
  final List<Map<String, dynamic>> employeeLeaveQuota;

  LeaveQuotaSuccess({required this.employeeLeaveQuota});
}

final class LeaveQuotaFailure extends LeaveQuotaInitial {
  final String errorMessage;

  LeaveQuotaFailure({required this.errorMessage});
}

class LeaveQuotaNoData
    extends LeaveQuotaState {} // New state for no leave quota
