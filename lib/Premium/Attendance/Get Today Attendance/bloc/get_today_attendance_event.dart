//event
part of 'get_today_attendance_bloc.dart';

@immutable
sealed class GetTodayAttendanceEvent {}

class GetTodayAttendance extends GetTodayAttendanceEvent {}

class GetTodayAttendanceLogs extends GetTodayAttendanceEvent {}

class GetAllPendingRequest extends GetTodayAttendanceEvent {}

@immutable
sealed class RequTodayAttendanceEvent {}

class RequTodayAttendance extends RequTodayAttendanceEvent {}
