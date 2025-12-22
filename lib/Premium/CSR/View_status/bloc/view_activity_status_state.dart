part of 'view_activity_status_bloc.dart';

@immutable
sealed class ViewActivityStatusState {}

final class ViewActivityStatusInitial extends ViewActivityStatusState {}

final class ViewActivityStatusLoading extends ViewActivityStatusState {}

final class ViewActivityStatusLoaded extends ViewActivityStatusState {
  final List<Map<String, dynamic>> activityStatus;

  ViewActivityStatusLoaded({required this.activityStatus});
}

final class ViewActivityStatusError extends ViewActivityStatusState {
  final String errorMessage;

  ViewActivityStatusError({required this.errorMessage});
}
