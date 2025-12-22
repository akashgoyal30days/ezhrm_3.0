part of 'advance_salary_bloc.dart';

@immutable
sealed class AdvanceSalaryEvent {}

class GetAdvanceSalary extends AdvanceSalaryEvent {}

class AdvanceSalary extends AdvanceSalaryEvent {
  final double advance_amount;
  final int month;
  final String remarks;

  AdvanceSalary(
      {required this.advance_amount,
      required this.month,
      required this.remarks});
}
