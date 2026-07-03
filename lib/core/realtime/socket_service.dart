// lib/core/realtime/socket_service.dart
//
// Kết nối Socket.IO tới namespace /realtime của backend để nhận sự kiện
// realtime. Handshake bằng JWT (auth.token = 'Bearer <accessToken>').
//
// Backend tự cho client vào room user:{userId} dựa trên JWT. App lắng nghe
// (cho CUSTOMER):
//   - payment.confirmed   { orderId, finalAmount }
//   - order.statusChanged { orderId, status }
//   - order.cancelled     { orderId, reason }
//   - order.expired       { orderId, reason }
//
// Listener được lưu trong _handlers và TỰ ĐĂNG KÝ LẠI mỗi khi tạo socket mới
// (reconnect / connect lại sau login), nên không bị mất khi socket tái tạo.

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';
import '../storage/secure_storage.dart';

typedef SocketEventHandler = void Function(dynamic data);

class SocketService {
  SocketService._internal();
  static final SocketService instance = SocketService._internal();

  io.Socket? _socket;
  final SecureStorage _storage = SecureStorage.instance;

  /// Lưu các listener bền vững để re-apply khi tạo socket mới.
  final Map<String, List<SocketEventHandler>> _handlers = {};

  bool get isConnected => _socket?.connected ?? false;

  /// Mở kết nối. Gọi sau khi đăng nhập thành công (đã có access token).
  Future<void> connect() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      if (ApiConfig.enableLogging) {
        debugPrint('🔌 Socket: chưa có token, bỏ qua connect');
      }
      return;
    }

    if (_socket != null && _socket!.connected) return;

    _socket?.dispose();

    _socket = io.io(
      '${ApiConfig.socketUrl}${ApiConfig.socketNamespace}',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': 'Bearer $token'})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    if (ApiConfig.enableLogging) {
      _socket!
        ..onConnect((_) => debugPrint('🔌 Socket connected'))
        ..onDisconnect((_) => debugPrint('🔌 Socket disconnected'))
        ..onConnectError((e) => debugPrint('🔌 Socket connect error: $e'));
    }

    // Re-apply tất cả listener đã đăng ký vào socket mới.
    _handlers.forEach((event, handlers) {
      for (final h in handlers) {
        _socket!.on(event, h);
      }
    });

    _socket!.connect();
  }

  /// Lắng nghe 1 event. Listener được nhớ và tự gắn lại khi reconnect.
  /// Trả về hàm huỷ lắng nghe.
  VoidCallback on(String event, SocketEventHandler handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
    return () {
      _handlers[event]?.remove(handler);
      _socket?.off(event, handler);
    };
  }

  void emit(String event, [dynamic data]) => _socket?.emit(event, data);

  /// Ngắt kết nối khi logout. Xoá luôn listener để phiên sau đăng ký lại sạch.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _handlers.clear();
  }
}
