// lib/services/order_live_activity.dart
//
// Timeline đơn hàng trên Dynamic Island / màn khoá (iOS Live Activity) và
// thông báo ongoing / Live Update (Android 16+).
//
// - syncOrders(): gọi mỗi khi danh sách đơn tải lại -> tự bật / cập nhật / kết
//   thúc activity cho khớp trạng thái đơn đang xử lý.
// - iOS: khi app đã đóng, SERVER cập nhật qua APNs bằng layout app gửi sẵn.
// - Android: khi app đã đóng, server gửi FCM data -> handleRemote() vẽ lại.
// - Máy không hỗ trợ / lỗi plugin -> im lặng, thông báo thường vẫn chạy.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:live_activity_kit/live_activity_kit.dart';

import '../core/network/api_client.dart';
import '../models/order_model.dart';

class _Step {
  final double progress;
  final String label; // tiêu đề lớn
  final String short; // chữ ngắn cạnh Dynamic Island
  final String sub; // dòng phụ màn khoá
  final String symbol; // SF Symbol (iOS)
  const _Step(this.progress, this.label, this.short, this.sub, this.symbol);
}

const _steps = <String, _Step>{
  'CONFIRMED': _Step(0.2, 'Đã xác nhận', 'Đã nhận', 'Quán đã nhận đơn của bạn',
      'checkmark.seal.fill'),
  'IN_PROGRESS': _Step(0.45, 'Đang pha chế', 'Đang pha',
      'Đồ uống của bạn đang được chuẩn bị', 'cup.and.saucer.fill'),
  'READY': _Step(0.7, 'Đã sẵn sàng', 'Sẵn sàng', 'Đơn đã pha xong', 'bag.fill'),
  'DELIVERING': _Step(0.88, 'Đang giao', 'Đang giao',
      'Shipper đang trên đường tới bạn', 'bicycle'),
  'DELIVERED': _Step(1.0, 'Hoàn thành', 'Xong',
      'Cảm ơn bạn đã chọn Mọng Fruits!', 'checkmark.circle.fill'),
  'CANCELLED': _Step(0, 'Đơn đã huỷ', 'Đã huỷ',
      'Liên hệ quán nếu cần hỗ trợ', 'xmark.circle.fill'),
};

const _active = {'CONFIRMED', 'IN_PROGRESS', 'READY', 'DELIVERING'};
const _terminal = {'DELIVERED', 'CANCELLED'};

const _brand = Color(0xFFD9653B);
const _ok = Color(0xFF2E9E5B);
const _bad = Color(0xFFD64545);
const _ink = Color(0xFF3A2A24); // chữ trên nền kem (màn khoá)
const _cream = Color(0xFFFFF8F1);

class OrderLiveActivity {
  OrderLiveActivity._();
  static final OrderLiveActivity instance = OrderLiveActivity._();

  /// activityId -> trạng thái đang hiển thị (trong phiên hiện tại).
  final Map<String, String> _shown = {};
  bool? _supported;
  StreamSubscription<dynamic>? _tokenSub;
  Future<void> _queue = Future.value();

  static String _laId(String orderId) => 'order-$orderId';
  static String _code(String orderId) {
    final hex = orderId.replaceAll('-', '');
    return hex.substring(0, hex.length < 8 ? hex.length : 8).toUpperCase();
  }

