part of 'week_off_bloc.dart';

@immutable
sealed class WeekOffEvent {}

class GetWeekOff extends WeekOffEvent {}

class GetEmployeeWeekOff extends WeekOffEvent {}
