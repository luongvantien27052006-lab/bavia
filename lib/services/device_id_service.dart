// ============================================================
//  FLUTTER
//  lib/services/device_id_service.dart
//  >> FILE MOI (dinh danh thiet bi chong ao)
// ============================================================

// lib/services/device_id_service.dart
//
// Lấy một định danh thiết bị ổn định để chống tạo tài khoản ảo cùng máy
// (dùng khi nhập mã giới thiệu). Không phải danh tính cá nhân.

import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceIdService {
  DeviceIdService._();
  static final DeviceIdService instance = DeviceIdService._();

  final _plugin = DeviceInfoPlugin();
  String? _cached;

  Future<String?> get() async {
    if (_cached != null) return _cached;
    try {
      if (kIsWeb) return null;
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        _cached = info.id; // Android ID (ổn định theo máy + app signing)
      } else if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        _cached = info.identifierForVendor; // ổn định theo vendor
      }
    } catch (e) {
      debugPrint('DeviceIdService lỗi: $e');
    }
    return _cached;
  }
}