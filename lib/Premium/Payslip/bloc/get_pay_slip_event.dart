part of 'get_pay_slip_bloc.dart';

@immutable
sealed class GetPaySlipEvent {}

class GetPaySlip extends GetPaySlipEvent {
  final String month;
  final String year;

  GetPaySlip({
    required this.month,
    required this.year,
  });
}

class CheckPaySlip extends GetPaySlipEvent {
  final String month;
  final String year;

  CheckPaySlip({
    required this.month,
    required this.year,
  });
}
