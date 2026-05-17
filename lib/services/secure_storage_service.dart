import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorage write error: $e');
    }
  }

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('SecureStorage read error: $e');
      return null;
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('SecureStorage delete error: $e');
    }
  }

  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('SecureStorage deleteAll error: $e');
    }
  }

  static Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('SecureStorage containsKey error: $e');
      return false;
    }
  }

  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  static Future<void> saveAuthToken(String token) async {
    await write(_authTokenKey, token);
  }

  static Future<String?> getAuthToken() async {
    return await read(_authTokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    await write(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    return await read(_userIdKey);
  }

  static Future<void> saveUserEmail(String email) async {
    await write(_userEmailKey, email);
  }

  static Future<String?> getUserEmail() async {
    return await read(_userEmailKey);
  }

  static Future<void> clearSession() async {
    await deleteAll();
  }
}