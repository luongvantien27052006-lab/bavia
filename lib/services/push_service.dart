// ============================================================
//  FLUTTER
//  lib/services/push_service.dart
//  >> ĐÃ VÁ: getInitialMessage() có timeout -> KHÔNG BAO GIỜ treo khởi động
// ============================================================

// lib/services/push_service.dart
//
// Thông báo đẩy (FCM): xin quyền, lấy token, gửi lên backend, và xử lý khi
// người dùng bấm vào thông báo.

import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import 'order_live_activity.dart';

/// Handler khi app đang ở nền/đã tắt (bắt buộc là hàm top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Thông báo thường: hệ điều hành tự hiển thị.
  // Live Update (Android): server gửi data-only -> tự vẽ lại thông báo ongoing.
  if (message.data['type'] == 'live_activity') {
    DartPluginRegistrant.ensureInitialized();
    await OrderLiveActivity.instance.handleRemote(message.data);
  }
}

/// Key điều hướng dùng chung, để mở màn chi tiết đơn từ thông báo
/// (kể cả khi bấm thông báo lúc app đang đóng).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String? _token;

  /// Callback khi người dùng bấm vào thông báo (nhận orderId).
  void Function(String orderId)? onOpenOrder;

  /// Callback khi người dùng bấm vào thông báo TIN TỨC (nhận newsId).
  void Function(String newsId)? onOpenNews;

  StreamSubscription<String>? _refreshSub;

  /// Gọi 1 lần lúc khởi động app (sau Firebase.initializeApp).
  Future<void> init() async {
    try {
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);

      // Bấm vào thông báo khi app đang chạy nền.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

      // App đang mở: Live Update Android (data-only) -> cập nhật ngay.
      FirebaseMessaging.onMessage.listen((m) {
        if (m.data['type'] == 'live_activity') {
          OrderLiveActivity.instance.handleRemote(m.data);
        }
      });

      // ⚠️ QUAN TRỌNG: trên iOS, getInitialMessage() ĐỢI APNS token.
      // Nếu app chưa có entitlement Push / chưa cấp được APNS token thì
      // lời gọi này TREO VÔ HẠN -> nếu await trước runApp sẽ ra màn trắng.
      // Bọc timeout để nó KHÔNG BAO GIỜ chặn khởi động.
      final initial = await _fcm
          .getInitialMessage()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      if (initial != null) _handleOpened(initial);
    } catch (e) {
      debugPrint('PushService.init lỗi: $e');
    }
  }

  /// orderId chờ mở khi app vừa khởi động từ thông báo (navigator chưa sẵn sàng).
  String? pendingOrderId;

  /// newsId chờ mở khi app vừa khởi động từ thông báo tin tức.
  String? pendingNewsId;

  void _handleOpened(RemoteMessage m) {
    final type = m.data['type'];

    // Tin tức -> mở bài viết.
    if (type == 'news') {
      final newsId = m.data['newsId'];
      if (newsId is String && newsId.isNotEmpty) {
        final cb = onOpenNews;
        if (cb != null) {
          cb(newsId);
        } else {
          pendingNewsId = newsId;
        }
      }
      return;
    }

    // Mặc định: đơn hàng -> mở chi tiết đơn.
    final orderId = m.data['orderId'];
    if (orderId is! String || orderId.isEmpty) return;
    final cb = onOpenOrder;
    if (cb != null) {
      cb(orderId);
    } else {
      pendingOrderId = orderId;
    }
  }

  /// Gọi khi app đã dựng xong navigator: mở đơn còn treo (nếu có).
  void flushPending() {
    final oid = pendingOrderId;
    if (oid != null && onOpenOrder != null) {
      pendingOrderId = null;
      onOpenOrder!(oid);
    }
    final nid = pendingNewsId;
    if (nid != null && onOpenNews != null) {
      pendingNewsId = null;
      onOpenNews!(nid);
    }
  }

  /// Sau khi đăng nhập: xin quyền, lấy token và gửi lên backend.
  Future<void> registerForUser() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Người dùng từ chối nhận thông báo');
        return;
      }

      // getToken() cũng phụ thuộc APNS trên iOS -> bọc timeout cho an toàn.
      final token = await _fcm
          .getToken()
          .timeout(const Duration(seconds: 8), onTimeout: () => null);
      if (token == null) return;
      _token = token;
      await _sendToken(token);

      // Token có thể được cấp lại — gửi bản mới lên backend.
      await _refreshSub?.cancel();
      _refreshSub = _fcm.onTokenRefresh.listen((t) {
        _token = t;
        _sendToken(t);
      });
    } catch (e) {
      debugPrint('Đăng ký thông báo lỗi: $e');
    }
  }

  Future<void> _sendToken(String token) async {
    try {
      await ApiClient.I.post('/push/token', data: {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      });
    } catch (e) {
      debugPrint('Gửi device token lỗi: $e');
    }
  }

  /// Khi đăng xuất / xoá tài khoản: gỡ token khỏi backend.
  Future<void> unregister() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    // Tắt timeline đơn (Dynamic Island / Live Update) của tài khoản cũ.
    await OrderLiveActivity.instance.endAll();
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await ApiClient.I.delete('/push/token', data: {'token': token});
    } catch (e) {
      debugPrint('Gỡ device token lỗi: $e');
    }
  }
}