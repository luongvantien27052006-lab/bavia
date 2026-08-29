// lib/screens/membership/membership_rank_screen.dart
//
// Màn Hạng thành viên: hạng hiện tại + tiến độ lên hạng kế + bảng 4 hạng.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/membership_rank.dart';
import '../../providers/loyalty_provider.dart';
import '../../utils/formatters.dart';

class MembershipRankScreen extends ConsumerWidget {
  const MembershipRankScreen({super.key});

  // Ngưỡng để hiển thị bảng (khớp backend).
  static const _tiers = [
    (MemberTier.bronze, 0, 0),
    (MemberTier.silver, 5, 200000),
    (MemberTier.gold, 10, 700000),
    (MemberTier.diamond, 20, 1000000),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(membershipRankProvider);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Hạng thành viên'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Không tải được hạng thành viên. Thử lại sau.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
        data: (r) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(membershipRankProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _hero(r),
              const SizedBox(height: 18),
              if (!r.isMax) _progress(r) else _maxBanner(r),
              const SizedBox(height: 24),
              Text('Các hạng & ưu đãi',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('Voucher vào ví đầu mỗi tháng · dùng trong 30 ngày',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              ..._tiers.reversed
                  .map((t) => _tierRow(t.$1, t.$2, t.$3, r.tier)),
              const SizedBox(height: 20),
              Text(
                'Đơn được tính khi bạn bấm "Đã nhận hàng" và đơn hoàn tất. '
                'Tổng chi tiêu cộng dồn từ các đơn đã hoàn thành. '
                'Ưu đãi theo hạng được tặng vào ví đầu mỗi tháng, mỗi mã dùng 1 lần trong 30 ngày.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(MembershipRank r) {
    final c = r.tier.color;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, Color.lerp(c, Colors.black, 0.28)!],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: c.withOpacity(0.32),
              blurRadius: 22,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18)),
            child: Icon(r.tier.icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hạng hiện tại',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12)),
                const SizedBox(height: 2),
                Text(r.rankName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(
                    '${r.completedOrders} đơn · ${Formatters.money(r.totalSpent)}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9), fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress(MembershipRank r) {
    final nextColor = (r.nextTier ?? r.tier).color;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: nextColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Lên hạng ${r.nextRankName}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ),
              Text('${(r.progress * 100).round()}%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: nextColor)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: r.progress,
              minHeight: 9,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(nextColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _needTile('Còn ${r.ordersToNext} đơn',
                    'Đã ${r.completedOrders}/${r.nextMinOrders}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _needTile(
                    'Còn ${Formatters.money(r.spentToNext)}',
                    'Đã ${Formatters.money(r.totalSpent)}/${Formatters.money(r.nextMinSpent ?? 0)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _needTile(String big, String small) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(big,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(small,
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _maxBanner(MembershipRank r) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: r.tier.tint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: r.tier.color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: r.tier.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Bạn đang ở hạng cao nhất. Cảm ơn bạn! 💚',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  /// Ưu đãi mỗi hạng (khớp gói tháng + thưởng lên hạng ở backend).
  List<(IconData, String)> _perksFor(MemberTier tier) {
    switch (tier) {
      case MemberTier.bronze:
        return const [
          (
            Icons.local_shipping_rounded,
            'Freeship 12k mỗi tháng (đơn từ 40k)'
          ),
        ];
      case MemberTier.silver:
        return const [
          (Icons.confirmation_number_rounded, 'Giảm 10% tối đa 15k mỗi tháng'),
          (Icons.local_shipping_rounded, 'Freeship 15k mỗi tháng'),
          (Icons.card_giftcard_rounded, 'Thưởng 20k khi lên hạng'),
        ];
      case MemberTier.gold:
        return const [
          (Icons.confirmation_number_rounded, 'Giảm 15% tối đa 25k mỗi tháng'),
          (Icons.local_shipping_rounded, 'Freeship 18k mỗi tháng'),
          (Icons.card_giftcard_rounded, 'Thưởng 30k khi lên hạng'),
        ];
      case MemberTier.diamond:
        return const [
          (Icons.confirmation_number_rounded, 'Giảm 20% tối đa 30k mỗi tháng'),
          (Icons.local_shipping_rounded, 'Freeship 25k mỗi tháng'),
          (Icons.card_giftcard_rounded, 'Thưởng 50k khi lên hạng'),
        ];
    }
  }

  Widget _tierRow(MemberTier tier, int orders, int spent, MemberTier current) {
    final isCurrent = tier == current;
    final achieved = tier.index <= current.index;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isCurrent ? tier.color : AppColors.border,
            width: isCurrent ? 1.6 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(color: tier.tint, shape: BoxShape.circle),
            child: Icon(tier.icon, color: tier.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tier.label,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: tier.color,
                            borderRadius: BorderRadius.circular(999)),
                        child: const Text('Hiện tại',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                    tier == MemberTier.bronze
                        ? 'Hạng khởi đầu'
                        : '$orders đơn · ${Formatters.money(spent)}',
                    style:
                        TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                ..._perksFor(tier).map((perk) => Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(perk.$1, size: 14, color: tier.color),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(perk.$2,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.3,
                                    color: AppColors.textDark)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          if (achieved)
            Icon(Icons.check_circle_rounded, color: tier.color, size: 22),
        ],
      ),
    );
  }
}