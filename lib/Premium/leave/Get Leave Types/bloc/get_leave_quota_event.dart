part of 'get_leave_quota_bloc.dart';

@immutable
sealed class GetLeaveQuotaEvent {}

class FetchLeaveQuota extends GetLeaveQuotaEvent {}
