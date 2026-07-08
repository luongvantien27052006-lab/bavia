// ============================================================
//  FLUTTER
//  lib/models/voucher_wallet.dart
//  >> FILE MOI
// ============================================================

// lib/models/voucher_wallet.dart
// Item từ GET /api/vouchers/available (ví voucher của khách).
import 'json_x.dart';

class VoucherWallet {
  final String id;
  final String code;
  final String name;
  final String type; // PERCENTAGE / FIXED_AMOUNT
  final int discountValue;
  final int minOrderValue;
  final int perUserLimit;
  final int usedByMe;
  final int remainingForMe;
  final DateTime? endDate;

  const VoucherWallet({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.discountValue,
    required this.minOrderValue,
    required this.perUserLimit,
    required this.usedByMe,
    required this.remainingForMe,
    required this.endDate,
  });

  factory VoucherWallet.fromJson(Map<String, dynamic> json) {
    return VoucherWallet(
      id: JsonX.str(json, ['id']),
      code: JsonX.str(json, ['code']),
      name: JsonX.str(json, ['name']),
      type: JsonX.str(json, ['type']),
      discountValue: JsonX.intVal(json, ['discountValue', 'discount_value']),
      minOrderValue: JsonX.intVal(json, ['minOrderValue', 'min_order_value']),
      perUserLimit: JsonX.intVal(json, ['perUserLimit', 'per_user_limit']),
      usedByMe: JsonX.intVal(json, ['usedByMe', 'used_by_me']),
      remainingForMe: JsonX.intVal(json, ['remainingForMe', 'remaining_for_me']),
      endDate: JsonX.dateTime(json, ['endDate', 'end_date']),
    );
  }

  bool get isPercent => type == 'PERCENTAGE';
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
  bool get isUsable => remainingForMe > 0 && !isExpired;
  String get discountLabel =>
      isPercent ? 'Giảm theo %: $discountValue%' : 'Giảm ${discountValue}đ';
}