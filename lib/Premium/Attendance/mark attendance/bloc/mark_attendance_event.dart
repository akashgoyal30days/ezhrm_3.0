part of 'mark_attendance_bloc.dart';

@immutable
sealed class MarkAttendanceEvent {}

class MarkAttendance extends MarkAttendanceEvent {
  String? employee_id;
  final String? latitude;
  final String? longitude;
  final int? faceRate;

  MarkAttendance({
    this.latitude,
    this.longitude,
    this.faceRate,
  });
}
