// lib/models/loyalty_model.dart
//
// Điểm thưởng. Hai endpoint:
//   GET /loyalty/balance  → số dư điểm hiện tại
//   GET /loyalty/history  → lịch sử cộng/trừ điểm (ledger)
//
// Shape chưa xác nhận tận mắt → parse linh hoạt.

import 'json_x.dart';

class LoyaltyBalance {
  final int balance; // số điểm hiện có
  final int? lifetimeEarned; // tổng điểm từng tích (nếu backend trả)

  const LoyaltyBalance({required this.balance, this.lifetimeEarned});

  factory LoyaltyBalance.fromJson(Map<String, dynamic> json) {
    return LoyaltyBalance(
      balance: JsonX.intVal(json, ['balance', 'points', 'current_balance']),
      lifetimeEarned: JsonX.pick(json, ['lifetime_earned', 'lifetimeEarned'])
              is num
          ? JsonX.intVal(json, ['lifetime_earned', 'lifetimeEarned'])
          : null,
    );
  }
}

enum PointTxnType {
  earn('EARN', 'Tích điểm', true),
  redeem('REDEEM', 'Dùng điểm', false),
  refundEarn('REFUND_EARN', 'Hoàn điểm tích', false),
  refundRedeem('REFUND_REDEEM', 'Hoàn điểm dùng', true),
  unknown('UNKNOWN', 'Khác', true);

  final String apiValue;
  final String label;
  final bool isPositive; // true = cộng điểm, false = trừ điểm
  const PointTxnType(this.apiValue, this.label, this.isPositive);

  static PointTxnType fromApi(String? v) => PointTxnType.values.firstWhere(
        (t) => t.apiValue == v,
        orElse: () => PointTxnType.unknown,
      );
}

class LoyaltyTransaction {
  final String id;
  final PointTxnType type;
  final int amount; // số điểm (luôn dương; dấu suy từ type.isPositive)
  final String? orderId;
  final String? description;
  final DateTime? createdAt;

  const LoyaltyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.orderId,
    this.description,
    this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: JsonX.str(json, ['id']),
      type: PointTxnType.fromApi(JsonX.strOrNull(json, ['type'])),
      amount: JsonX.intVal(json, ['amount', 'points']).abs(),
      orderId: JsonX.strOrNull(json, ['order_id', 'orderId']),
      description: JsonX.strOrNull(json, ['description', 'note']),
      createdAt: JsonX.dateTime(json, ['created_at', 'createdAt']),
    );
  }

  /// Số điểm có dấu để hiển thị (+10 / -5).
  int get signedAmount => type.isPositive ? amount : -amount;
}
