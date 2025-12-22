part of 'req_past_attendance_bloc.dart';

sealed class ReqPastAttendanceEvent {}

class ReqPastAttendance extends ReqPastAttendanceEvent {
  String? employee_id;
  final String attendance_date;
  final String attendance_upto;
  final String remarks;
  final String latitude;
  final String longitude;
  final String? imageBase; // New field for base64-encoded image

  ReqPastAttendance({
    required this.attendance_date,
    required this.attendance_upto,
    required this.remarks,
    required this.latitude,
    required this.longitude,
    this.imageBase, // Optional image data
  });
}

class ReqPastAttendanceHistory extends ReqPastAttendanceEvent{}
