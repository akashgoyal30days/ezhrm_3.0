part of 'add_comp_off_bloc.dart';

@immutable
sealed class AddCompOffEvent {}

class AddCompOff extends AddCompOffEvent {
  // int? employee_id;
  final String earned_type;
  final String earned_date;
  final String reason;

  AddCompOff({
    required this.earned_type,
    required this.earned_date,
    required this.reason,
  });
}
