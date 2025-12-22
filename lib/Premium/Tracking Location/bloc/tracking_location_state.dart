part of 'tracking_location_bloc.dart';

@immutable
sealed class TrackingLocationState {}

final class TrackingLocationInitial extends TrackingLocationState {}

final class TrackingLocationLoading extends TrackingLocationState {}

final class TrackingLocationSuccess extends TrackingLocationState {
  final String message;

  TrackingLocationSuccess({required this.message});
}

final class GetTimeIntervalSuccess extends TrackingLocationState {
  final double timeInterval;
  GetTimeIntervalSuccess({required this.timeInterval});
}

final class GetTimeIntervalFailure extends TrackingLocationState {
  final String errorMessage;
  GetTimeIntervalFailure({required this.errorMessage});
}

final class TrackingLocationFailure extends TrackingLocationState {
  final String errorMessage;

  TrackingLocationFailure({required this.errorMessage});
}
