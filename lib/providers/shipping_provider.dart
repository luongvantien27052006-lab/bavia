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
  final String? address;
  const ShipCoords(this.lat, this.lng, {this.address});

  @override
  bool operator ==(Object other) =>
      other is ShipCoords &&
      other.lat == lat &&
      other.lng == lng &&
      other.address == address;

  @override
  int get hashCode => Object.hash(lat, lng, address);
}

/// Phí ship cho một cặp toạ độ. Lỗi mạng -> trả mức miễn phí, không chặn khách.
final shippingQuoteProvider =
    FutureProvider.family<ShippingQuote, ShipCoords>((ref, coords) async {
  final hasCoords = coords.lat != null && coords.lng != null;
  final hasAddress = coords.address != null && coords.address!.trim().isNotEmpty;
  // Chưa có cả toạ độ lẫn địa chỉ -> miễn phí (không chặn khách).
  if (!hasCoords && !hasAddress) return ShippingQuote.empty;
  try {
    final data = await ApiClient.I.get(
      '/shipping/quote',
      query: {
        if (coords.lat != null) 'lat': '${coords.lat}',
        if (coords.lng != null) 'lng': '${coords.lng}',
        if (hasAddress) 'address': coords.address!.trim(),
      },
      skipAuth: true,
    );
    return ShippingQuote.fromJson(Map<String, dynamic>.from(data as Map));
  } catch (_) {
    return ShippingQuote.empty;
  }
});