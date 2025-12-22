part of 'dashboard_bloc.dart';

abstract class DashboardEvent {}

class FetchDashboardData extends DashboardEvent {
  final String userId;

  FetchDashboardData(this.userId);
}
