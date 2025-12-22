part of 'reimbursement_bloc.dart';

@immutable
sealed class ReimbursementEvent {}

class AddReimbursement extends ReimbursementEvent {
  int? employee_id;
  final String date;
  final String amount;
  final String expense_against_id;
  final String description;
  final String expense_client_id;
  File? document;

  AddReimbursement(
      {required this.date,
      required this.amount,
      required this.expense_against_id,
      required this.description,
      required this.expense_client_id,
      required this.document});
}

class GetReimbursment extends ReimbursementEvent {}
