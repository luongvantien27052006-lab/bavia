// lib/core/realtime/deep_link_service.dart
//
// Bắt link mời đặt chung: mongfruits://join?code=XXXX
// (hoặc https://.../join.html?code=XXXX, /join/XXXX). Khi app mở qua link,
// gọi onJoinCode(code) để điều hướng tới màn nhập mã (đã điền sẵn).

import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Gọi khi có link mời (nhận mã phòng). App gắn callback này để điều hướng.
  void Function(String code)? onJoinCode;

  /// Mã chờ xử lý nếu link đến trước khi UI sẵn sàng.
  String? pendingCode;

  Future<void> init() async {
    // Link mở app từ trạng thái tắt hẳn.
    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri != null) _handle(uri);
    } catch (_) {}
    // Link đến khi app đang chạy / nền.
    _sub = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void _handle(Uri uri) {
    final code = _extractCode(uri);
    if (code == null || code.isEmpty) return;
    final cb = onJoinCode;
    if (cb != null) {
      cb(code);
    } else {
      pendingCode = code;
    }
  }

  String? _extractCode(Uri uri) {
    final q = uri.queryParameters['code'];
    if (q != null && q.isNotEmpty) return q.toUpperCase();
    // Dạng /join/XXXX
    final segs = uri.pathSegments;
    final i = segs.indexOf('join');
    if (i >= 0 && i + 1 < segs.length) return segs[i + 1].toUpperCase();
    return null;
  }

  void flushPending() {
    final c = pendingCode;
    if (c != null && onJoinCode != null) {
      pendingCode = null;
      onJoinCode!(c);
    }
  }

  void dispose() => _sub?.cancel();
}