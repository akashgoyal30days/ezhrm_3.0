part of 'geo_location_bloc.dart';

@immutable
abstract class GeoLocationEvent {}

/// Event triggered to fetch the list of geo-locations from the API.
class FetchGeoLocations extends GeoLocationEvent {}
