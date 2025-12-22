part of 'holiday_bloc.dart';

@immutable
sealed class HolidayEvent {}

class FetchHolidays extends HolidayEvent {}
