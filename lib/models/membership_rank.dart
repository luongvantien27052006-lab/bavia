// lib/models/membership_rank.dart
//
// Hạng thành viên (Đồng → Bạc → Vàng → Kim cương).
// Nguồn: GET /loyalty/rank. Điều kiện lên hạng phải đạt CẢ số đơn hoàn thành
// lẫn tổng chi tiêu (đơn tính khi status = DELIVERED / đã nhận hàng).

import 'package:flutter/material.dart';
import 'json_x.dart';

enum MemberTier {
  bronze('BRONZE', 'Đồng'),
  silver('SILVER', 'Bạc'),
  gold('GOLD', 'Vàng'),
  diamond('DIAMOND', 'Kim cương');

  final String api;
  final String label;
  const MemberTier(this.api, this.label);

  static MemberTier fromApi(String? v) => MemberTier.values
      .firstWhere((e) => e.api == v, orElse: () => MemberTier.bronze);

  Color get color => switch (this) {
        MemberTier.bronze => const Color(0xFFB87333),
        MemberTier.silver => const Color(0xFF94A0B8),
        MemberTier.gold => const Color(0xFFCF9B08),
        MemberTier.diamond => const Color(0xFF2FB4C9),
      };

  /// Nền nhạt cho huy hiệu (chip).
  Color get tint => color.withOpacity(0.14);

  IconData get icon => switch (this) {
        MemberTier.bronze => Icons.military_tech_rounded,
        MemberTier.silver => Icons.workspace_premium_rounded,
        MemberTier.gold => Icons.emoji_events_rounded,
        MemberTier.diamond => Icons.diamond_rounded,
      };
}

class MembershipRank {
  final MemberTier tier;
  final String rankName;
  final int completedOrders;
  final int totalSpent;
  final MemberTier? nextTier;
  final String? nextRankName;
  final int? nextMinOrders;
  final int? nextMinSpent;
  final int ordersToNext;
  final int spentToNext;

  const MembershipRank({
    required this.tier,
    required this.rankName,
    required this.completedOrders,
    required this.totalSpent,
    this.nextTier,
    this.nextRankName,
    this.nextMinOrders,
    this.nextMinSpent,
    this.ordersToNext = 0,
    this.spentToNext = 0,
  });

  bool get isMax => nextTier == null;

  /// Tiến độ 0..1 tới hạng kế (lấy phần chậm hơn giữa đơn & chi tiêu).
  double get progress {
    if (isMax || nextMinOrders == null || nextMinSpent == null) return 1;
    final po = nextMinOrders! <= 0
        ? 1.0
        : (completedOrders / nextMinOrders!).clamp(0.0, 1.0);
    final ps = nextMinSpent! <= 0
        ? 1.0
        : (totalSpent / nextMinSpent!).clamp(0.0, 1.0);
    return po < ps ? po : ps;
  }

  factory MembershipRank.fromJson(Map<String, dynamic> json) {
    final nextRaw = JsonX.strOrNull(json, ['nextRank', 'next_rank']);
    bool hasNum(List<String> keys) => JsonX.pick(json, keys) is num;
    return MembershipRank(
      tier: MemberTier.fromApi(JsonX.strOrNull(json, ['rank'])),
      rankName: JsonX.str(json, ['rankName', 'rank_name']),
      completedOrders:
          JsonX.intVal(json, ['completedOrders', 'completed_orders']),
      totalSpent: JsonX.intVal(json, ['totalSpent', 'total_spent']),
      nextTier: nextRaw != null ? MemberTier.fromApi(nextRaw) : null,
      nextRankName: JsonX.strOrNull(json, ['nextRankName', 'next_rank_name']),
      nextMinOrders: hasNum(['nextMinOrders', 'next_min_orders'])
          ? JsonX.intVal(json, ['nextMinOrders', 'next_min_orders'])
          : null,
      nextMinSpent: hasNum(['nextMinSpent', 'next_min_spent'])
          ? JsonX.intVal(json, ['nextMinSpent', 'next_min_spent'])
          : null,
      ordersToNext: JsonX.intVal(json, ['ordersToNext', 'orders_to_next']),
      spentToNext: JsonX.intVal(json, ['spentToNext', 'spent_to_next']),
    );
  }
}