// lib/providers/realtime_order_provider.dart
//
// Lắng nghe các sự kiện đơn hàng qua Socket.IO khi đã đăng nhập, tự refresh
// danh sách/chi tiết đơn và phát ra một "sự kiện thông báo" để UI hiện SnackBar.
//
// Sự kiện backend (room user:{userId}):
//   payment.confirmed   { orderId, finalAmount }
//   order.statusChanged { orderId, status }
//   order.cancelled     { orderId, reason }
//   order.expired       { orderId, reason }

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/realtime/socket_service.dart';
import '../models/order_model.dart';
import 'auth_provider.dart';
import 'order_provider.dart';

/// Một lần cập nhật đơn realtime, để UI hiển thị thông báo.
class OrderRealtimeEvent {
  final String kind; // 'status' | 'cancelled' | 'expired' | 'paid'
  final String? orderId;
  final String message;
  final DateTime at;

  OrderRealtimeEvent({
    required this.kind,
    required this.orderId,
    required this.message,
  }) : at = DateTime.now();
}

class RealtimeOrderNotifier extends Notifier<OrderRealtimeEvent?> {
  final List<VoidCallback> _disposers = [];
  bool _registered = false;

  @override
  OrderRealtimeEvent? build() {
    // Phản ứng theo trạng thái đăng nhập.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        _register();
      } else {
        _unregister();
      }
    });

    // Trạng thái hiện tại lúc khởi tạo.
    if (ref.read(authProvider).status == AuthStatus.authenticated) {
      _register();
    }

    ref.onDispose(_unregister);
    return null;
  }

  void _register() {
    if (_registered) return;
    _registered = true;
    final socket = SocketService.instance;

    _disposers.add(socket.on('payment.confirmed', (data) {
      final id = _orderId(data);
      _refresh(id);
      _emit('paid', id, 'Đơn ${_short(id)} đã thanh toán thành công');
    }));

    _disposers.add(socket.on('order.statusChanged', (data) {
      final id = _orderId(data);
      final status = _status(data);
      _refresh(id);
      final label = status != null
          ? OrderStatus.fromApi(status).label
          : 'đã cập nhật';
      _emit('status', id, 'Đơn ${_short(id)}: $label');
    }));

    _disposers.add(socket.on('order.cancelled', (data) {
      final id = _orderId(data);
      _refresh(id);
      _emit('cancelled', id, 'Đơn ${_short(id)} đã bị huỷ');
    }));

    _disposers.add(socket.on('order.expired', (data) {
      final id = _orderId(data);
      _refresh(id);
      _emit('expired', id, 'Đơn ${_short(id)} đã hết hạn thanh toán');
    }));
  }

  void _unregister() {
    for (final d in _disposers) {
      d();
    }
    _disposers.clear();
    _registered = false;
  }

  /// Refresh danh sách + chi tiết đơn liên quan để UI tự cập nhật.
  void _refresh(String? orderId) {
    ref.invalidate(ordersProvider);
    if (orderId != null) {
      ref.invalidate(orderDetailProvider(orderId));
    }
  }

  void _emit(String kind, String? orderId, String message) {
    state = OrderRealtimeEvent(kind: kind, orderId: orderId, message: message);
  }

  String? _orderId(dynamic data) =>
      (data is Map) ? data['orderId']?.toString() : null;

  String? _status(dynamic data) =>
      (data is Map) ? data['status']?.toString() : null;

  String _short(String? orderId) {
    if (orderId == null) return '';
    final hex = orderId.replaceAll('-', '');
    final take = hex.length < 8 ? hex.length : 8;
    return '#${hex.substring(0, take).toUpperCase()}';
  }
}

final realtimeOrderProvider =
    NotifierProvider<RealtimeOrderNotifier, OrderRealtimeEvent?>(
        RealtimeOrderNotifier.new);
