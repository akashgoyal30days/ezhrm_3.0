part of 'holiday_bloc.dart';

@immutable
sealed class HolidayState {}

final class HolidayInitial extends HolidayState {}

final class HolidayLoading extends HolidayState {}

final class HolidayLoaded extends HolidayState {
  final List<HolidayModel> holidaysList;

  HolidayLoaded(this.holidaysList);
}

final class HolidayError extends HolidayState {
  final String errorMessage;

  HolidayError(this.errorMessage);
}
