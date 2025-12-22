part of 'get_expense_bloc.dart';

@immutable
sealed class GetExpenseState {}

final class GetExpenseInitial extends GetExpenseState {}

final class GetExpenseLoading extends GetExpenseState {}

final class GetExpenseSuccess extends GetExpenseState {
  final List<Map<String, dynamic>> expenses;
  GetExpenseSuccess({required this.expenses});
}

final class GetExpenseFailure extends GetExpenseState {
  final String errorMessage;
  GetExpenseFailure({required this.errorMessage});
}
