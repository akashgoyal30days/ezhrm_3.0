part of 'leave_status_bloc.dart';

@immutable
sealed class LeaveStatusState {}

final class LeaveStatusInitial extends LeaveStatusState {}

final class LeaveStatusLoading extends LeaveStatusState {}

final class LeaveStatusSuccess extends LeaveStatusState {
  final List<LeaveCardModel> fetchedLeaveData;
  final String setting; // <-- ADD THIS LINE

  // UPDATE THE CONSTRUCTOR TO ACCEPT THE NEW 'setting' PROPERTY
  LeaveStatusSuccess(this.fetchedLeaveData, this.setting);
}

final class LeaveStatusFailure extends LeaveStatusState {
  final String errorMessage;

  LeaveStatusFailure({required this.errorMessage});
}

// Delete States

@immutable
sealed class DeleteState {}

class DeleteInitial extends DeleteState {}

class DeleteLoading extends DeleteState {}

class DeleteSuccess extends DeleteState {}

class DeleteFailure extends DeleteState {
  final String error;

  DeleteFailure(this.error);
}
