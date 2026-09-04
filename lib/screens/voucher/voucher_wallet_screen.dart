// ============================================================
//  FLUTTER
//  lib/screens/voucher/voucher_wallet_screen.dart
//  >> FILE MOI (man vi voucher)
// ============================================================

// lib/screens/voucher/voucher_wallet_screen.dart
// Ví voucher của khách (thay tab Scan). Chia Khả dụng / Hết hạn.
import 'package:flutter/material.dart';
import '../../widgets/anim.dart';
import '../../widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/voucher_wallet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/voucher_wallet_provider.dart';
import '../../utils/formatters.dart';
import '../auth/login_screen.dart';

class VoucherWalletScreen extends ConsumerStatefulWidget {
  const VoucherWalletScreen({super.key});
  @override
  ConsumerState<VoucherWalletScreen> createState() =>
      _VoucherWalletScreenState();
}

class _VoucherWalletScreenState extends ConsumerState<VoucherWalletScreen> {
  bool _showExpired = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        
        appBar: AppBar(title: const Text('Voucher')),
        body: _guestPrompt(context),
      ));
    }

    final async = ref.watch(availableVouchersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Voucher')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(availableVouchersProvider),
        child: async.when(
          loading: () => const ShimmerList(height: 96),
          error: (e, _) => ListView(children: [
            SizedBox(height: 120),
            Center(
                child: Text('Không tải được voucher',
                    style: TextStyle(color: AppColors.textMuted))),
          ]),
          data: (all) {
            final usable = all.where((v) => v.isUsable).toList();
            final expired = all.where((v) => !v.isUsable).toList();
            final list = _showExpired ? expired : usable;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  Expanded(
                      child: _tab('Khả dụng', usable.length, !_showExpired,
                          () => setState(() => _showExpired = false))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _tab('Hết hạn', expired.length, _showExpired,
                          () => setState(() => _showExpired = true))),
                ]),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Column(children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.coffee.withOpacity(0.12),
                        ),
                        child: Icon(Icons.card_giftcard_rounded,
                            size: 44, color: AppColors.coffee),
                      ),
                      const SizedBox(height: 16),
                      Text('Chưa có voucher',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      Text('Voucher & ưu đãi sẽ xuất hiện ở đây',
                          style:
                              TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ]),
                  )
                else
                  ...list.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _card(v))),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _guestPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.coffee.withOpacity(0.12),
              child: const Icon(Icons.confirmation_number_rounded,
                  color: AppColors.coffee, size: 36),
            ),
            const SizedBox(height: 14),
            const Text('Đăng nhập để xem voucher',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Nhận ngay ưu đãi dành cho khách hàng mới.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Đăng nhập'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int count, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active
              ? AppColors.coffee.withOpacity(0.12)
              : (AppColors.dark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: active
                  ? AppColors.coffee
                  : AppColors.textMuted.withOpacity(0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.coffee : AppColors.textDark)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
                color: active
                    ? AppColors.coffee
                    : AppColors.textMuted.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Text('$count',
                style: TextStyle(
                    color: active ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  Widget _card(VoucherWallet v) {
    final isShip = v.type == 'SHIPPING';
    final accent = isShip ? AppColors.success : AppColors.coffee;
    return Opacity(
      opacity: v.isUsable ? 1 : 0.6,
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(
                  isShip
                      ? Icons.local_shipping_rounded
                      : Icons.confirmation_number_rounded,
                  color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(isShip ? 'FREESHIP' : 'GIẢM GIÁ',
                        style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 4),
                  Text(v.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _row(Icons.local_offer_outlined, v.discountLabel),
          if (v.minOrderValue > 0)
            _row(Icons.shopping_bag_outlined,
                'Đơn từ ${Formatters.money(v.minOrderValue)}'),
          _row(Icons.access_time_rounded,
              'HSD đến ${Formatters.date(v.endDate)}'),
          _row(Icons.person_outline_rounded,
              'Giới hạn ${v.perUserLimit}/người'),
          _row(Icons.bar_chart_rounded,
              'Đã dùng ${v.usedByMe} - Còn ${v.remainingForMe} lượt'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withOpacity(0.3))),
            child: Text('Mã: ${v.code}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.coffeeDark,
                    fontSize: 13)),
          ),
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppColors.textDark, fontSize: 14))),
      ]),
    );
  }
}