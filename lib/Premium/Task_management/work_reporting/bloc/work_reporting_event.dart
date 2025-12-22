part of 'work_reporting_bloc.dart';

@immutable
sealed class WorkReportingEvent {}

class GetWorkReporting extends WorkReportingEvent {}

class UpdateWorkReporting extends WorkReportingEvent {
  int? taskId;
  final List<String> todayplan;
  final List<String> todaycompletework;
  final List<String> nextdayplanning;

  UpdateWorkReporting({
    this.taskId,
    required this.todayplan,
    required this.todaycompletework,
    required this.nextdayplanning,
  });
}

class UpdateWorkStatus extends WorkReportingEvent {
  final int taskId;
  final String status;

  UpdateWorkStatus({
    required this.taskId,
    required this.status,
  });
}
