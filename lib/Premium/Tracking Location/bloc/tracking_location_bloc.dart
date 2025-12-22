import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiService.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../SessionHandling/session_bloc.dart';

part 'tracking_location_event.dart';
part 'tracking_location_state.dart';

class TrackingLocationBloc
    extends Bloc<TrackingLocationEvent, TrackingLocationState> {
  final ApiService apiService; // Dependency
  final UserSession userSession; // Dependency
  final ApiUrlConfig apiUrlConfig;
  final SessionBloc sessionBloc;

  TrackingLocationBloc(
      {required this.apiService,
      required this.userSession,
      required this.apiUrlConfig,
      required this.sessionBloc})
      : super(TrackingLocationInitial()) {
    on<TrackingLocation>(_onTrackingLocation);
    on<GetTimeInterval>(_onGetTimeInterval);
  }

  Future<void> _onTrackingLocation(
      TrackingLocation event, Emitter<TrackingLocationState> emit) async {
    emit(TrackingLocationLoading());
    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching location for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      final body = {
        'employee_id': uid,
        'date': DateFormat('yyyy-MM-dd')
            .format(DateTime.now()), // Convert DateTime to string
        'time': event.time,
        'lat': event.lat,
        'lng': event.lng,
      };

      // Call the API to fetch company info
      final response = await apiService.makeRequest(
          endpoint: apiUrlConfig.addLocation,
          method: 'POST',
          headers: headers,
          body: body);

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        // Safely extract the data
        final message = response['data']['message'];
        emit(TrackingLocationSuccess(message: message));
        print('response from the api for sending user location: $message');
      } else {
        final String errorMessage = 'Failed to send user location.';
        print('error in sending location of user: $errorMessage');
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          print('Error in marking today attendance: $errorMessage');
          emit(TrackingLocationFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('error in sending location of user Exception: $e');
      if (e.toString().toLowerCase().contains('token') ||
          e.toString().toLowerCase().contains('session expired')) {
        sessionBloc.add(SessionExpired());
      } else if (e.toString().contains('User not found')) {
        sessionBloc.add(UserNotFound());
        print('User not found: $e');
      } else {
        emit(TrackingLocationFailure(
            errorMessage: 'Error in marking today attendance: $e'));
      }
    }
  }

  Future<void> _onGetTimeInterval(
      GetTimeInterval event, Emitter<TrackingLocationState> emit) async {
    emit(TrackingLocationLoading());
    try {
      // Fetch UID and Token from UserSession
      final String? uid = await userSession.uid;
      final String? token = await userSession.token;

      print('Fetching time interval for UID: $uid with Token: $token');

      // Prepare headers with Authorization
      final Map<String, String> headers = {
        'Authorization': token ?? '', // Add 'Bearer ' if your API requires it
      };

      print('endpoint is ${apiUrlConfig.getTimeInterval}$uid');
      // Call the API to fetch company info
      final response = await apiService.makeRequest(
        endpoint: '${apiUrlConfig.getTimeInterval}$uid',
        method: 'GET',
        headers: headers,
      );

      print('API Response: $response');

      // Check response
      if (response['success'] == true) {
        final data = response['data'];

        if (data != null) {
          final trackList = data['data'] as List<dynamic>;

          if (trackList.isEmpty) {
            emit(GetTimeIntervalFailure(
                errorMessage: 'No tracking records found.'));
            print('⚠️ No tracking records found');
            return;
          }

          // Get the first tracking record
          final trackRecord = trackList[0] as Map<String, dynamic>;
          final trackingStatus = trackRecord['status'];
          final interval = trackRecord['tracking_interval'];

          if (trackingStatus == 1) {
            // Tracking enabled
            double timeInterval;
            if (interval is num) {
              timeInterval = interval.toDouble();
            } else if (interval is String) {
              timeInterval = double.tryParse(interval) ?? 1.0;
            } else {
              throw Exception(
                  'Unexpected tracking_interval type: ${interval.runtimeType}');
            }

            emit(GetTimeIntervalSuccess(timeInterval: timeInterval));
            print('✅ Tracking enabled. Time interval: $timeInterval');
          } else {
            // Tracking disabled
            emit(GetTimeIntervalFailure(
                errorMessage: 'Location tracking is disabled.'));
            print('🚫 Tracking is disabled (status: $trackingStatus)');
          }
        } else {
          print('⚠️ API data field is null');
          emit(GetTimeIntervalFailure(
              errorMessage: 'No data found in response.'));
        }
      } else {
        final String errorMessage = 'Failed to fetch time interval.';
        if (errorMessage.toLowerCase().contains('invalid token') ||
            errorMessage.toLowerCase().contains('session expired')) {
          sessionBloc.add(SessionExpired());
          print('Session is expired: $errorMessage');
        } else if (errorMessage.contains('User not found')) {
          sessionBloc.add(UserNotFound());
          print('User not found: $errorMessage');
        } else {
          print('Failed to fetch time interval: $errorMessage');
          emit(GetTimeIntervalFailure(errorMessage: errorMessage));
        }
      }
    } catch (e) {
      print('error in fetching time interval of user Exception: $e');
      if (e.toString().toLowerCase().contains('token') ||
          e.toString().toLowerCase().contains('session expired')) {
        sessionBloc.add(SessionExpired());
      } else if (e.toString().contains('User not found')) {
        sessionBloc.add(UserNotFound());
        print('User not found: $e');
      } else {
        emit(GetTimeIntervalFailure(
            errorMessage: 'Failed to fetch time interval: $e'));
      }
    }
  }
}
