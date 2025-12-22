part of 'apply_loan_bloc.dart';

@immutable
sealed class ApplyLoanEvent {}

class GetApplyLoan extends ApplyLoanEvent {}

class ApplyLoan extends ApplyLoanEvent {
  final double loan_amount;
  final double emi_amount;

  ApplyLoan({required this.loan_amount, required this.emi_amount});
}
