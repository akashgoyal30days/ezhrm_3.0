part of 'work_reporting_bloc.dart';

@immutable
sealed class WorkReportingState {}

final class WorkReportingInitial extends WorkReportingState {}

final class WorkReportingLoading extends WorkReportingState {}

final class WorkReportingSuccess extends WorkReportingState {
  final List<Map<String, dynamic>> workReporting;

  WorkReportingSuccess({required this.workReporting});
}

final class WorkReportingFailure extends WorkReportingState {
  final String errorMessage;

  WorkReportingFailure({required this.errorMessage});
}

final class UpdateWorkReportingSuccess extends WorkReportingState {
  final List<Map<String, dynamic>> updateWorkReporting;

  UpdateWorkReportingSuccess({required this.updateWorkReporting});
}

final class UpdateWorkReportingFailure extends WorkReportingState {
  final String errorMessage;

  UpdateWorkReportingFailure({required this.errorMessage});
}
