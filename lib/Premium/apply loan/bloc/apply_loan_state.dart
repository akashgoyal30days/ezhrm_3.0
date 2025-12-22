part of 'apply_loan_bloc.dart';

@immutable
sealed class ApplyLoanState {}

final class ApplyLoanInitial extends ApplyLoanState {}

final class ApplyLoanLoading extends ApplyLoanState {}

final class ApplyLoanSuccess extends ApplyLoanState {
  final String message;

  ApplyLoanSuccess({required this.message});
}

final class GetApplyLoanSuccess extends ApplyLoanState {
  final List<Map<String, dynamic>> getApplyLoan;

  GetApplyLoanSuccess({required this.getApplyLoan});
}

final class GetApplyLoanFailure extends ApplyLoanState {
  final String errorMessage;

  GetApplyLoanFailure({required this.errorMessage});
}

final class ApplyLoanFailure extends ApplyLoanState {
  final String errorMessage;

  ApplyLoanFailure({required this.errorMessage});
}
