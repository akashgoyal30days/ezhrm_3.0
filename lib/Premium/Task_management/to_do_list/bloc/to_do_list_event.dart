part of 'to_do_list_bloc.dart';

@immutable
sealed class ToDoListEvent {}

class FetchToDoList extends ToDoListEvent {}

class UpdateToDoTask extends ToDoListEvent {
  final String status;
  final String taskId;

  UpdateToDoTask({required this.status, required this.taskId});
}
