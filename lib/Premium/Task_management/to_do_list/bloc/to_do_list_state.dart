part of 'to_do_list_bloc.dart';

@immutable
sealed class ToDoListState {}

final class ToDoListInitial extends ToDoListState {}

final class ToDoListLoading extends ToDoListState {}

final class ToDoListSuccess extends ToDoListState {
  final List<Map<String, dynamic>> toDoListData;
  ToDoListSuccess(this.toDoListData);
}

final class ToDoListFailure extends ToDoListState {
  final String errorMessage;
  ToDoListFailure(this.errorMessage);
}

final class UpdateToDoListLoading extends ToDoListState {}

final class UpdateToDoListSuccess extends ToDoListState {
  final String message;
  UpdateToDoListSuccess(this.message);
}

final class UpdateToDoListFailure extends ToDoListState {
  final String errorMessage;
  UpdateToDoListFailure(this.errorMessage);
}
