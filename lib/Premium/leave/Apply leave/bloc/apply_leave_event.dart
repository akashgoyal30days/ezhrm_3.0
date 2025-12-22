part of 'apply_leave_bloc.dart';

@immutable
sealed class ApplyLeaveEvent {}

class ApplyLeave extends ApplyLeaveEvent {
  final int? employee_id;
  final int quota_id;
  final String credit_type;
  final String start_date;
  final String end_date;
  final double total_days;
  final String reason;
  final String? status;
  final int? approved_by;
  final String? remarks;

  ApplyLeave({
    this.employee_id,
    required this.quota_id,
    required this.credit_type,
    required this.start_date,
    required this.end_date,
    required this.total_days,
    required this.reason,
    this.status,
    this.approved_by,
    this.remarks,
  });
}
