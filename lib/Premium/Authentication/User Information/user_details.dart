import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDetails {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _isInitializedKey = 'user_details_initialized';

  // Keys matching LocationService for consistency
  static const String _lastSendTimeKey = 'last_location_send_time';
  static const String _intervalKey = 'location_update_interval';
  static const String _profileImageKey = 'profile_image';
  static const String _isTrackingEnabledKey = 'is_tracking_enabled';
  static const String _isTrackingStatusEnabledKey =
      'is_tracking_status_enabled';
  static const String _isCheckedInKey = 'is_checked_in';
  static const String _isCheckedOutKey = 'is_checked_out';
  static const String _newCheckoutTimeKey = 'last_checkout_time';
  static const String _currentCheckoutTimeKey = 'current_checkout_time';
  static const String _startTimeKey = 'start_time';
  static const String _endTimeKey = 'end_time';
  static const String _lastProcessedTime = 'last_processed_time';
  static const String _fcmToken = 'fcm_token';
  static const String _deviceIdToken = 'deviceId';
  static const String _faceRecognitionToken = 'faceRecognition';
  static const String _autoAttendanceToken = 'autoAttendance';
  static const String _gpsLocationToken = 'gpsLocation';
  static const String _reqAttendanceToken = 'reqAttendance';

  // Helper to get SharedPreferences instance
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // Initialize UserDetails to ensure consistency across app restarts
  Future<void> initialize() async {
    print('UserDetails: Initializing UserDetails');
    try {
      final prefs = await _getPrefs();
      bool isInitialized = prefs.getBool(_isInitializedKey) ?? false;

      if (!isInitialized) {
        // Sync all values from FlutterSecureStorage to SharedPreferences
        // await _syncStorageToPrefs();
        await prefs.setBool(_isInitializedKey, true);
        print('UserDetails: Initialization complete - Synced storage to prefs');
      } else {
        // Verify consistency between storage and prefs
        // await _verifyAndSyncStorage();
        print('UserDetails: Consistency check complete');
      }
    } catch (e) {
      print('UserDetails: Error during initialization: $e');
    }
  }

  // // Sync all values from FlutterSecureStorage to SharedPreferences
  // Future<void> _syncStorageToPrefs() async {
  //   final prefs = await _getPrefs();
  //   final keys = [
  //     _isCheckedInKey,
  //     _isCheckedOutKey,
  //     _currentCheckoutTimeKey,
  //     _newCheckoutTimeKey,
  //     _isTrackingEnabledKey,
  //     _intervalKey,
  //     _lastSendTimeKey,
  //     'userName',
  //     'email',
  //     'profileImg',
  //     'screen_password',
  //     'start_time',
  //     'end_time',
  //   ];
  //
  //   for (final key in keys) {
  //     final value = await _storage.read(key: key);
  //     if (value != null) {
  //       if (key == _isCheckedInKey || key == _isCheckedOutKey || key == _isTrackingEnabledKey) {
  //         await prefs.setBool(key, value == 'true');
  //       } else if (key == _intervalKey) {
  //         final intValue = int.tryParse(value);
  //         if (intValue != null) await prefs.setInt(key, intValue);
  //       } else {
  //         await prefs.setString(key, value);
  //       }
  //     } else {
  //       await prefs.remove(key);
  //     }
  //   }
  //   print('UserDetails: Synced all values from SecureStorage to SharedPreferences');
  // }
  //
  // // Verify consistency and resolve conflicts (prioritize FlutterSecureStorage)
  // Future<void> _verifyAndSyncStorage() async {
  //   final prefs = await _getPrefs();
  //   final keys = [
  //     _isCheckedInKey,
  //     _isCheckedOutKey,
  //     _currentCheckoutTimeKey,
  //     _newCheckoutTimeKey,
  //     _isTrackingEnabledKey,
  //     _intervalKey,
  //     _lastSendTimeKey,
  //     'userName',
  //     'email',
  //     'profileImg',
  //     'screen_password',
  //     'start_time',
  //     'end_time',
  //   ];
  //
  //   for (final key in keys) {
  //     final storageValue = await _storage.read(key: key);
  //     if (key == _isCheckedInKey || key == _isCheckedOutKey || key == _isTrackingEnabledKey) {
  //       final prefValue = prefs.getBool(key);
  //       if (storageValue != null && prefValue != (storageValue == 'true')) {
  //         await prefs.setBool(key, storageValue == 'true');
  //         print('UserDetails: Synced $key from SecureStorage ($storageValue) to SharedPreferences');
  //       } else if (storageValue == null && prefValue != null) {
  //         await _storage.write(key: key, value: prefValue.toString());
  //         print('UserDetails: Synced $key from SharedPreferences ($prefValue) to SecureStorage');
  //       }
  //     } else if (key == _intervalKey) {
  //       final prefValue = prefs.getInt(key);
  //       final storageInt = int.tryParse(storageValue ?? '');
  //       if (storageValue != null && prefValue != storageInt) {
  //         await prefs.setInt(key, storageInt!);
  //         print('UserDetails: Synced $key from SecureStorage ($storageValue) to SharedPreferences');
  //       } else if (storageValue == null && prefValue != null) {
  //         await _storage.write(key: key, value: prefValue.toString());
  //         print('UserDetails: Synced $key from SharedPreferences ($prefValue) to SecureStorage');
  //       }
  //     } else {
  //       final prefValue = prefs.getString(key);
  //       if (storageValue != null && prefValue != storageValue) {
  //         await prefs.setString(key, storageValue);
  //         print('UserDetails: Synced $key from SecureStorage ($storageValue) to SharedPreferences');
  //       } else if (storageValue == null && prefValue != null) {
  //         await _storage.write(key: key, value: prefValue);
  //         print('UserDetails: Synced $key from SharedPreferences ($prefValue) to SecureStorage');
  //       }
  //     }
  //   }
  // }

  Future<bool> getCheckedIn() async {
    try {
      final value = await _storage.read(key: _isCheckedInKey);
      final prefs = await _getPrefs();
      final prefValue = prefs.getBool(_isCheckedInKey);
      final result = value == 'true' || prefValue == true;
      print(
          'UserDetails: getCheckedIn - SecureStorage: $value, SharedPrefs: $prefValue, Result: $result');
      return result;
    } catch (e) {
      print('UserDetails: Error getting checked-in status: $e');
      return false;
    }
  }

  Future<void> setCheckedIn(bool value, {bool forceUpdate = false}) async {
    try {
      await _storage.write(key: _isCheckedInKey, value: value.toString());
      final prefs = await _getPrefs();
      await prefs.setBool(_isCheckedInKey, value);
      print(
          'UserDetails: setCheckedIn - Value: $value, ForceUpdate: $forceUpdate');
    } catch (e) {
      print('UserDetails: Error setting checked-in status: $e');
    }
  }

  Future<String?> getLastProcessedTime() async {
    try {
      final value = await _storage.read(key: _lastProcessedTime);
      final prefs = await _getPrefs();
      final prefValue = prefs.getString(_lastProcessedTime);
      print(
          'last processed time - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error getting last processed time status: $e');
      return null;
    }
  }

  Future<void> setLastProcessedTime(String? value,
      {bool forceUpdate = false}) async {
    try {
      await _storage.write(key: _lastProcessedTime, value: value.toString());
      final prefs = await _getPrefs();
      if (value != null && value.isNotEmpty) {
        await prefs.setString(_lastProcessedTime, value);
        print(
            'UserDetails: setCheckedIn - Value: $value, ForceUpdate: $forceUpdate');
      }
    } catch (e) {
      print('UserDetails: Error setting checked-in status: $e');
    }
  }

  Future<bool> getCheckedOut() async {
    try {
      final value = await _storage.read(key: _isCheckedOutKey);
      final prefs = await _getPrefs();
      final prefValue = prefs.getBool(_isCheckedOutKey);
      final result = value == 'true' || prefValue == true;
      print(
          'UserDetails: getCheckedOut - SecureStorage: $value, SharedPrefs: $prefValue, Result: $result');
      return result;
    } catch (e) {
      print('UserDetails: Error getting checked-out status: $e');
      return false;
    }
  }

  Future<void> setCheckedOut(bool value, String? checkoutTime,
      {bool forceUpdate = false}) async {
    try {
      await _storage.write(key: _isCheckedOutKey, value: value.toString());
      final prefs = await _getPrefs();
      await prefs.setBool(_isCheckedOutKey, value);

      if (checkoutTime != null && checkoutTime.isNotEmpty) {
        await _storage.write(key: _currentCheckoutTimeKey, value: checkoutTime);
        await _storage.write(key: _newCheckoutTimeKey, value: checkoutTime);
        await prefs.setString(_currentCheckoutTimeKey, checkoutTime);
        await prefs.setString(_newCheckoutTimeKey, checkoutTime);
        print(
            'UserDetails: setCheckedOut - Value: $value, CurrentCheckoutTime: $checkoutTime, NewCheckoutTime: $checkoutTime, ForceUpdate: $forceUpdate');
      } else {
        await _storage.delete(key: _currentCheckoutTimeKey);
        await _storage.delete(key: _newCheckoutTimeKey);
        await prefs.remove(_currentCheckoutTimeKey);
        await prefs.remove(_newCheckoutTimeKey);
        print(
            'UserDetails: setCheckedOut - Value: $value, Checkout time cleared, ForceUpdate: $forceUpdate');
      }
    } catch (e) {
      print('UserDetails: Error setting checked-out status or time: $e');
    }
  }

  Future<void> setStartTime(String? startTime) async {
    try {
      await _storage.write(key: _startTimeKey, value: startTime);
      final prefs = await _getPrefs();
      if (startTime != null && startTime.isNotEmpty) {
        await prefs.setString(_startTimeKey, startTime);
      } else {
        print('start time is empty');
      }
    } catch (e) {
      print('UserDetails: Error setting start time: $e');
    }
  }

  Future<void> setEndTime(String? endTime) async {
    try {
      await _storage.write(key: _endTimeKey, value: endTime);
      final prefs = await _getPrefs();
      if (endTime != null && endTime.isNotEmpty) {
        await prefs.setString(_endTimeKey, endTime);
      } else {
        print('start time is empty');
      }
    } catch (e) {
      print('UserDetails: Error setting start time: $e');
    }
  }

  Future<String?> getStartTime() async {
    try {
      final value = await _storage.read(key: _startTimeKey);
      final prefs = await _getPrefs();
      final prefValue = prefs.getString(_startTimeKey);
      print(
          'UserDetails: getStartTime - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error in getting start time: $e');
      return null;
    }
  }

  Future<String?> getEndTime() async {
    try {
      final value = await _storage.read(key: _endTimeKey);
      final prefs = await _getPrefs();
      final prefValue = prefs.getString(_endTimeKey);
      print(
          'UserDetails: getEndTime - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error in getting end time: $e');
      return null;
    }
  }

  Future<void> setCheckOutValue(bool value, {bool forceUpdate = false}) async {
    try {
      await _storage.write(key: _isCheckedOutKey, value: value.toString());
      final prefs = await _getPrefs();
      await prefs.setBool(_isCheckedOutKey, value);
      print(
          'UserDetails: setCheckOutValue - Value: $value, ForceUpdate: $forceUpdate');
    } catch (e) {
      print('UserDetails: Error setting checked-out status: $e');
    }
  }

  Future<String?> getCheckoutTime() async {
    try {
      final value = await _storage.read(key: _currentCheckoutTimeKey);
      final prefs = await _getPrefs();
      final prefValue = prefs.getString(_currentCheckoutTimeKey);
      print(
          'UserDetails: getCheckoutTime - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error getting checkout time: $e');
      return null;
    }
  }

  Future<String?> getNewCheckoutTime() async {
    try {
      final value = await _storage.read(key: _newCheckoutTimeKey);
      final prefs = await _getPrefs();
      final prefValue = prefs.getString(_newCheckoutTimeKey);
      print(
          'UserDetails: getNewCheckoutTime - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error getting new checkout time: $e');
      return null;
    }
  }

  Future<void> setNewCheckedOut(String checkoutTime,
      {bool forceUpdate = false}) async {
    try {
      if (checkoutTime.isEmpty) {
        throw ArgumentError('New checkout time cannot be empty');
      }
      await _storage.write(key: _newCheckoutTimeKey, value: checkoutTime);
      final prefs = await _getPrefs();
      await prefs.setString(_newCheckoutTimeKey, checkoutTime);
      print(
          'UserDetails: setNewCheckedOut - NewCheckoutTime: $checkoutTime, ForceUpdate: $forceUpdate');
    } catch (e) {
      print('UserDetails: Error setting new checked-out time: $e');
    }
  }

  Future<bool> getLocationPermission() async {
    try {
      final value = await _storage.read(key: _isTrackingEnabledKey);
      final prefs = await _getPrefs();
      final prefValue = prefs.getBool(_isTrackingEnabledKey);
      final result = value == 'true' || prefValue == true;
      print(
          'UserDetails: getIsTrackingEnabled - SecureStorage: $value, SharedPrefs: $prefValue, Result: $result');
      return result;
    } catch (e) {
      print('UserDetails: Error getting tracking permission: $e');
      return false;
    }
  }

  Future<void> setLocationPermission(bool enabled,
      {bool forceUpdate = false}) async {
    try {
      await _storage.write(
          key: _isTrackingEnabledKey, value: enabled.toString());
      final prefs = await _getPrefs();
      await prefs.setBool(_isTrackingEnabledKey, enabled);
      print(
          'UserDetails: setTrackingPermission - Value: $enabled, ForceUpdate: $forceUpdate');
    } catch (e) {
      print('UserDetails: Error setting tracking permission: $e');
    }
  }

  // this getter and setter for checking the user tracking status so enable location tracking.
  Future<bool> getTrackingStatus() async {
    try {
      final value = await _storage.read(key: _isTrackingStatusEnabledKey);
      final prefs = await _getPrefs();
      final prefValue = prefs.getBool(_isTrackingStatusEnabledKey);
      final result = value == 'true' || prefValue == true;
      print(
          'UserDetails: getTrackingEnabled - SecureStorage: $value, SharedPrefs: $prefValue, Result: $result');
      return result;
    } catch (e) {
      print('UserDetails: Error in getting tracking status: $e');
      return false;
    }
  }

  Future<void> setTrackingStatus(bool enabled,
      {bool forceUpdate = false}) async {
    try {
      await _storage.write(
          key: _isTrackingStatusEnabledKey, value: enabled.toString());
      final prefs = await _getPrefs();
      await prefs.setBool(_isTrackingStatusEnabledKey, enabled);
      print(
          'UserDetails: setTrackingEnabled - Value: $enabled, ForceUpdate: $forceUpdate');
    } catch (e) {
      print('UserDetails: Error setting tracking status: $e');
    }
  }

  Future<double?> getTimeInterval() async {
    try {
      final value = await _storage.read(key: _intervalKey);
      final prefs = await _getPrefs();
      final prefValue = prefs.getInt(_intervalKey);
      final result =
          value != null ? double.tryParse(value) : prefValue?.toDouble();
      print(
          'UserDetails: getTimeInterval - SecureStorage: $value, SharedPrefs: $prefValue, Result: $result');
      return result;
    } catch (e) {
      print('UserDetails: Error getting time interval: $e');
      return null;
    }
  }

  Future<void> setTimeInterval(double? interval,
      {bool forceUpdate = false}) async {
    try {
      if (interval == null) {
        // If you want to remove the stored interval
        await _storage.delete(key: _intervalKey);
        final prefs = await _getPrefs();
        await prefs.remove(_intervalKey);
        print('UserDetails: Cleared time interval (set to null)');
        return;
      }

      if (interval <= 0) {
        throw ArgumentError('Time interval must be positive: $interval');
      }
      await _storage.write(key: _intervalKey, value: interval.toString());
      final prefs = await _getPrefs();
      await prefs.setInt(_intervalKey, interval.toInt());
      print(
          'UserDetails: setTimeInterval - Value: $interval, ForceUpdate: $forceUpdate');
    } catch (e) {
      print('UserDetails: Error setting time interval: $e');
    }
  }

  Future<String?> getLastSendTime() async {
    try {
      final value = await _storage.read(key: _lastSendTimeKey);
      final prefs = await _getPrefs();
      final prefValue = prefs.getString(_lastSendTimeKey);
      print(
          'UserDetails: getLastSendTime - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error getting last send time: $e');
      return null;
    }
  }

  Future<void> setLastSendTime(String sendTime,
      {bool forceUpdate = false}) async {
    try {
      await _storage.write(key: _lastSendTimeKey, value: sendTime);
      final prefs = await _getPrefs();
      await prefs.setString(_lastSendTimeKey, sendTime);
      print(
          'UserDetails: setLastSendTime - Value: $sendTime, ForceUpdate: $forceUpdate');
    } catch (e) {
      print('UserDetails: Error setting last send time: $e');
    }
  }

  Future<void> setUserDetails({
    required String userName,
    required String email,
    required String imageUrl,
    bool forceUpdate = false,
  }) async {
    try {
      await _storage.write(key: 'userName', value: userName);
      await _storage.write(key: 'email', value: email);
      await _storage.write(key: 'imageUrl', value: imageUrl);
      final prefs = await _getPrefs();
      await prefs.setString('userName', userName);
      await prefs.setString('email', email);
      await prefs.setString('imageUrl', imageUrl);
      print(
          'UserDetails: setUserDetails - userName: $userName, email: $email, imageUrl: $imageUrl, ForceUpdate: $forceUpdate');
    } catch (e) {
      print('UserDetails: Error setting user details: $e');
    }
  }

  Future<Map<String, String?>> getUserDetails() async {
    try {
      final userName = await _storage.read(key: 'userName');
      final email = await _storage.read(key: 'email');
      final imageUrl = await _storage.read(key: 'imageUrl');
      final prefs = await _getPrefs();
      final prefUserName = prefs.getString('userName');
      final prefEmail = prefs.getString('email');
      final prefImageUrl = prefs.getString('imageUrl');
      print(
          'UserDetails: getUserDetails - SecureStorage: {userName: $userName, email: $email, imageUrl: $imageUrl},'
          ' SharedPrefs: {userName: $prefUserName, imageUrl: $prefImageUrl, imageUrl: $prefEmail}');
      return {
        'userName': userName ?? prefUserName,
        'email': email ?? prefEmail,
        'imageUrl': imageUrl ?? prefImageUrl,
      };
    } catch (e) {
      print('UserDetails: Error getting user details: $e');
      return {'userName': null, 'imageUrl': null, 'email': null};
    }
  }

  Future<String?> getUserName() async {
    try {
      final value = await _storage.read(key: 'userName');
      final prefs = await _getPrefs();
      final prefValue = prefs.getString('userName');
      print(
          'UserDetails: getUserName - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error getting userName: $e');
      return null;
    }
  }

  Future<String?> getProfileImg() async {
    try {
      final value = await _storage.read(key: 'profileImg');
      final prefs = await _getPrefs();
      final prefValue = prefs.getString('profileImg');
      print(
          'UserDetails: getProfileImg - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error getting profileImg: $e');
      return null;
    }
  }

  Future<void> setProfileImg(String profileImg,
      {bool forceUpdate = false}) async {
    try {
      await _storage.write(key: 'profileImg', value: profileImg);
      final prefs = await _getPrefs();
      await prefs.setString('profileImg', profileImg);
      print(
          'UserDetails: setProfileImg - Value: $profileImg, ForceUpdate: $forceUpdate');
    } catch (e) {
      print('UserDetails: Error setting profileImg: $e');
    }
  }

  Future<String?> getEmail() async {
    try {
      final value = await _storage.read(key: 'email');
      final prefs = await _getPrefs();
      final prefValue = prefs.getString('email');
      print(
          'UserDetails: getEmail - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error getting email: $e');
      return null;
    }
  }

  Future<void> savePassword(String password, {bool forceUpdate = false}) async {
    try {
      await _storage.write(key: 'screen_password', value: password);
      final prefs = await _getPrefs();
      await prefs.setString('screen_password', password);
      print('UserDetails: savePassword - Success, ForceUpdate: $forceUpdate');
    } catch (e) {
      print('UserDetails: Error saving password: $e');
    }
  }

  Future<String?> getPassword() async {
    try {
      final value = await _storage.read(key: 'screen_password');
      final prefs = await _getPrefs();
      final prefValue = prefs.getString('screen_password');
      print(
          'UserDetails: getPassword - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error getting password: $e');
      return null;
    }
  }

  Future<void> clearPassword() async {
    try {
      await _storage.delete(key: 'screen_password');
      final prefs = await _getPrefs();
      await prefs.remove('screen_password');
      print('UserDetails: clearPassword - Success');
    } catch (e) {
      print('UserDetails: Error clearing password: $e');
    }
  }

  Future<void> clearUserDetails() async {
    try {
      await _storage.deleteAll();
      final prefs = await _getPrefs();
      await prefs.clear();
      await prefs.setBool(_isInitializedKey, false);
      print('UserDetails: clearUserDetails - Success');
    } catch (e) {
      print('UserDetails: Error clearing user details: $e');
    }
  }

  Future<void> setFcmToken(String? fcmToken) async {
    try {
      await _storage.write(key: _fcmToken, value: fcmToken);
      final prefs = await _getPrefs();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await prefs.setString(_fcmToken, fcmToken);
      } else {
        print('fcm token is empty');
      }
    } catch (e) {
      print('UserDetails: Error in setting fcm token: $e');
    }
  }

  Future<String?> getFcmToken() async {
    try {
      final value = await _storage.read(key: _fcmToken);
      final prefs = await _getPrefs();
      final prefValue = prefs.getString(_fcmToken);
      print(
          'UserDetails: getFcmToken - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error in getting fcm token: $e');
      return null;
    }
  }

  Future<void> setDeviceId(String? deviceId) async {
    try {
      await _storage.write(key: _deviceIdToken, value: deviceId);
      final prefs = await _getPrefs();
      if (deviceId != null && deviceId.isNotEmpty) {
        await prefs.setString(_deviceIdToken, deviceId);
      } else {
        print('device id is empty');
      }
    } catch (e) {
      print('UserDetails: Error in setting device id: $e');
    }
  }

  Future<String?> getDeviceId() async {
    try {
      final value = await _storage.read(key: _deviceIdToken);
      final prefs = await _getPrefs();
      final prefValue = prefs.getString(_deviceIdToken);
      print(
          'UserDetails: getDeviceId - SecureStorage: $value, SharedPrefs: $prefValue');
      return value ?? prefValue;
    } catch (e) {
      print('UserDetails: Error in getting device id: $e');
      return null;
    }
  }

  Future<void> setUserPermissions(
      {required String faceRecognition,
      required String gpsLocation,
      required String autoAttendance,
      required String reqAttendance}) async {
    try {
      await _storage.write(key: _faceRecognitionToken, value: faceRecognition);
      await _storage.write(key: _gpsLocationToken, value: gpsLocation);
      await _storage.write(key: _autoAttendanceToken, value: autoAttendance);
      await _storage.write(key: _reqAttendanceToken, value: reqAttendance);
      final prefs = await _getPrefs();
      if ((faceRecognition.isNotEmpty) &&
          (gpsLocation.isNotEmpty) &&
          (autoAttendance.isNotEmpty) &&
          (reqAttendance.isNotEmpty)) {
        await prefs.setString(_faceRecognitionToken, faceRecognition);
        await prefs.setString(_gpsLocationToken, gpsLocation);
        await prefs.setString(_autoAttendanceToken, autoAttendance);
        await prefs.setString(_reqAttendanceToken, reqAttendance);
      } else {
        print('device id is empty');
      }
    } catch (e) {
      print('UserDetails: Error in setting device id: $e');
    }
  }

  Future<List<String>> getUserPermissions() async {
    try {
      final prefs = await _getPrefs();

      final faceRecognition = prefs.getString(_faceRecognitionToken) ?? '';
      final gpsLocation = prefs.getString(_gpsLocationToken) ?? '';
      final autoAttendance = prefs.getString(_autoAttendanceToken) ?? '';
      final reqAttendance = prefs.getString(_reqAttendanceToken) ?? '';

      return [faceRecognition, gpsLocation, autoAttendance, reqAttendance];
    } catch (e) {
      print('UserDetails: Error getting permissions: $e');
      return ['', '', '', '']; // return empty/default values in case of error
    }
  }
}
