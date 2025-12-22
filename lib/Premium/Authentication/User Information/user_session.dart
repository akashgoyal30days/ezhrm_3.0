// lib/authentication/user_information/user_session.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSession {
  final FlutterSecureStorage _storage;

  UserSession() : _storage = const FlutterSecureStorage();

  static const String _uid = 'user_id';
  static const String _token = 'auth_token';
  static const String _timestampKey = 'timestamp';
  static const String _sessionValidityKey = 'session_validity';
  static const String _userRoleId = 'user_role_id';
  static const String _cid = 'cid';
  static const String _apiKey = 'apiKey';

  Future<void> setUserCredentials(
      {required String userId,
      required String userToken,
      required bool sessionValidity}) async {
    await _storage.write(key: _uid, value: userId);
    await _storage.write(key: _token, value: userToken);
    await _storage.write(
        key: _sessionValidityKey, value: sessionValidity.toString());

    final existingTimestamp = await _storage.read(key: _timestampKey);
    if (existingTimestamp == null) {
      await _storage.write(
          key: _timestampKey, value: DateTime.now().toIso8601String());
    } else {
      final storedTime = DateTime.parse(existingTimestamp);
      final currentTime = DateTime.now();
      final difference = currentTime.difference(storedTime);
      if (difference.inHours >= 48) {
        await _storage.write(
            key: _timestampKey, value: currentTime.toIso8601String());
      }
    }
  }

  Future<void> setUserRoleId({required String roleId}) async {
    await _storage.write(key: _userRoleId, value: roleId);
  }

  Future<void> setApiKey({required String apiKey}) async {
    await _storage.write(key: _apiKey, value: apiKey);
  }

  Future<void> setCId({required String CId}) async {
    await _storage.write(key: _cid, value: CId);
  }

  Future<String?> get apiKey async => await _storage.read(key: _apiKey);

  Future<String?> get userRoleId async => await _storage.read(key: _userRoleId);
  Future<String?> get cId async => await _storage.read(key: _cid);

  Future<String?> get uid async => await _storage.read(key: _uid);
  Future<String?> get token async => await _storage.read(key: _token);

  Future<bool> getSessionValidity() async {
    final validityString = await _storage.read(key: _sessionValidityKey);
    if (validityString == 'true') return true;
    if (validityString == 'false') return false;
    return false;
  }

  Future<DateTime?> get timestamp async {
    final timestampString = await _storage.read(key: _timestampKey);
    return timestampString != null ? DateTime.parse(timestampString) : null;
  }

  Future<bool> isSessionValid() async {
    final storedTimestamp = await timestamp;
    final isValidFlag = await getSessionValidity();
    if (storedTimestamp != null && isValidFlag) {
      final currentTime = DateTime.now();
      final diff = currentTime.difference(storedTimestamp);
      return diff.inHours < 48;
    }
    return false;
  }

  Future<void> clearUserCredentials() async {
    await _storage.delete(key: _uid);
    await _storage.delete(key: _token);
    await _storage.delete(key: _timestampKey);
    await _storage.delete(key: _userRoleId);
    await _storage.write(key: _sessionValidityKey, value: 'false');
  }
}
