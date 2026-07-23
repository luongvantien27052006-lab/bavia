// ============================================================
//  FLUTTER
//  lib/models/shipping_quote.dart
//  >> FILE MOI
// ============================================================

// lib/models/shipping_quote.dart
import 'json_x.dart';

class ShippingQuote {
  final double distanceKm;
  final int fee;
  final double freeRadiusKm;
  final int feePerKm;
  final bool outOfRange;

  const ShippingQuote({
    required this.distanceKm,
    required this.fee,
    required this.freeRadiusKm,
    required this.feePerKm,
    required this.outOfRange,
  });

  static const empty = ShippingQuote(
    distanceKm: 0,
    fee: 0,
    freeRadiusKm: 2,
    feePerKm: 7000,
    outOfRange: false,
  );

  factory ShippingQuote.fromJson(Map<String, dynamic> j) => ShippingQuote(
        distanceKm: _d(j['distanceKm']),
        fee: JsonX.intVal(j, ['fee']),
        freeRadiusKm: _d(j['freeRadiusKm'], fallback: 2),
        feePerKm: JsonX.intVal(j, ['feePerKm']),
        outOfRange: JsonX.boolVal(j, ['outOfRange']),
      );

  static double _d(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }
}