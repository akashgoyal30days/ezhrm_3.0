part of 'leave_quota_bloc.dart';

@immutable
sealed class LeaveQuotaEvent {}

class FetchEmployeeLeaveQuota extends LeaveQuotaEvent {}
