//state
part of 'get_today_attendance_bloc.dart';

@immutable
sealed class GetTodayAttendanceState {}

final class GetTodayAttendanceInitial extends GetTodayAttendanceState {}

final class GetTodayAttendanceLoading extends GetTodayAttendanceState {}

final class GetTodayAttendanceSuccess extends GetTodayAttendanceState {
  final List<Map<String, dynamic>> attendanceData;

  GetTodayAttendanceSuccess({required this.attendanceData});
}

final class GetTodayAttendanceFailure extends GetTodayAttendanceState {
  final String errorMessage;

  GetTodayAttendanceFailure(this.errorMessage);
}

//Fetch Pending Request

final class GetAllPendingRequestLoading extends GetTodayAttendanceState {}

final class GetAllPendingRequestSuccess extends GetTodayAttendanceState {
  final List<Map<String, dynamic>> pendingRequestData;

  GetAllPendingRequestSuccess({required this.pendingRequestData});
}

final class GetAllPendingRequestFailure extends GetTodayAttendanceState {
  final String errorMessage;

  GetAllPendingRequestFailure(this.errorMessage);
}

final class GetTodayAttendanceLogsInitial extends GetTodayAttendanceState {}

final class GetTodayAttendanceLogsLoading extends GetTodayAttendanceState {}

final class GetTodayAttendanceLogsSuccess extends GetTodayAttendanceState {
  final List<Map<String, dynamic>> attendanceData;

  GetTodayAttendanceLogsSuccess({required this.attendanceData});
}

final class GetTodayAttendanceLogsFailure extends GetTodayAttendanceState {
  final String errorMessage;

  GetTodayAttendanceLogsFailure(this.errorMessage);
}

//req

@immutable
sealed class RequTodayAttendanceState {}

final class RequTodayAttendanceInitial extends RequTodayAttendanceState {}

final class RequTodayAttendanceLoading extends RequTodayAttendanceState {}

final class RequTodayAttendanceSuccess extends RequTodayAttendanceState {
  final List<Map<String, dynamic>> requAttendanceData;

  RequTodayAttendanceSuccess({required this.requAttendanceData});
}

final class RequTodayAttendanceFailure extends RequTodayAttendanceState {
  final String errorMessage;

  RequTodayAttendanceFailure(this.errorMessage);
}
