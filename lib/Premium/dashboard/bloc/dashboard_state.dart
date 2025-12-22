part of 'dashboard_bloc.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final UserProfile profile;

  DashboardLoaded(this.profile);
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}
