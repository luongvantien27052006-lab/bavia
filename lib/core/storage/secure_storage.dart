// ============================================================
//  FLUTTER
//  lib/core/storage/secure_storage.dart
//  >> CHEP DE (them luu/doc device id)
// ============================================================

// lib/core/storage/secure_storage.dart
//
// Lưu trữ an toàn cho JWT (access + refresh token).
// Dùng flutter_secure_storage → Android Keystore / iOS Keychain.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._internal();
  static final SecureStorage instance = SecureStorage._internal();

  static const _kAccessToken = 'bavia_access_token';
  static const _kRefreshToken = 'bavia_refresh_token';
  static const _kDeviceId = 'bavia_device_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
    ]);
  }

  Future<void> saveAccessToken(String accessToken) =>
      _storage.write(key: _kAccessToken, value: accessToken);

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<bool> hasSession() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getDeviceId() => _storage.read(key: _kDeviceId);

  Future<void> saveDeviceId(String id) =>
      _storage.write(key: _kDeviceId, value: id);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
    ]);
  }
}