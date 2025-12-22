class LeaveCardModel {
  final int leaveApplicationId;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final int quotaId;
  final String? leaveName;
  final String? leaveCode;
  final String creditType;
  final String startDate;
  final String endDate;
  final double totalDays;
  final String reason;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String leaveTypeName;

  LeaveCardModel({
    required this.leaveApplicationId,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.quotaId,
    this.leaveName,
    this.leaveCode,
    required this.creditType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.leaveTypeName,
  });

  factory LeaveCardModel.fromJson(Map<String, dynamic> json) {
    return LeaveCardModel(
      leaveApplicationId: _parseInt(json['leave_application_id']),
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      employeeCode: json['employee_code']?.toString() ?? '',
      quotaId: _parseInt(json['quota_id']),
      leaveName: json['leave_name']?.toString(),
      leaveCode: json['leave_code']?.toString(),
      creditType: json['credit_type']?.toString() ?? 'Full Day',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      totalDays: _parseDouble(json['total_days']),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      leaveTypeName: json['leave_type_name']?.toString() ?? 'Unknown Leave',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // Helper method to get the start date as DateTime
  DateTime get startDateTime {
    try {
      return DateTime.parse(startDate);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Helper method to get the end date as DateTime
  DateTime get endDateTime {
    try {
      return DateTime.parse(endDate);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Helper method to check if this leave is active (pending or approved)
  bool get isActiveLeave => status == 'Pending' || status == 'Approved';

  // Helper method to get all dates covered by this leave
  List<DateTime> get coveredDates {
    if (!isActiveLeave) return [];

    final dates = <DateTime>[];
    final start = startDateTime;
    final end = endDateTime;

    if (start.isAtSameMomentAs(end)) {
      dates.add(start);
    } else {
      DateTime current = start;
      while (!current.isAfter(end)) {
        dates.add(current);
        current = current.add(const Duration(days: 1));
      }
    }

    return dates;
  }
}
