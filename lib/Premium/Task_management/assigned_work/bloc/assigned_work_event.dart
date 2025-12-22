part of 'assigned_work_bloc.dart';

@immutable
sealed class AssignedWorkEvent {}

class AssignedWork extends AssignedWorkEvent {}

class UpdateAssignedWork extends AssignedWork {
  final String workId;

  UpdateAssignedWork({required this.workId});
}
