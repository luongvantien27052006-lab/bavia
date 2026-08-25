// ============================================================
//  FLUTTER — lib/providers/ratings_provider.dart  (>> CHÉP ĐÈ)
//  Đánh giá món (số sao): lưu máy (UI phản hồi ngay) + GỬI BACKEND.
// ============================================================

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_client.dart';

final ratingsProvider =
    NotifierProvider<RatingsNotifier, Map<String, int>>(RatingsNotifier.new);

class RatingsNotifier extends Notifier<Map<String, int>> {
  static const _key = 'bavia_product_ratings';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Map<String, int> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null && raw.isNotEmpty) {
        state = (jsonDecode(raw) as Map)
            .map((k, v) => MapEntry('$k', (v as num).toInt()));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      await _storage.write(key: _key, value: jsonEncode(state));
    } catch (_) {}
  }

  int ratingOf(String key) => state[key] ?? 0;

  /// [key] chính là productId (order_detail truyền it.productId).
  /// [productName]/[orderId] tuỳ chọn — nếu có sẽ gửi kèm để admin xem đẹp hơn.
  void setRating(
    String key,
    int stars, {
    String? productName,
    String? orderId,
  }) {
    state = {...state, key: stars};
    _save();
    _syncToServer(key, stars, productName: productName, orderId: orderId);
  }

  /// Gửi đánh giá lên backend (best-effort, không chặn UI).
  Future<void> _syncToServer(
    String productId,
    int stars, {
    String? productName,
    String? orderId,
  }) async {
    try {
      await ApiClient.I.post('/reviews', data: {
        'productId': productId,
        'stars': stars,
        if (productName != null && productName.isNotEmpty)
          'productName': productName,
        if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
      });
    } catch (_) {
      // Bỏ qua lỗi mạng — vẫn đã lưu máy; lần sau đánh giá lại sẽ gửi.
    }
  }
}