part of 'week_off_bloc.dart';

@immutable
sealed class WeekOffState {}

final class WeekOffInitial extends WeekOffState {}

final class WeekOffLoading extends WeekOffState {}

final class WeekOffSuccess extends WeekOffState {
  final List<Map<String, dynamic>> weekOffData;
  WeekOffSuccess({required this.weekOffData});
}

final class WeekOffFailure extends WeekOffState {
  final String errorMessage;
  WeekOffFailure({required this.errorMessage});
}

final class EmployeeWeekOffInitial extends WeekOffState {}

final class EmployeeWeekOffLoading extends WeekOffState {}

final class EmployeeWeekOffSuccess extends WeekOffState {
  final List<Map<String, dynamic>> employeeWeekOffData;
  EmployeeWeekOffSuccess({required this.employeeWeekOffData});
}

final class EmployeeWeekOffFailure extends WeekOffState {
  final String errorMessage;
  EmployeeWeekOffFailure({required this.errorMessage});
}
