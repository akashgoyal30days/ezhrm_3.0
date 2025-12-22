part of 'attendance_history_bloc.dart';

@immutable
sealed class AttendanceHistoryEvent {}

class FetchAttendanceHistory extends AttendanceHistoryEvent {}
