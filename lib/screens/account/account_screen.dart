// ============================================================
//  FLUTTER
//  lib/screens/account/account_screen.dart
//  >> CHEP DE (them muc Gioi thieu ban be)
// ============================================================

// ============================================================
//  FLUTTER
//  lib/screens/account/account_screen.dart
//  >> CHEP DE (trang thai khach + nut Dang nhap)
// ============================================================

// lib/screens/account/account_screen.dart
//
// Tab Tài khoản: thẻ user (bấm mở Hồ sơ), Lịch sử đơn, Sổ địa chỉ,
// Điểm thưởng, và Đăng xuất.

import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/theme_switcher.dart';
import '../../utils/formatters.dart';
import '../auth/login_screen.dart';
import '../address/address_list_screen.dart';
import '../loyalty/loyalty_screen.dart';
import '../orders/order_history_screen.dart';
import '../profile/profile_screen.dart';
import '../legal/legal_screen.dart';
import '../referral/referral_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        
      appBar: AppBar(
        title: const Text('Tài khoản',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: user == null
          ? _guestView(context, ref)
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.coffeeDark, AppColors.coffee],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? 'Khách',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        user != null
                            ? Formatters.prettyPhone(user.phone)
                            : '',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ),
          ),
          const SizedBox(height: 16),
          _tile(context, Icons.receipt_long_rounded, 'Lịch sử đơn hàng',
              'Xem các đơn đã đặt', const OrderHistoryScreen()),
          _tile(context, Icons.location_on_rounded, 'Sổ địa chỉ',
              'Quản lý địa chỉ giao hàng', const AddressListScreen()),
          _tile(context, Icons.card_giftcard_rounded, 'Điểm thưởng',
              'Số dư & lịch sử điểm', const LoyaltyScreen()),
          _tile(context, Icons.groups_rounded, 'Giới thiệu bạn bè',
              'Nhận voucher & điểm khi mời bạn', const ReferralScreen()),
          _tile(context, Icons.privacy_tip_rounded, 'Chính sách & Điều khoản',
              'Điều khoản sử dụng và quyền riêng tư', const LegalScreen()),
          const SizedBox(height: 6),
          _themeTile(context, ref),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.delivery),
            label: const Text('Đăng xuất',
                style: TextStyle(color: AppColors.delivery)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.delivery),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _guestView(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.coffee.withOpacity(0.12),
              child: const Icon(Icons.person_outline_rounded,
                  color: AppColors.coffee, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Bạn chưa đăng nhập',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để quản lý tài khoản, xem đơn hàng và nhận ưu đãi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Đăng nhập ngay'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LegalScreen()),
              ),
              child: Text('Chính sách & Điều khoản',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            const SizedBox(height: 8),
            _themeTile(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _themeTile(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: isDark,
        onChanged: (v) => ThemeSwitcher.run(
          context,
          () => ref
              .read(themeModeProvider.notifier)
              .setMode(v ? ThemeMode.dark : ThemeMode.light),
        ),
        activeColor: AppColors.coffee,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: AppColors.coffee,
        ),
        title: const Text('Chế độ tối',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          isDark ? 'Đang bật — nền tối' : 'Đang tắt — nền sáng',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title,
      String subtitle, Widget destination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: AppColors.coffee),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: AppColors.textMuted),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => destination),
        ),
      ),
    );
  }
}