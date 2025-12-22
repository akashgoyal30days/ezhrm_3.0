// lib/Attendance/GetTodayAttendance/model/today_attendance_model.dart

class TodayAttendanceModel {
  final String inTime;
  final String outTime;

  TodayAttendanceModel({
    required this.inTime,
    required this.outTime,
  });

  factory TodayAttendanceModel.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceModel(
      inTime: json['check_in'] ?? "00:00 AM",
      outTime: json['check_out'] ?? "00:00 PM",
    );
  }
}
