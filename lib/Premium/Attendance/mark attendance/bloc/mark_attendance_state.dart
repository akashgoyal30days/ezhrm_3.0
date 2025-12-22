part of 'mark_attendance_bloc.dart';

@immutable
sealed class MarkAttendanceState {}

final class MarkAttendanceInitial extends MarkAttendanceState {}

final class MarkAttendanceLoading extends MarkAttendanceState {}

final class MarkAttendanceSuccess extends MarkAttendanceState {
  final String message;

  MarkAttendanceSuccess({required this.message});
}

final class MarkAttendanceFailure extends MarkAttendanceState {
  final String errorMessage;

  MarkAttendanceFailure({required this.errorMessage});
}
