part of 'geo_location_bloc.dart';

@immutable
abstract class GeoLocationState {}

class GeoLocationInitial extends GeoLocationState {}

class GeoLocationLoading extends GeoLocationState {}

/// State when the active geo-locations are fetched successfully.
/// Contains a list of only the locations with "Active" status.
class GeoLocationSuccess extends GeoLocationState {
  final List<Map<String, dynamic>> activeLocations;
  GeoLocationSuccess({required this.activeLocations});
}

class GeoLocationFailure extends GeoLocationState {
  final String errorMessage;
  GeoLocationFailure({required this.errorMessage});
}
