// lib/core/config/api_config.dart
//
// Cấu hình endpoint backend Bavia.
//
// ┌──────────────────────────────────────────────────────────────────┐
// │  CHỈ SỬA 1 DÒNG: _appHost — dán domain của SERVICE APP (merry-     │
// │  harmony) trên Railway. KHÔNG phải domain Postgres.                │
// │                                                                    │
// │  Lấy ở đâu: Railway → click card "merry-harmony" (không phải       │
// │  Postgres) → Settings → Networking → Public Networking.            │
// │  Dán host dạng "merry-harmony-production-xxxx.up.railway.app".     │
// │  KHÔNG kèm https://, KHÔNG kèm /api (code tự thêm).                │
// └──────────────────────────────────────────────────────────────────┘

import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  // ═══════════════════════════════════════════════════════════════════
  // 👇 DÁN DOMAIN APP (merry-harmony) VÀO ĐÂY
  static const String _appHost = 'merry-harmony-production-ae63.up.railway.app';
  // ═══════════════════════════════════════════════════════════════════

  /// Bật true CHỈ khi test với backend chạy ở máy tính (npm run start:dev).
  /// Khi đó cần thiết bị cùng mạng LAN + điền IP máy ở _localIp.
  static const bool _useLocalBackend = false;

  /// IP LAN máy tính (chỉ dùng khi _useLocalBackend = true).
  /// Windows: chạy `ipconfig`, lấy dòng IPv4 Address. Vd: 192.168.1.10
  static const String _localIp = '192.168.1.10';
  static const int _localPort = 3000;

  // ─── Resolve ───────────────────────────────────────────────────────

  static String get _scheme => _useLocalBackend ? 'http' : 'https';

  static String get _host =>
      _useLocalBackend ? '$_localIp:$_localPort' : _appHost;

  /// Base URL cho REST API, vd: https://....up.railway.app/api
  static String get baseUrl => '$_scheme://$_host/api';

  /// URL gốc cho Socket.IO (KHÔNG kèm /api), vd: https://....up.railway.app
  static String get socketUrl => '$_scheme://$_host';

  /// Namespace Socket.IO ở backend.
  static const String socketNamespace = '/realtime';

  // ─── Timeouts ──────────────────────────────────────────────────────

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  static bool get enableLogging => kDebugMode;
}
