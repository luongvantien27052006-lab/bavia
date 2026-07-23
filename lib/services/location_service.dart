// ============================================================
//  FLUTTER
//  lib/services/location_service.dart
//  >> FILE MOI (lay vi tri, xu ly quyen)
// ============================================================

// lib/services/location_service.dart
//
// Lấy vị trí hiện tại của khách để tính phí giao hàng theo khoảng cách.
// Mọi lỗi đều trả null — không bao giờ làm app crash hay chặn đặt hàng.

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  const LocationResult(this.latitude, this.longitude);
}

enum LocationError { serviceOff, denied, deniedForever, failed }

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Lỗi của lần lấy vị trí gần nhất (để hiện thông báo phù hợp).
  LocationError? lastError;

  /// Xin quyền + lấy toạ độ hiện tại. Trả null nếu không lấy được.
  Future<LocationResult?> getCurrent() async {
    lastError = null;
    try {
      // 1. Dịch vụ định vị (GPS) của máy có bật không?
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        lastError = LocationError.serviceOff;
        return null;
      }

      // 2. Quyền truy cập vị trí.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        lastError = LocationError.denied;
        return null;
      }
      if (permission == LocationPermission.deniedForever) {
        lastError = LocationError.deniedForever;
        return null;
      }

      // 3. Lấy toạ độ (giới hạn 15 giây để không treo màn hình).
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      return LocationResult(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('LocationService lỗi: $e');
      lastError = LocationError.failed;
      return null;
    }
  }

  /// Câu thông báo tiếng Việt cho lỗi gần nhất.
  String get lastErrorMessage {
    switch (lastError) {
      case LocationError.serviceOff:
        return 'Vui lòng bật Định vị (GPS) trên máy rồi thử lại.';
      case LocationError.denied:
        return 'Bạn cần cho phép truy cập vị trí để tính phí giao hàng.';
      case LocationError.deniedForever:
        return 'Quyền vị trí đang bị chặn. Hãy bật lại trong Cài đặt của máy.';
      case LocationError.failed:
      case null:
        return 'Không lấy được vị trí, vui lòng thử lại.';
    }
  }

  /// Mở màn hình cài đặt để khách bật lại quyền.
  Future<void> openSettings() => Geolocator.openAppSettings();
}