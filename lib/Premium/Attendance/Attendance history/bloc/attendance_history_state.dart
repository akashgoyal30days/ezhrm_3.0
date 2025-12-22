part of 'attendance_history_bloc.dart';

@immutable
sealed class AttendanceHistoryState {}

final class AttendanceHistoryInitial extends AttendanceHistoryState {}

final class AttendanceHistoryLoading extends AttendanceHistoryState {}

final class AttendanceHistorySuccess extends AttendanceHistoryState {
  final List<Map<String, dynamic>> attendanceHistory;

  AttendanceHistorySuccess({required this.attendanceHistory});
}

final class AttendanceHistoryFailure extends AttendanceHistoryState {
  final String errorMessage;

  AttendanceHistoryFailure({required this.errorMessage});
}
