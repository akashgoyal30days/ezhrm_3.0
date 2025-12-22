part of 'req_today_attendance_bloc.dart';

@immutable
sealed class ReqTodayAttendanceEvent {}

// This single event now handles both check-in and check-out
class RequestTodayAttendance extends ReqTodayAttendanceEvent {
  final String latitude;
  final String longitude;
  final File? imageBase;

  // A flag to decide the action
  final bool isCheckIn;

  // Fields for Check-In
  final String? attendanceDate;
  final String? checkInTime;

  // Fields for Check-Out
  final String? attendanceId;
  final String? checkOutTime;

  RequestTodayAttendance({
    required this.latitude,
    required this.longitude,
    this.imageBase,
    this.isCheckIn = true, // Default to check-in
    this.attendanceDate,
    this.checkInTime,
    this.attendanceId,
    this.checkOutTime,
  });
}
