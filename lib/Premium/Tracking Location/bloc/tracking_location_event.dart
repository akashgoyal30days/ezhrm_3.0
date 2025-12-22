part of 'tracking_location_bloc.dart';

@immutable
sealed class TrackingLocationEvent {}

class TrackingLocation extends TrackingLocationEvent {
  final String time;
  final String lat;
  final String lng;

  TrackingLocation({
    required this.time,
    required this.lat,
    required this.lng,
  });
}

class GetTimeInterval extends TrackingLocationEvent {}
