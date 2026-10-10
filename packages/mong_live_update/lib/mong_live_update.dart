// Thông báo tiến trình đơn hàng chuẩn Android "Live Update".
//
// Android 16+: thông báo được hệ điều hành nâng thành Live Update -> hiện chip
// trên thanh trạng thái, màn khoá, và Hyper Island (Xiaomi HyperOS 3.1+).
// Android cũ hơn: thông báo cố định có thanh tiến trình.
//
// Plugin được đăng ký ở mọi Flutter engine (kể cả isolate nền của
// firebase_messaging) nên cập nhật được cả khi app đã thoát.

import 'package:flutter/services.dart';

class MongLiveUpdate {
  MongLiveUpdate._();

  static const MethodChannel _ch = MethodChannel('mong_live_update');

  /// {sdk, notificationsEnabled, canPromote}
  static Future<Map<String, dynamic>> status() async {
    final r = await _ch.invokeMethod<Map<Object?, Object?>>('status');
    return {for (final e in (r ?? const {}).entries) e.key.toString(): e.value};
  }

  /// Hiện / cập nhật thông báo của 1 đơn (cùng [id] -> thay thế, không chồng).
  static Future<void> show({
    required String id,
    required String title,
    required String text,
    String? subText,
    String? shortText,
    int progress = -1,
    List<int> points = const [],
    bool ongoing = true,
    bool alert = false,
    int? color,
    int timeoutMs = 0,
  }) =>
      _ch.invokeMethod('show', {
        'id': id,
        'title': title,
        'text': text,
        'subText': subText,
        'shortText': shortText,
        'progress': progress,
        'points': points,
        'ongoing': ongoing,
        'alert': alert,
        'color': color,
        'timeoutMs': timeoutMs,
      });

  static Future<void> cancel(String id) => _ch.invokeMethod('cancel', {'id': id});

  static Future<void> cancelAll() => _ch.invokeMethod('cancelAll');
}
