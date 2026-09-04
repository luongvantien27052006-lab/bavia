// lib/models/app_version_config.dart
//
// Cấu hình phiên bản app (lấy từ GET /api/app-config).

import 'json_x.dart';

class AppVersionConfig {
  /// Thấp hơn mức này → BẮT BUỘC cập nhật mới dùng tiếp.
  final String minVersion;

  /// Có bản mới hơn mức này → GỢI Ý cập nhật (không chặn).
  final String latestVersion;

  final String androidUrl;
  final String iosUrl;
  final String message;

  const AppVersionConfig({
    required this.minVersion,
    required this.latestVersion,
    required this.androidUrl,
    required this.iosUrl,
    required this.message,
  });

  factory AppVersionConfig.fromJson(Map<String, dynamic> j) => AppVersionConfig(
        minVersion: JsonX.str(j, ['minVersion', 'min_version'], fallback: '1.0.0'),
        latestVersion:
            JsonX.str(j, ['latestVersion', 'latest_version'], fallback: '1.0.0'),
        androidUrl: JsonX.str(j, ['androidUrl', 'android_url']),
        iosUrl: JsonX.str(j, ['iosUrl', 'ios_url']),
        message: JsonX.str(j, ['message'],
            fallback: 'Phiên bản mới đã sẵn sàng với nhiều cải tiến.'),
      );
}