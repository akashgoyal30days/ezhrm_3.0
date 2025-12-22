part of 'work_from_home_bloc.dart';

@immutable
sealed class WorkFromHomeEvent {}

class RequestWorkFromHome extends WorkFromHomeEvent {
  double? employee_id;
  final String start_date;
  final String end_date;
  final String reason;

  RequestWorkFromHome(
      {required this.start_date, required this.end_date, required this.reason});
}

class GetWorkFromHome extends WorkFromHomeEvent {}
