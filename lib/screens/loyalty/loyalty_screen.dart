// lib/screens/loyalty/loyalty_screen.dart
//
// Điểm thưởng: số dư + lịch sử cộng/trừ điểm.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/loyalty_model.dart';
import '../../providers/loyalty_provider.dart';
import '../../utils/formatters.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(loyaltyBalanceProvider);
    final history = ref.watch(loyaltyHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm thưởng',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(loyaltyBalanceProvider);
          ref.invalidate(loyaltyHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _balanceCard(balance),
            const SizedBox(height: 20),
            const Text('Lịch sử điểm',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            _historyList(history),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(AsyncValue<LoyaltyBalance> balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.coffeeDark, AppColors.coffee],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Điểm hiện có',
                  style: TextStyle(color: Colors.white.withOpacity(0.9))),
            ],
          ),
          const SizedBox(height: 12),
          balance.when(
            loading: () => const SizedBox(
              height: 40,
              child: Center(
                  child: CircularProgressIndicator(color: Colors.white70)),
            ),
            error: (e, _) => const Text('Không tải được điểm',
                style: TextStyle(color: Colors.white)),
            data: (b) => Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${b.balance}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                const Text('điểm',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyList(AsyncValue<List<LoyaltyTransaction>> history) {
    return history.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Không tải được lịch sử: $e',
          style: const TextStyle(color: AppColors.textMuted)),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Chưa có giao dịch điểm nào',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          );
        }
        return Column(children: list.map(_txnTile).toList());
      },
    );
  }

  Widget _txnTile(LoyaltyTransaction t) {
    final positive = t.type.isPositive;
    final color = positive ? AppColors.success : AppColors.delivery;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
                positive
                    ? Icons.add_rounded
                    : Icons.remove_rounded,
                color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description ?? t.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(Formatters.dateTime(t.createdAt),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text('${t.signedAmount > 0 ? '+' : ''}${t.signedAmount}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}
