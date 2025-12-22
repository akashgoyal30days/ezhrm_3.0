part of 'req_past_attendance_bloc.dart';

sealed class ReqPastAttendanceState {}

final class ReqPastAttendanceInitial extends ReqPastAttendanceState {}

final class ReqPastAttendanceLoading extends ReqPastAttendanceState {}

final class ReqPastAttendanceSuccess extends ReqPastAttendanceState {
  final List<Map<String, dynamic>> responseData;
  ReqPastAttendanceSuccess({required this.responseData});
}

final class ReqPastAttendanceFailure extends ReqPastAttendanceState {
  final String message;
  ReqPastAttendanceFailure({required this.message});
}

final class ReqPastAttendanceHistoryInitial extends ReqPastAttendanceState {}

final class ReqPastAttendanceHistoryLoading extends ReqPastAttendanceState {}

final class ReqPastAttendanceHistorySuccess extends ReqPastAttendanceState {
  final List<Map<String, dynamic>> responseData;
  ReqPastAttendanceHistorySuccess({required this.responseData});
}

final class ReqPastAttendanceHistoryFailure extends ReqPastAttendanceState {
  final String message;
  ReqPastAttendanceHistoryFailure({required this.message});
}
