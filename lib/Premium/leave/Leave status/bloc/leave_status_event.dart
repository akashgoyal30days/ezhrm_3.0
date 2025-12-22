part of 'leave_status_bloc.dart';

@immutable
sealed class LeaveStatusEvent {}

class FetchLeaveStatus extends LeaveStatusEvent {}

// delete events
@immutable
sealed class DeleteEvent {}

class DeleteItem extends DeleteEvent {
  final int leaveApplicationId;
  DeleteItem({required this.leaveApplicationId});
}
