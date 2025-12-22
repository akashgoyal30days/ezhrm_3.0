part of 'reimbursement_bloc.dart';

@immutable
sealed class ReimbursementState {}

final class ReimbursementInitial extends ReimbursementState {}

final class ReimbursementLoading extends ReimbursementState {}

final class ReimbursementSuccess extends ReimbursementState {
  final String message;

  ReimbursementSuccess({required this.message});
}

final class ReimbursementFailure extends ReimbursementState {
  final String errorMessage;

  ReimbursementFailure({required this.errorMessage});
}

final class GetReimbursementInitial extends ReimbursementState {}

final class GetReimbursementLoading extends ReimbursementState {}

final class GetReimbursementSuccess extends ReimbursementState {
  final List<dynamic> reimbursmentHistory;

  GetReimbursementSuccess({required this.reimbursmentHistory});
}

final class GetReimbursementFailure extends ReimbursementState {
  final String errorMessage;

  GetReimbursementFailure({required this.errorMessage});
}
