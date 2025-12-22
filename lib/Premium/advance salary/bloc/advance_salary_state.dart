part of 'advance_salary_bloc.dart';

@immutable
sealed class AdvanceSalaryState {}

final class AdvanceSalaryInitial extends AdvanceSalaryState {}

final class AdvanceSalaryLoading extends AdvanceSalaryState {}

final class AdvanceSalarySuccess extends AdvanceSalaryState {
  final String message;

  AdvanceSalarySuccess({required this.message});
}

final class GetAdvanceSalarySuccess extends AdvanceSalaryState {
  final List<Map<String, dynamic>> advanceSalary;

  GetAdvanceSalarySuccess({required this.advanceSalary});
}

final class GetAdvanceSalaryFailure extends AdvanceSalaryState {
  final String errorMessage;

  GetAdvanceSalaryFailure({required this.errorMessage});
}

final class AdvanceSalaryFailure extends AdvanceSalaryState {
  final String errorMessage;

  AdvanceSalaryFailure({required this.errorMessage});
}
