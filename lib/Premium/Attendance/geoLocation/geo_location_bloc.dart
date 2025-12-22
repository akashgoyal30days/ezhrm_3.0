import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';
part 'geo_location_event.dart';
part 'geo_location_state.dart';

class GeoLocationBloc extends Bloc<GeoLocationEvent, GeoLocationState> {
  final ApiService apiService;
  final UserSession userSession;
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  GeoLocationBloc({
    required this.apiService,
    required this.userSession,
    required this.apiUrlConfig,
    required this.sessionBloc,
  }) : super(GeoLocationInitial()) {
    on<FetchGeoLocations>(_onFetchGeoLocations);
  }

  Future<void> _onFetchGeoLocations(
      FetchGeoLocations event, Emitter<GeoLocationState> emit) async {
    // --- DEBUG ---
    print('➡️ [GeoLocationBloc] Starting to fetch geo-locations...');
    emit(GeoLocationLoading());
    try {
      final token = await userSession.token;
      if (token == null || token.isEmpty) {
        // --- DEBUG ---
        print('❌ [GeoLocationBloc] Authentication token not found.');
        emit(GeoLocationFailure(
            errorMessage: 'Authentication token not found.'));
        return;
      }

      // --- DEBUG ---
      print('✅ [GeoLocationBloc] Authentication token found.');
      final headers = {
        'Authorization': token,
        'Accept': 'application/json',
      };

      final response = await apiService.makeRequest(
        endpoint: apiUrlConfig
            .geoLocation, // Make sure 'geoLocation' is correct in ApiUrlConfig
        method: 'GET',
        headers: headers,
      );

      // --- DEBUG ---
      print(
          '📦 [GeoLocationBloc] Raw API Response received: ${jsonEncode(response)}');

      if (response.containsKey('data')) {
        final dynamic dataField = response['data'];

        // --- DEBUG ---
        print(
            '🔍 [GeoLocationBloc] "data" field found. Its type is: ${dataField.runtimeType}');
        List<dynamic> allLocations = []; // Default to an empty list

        if (dataField is List) {
          // --- DEBUG ---
          print(
              '➡️ [GeoLocationBloc] Path A: "data" field is a List. Parsing directly.');
          allLocations = dataField;
        } else if (dataField is Map<String, dynamic>) {
          // --- DEBUG ---
          print(
              '➡️ [GeoLocationBloc] Path B: "data" field is a Map. Checking for nested lists.');
          if (dataField.containsKey('data') && dataField['data'] is List) {
            // --- DEBUG ---
            print(' nested list found under key "data".');
            allLocations = dataField['data'];
          } else if (dataField.containsKey('locations') &&
              dataField['locations'] is List) {
            // --- DEBUG ---
            print(' nested list found under key "locations".');
            allLocations = dataField['locations'];
          } else {
            // --- DEBUG ---
            print(
                '⚠️ [GeoLocationBloc] "data" is a Map, but no known nested list was found inside it.');
          }
        }

        // --- DEBUG ---
        print(
            '🔍 [GeoLocationBloc] Found ${allLocations.length} total locations before filtering.');

        final List<Map<String, dynamic>> activeLocations =
            List<Map<String, dynamic>>.from(allLocations)
                .where((location) => location['status'] == 'Active')
                .toList();

        // --- DEBUG ---
        print(
            '✅ [GeoLocationBloc] Found ${activeLocations.length} active locations after filtering.');
        print('✅ [GeoLocationBloc] Emitting GeoLocationSuccess.');
        emit(GeoLocationSuccess(activeLocations: activeLocations));
      } else {
        // --- DEBUG ---
        print(
            '❌ [GeoLocationBloc] API response does not contain a "data" key.');
        final String errorMessage = 'Failed to fetch geo-locations.';
        emit(GeoLocationFailure(errorMessage: errorMessage));
      }
    } catch (e) {
      // --- DEBUG ---
      print('❌ [GeoLocationBloc] An exception occurred in try-catch block: $e');
      emit(GeoLocationFailure(errorMessage: 'An error occurred: $e'));
    }
  }
}