  /// OrderStatus.inProgress -> 'IN_PROGRESS'
  static String _api(OrderStatus s) => s.name
      .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]}')
      .toUpperCase();

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> _isSupported() async {
    if (kIsWeb) return false;
    if (_supported != null) return _supported!;
    try {
      final s = await LiveActivity.support();
      _supported = s.canStart;
    } catch (_) {
      _supported = false;
    }
    return _supported!;
  }

  // ─────────────────────────── Layout ───────────────────────────

  LiveActivityLayout _layout(String orderId, String status) {
    final s = _steps[status]!;
    final color = status == 'CANCELLED'
        ? _bad
        : status == 'DELIVERED'
            ? _ok
            : _brand;
    final showProgress = status != 'CANCELLED';
    final code = _code(orderId);

    return LiveActivityLayout(
      theme: const LATheme(background: _cream, tint: _brand),
      // Dynamic Island (nền đen) -> chữ trắng.
      compactLeading: LA.symbol(s.symbol, color: color),
      compactTrailing:
          LA.text(s.short, size: 13, weight: FontWeight.w600, color: color),
      minimal: LA.symbol(s.symbol, color: color),
      expandedLeading: LA.symbol(s.symbol, size: 22, color: color),
      expandedTrailing: LA.text('#$code', size: 13, color: Colors.white),
      expandedCenter: LA.text('Mọng Fruits',
          size: 14, weight: FontWeight.w600, color: Colors.white),
      expandedBottom: LA.column([
        LA.text(s.label, size: 17, weight: FontWeight.bold, color: Colors.white),
        if (showProgress) LA.progress(s.progress, tint: color),
      ], spacing: 6),
      // Màn khoá (nền kem) -> chữ nâu đậm.
      lockScreen: LA.column([
        LA.row([
          LA.symbol(s.symbol, size: 14, color: color),
          LA.text('Mọng Fruits · Đơn #$code',
              size: 13, weight: FontWeight.w600, color: _ink),
          LA.spacer(),
        ], spacing: 6),
        LA.text(s.label, size: 20, weight: FontWeight.bold, color: _ink),
        if (showProgress) LA.progress(s.progress, tint: color),
        LA.text(s.sub, size: 13, color: _ink, opacity: 0.75),
      ], spacing: 6),
    );
  }

  /// Layout sẵn cho mọi trạng thái (server dùng để cập nhật khi app đã đóng).
  Map<String, String> _allPayloads(String orderId) => {
        for (final st in _steps.keys)
          st: jsonEncode(_layout(orderId, st).toJson()),
      };

  // ─────────────────────────── Đồng bộ ───────────────────────────

  /// Gọi mỗi khi danh sách đơn tải lại.
  Future<void> syncOrders(List<OrderModel> orders) =>
      _enqueue(() => _sync(orders));

  Future<void> _sync(List<OrderModel> orders) async {
    if (!await _isSupported()) return;
    _listenTokens();

    final activeIds = <String>{};
    for (final o in orders) {
      final st = _api(o.status);
      if (!_active.contains(st)) continue;
      // Đơn hẹn giờ còn xa: chưa bật (Live Activity tối đa ~8 giờ).
      final sf = o.scheduledFor;
      if (sf != null &&
          sf.toLocal().isAfter(DateTime.now().add(const Duration(hours: 1)))) {
        continue;
      }
      activeIds.add(o.id);
      await _apply(o.id, st);
    }

    // Đơn đang hiển thị nhưng không còn xử lý -> khung kết thúc / tắt.
    for (final laId in _shown.keys.toList()) {
      final orderId = laId.substring('order-'.length);
      if (activeIds.contains(orderId)) continue;
      OrderModel? o;
      for (final x in orders) {
        if (x.id == orderId) {
          o = x;
          break;
        }
      }
      final st = o == null ? null : _api(o.status);
      await _apply(orderId,
          (st == 'DELIVERED') ? 'DELIVERED' : 'CANCELLED',
          silentEnd: st != 'DELIVERED' && st != 'CANCELLED' && st != 'REFUNDED');
    }
  }

  /// Android: FCM data khi app ở nền/đã đóng.
  Future<void> handleRemote(Map<String, dynamic> data) async {
    final orderId = data['orderId']?.toString();
    var status = data['status']?.toString();
    if (orderId == null || status == null) return;
    if (status == 'REFUNDED') status = 'CANCELLED';
    if (!_steps.containsKey(status)) return;
    final st = status;
    await _enqueue(() async {
      if (!await _isSupported()) return;
      await _apply(orderId, st);
    });
  }

  /// Đăng xuất: tắt hết.
  Future<void> endAll() async {
    _shown.clear();
    try {
      await LiveActivity.endAll(immediate: true);
    } catch (_) {}
  }

  // ─────────────────────────── Lõi ───────────────────────────

  Future<void> _enqueue(Future<void> Function() job) {
    // Chạy tuần tự, tránh 2 lần show() cùng lúc cho 1 đơn.
    final next = _queue.then((_) => job()).catchError((Object e) {
      debugPrint('LiveActivity lỗi: $e');
    });
    _queue = next;
    return next;
  }

  Future<void> _apply(String orderId, String status,
      {bool silentEnd = false}) async {
    final id = _laId(orderId);
    if (_shown[id] == status) return;
    final l = _layout(orderId, status);

    bool running = _shown.containsKey(id);
    if (!running) {
      try {
        running = await LiveActivity.isRunning(id);
      } catch (_) {}
    }

    if (_terminal.contains(status)) {
      _shown.remove(id);
      if (silentEnd) {
        if (running) {
          await LiveActivity.end(
              id: id, policy: const LiveActivityEndPolicy.immediate());
        }
        return;
      }
      // Android sau khi app bị đóng: plugin mất trạng thái -> vẽ lại rồi kết thúc
      // để không còn sót thông báo ongoing cũ.
      if (!running && !_isIOS) {
        await _show(id, l, push: false);
      } else if (!running) {
        return;
      }
      await LiveActivity.end(
        id: id,
        lockScreen: l.lockScreen,
        policy: LiveActivityEndPolicy.after(
            DateTime.now().add(const Duration(minutes: 30))),
      );
      return;
    }

    if (running) {
      await LiveActivity.update(
        id: id,
        lockScreen: l.lockScreen,
        compactLeading: l.compactLeading,
        compactTrailing: l.compactTrailing,
        minimal: l.minimal,
        expandedLeading: l.expandedLeading,
        expandedTrailing: l.expandedTrailing,
        expandedCenter: l.expandedCenter,
        expandedBottom: l.expandedBottom,
      );
    } else {
      await _show(id, l, push: _isIOS);
      // Android: đăng ký ngay (không có push token). iOS: đăng ký khi có token.
      if (!_isIOS) unawaited(_register(orderId));
    }
    _shown[id] = status;
  }

  Future<void> _show(String id, LiveActivityLayout l, {required bool push}) async {
    await LiveActivity.show(
      id: id,
      theme: l.theme,
      lockScreen: l.lockScreen,
      compactLeading: l.compactLeading,
      compactTrailing: l.compactTrailing,
      minimal: l.minimal,
      expandedLeading: l.expandedLeading,
      expandedTrailing: l.expandedTrailing,
      expandedCenter: l.expandedCenter,
      expandedBottom: l.expandedBottom,
      enablePush: push,
      relevanceScore: 80,
    );
  }

  void _listenTokens() {
    if (!_isIOS || _tokenSub != null) return;
    try {
      _tokenSub = LiveActivity.pushTokens.listen((t) {
        final id = t.id;
        if (!id.startsWith('order-')) return;
        // Token có thể đổi -> luôn gửi bản mới nhất.
        _register(id.substring('order-'.length), pushToken: t.token);
      });
    } catch (e) {
      debugPrint('LiveActivity pushTokens lỗi: $e');
    }
  }

  Future<void> _register(String orderId, {String? pushToken}) async {
    try {
      await ApiClient.I.post('/push/live-activity/$orderId', data: {
        'platform': _isIOS ? 'ios' : 'android',
        if (pushToken != null) 'pushToken': pushToken,
        if (_isIOS) 'layouts': _allPayloads(orderId),
      });
    } catch (e) {
      debugPrint('Đăng ký Live Activity lỗi: $e');
    }
  }
}
