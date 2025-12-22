part of 'apply_leave_bloc.dart';

@immutable
sealed class ApplyLeaveState {}

final class ApplyLeaveInitial extends ApplyLeaveState {}

final class ApplyLeaveLoading extends ApplyLeaveInitial {}

final class ApplyLeaveSuccess extends ApplyLeaveInitial {
  final List<Map<String, dynamic>> employeeApplyLeave;

  ApplyLeaveSuccess({required this.employeeApplyLeave});
}

final class ApplyLeaveFailure extends ApplyLeaveInitial {
  final String errorMessage;

  ApplyLeaveFailure({required this.errorMessage});
}
