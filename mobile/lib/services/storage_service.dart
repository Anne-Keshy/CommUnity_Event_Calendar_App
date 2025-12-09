import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<void> saveString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }
}