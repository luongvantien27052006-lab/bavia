// ============================================================
//  FLUTTER
//  lib/services/device_id_service.dart
//  >> CHEP DE (sinh UUID luu secure storage, BO device_info_plus)
// ============================================================

// lib/services/device_id_service.dart
//
// Định danh thiết bị để chống tạo tài khoản ảo khi nhập mã giới thiệu.
// Sinh một UUID ngẫu nhiên ở lần chạy đầu và lưu vào secure storage
// (Android Keystore / iOS Keychain). Không dùng plugin nào -> không đụng SDK.

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/storage/secure_storage.dart';

class DeviceIdService {
  DeviceIdService._();
  static final DeviceIdService instance = DeviceIdService._();

  String? _cached;

  Future<String?> get() async {
    if (_cached != null) return _cached;
    try {
      final store = SecureStorage.instance;
      var id = await store.getDeviceId();
      if (id == null || id.isEmpty) {
        id = _generateUuidV4();
        await store.saveDeviceId(id);
      }
      _cached = id;
      return id;
    } catch (e) {
      debugPrint('DeviceIdService lỗi: $e');
      return null;
    }
  }

  /// UUID v4 dùng Random.secure().
  String _generateUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}