// ============================================================
//  FLUTTER
//  lib/providers/shipping_provider.dart
//  >> FILE MOI (goi /shipping/quote)
// ============================================================

// lib/providers/shipping_provider.dart
//
// Hỏi backend phí giao hàng theo toạ độ địa chỉ đang chọn.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/shipping_quote.dart';

/// Toạ độ cần báo giá (lat, lng). null = chưa có toạ độ -> miễn phí.
class ShipCoords {
  final double? lat;
  final double? lng;
  const ShipCoords(this.lat, this.lng);

  @override
  bool operator ==(Object other) =>
      other is ShipCoords && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

/// Phí ship cho một cặp toạ độ. Lỗi mạng -> trả mức miễn phí, không chặn khách.
final shippingQuoteProvider =
    FutureProvider.family<ShippingQuote, ShipCoords>((ref, coords) async {
  if (coords.lat == null || coords.lng == null) return ShippingQuote.empty;
  try {
    final data = await ApiClient.I.get(
      '/shipping/quote',
      query: {'lat': '${coords.lat}', 'lng': '${coords.lng}'},
      skipAuth: true,
    );
    return ShippingQuote.fromJson(Map<String, dynamic>.from(data as Map));
  } catch (_) {
    return ShippingQuote.empty;
  }
});