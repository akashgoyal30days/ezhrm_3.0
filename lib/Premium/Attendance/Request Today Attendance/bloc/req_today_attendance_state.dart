part of 'req_today_attendance_bloc.dart';

@immutable
sealed class ReqTodayAttendanceState {}

final class ReqTodayAttendanceInitial extends ReqTodayAttendanceState {}

final class ReqTodayAttendanceLoading extends ReqTodayAttendanceState {}

final class ReqTodayAttendanceSuccess extends ReqTodayAttendanceState {
  final Map<String, dynamic> responseData;
  ReqTodayAttendanceSuccess({required this.responseData});
}

final class ReqTodayAttendanceFailure extends ReqTodayAttendanceState {
  final String message;
  ReqTodayAttendanceFailure({required this.message});
}
