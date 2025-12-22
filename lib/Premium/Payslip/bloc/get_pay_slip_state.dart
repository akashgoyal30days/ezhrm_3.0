part of 'get_pay_slip_bloc.dart';

@immutable
sealed class GetPaySlipState {}

final class GetPaySlipInitial extends GetPaySlipState {}

final class GetPaySlipLoading extends GetPaySlipState {}

final class GetPaySlipSuccess extends GetPaySlipState {
  final List<dynamic> payslips;

  GetPaySlipSuccess({required this.payslips});
}

final class GetPaySlipFailure extends GetPaySlipState {
  final String errorMessage;

  GetPaySlipFailure({required this.errorMessage});
}

final class CheckPaySlipInitial extends GetPaySlipState {}

final class CheckPaySlipLoading extends GetPaySlipState {}

final class CheckPaySlipSuccess extends GetPaySlipState {
  final List<dynamic> payslips;

  CheckPaySlipSuccess({required this.payslips});
}

final class CheckPaySlipFailure extends GetPaySlipState {
  final String errorMessage;

  CheckPaySlipFailure({required this.errorMessage});
}
