part of 'assigned_work_bloc.dart';

@immutable
sealed class AssignedWorkState {}

final class AssignedWorkInitial extends AssignedWorkState {}

final class AssignedWorkLoading extends AssignedWorkState {}

final class AssignedWorkSuccess extends AssignedWorkState {
  final List<AssignedTask> assignedWork;
  AssignedWorkSuccess(this.assignedWork);
}

final class AssignedWorkFailure extends AssignedWorkState {
  final String errorMessage;
  AssignedWorkFailure(this.errorMessage);
}

final class UpdateAssignedWorkLoading extends AssignedWorkState {}

final class UpdateAssignedWorkSuccess extends AssignedWorkState {
  final String message;
  UpdateAssignedWorkSuccess(this.message);
}

final class UpdateAssignedWorkFailure extends AssignedWorkState {
  final String errorMessage;
  UpdateAssignedWorkFailure(this.errorMessage);
}
